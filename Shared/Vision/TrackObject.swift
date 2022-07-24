//
//  TrackObject.swift
//  ProjectileAim
//
//  Created by Mikael Waninger on 2022-04-13.
//

import Foundation
import Vision
import UIKit

class TrackObject {
    var objectToTrack: CGRect?
    var frames: [CVPixelBuffer]?
    var times: [TimeInterval]?
    var trackedPoints = [CGPoint]()
    
    func setObjectToTrack(rect: CGRect) {
        objectToTrack = rect
    }
    
    func setBuffer(buffer: [CVPixelBuffer]) {
        frames = buffer
    }
    
    func setTime(times: [TimeInterval]) {
        self.times = times
    }
    
    func getPoints()->[CGPoint]{
        return trackedPoints
    }
    
    func performTracking() {
        var inputObservations = VNDetectedObjectObservation(boundingBox: objectToTrack!)
        let requestHandler = VNSequenceRequestHandler()
        print(frames?.count)
        
        for frame in frames! {
            
            //print(frames?.firstIndex(of: frame)!)
            
            var trackingRequests = [VNRequest]()
            
            lazy var request: VNTrackingRequest = {
                let trackObjectRequest = VNTrackObjectRequest(detectedObjectObservation: inputObservations)
                return trackObjectRequest
            }()
            request.trackingLevel = VNRequestTrackingLevel.accurate
            trackingRequests.append(request)
            
            do {
                try requestHandler.perform(trackingRequests, on: frame)
                } catch {
                    print(error)
            }
            
            var result = trackingRequests.first?.results as? [VNDetectedObjectObservation]
            if result != nil {
                //print(result!.first)
                let point = CGPoint(x: (result?.first?.boundingBox.midX)!, y: (result?.first?.boundingBox.midY)!)
                inputObservations = (result?.first)!
                trackedPoints.append(point)
            } else {
                let point = CGPoint(x: 0, y: 0)
                trackedPoints.append(point)
            }
            
        }        
    }

}
