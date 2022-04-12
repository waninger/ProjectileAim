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
        inGroupNamed: "AR Resources", bundle: nil) else {
          fatalError("Missing expected asset catalog resources.")
      }

        worldConfiguration.detectionObjects = referenceObjects

      guard let referenceImages = ARReferenceImage.referenceImages(
        inGroupNamed: "AR Resources", bundle: nil) else {
          fatalError("Missing expected asset catalog resources.")
      }
        worldConfiguration.detectionImages = referenceImages
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print(frame.anchors)
        currentFrame.self = frame.capturedImage
        
        if let objectAnchor = frame.anchors.first as? ARObjectAnchor {
          handleFoundObject(imageAnchor, node)
        } else {
         
        }
    }
    
    func handleFoundObject
}
