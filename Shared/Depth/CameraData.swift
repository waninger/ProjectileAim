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
    let session = ARSession()
    let config = ARWorldTrackingConfiguration()
        
    @Published var currentFrame: CVPixelBuffer?
    
    static let shared = CameraData()
    
    private override init(){
        super.init()
        session.delegate=self
        session.run(config)
        print("initialized")
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.currentFrame = frame.capturedImage
        print(frame.capturedDepthDataTimestamp)
    }
    
}
