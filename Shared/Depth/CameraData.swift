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
    @Published var anchors = [ARAnchor]()
    @Published var newAnchors = [ARAnchor]()
    @Published var planeAnchor:ARAnchor?
    private let trackObject = TrackObject()
    var savedPixelBuffer = [CVPixelBuffer]()
    var savedTimestamps = [TimeInterval]()
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
        print(recording)
        // Recording allowed and set start
        if(recording == true) {
            
            if(savedPixelBuffer.isEmpty) {
                
                var anchor = anchors.last(where: { $0.name == "boll" })
                if(anchor != nil ){
                    print(anchor?.name)
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
                    print("COUNT: ", self.savedPixelBuffer.count)
                
                }
            }
        }
        
        if recording == true && savedTimestamps.count >= 420 {
            recording = false
            trackObject.setBuffer(buffer: savedPixelBuffer)
            trackObject.setTime(times: savedTimestamps)
            DispatchQueue.global().async {
                self.trackObject.performTracking()
            }
            savedPixelBuffer.removeAll()
            savedTimestamps.removeAll()
        }
        
        // adding new anchors to view
        if newAnchors.isEmpty != true { newAnchors.removeAll()}
        if planeAnchor != nil { planeAnchor = nil }
       
        if frame.anchors.first != nil {
        }
        
        // anchor management
        if anchors.count < frame.anchors.count{
            anchors = frame.anchors
            newAnchors.append(frame.anchors.last!)
            
            // om vi har hittat både boll och mål skapa plan
            if(anchors.last?.name == "boll"){
                
                planeAnchor = createPlaneAnchor(fromMatrix: frame.anchors.last!.transform, toMatrix: frame.camera.transform)
                newAnchors.append(planeAnchor!)
                session.add(anchor: planeAnchor!)
            }
        }
        if self.savedPixelBuffer.count >= 420 {
            self.recording = false
        }
    }
    //MARK: save image and information
    
    
    //MARK: World setup and anchors
    func createPlaneAnchor(fromMatrix: simd_float4x4, toMatrix:simd_float4x4)->ARAnchor{
        let anchor = ARAnchor(name: "boundingbox", transform: CreatePlaneTransform(fromMatrix,toMatrix))
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
        
        var y =  1440 - pixelPlacement.y
        y = y/1440
        var x = pixelPlacement.x/1920
        y = y - 0.05
        x = x - 0.05
        
        let rect = CGRect(x: x, y: y, width: 0.1, height: 0.1)
        if rect.minX>0 && rect.maxX<1 && rect.minY>0 && rect.maxY<1{
            return rect
        }else {return nil}
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

