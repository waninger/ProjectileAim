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
    @Published var parabola: [VNPoint]?
    
    private lazy var request: VNDetectTrajectoriesRequest = {
      return VNDetectTrajectoriesRequest(frameAnalysisSpacing: .zero,
                                         trajectoryLength: 15,
                                         completionHandler: completionHandler)
    }()
    func completionHandler(request: VNRequest, error: Error?) {
        var points: [VNPoint] = []
        guard let observations = request.results as? [VNTrajectoryObservation] else { return }
        observations.first?.detectedPoints.forEach {point in points.append(point)}
        if !observations.isEmpty{
            DispatchQueue.main.async {
                self.parabola = points
            }
        }
    }
    
    static let shared = CameraData()
    
    private override init(){
        super.init()
        session.delegate=self
        session.run(config)
        print("initialized")
    }
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.currentFrame = frame.capturedImage
        if currentFrame != nil{
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage)
            do {
                try requestHandler.perform([request])
            } catch {
                print(error)
            }
          }
    }
    
}
