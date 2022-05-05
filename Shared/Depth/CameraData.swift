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
 
    private override init() {
        super.init()
    }
    

    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        DispatchQueue.global(qos: .userInitiated).async {
        
            if(self.savedPixelBuffer.count < 1000) {
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
            let buf = CVPixelBufferGetWidth(self.savedPixelBuffer.last!)
            
            print("SAVED: ", buf)
            print("COUNT: ", self.savedPixelBuffer.count)
        
            }
                
        }
        
        
        if newAnchors.isEmpty != true { newAnchors.removeAll()}
        if boundingBox != nil { boundingBox = nil }
        ////-----------------
        let placement = simd_float3(x: 0, y: 1, z: -3)
        
        let pixelPlacement = frame.camera.projectPoint(placement, orientation: .portrait, viewportSize: frame.camera.imageResolution)
        //print("pixel in frame: ",pixelPlacement)
        var worldPoint = frame.camera.unprojectPoint(CGPoint(x: 0.5,y: 0.5), ontoPlane: frame.camera.projectionMatrix(for: .portrait, viewportSize: frame.camera.imageResolution, zNear: CGFloat(1), zFar: CGFloat(5)), orientation: .portrait, viewportSize: frame.camera.imageResolution)
        
        //print(frame.camera.projectionMatrix)
        //print(frame.camera.projectionMatrix(for: .portrait, viewportSize: frame.camera.imageResolution, zNear: CGFloat(1), zFar: CGFloat(5)))
        //print("place in world: ", worldPoint?.x, worldPoint?.y
          //    , worldPoint?.z)
        ////----------------------------
        
        if anchors.count < frame.anchors.count{
            anchors = frame.anchors
            newAnchors.append(frame.anchors.last!)
            
            if(anchors.last?.name == "mugg"){
                print("mugg foun and adding rect")
                let placement = simd_float3(x: (anchors.last?.transform.columns.3.x)!, y: (anchors.last?.transform.columns.3.y)!, z: (anchors.last?.transform.columns.3.z)!)
                let pixelPlacement = frame.camera.projectPoint(placement, orientation: .landscapeRight, viewportSize: frame.camera.imageResolution)
                trackObject.setObservationRect(rect: CGRect(x: pixelPlacement.x/1920, y: pixelPlacement.y/1440, width: 0.1, height: 0.1))
                print(pixelPlacement)
                
                trackObject.trackObject(buffer: frame.capturedImage)
                boundingBox = createAnchor(frame: frame)
                newAnchors.append(boundingBox!)
                print("från point till camera",frame.camera.unprojectPoint(pixelPlacement, ontoPlane: frame.camera.projectionMatrix, orientation: .portrait, viewportSize: frame.camera.imageResolution))
                
            }
            
        }
        trackInterval -= 1
        if trackInterval < 0{
            trackInterval = 5
            trackObject.trackObject(buffer: frame.capturedImage)
        }
    }

    func createRect(){
        let rect = CGRect(x: 1000, y: 720, width: 300, height: 300)
    }
    
    func CreateTransform(frameIn:ARFrame)->simd_float4x4{
        var transform = simd_float4x4(1)
        
        CVPixelBufferLockBaseAddress(frameIn.sceneDepth!.depthMap, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(frameIn.sceneDepth!.depthMap)
        let byteBuffer = unsafeBitCast(baseAddress, to: UnsafeMutablePointer<Float32>.self)
        
        let X = Float((trackObject.results?.first?.boundingBox.midX)!)
        let Y = Float((trackObject.results?.first?.boundingBox.midY)!)
        let Z = byteBuffer[Int(X*256*192*Y)]

        
        transform = frameIn.camera.transform
        transform.columns.3[0] = X * 1920
        transform.columns.3[1] = Y * 1440
        transform.columns.3[2] -= Z
        transform.columns.3[3] = 1
        
        //print(transform)
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
}

