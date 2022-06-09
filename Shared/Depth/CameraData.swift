//
//  Depth.swift
//  ProjectileAim (iOS)
//
//  Created by Mikael Waninger on 2022-04-06.
//

import Foundation
import ARKit
import UIKit
import SceneKit
import SwiftUI


class CameraData:NSObject, ARSessionDelegate, ObservableObject{
    static let shared = CameraData()
    private var trackObject = TrackObject()
    var fileManager = FileManager()
    private let saveVideo = CaptureVideo()
    @Published var newAnchors = [ARAnchor]()
    
    var parabolaAnchors = [ARAnchor]()
    var planeAnchor:ARAnchor?
    var goalPlaneAnchor: ARAnchor?
    var currentGoalAnchor: ARAnchor?
    
    var savedPixelBuffer = [CVPixelBuffer]()
    var savedTimestamps = [TimeInterval]()
    var pointsFromTracking = [CGPoint]()
    
    var speeds = [Float]()
    var recording = false
    var reset = false
    
    
    private override init() {
        super.init()
    }
    
    func startRecording() {
        recording = true
    }
    func resetValues(){
        reset = true
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
     
        // Recording allowed and set start
        if(recording == true) {
            if(savedPixelBuffer.isEmpty) {
                
                let anchor = frame.anchors.last(where: { $0.name == "boll" })
                if(anchor != nil ){
                    let rect = worldToView(frame: frame, anchor: anchor!)
                    if(rect != nil) {
                        trackObject.setObjectToTrack(rect: rect!)
                    }else {
                        recording = false
                        print("rect is nil")
                    }
                }else {
                    recording = false
                    print("anchor is nil")
                }
            }
        }
        
        
        //MARK: Copy buffer from frame to new buffer
        if(recording == true) {
            
            DispatchQueue.global(qos: .userInitiated).async {
                if(self.savedPixelBuffer.count < 420) {
                    var _copy: CVPixelBuffer?
                    
                    CVPixelBufferCreate(
                                nil,
                                CVPixelBufferGetWidth(frame.capturedImage),
                                CVPixelBufferGetHeight(frame.capturedImage),
                                CVPixelBufferGetPixelFormatType(frame.capturedImage),
                                CVBufferCopyAttachments(frame.capturedImage, .shouldPropagate),
                                &_copy)
                    
                    guard let copy = _copy else { fatalError() }

                    CVPixelBufferLockBaseAddress(frame.capturedImage, .readOnly)
                    CVPixelBufferLockBaseAddress(copy, [])
                    defer
                    {
                        CVPixelBufferUnlockBaseAddress(copy, [])
                        CVPixelBufferUnlockBaseAddress(frame.capturedImage, .readOnly)
                    }

                    for plane in 0 ..< CVPixelBufferGetPlaneCount(frame.capturedImage)
                    {
                        let dest        = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
                        let source      = CVPixelBufferGetBaseAddressOfPlane(frame.capturedImage, plane)
                        let height      = CVPixelBufferGetHeightOfPlane(frame.capturedImage, plane)
                        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(frame.capturedImage, plane)

                        memcpy(dest, source, height * bytesPerRow)
                    }
                
                    self.savedPixelBuffer.append(_copy!)
                    self.savedTimestamps.append(frame.timestamp)

                    print("COUNT: ", self.savedPixelBuffer.count)
                
                }
            }
        }
        
        //On recording done;
        if recording == true && savedPixelBuffer.count >= 420 {
            recording = false
            trackObject.setBuffer(buffer: savedPixelBuffer)
            saveVideo.setBuffer(videoBufferIn: savedPixelBuffer)
            trackObject.setTime(times: savedTimestamps)
            
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.global().async {
                self.trackObject.performTracking()
                group.leave()
            }
            
            group.notify(queue:.main) { [self] in
                self.pointsFromTracking = self.trackObject.trackedPoints
            }
            savedPixelBuffer.removeAll()
        }
        
        //reset
        if reset && !recording {
            session.currentFrame?.anchors.forEach{ anchor in
                if anchor.name == "parabola" || anchor.name == "text"{
                    session.remove(anchor: anchor)
                }
            }
            trackObject = TrackObject()
            savedPixelBuffer.removeAll()
            savedTimestamps.removeAll()
            parabolaAnchors.removeAll()
            pointsFromTracking.removeAll()
            speeds.removeAll()
            reset = false
        }else { reset = false}
        

        // MARK: anchor management

        // om vi har hittat både boll och mål skapa plan
        if(planeAnchor == nil && frame.anchors.last(where: { $0.name == "boll" }) != nil ){
            planeAnchor = createPlaneAnchor(fromMatrix: frame.anchors.last!.transform, toMatrix: frame.camera.transform)
            goalPlaneAnchor = createGoalPlaneAnchor(planeAnchor: planeAnchor!, distance: 0.5)
            newAnchors.append(planeAnchor!)
            newAnchors.append(goalPlaneAnchor!)
            newAnchors.append(frame.anchors.last(where: { $0.name == "boll" })!)
        }
        
        if !pointsFromTracking.isEmpty {
            let anchors = addPointsToWorld(frame: frame, points: pointsFromTracking)
            parabolaAnchors.append(contentsOf: anchors)
            
            let filterdPoints = filterParabolaPoints(anchors: parabolaAnchors, timestamps: savedTimestamps)
            
            // if filterd points are to few reset
            if filterdPoints.0.count > 10 {
                DispatchQueue.main.async {
                    self.saveVideo.saveVideo(videoName: "MakeItWork", size: frame.camera.imageResolution)
                }
                speeds = calculateSpeed(anchors: filterdPoints.0, timestamps: filterdPoints.1)!
                currentGoalAnchor = goalPoint(frame: frame, speeds: speeds, distance: 0.5, timestamps: filterdPoints.1, goalPlane: goalPlaneAnchor!, viewPoints: pointsFromTracking)
                newAnchors.append(contentsOf: filterdPoints.0)
                newAnchors.append(currentGoalAnchor!)
                newAnchors.append(createTextAnchor(transform: (filterdPoints.0.first?.transform)!))
                 
                let parabolaValues = convertToString(points: pointsFromTracking)
                var goalList = [Any]()
                goalList.append(currentGoalAnchor)
                fileHandling(list: speeds, fileName: "velocity.txt")
                fileHandling(list: parabolaValues, fileName: "parabola.txt")
                fileHandling(list: speeds, fileName: "goal.txt")
                
            } else { reset = true }
            pointsFromTracking.removeAll()
        }
    }
    
