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
    @Published var boundingBox = [simd_float4x4]()
    private let trackObject = TrackObject()
    
    private override init() {
        super.init()
    }


    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if frame.anchors.count > anchors.count{
            anchors = frame.anchors
        }
        trackObject.TrackObject(buffer: frame.capturedImage)
        calculateDistance(frame: frame)
        
        if trackObject.results?.first != nil && frame.sceneDepth?.depthMap != nil {
            boundingBox = [simd_float4x4]()
            trackObject.results?.forEach{ result in
                anchors.forEach{ anchor in
                }
                /*
                if result.uuid.uuidString not in
                anchors.append(ARAnchor())
                boundingBox.append( CreateTransform(frameIn: frame))
                 */
            }
        }
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
        transform.columns.3[0] = X
        transform.columns.3[1] = Y
        transform.columns.3[2] = Z
        transform.columns.3[3] = 1
        
        //print(transform)
        return transform
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

