//
//  TrackObject.swift
//  ProjectileAim
//
//  Created by Mikael Waninger on 2022-04-13.
//

import Foundation
import Vision
import UIKit

class TrackObject{
    var results: [VNDetectedObjectObservation]?
    var inputObservations = [UUID: VNDetectedObjectObservation]()
    let requestHandler = VNSequenceRequestHandler()
    var trackingLevel = VNRequestTrackingLevel.fast
    var observation : VNDetectedObjectObservation?

    
    func setObservationRect(rect:CGRect){
        observation = VNDetectedObjectObservation(boundingBox: rect)
    }

    func TrackObject(buffer:CVPixelBuffer){
        
        var requests = [VNRequest]()
        lazy var request: VNTrackingRequest = {
            let trackingRequest = VNTrackObjectRequest(detectedObjectObservation: observation!)
            return trackingRequest
        }()
        requests.append(request)
        
        do {
            try requestHandler.perform(requests, on: buffer)
            } catch {
                print(error)
        }
        
        print(requests.first?.results?.first as? VNDetectedObjectObservation)
        results = request.results as? [VNDetectedObjectObservation]
    }
    
    func completionHandler(request: VNRequest, error: Error?) {
        guard let result = request.results as? [VNDetectedObjectObservation] else { return }
        results = result
    }
}
