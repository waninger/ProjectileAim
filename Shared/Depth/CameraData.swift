//
//  Depth.swift
//  ProjectileAim (iOS)
//
//  Created by Mikael Waninger on 2022-04-06.
//

import Foundation
import ARKit
import Vision

//singelton
class CameraData:NSObject, ARSessionDelegate{
    let config = ARWorldTrackingConfiguration()
    
    @Published var session = ARSession()
    @Published var currentFrame: CVPixelBuffer?
    
    static let shared = CameraData()
    
    private override init(){
        super.init()
        session.delegate=self
        configSetup()
        session.run(config)
        print("initialized")
    }
    func configSetup(){
        config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.currentFrame = frame.capturedImage
        print(frame.anchors)
        CVPixelBufferLockBaseAddress(frame.sceneDepth!.depthMap, .readOnly)
        var a = CVPixelBufferGetBaseAddress(frame.sceneDepth!.depthMap)
        print(a)
        print(a?.load(as: Float32.self))
        a=a?.advanced(by: 24576)
        print(a)
        print(a?.load(as: Float32.self))
        //print(frame.sceneDepth!.depthMap)
    }
    
}