    func convertToString(points: [CGPoint]) -> [String] {
        var result = [String]()
        var s = String()
        points.forEach { CGpoint in
            s = String(Double(CGpoint.x)) + " " + String(Double(CGpoint.y))
            result.append(s)
            
        }
        return result
    }
    
    // MARK: Save to File
    func fileHandling(list: [Any], fileName: String) {
        
        fileManager.save(list: list,toDirectory: fileManager.documentDirectory(), withFileName: fileName)
        fileManager.read(fromDocumentsWithFileName: fileName)
        
    }
    
    //MARK: World setup and anchors
    func createTextAnchor(transform: simd_float4x4)  -> ARAnchor {
        let anchor = ARAnchor(name: "text", transform: transform)
        return anchor
    }
    
    func worldToView(frame: ARFrame, anchor: ARAnchor) -> CGRect?{
        let placement = simd_float3(x: (anchor.transform.columns.3.x), y: (anchor.transform.columns.3.y), z: (anchor.transform.columns.3.z))
        let pixelPlacement = frame.camera.projectPoint(placement, orientation: .landscapeLeft, viewportSize: frame.camera.imageResolution)
        
        if pixelPlacement.x>1920 || pixelPlacement.x < 0 || pixelPlacement.y > 1440 || pixelPlacement.y < 0 {
            return nil
        }
        
        var y = pixelPlacement.y/1440
        var x = (1920 - pixelPlacement.x)/1920
        y = y - 0.05
        x = x - 0.05
        
        let rect = CGRect(x: x, y: y, width: 0.1, height: 0.1)
        
        print(rect)
        return rect
    }
    
