//
//  Depth.swift
//  ProjectileAim (iOS)
//
//  Created by Mikael Waninger on 2022-04-06.
//

import Foundation
import ARKit
import UIKit
import SceneKit


class CameraData:NSObject, ARSessionDelegate, ObservableObject{
    static let shared = CameraData()
    //@Published var anchors = [ARAnchor]()
    @Published var parabolaAnchors = [ARAnchor]()
    @Published var newAnchors = [ARAnchor]()
    @Published var planeAnchor:ARAnchor?
    var anchorCount = 0
    private let trackObject = TrackObject()
    var savedPixelBuffer = [CVPixelBuffer]()
    var savedTimestamps = [TimeInterval]()
    var pointsFromTracking = [CGPoint]()
    var recording = false
    
    private override init() {
        super.init()
    }
    
    func startRecording() {
        recording = true
    }
    
    func checkSavedValues() {
        if savedTimestamps.count > 2 {
            for i in 0...savedTimestamps.count-2 {
                       if savedTimestamps[i] < savedTimestamps[i+1] {
                           print("true")
                       }
            }
        }
        
        if savedTimestamps.count == 420 {
            print("420")
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
     
        // Recording allowed and set start
        if(recording == true) {
            if(savedPixelBuffer.isEmpty) {
                
                let anchor = frame.anchors.last(where: { $0.name == "boll" })
                if(anchor != nil ){
                    let rect = worldToView(frame: frame, anchor: anchor!)
                    if(rect != nil) {
                        trackObject.setObjectToTrack(rect: rect!)
                    }else {
                        recording = false
                        print("rect is nil")
                    }
                }else {
                    recording = false
                    print("anchor is nil")
                }
            }
        }
        
        
        //MARK: Copy buffer from frame to new buffer
        if(recording == true) {
            
            DispatchQueue.global(qos: .userInitiated).async {
                if(self.savedPixelBuffer.count < 420) {
                    var _copy: CVPixelBuffer?
                    
                    CVPixelBufferCreate(
                                nil,
                                CVPixelBufferGetWidth(frame.capturedImage),
                                CVPixelBufferGetHeight(frame.capturedImage),
                                CVPixelBufferGetPixelFormatType(frame.capturedImage),
                                CVBufferCopyAttachments(frame.capturedImage, .shouldPropagate),
                                &_copy)
                    
                    guard let copy = _copy else { fatalError() }

                    CVPixelBufferLockBaseAddress(frame.capturedImage, .readOnly)
                    CVPixelBufferLockBaseAddress(copy, [])
                    defer
                    {
                        CVPixelBufferUnlockBaseAddress(copy, [])
                        CVPixelBufferUnlockBaseAddress(frame.capturedImage, .readOnly)
                    }

                    for plane in 0 ..< CVPixelBufferGetPlaneCount(frame.capturedImage)
                    {
                        let dest        = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
                        let source      = CVPixelBufferGetBaseAddressOfPlane(frame.capturedImage, plane)
                        let height      = CVPixelBufferGetHeightOfPlane(frame.capturedImage, plane)
                        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(frame.capturedImage, plane)

                        memcpy(dest, source, height * bytesPerRow)
                    }
                
                    self.savedPixelBuffer.append(_copy!)
                    self.savedTimestamps.append(frame.timestamp)
                        
                    let buf = CVPixelBufferGetWidth(self.savedPixelBuffer.last!)
                    
                    print("SAVED: ", buf)
                    //print("COUNT: ", self.savedPixelBuffer.count)
                
                }
            }
        }
        
        //On recording done
        if recording == true && savedPixelBuffer.count >= 420 {
            recording = false
            trackObject.setBuffer(buffer: savedPixelBuffer)
            trackObject.setTime(times: savedTimestamps)
            
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.global().async {
                self.trackObject.performTracking()
                group.leave()
            }
            
            group.notify(queue:.main) {
                self.pointsFromTracking = self.trackObject.trackedPoints
            }
            savedPixelBuffer.removeAll()
            savedTimestamps.removeAll()
        }
        
        // MARK: anchor management
        // adding new anchors to view
        //if !newAnchors.isEmpty { newAnchors.removeAll()}
        
        
        //points to anchor
        if !pointsFromTracking.isEmpty {
            var points = [CGPoint]()
            points.append(pointsFromTracking.removeFirst())
            parabolaAnchors.append(contentsOf: addPointsToWorld(frame: frame, points: points))
        }
        
        // adding parabola
        if !parabolaAnchors.isEmpty{
            parabolaAnchors.forEach { anchor in
                session.add(anchor: anchor)
            }
            parabolaAnchors.removeAll()
        }
        
        
        if anchorCount < frame.anchors.count{
            for count in anchorCount ..< frame.anchors.count{
                newAnchors.append(frame.anchors[count])
            }
            // om vi har hittat både boll och mål skapa plan
            if(planeAnchor == nil && frame.anchors.last(where: { $0.name == "boll" }) != nil ){
                planeAnchor = createPlaneAnchor(fromMatrix: frame.anchors.last!.transform, toMatrix: frame.camera.transform)
                session.add(anchor: planeAnchor!)
            }
            anchorCount = frame.anchors.count
        }
    }
    
    
    //MARK: World setup and anchors
    func addPointsToWorld(frame:ARFrame, points:[CGPoint])->[ARAnchor]{
        let plane = frame.anchors.last(where: { $0.name == "plane" })
        var i = 0
        var parabolaAnchors = [ARAnchor]()
        points.forEach { point in
            i += 1
            let viewportPoint = CGPoint(x: (1 - point.x) * 1920, y: point.y * 1440)
            let placement = frame.camera.unprojectPoint(viewportPoint, ontoPlane: plane!.transform, orientation: .landscapeLeft, viewportSize: frame.camera.imageResolution)
            if(placement != nil){
                var transform = simd_float4x4(1)
                transform.columns.3.x = placement!.x
                transform.columns.3.y = placement!.y
                transform.columns.3.z = placement!.z
        
                let anchor = ARAnchor(name: "parabola", transform: transform)
                parabolaAnchors.append(anchor)
            }else {
                print("failed to project: ",i)
            }
        }
        return parabolaAnchors
    }
    
    func createPlaneAnchor(fromMatrix: simd_float4x4, toMatrix:simd_float4x4)->ARAnchor{
        let anchor = ARAnchor(name: "plane", transform: CreatePlaneTransform(fromMatrix,toMatrix))
        return anchor
    }

    func CreatePlaneTransform(_ fromMatrix: simd_float4x4, _ toMatrix:simd_float4x4)->simd_float4x4{
        var transform = simd_float4x4(1)

        transform.columns.3 = (fromMatrix.columns.3)
        let angle = angleBetween(matrixA: transform, matrixB: toMatrix)
        transform = rotateY(matrix: transform, RadAngle: angle)
        transform = rotateX(matrix: transform, RadAngle: -Float.pi/2)
        return transform
    }
    func worldToView(frame: ARFrame, anchor: ARAnchor) -> CGRect?{
        let placement = simd_float3(x: (anchor.transform.columns.3.x), y: (anchor.transform.columns.3.y), z: (anchor.transform.columns.3.z))
        let pixelPlacement = frame.camera.projectPoint(placement, orientation: .landscapeLeft, viewportSize: frame.camera.imageResolution)
        
        if pixelPlacement.x>1920 || pixelPlacement.x < 0 || pixelPlacement.y > 1440 || pixelPlacement.y < 0 {
            return nil
        }
        
        var y = pixelPlacement.y/1440
        var x = (1920 - pixelPlacement.x)/1920
        y = y - 0.05
        x = x - 0.05
        
        let rect = CGRect(x: x, y: y, width: 0.1, height: 0.1)
        
        print(rect)
        
        return rect
      
    }

    // MARK: Matrix manipulation
    func rotateZ(matrix: simd_float4x4, RadAngle: Float)->simd_float4x4{
        let col1 = simd_float4(cosf(RadAngle),-sinf(RadAngle),0,0)
        let col2 = simd_float4(sinf(RadAngle),cosf(RadAngle),0,0)
        let col3 = simd_float4(0,0,1,0)
        let col4 = simd_float4(0,0,0,1)
        let rotation = simd_float4x4(col1,col2,col3,col4)
        return matrix*rotation
    }
    func rotateX(matrix: simd_float4x4, RadAngle: Float)->simd_float4x4{
        let col1 = simd_float4(1,0,0,0)
        let col2 = simd_float4(0,cosf(RadAngle),sinf(RadAngle),0)
        let col3 = simd_float4(0,-sinf(RadAngle),cosf(RadAngle),0)
        let col4 = simd_float4(0,0,0,1)
        let rotation = simd_float4x4(col1,col2,col3,col4)
        return matrix*rotation
    }
    func rotateY(matrix: simd_float4x4, RadAngle: Float)->simd_float4x4{
        let col1 = simd_float4(cosf(RadAngle),0,sinf(RadAngle),0)
        let col2 = simd_float4(0,1,0,0)
        let col3 = simd_float4(-sinf(RadAngle),0,cosf(RadAngle),0)
        let col4 = simd_float4(0,0,0,1)
        let rotation = simd_float4x4(col1,col2,col3,col4)
        return matrix*rotation
    }
    
    func angleBetween(matrixA: simd_float4x4, matrixB: simd_float4x4)->Float{
        let x = matrixB.columns.3.x - matrixA.columns.3.x
        let z = (matrixB.columns.3.z - matrixA.columns.3.z)
        print(matrixB.columns.3.x, matrixA.columns.3.x)
        print(x,z)
        print(atan2f(z, x))
        let angle = atan2f(z, x)
        return angle
    }
    
    // MARK: Calculations
    func calculateDistance(frame:ARFrame){
        let cx = frame.camera.transform.columns.3[0]
        let cy = frame.camera.transform.columns.3[1]
        let cz = frame.camera.transform.columns.3[2]
        frame.anchors.forEach { anchor in
            let ax = anchor.transform.columns.3[0]
            let ay = anchor.transform.columns.3[1]
            let az = anchor.transform.columns.3[2]
            let distance = sqrt(pow(ax-cx,2)+pow(ay-cy,2)+pow(az-cz,2))
        }
    }
}

