//
//  Depth.swift
//  ProjectileAim (iOS)
//
//  Created by Mikael Waninger on 2022-04-06.
//

import Foundation
import ARKit
import Vision

class CameraData:NSObject, ARSessionDelegate{
    static let shared = CameraData()
    
    private override init() {
        super.init()
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //frame.camera.transform.columns.
        print(frame.camera)
        print(frame.camera.transform.columns.0,"x")
        print(frame.camera.transform.columns.1,"y")
        print(frame.camera.transform.columns.2,"z")

        //print(frame.sceneDepth!.depthMap)
    }

        
        func calculateDistance(frame:ARFrame?){
            if frame != nil{
                frame?.anchors.forEach { frame in
                    //sqrt(())
                }
            }
        }
}
