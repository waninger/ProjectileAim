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
    var anchors = [ARAnchor]()
    
    private override init() {
        super.init()
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if frame.anchors.count > anchors.count{
            anchors = frame.anchors
        }
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