    func addPointsToWorld(frame:ARFrame, points:[CGPoint])-> [ARAnchor]{
        let plane = frame.anchors.last(where: { $0.name == "plane" })
        var i = 0
        var parabolaAnchors = [ARAnchor]()
        points.forEach { point in
            i += 1
            let viewportPoint = CGPoint(x: (1 - point.x) * 1920, y: point.y * 1440)
            let placement = frame.camera.unprojectPoint(viewportPoint, ontoPlane: plane!.transform, orientation: .landscapeLeft, viewportSize: frame.camera.imageResolution)
            if(placement != nil){
                var transform = simd_float4x4(1)
                transform.columns.3.x = placement!.x
                transform.columns.3.y = placement!.y
                transform.columns.3.z = placement!.z
        
                let anchor = ARAnchor(name: "parabola", transform: transform)
                parabolaAnchors.append(anchor)
            }else {
                print("failed to project: ",i)
            }
        }
        return parabolaAnchors
    }
    
    func filterParabolaPoints(anchors: [ARAnchor], timestamps:[TimeInterval]) -> ([ARAnchor],[TimeInterval]){
        var filterdPoints = [ARAnchor]()
        var filterdTimestamps = [TimeInterval]()
        filterdPoints.append(anchors.first!)
        filterdTimestamps.append(timestamps.first!)
        
        for count in 1 ... anchors.count-1 {
            let distance = calculateDistance(anchorA: filterdPoints.last!, anchorB: anchors[count], directional: false)
            if distance > 0.05{
                filterdPoints.append(anchors[count])
                filterdTimestamps.append(timestamps[count])
            }
        }
        return (filterdPoints,filterdTimestamps)
    }
    
    //MARK: Plane creation
    func createPlaneAnchor(fromMatrix: simd_float4x4, toMatrix:simd_float4x4)->ARAnchor{
        let anchor = ARAnchor(name: "plane", transform: CreatePlaneTransform(fromMatrix,toMatrix))
        return anchor
    }

    func CreatePlaneTransform(_ fromMatrix: simd_float4x4, _ toMatrix:simd_float4x4)->simd_float4x4{
        var transform = simd_float4x4(1)

        transform.columns.3 = (fromMatrix.columns.3)
        let angle = angleBetween(matrixA: transform, matrixB: toMatrix)
        transform = rotateY(matrix: transform, RadAngle: angle)
        transform = rotateX(matrix: transform, RadAngle: -Float.pi/2)
        return transform
    }
    
    func createGoalPlaneAnchor(planeAnchor: ARAnchor, distance:Float)-> ARAnchor{
        print("creating goal plane")
        var transform = planeAnchor.transform
        var translationVector = simd_float4(-distance,0,0,0)
        translationVector = transform * translationVector
        transform = rotateZ(matrix: transform, RadAngle: Float.pi/2)
        transform.columns.3 = transform.columns.3 + translationVector
        return ARAnchor(name: "goalPlane", transform: transform)
    }

