//
//  Depth.swift
//  ProjectileAim (iOS)
//
//  Created by Mikael Waninger on 2022-04-06.
//

import Foundation
import ARKit

//singelton
class CameraData:NSObject, ARSessionDelegate{
    let session = ARSession()
    let config = ARWorldTrackingConfiguration()
    var parabola: TrackParabola?
        
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
        sendImage()
    }
    
    func setParabolaTracker (trackParabola:TrackParabola){
        parabola = trackParabola
    }
    private func sendImage(){
        if parabola != nil{
            parabola!.reciveFrame(frame:currentFrame)
        }
    }
}
