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
    @Published var boundingBox:ARAnchor?
    private let trackObject = TrackObject()
    var trackInterval = 10

    var savedPixelBuffer = [CVPixelBuffer]()
    var savedTimestamps = [TimeInterval]()
    var recording = false

    private override init() {
        super.init()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
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
  
        
        if newAnchors.isEmpty != true { newAnchors.removeAll()}
        if boundingBox != nil { boundingBox = nil }
       
        if frame.anchors.first != nil {
        }

        if anchors.count < frame.anchors.count{
            anchors = frame.anchors
            newAnchors.append(frame.anchors.last!)
            
            if(anchors.last?.name == "mugg"){
                print("mugg foun and adding rect")
                let placement = simd_float3(x: (anchors.last?.transform.columns.3.x)!, y: (anchors.last?.transform.columns.3.y)!, z: (anchors.last?.transform.columns.3.z)!)
                let pixelPlacement = frame.camera.projectPoint(placement, orientation: .landscapeRight, viewportSize: frame.camera.imageResolution)
                //trackObject.setObservationRect(rect: CGRect(x: pixelPlacement.x/1920, y: pixelPlacement.y/1440, width: 0.1, height: 0.1))
                
                //trackObject.trackObject(buffer: frame.capturedImage)
                boundingBox = createAnchor(frame: frame)
                newAnchors.append(boundingBox!)
                session.add(anchor: boundingBox!)

            }
            
        }
        trackInterval -= 1
        if trackInterval < 0{
            trackInterval = 5
            trackObject.trackObject(buffer: frame.capturedImage)
        }
        
        if self.savedPixelBuffer.count >= 420 {
            self.recording = false
        }
        
    }

    func createRect(){
        let rect = CGRect(x: 1000, y: 720, width: 300, height: 300)
    }
    
    func CreateTransform(frameIn:ARFrame)->simd_float4x4{
        var transform = simd_float4x4(1)

        transform.columns.3 = (frameIn.anchors.last?.transform.columns.3)!
        let angle = angleBetween(matrixA: transform, matrixB: frameIn.camera.transform)
        print(angle)
        transform = rotateY(matrix: transform, RadAngle: angle)
        transform = rotateX(matrix: transform, RadAngle: -Float.pi/2)
        //transform.columns.3 = (frameIn.anchors.last?.transform.columns.3)!
        print(transform)
        return transform
    }
    
    func createAnchor(frame:ARFrame)->ARAnchor{
        let anchor = ARAnchor(name: "boundingbox", transform: CreateTransform(frameIn: frame))
        return anchor
    }
    
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
}

