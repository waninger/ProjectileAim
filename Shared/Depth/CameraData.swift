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
 
        for anchor in frame.anchors {
            print(anchor.name , anchor.transform.columns.3)
            
        }
   
        
       // print(frame.camera.transform.columns.0,"x")
        //print(frame.camera.transform.columns.1,"y")
        //print(frame.camera.transform.columns.2,"z")

        calculateDistance(frame: frame)
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
            print(distance,"for anchor",anchor.identifier)
        }
    }
}

