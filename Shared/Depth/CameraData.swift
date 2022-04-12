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
    // Add configuration variables here:
    let session = ARSession()
    private var worldConfiguration = ARWorldTrackingConfiguration()
    
    @Published var currentFrame: CVPixelBuffer?
    
    static let shared = CameraData()
    
    private override init() {
        super.init()
        setupObjectDetection()
        session.delegate = self
        session.run(worldConfiguration)
    }

    // MARK: - Configuration functions to fill out

    private func setupObjectDetection() {

      guard let referenceObjects = ARReferenceObject.referenceObjects(
        inGroupNamed: "AR", bundle: nil) else {
          fatalError("Missing expected asset catalog resources.")
      }

        worldConfiguration.detectionObjects = referenceObjects

    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

        currentFrame.self = frame.capturedImage
        
        for anchor in frame.anchors {
            print(anchor)
            
        }
        
        if let objectAnchor = frame.anchors as? ARObjectAnchor {
         
            
            // handleFoundObject(imageAnchor, node)
        } else {
         
        }
    }
    
}