    // MARK: Matrix manipulation
    func rotateZ(matrix: simd_float4x4, RadAngle: Float)->simd_float4x4{
        let col1 = simd_float4(cosf(RadAngle),-sinf(RadAngle),0,0)
        let col2 = simd_float4(sinf(RadAngle),cosf(RadAngle),0,0)
        let col3 = simd_float4(0,0,1,0)
        let col4 = simd_float4(0,0,0,1)
        let rotation = simd_float4x4(col1,col2,col3,col4)
        return matrix*rotation
    }
    func rotateX(matrix: simd_float4x4, RadAngle: Float)->simd_float4x4{
        let col1 = simd_float4(1,0,0,0)
        let col2 = simd_float4(0,cosf(RadAngle),sinf(RadAngle),0)
        let col3 = simd_float4(0,-sinf(RadAngle),cosf(RadAngle),0)
        let col4 = simd_float4(0,0,0,1)
        let rotation = simd_float4x4(col1,col2,col3,col4)
        return matrix*rotation
    }
    func rotateY(matrix: simd_float4x4, RadAngle: Float)->simd_float4x4{
        let col1 = simd_float4(cosf(RadAngle),0,sinf(RadAngle),0)
        let col2 = simd_float4(0,1,0,0)
        let col3 = simd_float4(-sinf(RadAngle),0,cosf(RadAngle),0)
        let col4 = simd_float4(0,0,0,1)
        let rotation = simd_float4x4(col1,col2,col3,col4)
        return matrix*rotation
    }
    
    func angleBetween(matrixA: simd_float4x4, matrixB: simd_float4x4)->Float{
        let x = matrixB.columns.3.x - matrixA.columns.3.x
        let z = (matrixB.columns.3.z - matrixA.columns.3.z)
        print(matrixB.columns.3.x, matrixA.columns.3.x)
        print(x,z)
        print(atan2f(z, x))
        let angle = atan2f(z, x)
        return angle
    }
    
    // MARK: Calculations
    func calculateDistance(anchorA: ARAnchor, anchorB: ARAnchor, directional: Bool)->Float{
        let difference = (anchorA.transform.columns.3 - anchorB.transform.columns.3)
        if(directional){
            let distance = sqrtf( powf(difference.x, 2) + powf(difference.z, 2))
            return distance
        } else {
            let distance = sqrtf( powf(difference.x, 2) + powf(difference.y, 2) + powf(difference.z, 2))
            return distance
        }
    }
    
    func calculateSpeed(anchors:[ARAnchor], timestamps: [TimeInterval])-> [Float]?{
        if anchors.count < 2{ return nil}
        
        var speeds = [Float]()
        speeds.append(0)
        
        for count in 1 ... anchors.count-1 {
            let distance = calculateDistance(anchorA: anchors[count-1], anchorB: anchors[count], directional: false)
            let timedif = Float(timestamps[count] - timestamps[count-1])
            let speed = (distance / timedif)
            speeds.append(speed)
        }
        return speeds
    }
    
    func goalPoint(frame:ARFrame, speeds: [Float], distance:Float, timestamps:[TimeInterval] ,goalPlane: ARAnchor,  viewPoints: [CGPoint])-> ARAnchor? {
        if speeds.count < 4 { return nil }
        let startingTime = timestamps[1]-timestamps[0]
        
        var currentDistance: Float
        currentDistance = 0.0
        var loopVar = 1
        var averageSpeed: Float
        averageSpeed = 0.0
        while currentDistance < distance/2 && loopVar < speeds.count-1 {
            currentDistance += speeds[loopVar]*(Float(timestamps[loopVar]-(timestamps[loopVar-1])))
            averageSpeed += speeds[loopVar]
            loopVar += 1
        }
        averageSpeed = averageSpeed/Float(loopVar)
        let time = distance/averageSpeed
        let frameInt = Int((time + Float(startingTime)) * 60)
        print("loop: ", loopVar, "speed: ", averageSpeed,"frameint: ", frameInt,"speedcount: ", speeds.count)

        
        let viewportPoint = CGPoint(x: (1 - viewPoints[frameInt].x) * 1920, y: viewPoints[frameInt].y * 1440)
        let placement = frame.camera.unprojectPoint(viewportPoint, ontoPlane: goalPlane.transform, orientation: .landscapeLeft, viewportSize: frame.camera.imageResolution)
        if(placement != nil){
            var transform = simd_float4x4(1)
            transform.columns.3.x = placement!.x
            transform.columns.3.y = placement!.y
            transform.columns.3.z = placement!.z
    
            let anchor = ARAnchor(name: "goalPoint", transform: transform)
            return anchor
        }else {
            print("could not place on goal")
        }
        return nil
    }
}

