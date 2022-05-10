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
    
    
    func performTracking() {
        
        var inputObservations = VNDetectedObjectObservation(boundingBox: objectToTrack!)
        let requestHandler = VNSequenceRequestHandler()
        
        for frame in frames! {
            print(frames?.firstIndex(of: frame)!)
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
            print(result!.first)
            let point = CGPoint(x: (result?.first?.boundingBox.midX)!, y: (result?.first?.boundingBox.midY)!)
            trackedPoints.append(point)
            
            inputObservations = (result?.first)!
        }
        
        for point in trackedPoints {
            print("tracked points x: ", point.x, " y: ", point.y)
        }
        
    }
    /*
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
    }*/

}
