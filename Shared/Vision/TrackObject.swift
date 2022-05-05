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
    var point:CGPoint?
    var pixelBuffer = [CVPixelBuffer]()
    var timeIntervals = [TimeInterval]()
    var objectToTrack = CGRect()

    
    func setObservationRect(rect:CGRect){
        print(rect, rect.minX, rect.maxX, rect.minY, rect.maxY )
        if rect.minX>0 && rect.maxX<1920 && rect.minY>0 && rect.maxY<1440{
            print("set box")
            observation = VNDetectedObjectObservation(boundingBox: rect)
            point = rect.origin
        }
    }

    func trackObject(buffer:CVPixelBuffer){
        if observation != nil {
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
            results = request.results as? [VNDetectedObjectObservation]
            //print(results?.first)
        }
    }
    
    func completionHandler(request: VNRequest, error: Error?) {
        guard let result = request.results as? [VNDetectedObjectObservation] else { return }
        results = result
    }
}
