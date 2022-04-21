//
//  Depth.swift
//  ProjectileAim (iOS)
//
//  Created by Mikael Waninger on 2022-04-06.
//

import Foundation
import ARKit


class CameraData:NSObject, ARSessionDelegate, ObservableObject{
    static let shared = CameraData()
    @Published var anchors = [ARAnchor]()
    @Published var newAnchors = [ARAnchor]()
    @Published var boundingBox:ARAnchor?
    private let trackObject = TrackObject()
    var trackInterval = 10
    
    private override init() {
        super.init()
    }


    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if newAnchors.isEmpty != true { newAnchors.removeAll()}
        if boundingBox != nil { boundingBox = nil }
        
        if anchors.count < frame.anchors.count{
            anchors = frame.anchors
            newAnchors.append(frame.anchors.last!)
            
            if(anchors.last?.name == "mugg"){
                print("mugg foun and adding rect")
                trackObject.setObservationRect(rect: CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1))
                trackObject.trackObject(buffer: frame.capturedImage)
                boundingBox = createAnchor(frame: frame)
                newAnchors.append(boundingBox!)
            }
            
        }
        trackInterval -= 1
        if trackInterval < 0{
            trackInterval = 10
            trackObject.trackObject(buffer: frame.capturedImage)
        }
        
        //print(frame.camera.projectPoint(<#T##point: simd_float3##simd_float3#>, orientation: .portrait, viewportSize: frame.camera.imageResolution))
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

