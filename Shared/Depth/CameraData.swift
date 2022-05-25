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
import SwiftUI


class CameraData:NSObject, ARSessionDelegate, ObservableObject{
    static let shared = CameraData()

    var parabolaAnchors = [ARAnchor]()

    @Published var newAnchors = [ARAnchor]()
    var planeAnchor:ARAnchor?
    var anchorCount = 0
    private var trackObject = TrackObject()
    var savedPixelBuffer = [CVPixelBuffer]()
    var savedTimestamps = [TimeInterval]()
    var pointsFromTracking = [CGPoint]()
    var recording = false
    var reset = false
    
    
    private override init() {
        super.init()
    }
    
    func startRecording() {
        recording = true
    }
    
    
    func resetValues() {
        print("in reset to change text")
        trackObject = TrackObject()
        reset = true
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
                

                let anchor = frame.anchors.last(where: { $0.name == "mugg" })
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
                        
                    //let buf = CVPixelBufferGetWidth(self.savedPixelBuffer.last!)
                    
                    //print("SAVED: ", buf)
                    print("COUNT: ", self.savedPixelBuffer.count)
                
                }
            }
        }
        
        //On recording done;
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
                let anchors = self.addPointsToWorld(frame: frame, points: self.pointsFromTracking)
                self.parabolaAnchors.append(contentsOf: anchors)
                let res = self.filterParabolaPoints(anchors: self.parabolaAnchors, timestamps: self.savedTimestamps)
                print(res.0.count, res.1[2])
            }
            savedPixelBuffer.removeAll()
            //savedTimestamps.removeAll()
        }
        
        //reset
        if reset && !recording {
            session.currentFrame?.anchors.forEach{ anchor in
                if anchor.name == "parabola"{
                    session.remove(anchor: anchor)
                }
            }
            print("anchor count: ",anchorCount, frame.anchors.count)
            trackObject = TrackObject()
            savedPixelBuffer.removeAll()
            savedTimestamps.removeAll()
            reset = false
        }
        

        // MARK: anchor management
        //Create 3D anchor from 2D point. One for each frame, not all at the same time, to ease processor
        //Add new anchor, created from 2D points, to the current session. This triggers the view which then draws the parabola.
        
        if !parabolaAnchors.isEmpty {
            // rensa parabola anchors
            session.add(anchor: parabolaAnchors.removeFirst())
            if parabolaAnchors.isEmpty {
                // hämta alla tidsstämplar
                let textAnchor = createTextAnchor(frame: frame)
                print(textAnchor.name)
                session.add(anchor: textAnchor)
            }
        }
        
        // om vi har hittat både boll och mål skapa plan
        if(planeAnchor == nil && frame.anchors.last(where: { $0.name == "mugg" }) != nil ){
            planeAnchor = createPlaneAnchor(fromMatrix: frame.anchors.last!.transform, toMatrix: frame.camera.transform)
            session.add(anchor: planeAnchor!)
        }
        
        // anchors to view
        if anchorCount < frame.anchors.count{
            for count in anchorCount ..< frame.anchors.count{
                newAnchors.append(frame.anchors[count])
                print(frame.anchors[count].name)
            }
            anchorCount = frame.anchors.count
        }else if anchorCount > frame.anchors.count { anchorCount = frame.anchors.count}
    }
    
    func createTextAnchor(frame: ARFrame)  -> ARAnchor {
        var transform = frame.camera.transform
        transform.columns.3 -= 2
         let anchor = ARAnchor(name: "text", transform: transform)
        print("creating textanchor", anchor.name)
        return anchor
    }
    
    
    //MARK: World setup and anchors
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
    
    func addPointsToWorld(frame:ARFrame, points:[CGPoint])-> [ARAnchor]{
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
    func filterParabolaPoints(anchors: [ARAnchor], timestamps:[TimeInterval]) -> ([ARAnchor],[Float]){
        var filterdPoints = [ARAnchor]()
        filterdPoints.append(anchors.first!)
        var speeds = [Float]()
        speeds.append(0)
        for count in 1 ... anchors.count { // kanske -1
            let distance = calculateDistance(anchorA: filterdPoints.last!, anchorB: anchors[count])
            if distance > 0.1{
                filterdPoints.append(anchors[count])
                let speed = (distance / Float(timestamps[count]-timestamps[count-1]) * 1000)
                print(speed)
                speeds.append(speed)
            }
        }
        return (filterdPoints,speeds)
    }
    
    //MARK: Plane creation
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
    func calculateDistance(anchorA: ARAnchor, anchorB: ARAnchor)->Float{
        let difference = (anchorA.transform.columns.3 - anchorB.transform.columns.3)
        let distance = sqrtf( powf(difference.x, 2) + powf(difference.y, 2) + powf(difference.z, 2))
        return distance
    }
}

