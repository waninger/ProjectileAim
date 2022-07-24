//
//  captureVideo.swift
//  ProjectileAim (iOS)
//
//  Created by Mikael Waninger on 2022-06-01.
//

import Foundation
import AVFoundation
import Photos

class CaptureVideo{
    var videoBuffer: [CVPixelBuffer]?
    var pixelBufferAdaptor:AVAssetWriterInputPixelBufferAdaptor?
    var videoInput:AVAssetWriterInput?;
    var assetWriter:AVAssetWriter?;
    static let shared = CaptureVideo()
    // skapa en url
    // writer
    public func setBuffer(videoBufferIn: [CVPixelBuffer]){
        videoBuffer = videoBufferIn
    }
    
    public func saveVideo(videoName: String, size: CGSize){
        if videoBuffer == nil { print("no buffer"); return}
        let videoURL = createURLForVideo(withName: videoName)
        prepareWriterAndInput( size: size, videoURL: videoURL)
        createVideo(images: videoBuffer!, fps: 60, size: size)
        finishVideoRecordingAndSave()
    }
    
    private func createURLForVideo(withName:String) -> URL{
        // Clear the location for the temporary file.
        let temporaryDirectoryURL:URL = URL.init(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true);
        let targetURL:URL = temporaryDirectoryURL.appendingPathComponent("\(withName).mp4")
        // Delete the file, incase it exists.
        do {
            try FileManager.default.removeItem(at: targetURL);
            
        } catch let error {
            NSLog("Unable to delete file, with error: \(error)")
        }
        return targetURL
    }
    
    
    private func prepareWriterAndInput(size:CGSize, videoURL:URL) {
        
        do {
            self.assetWriter = try AVAssetWriter(outputURL: videoURL, fileType: AVFileType.mp4)
            
            let videoOutputSettings: Dictionary<String, Any> = [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : size.width,
                AVVideoHeightKey : size.height
            ];
    
            self.videoInput  = AVAssetWriterInput (mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            self.videoInput!.expectsMediaDataInRealTime = true
            self.assetWriter!.add(self.videoInput!)
            
            // Create Pixel buffer Adaptor
            
            let sourceBufferAttributes:[String : Any] = [
                (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
                (kCVPixelBufferWidthKey as String): Float(size.width),
                (kCVPixelBufferHeightKey as String): Float(size.height)] as [String : Any]
            
            self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput!, sourcePixelBufferAttributes: sourceBufferAttributes);
            
            assetWriter?.startWriting()
            self.assetWriter?.startSession(atSourceTime: CMTime.zero);
        }
        catch {
            print("Failed to create assetWritter with error : \(error)");
        }
    }
    
    private func createVideo(images: [CVPixelBuffer], fps:Int, size:CGSize) {
           
           var currentframeTime:CMTime = CMTime.zero;
           var currentFrame:Int = 0;
                      
           while (currentFrame < images.count) {
    
               // When the video input is ready for more media data...
               if (self.videoInput?.isReadyForMoreMediaData)!  {
                   //print("processing current frame :: \(currentFrame)");
                       // Calc the current frame time
                   currentframeTime = CMTimeAdd(currentframeTime, CMTimeMake(value: 1, timescale: 60)) 

                       
                   //print("SECONDS : \(currentframeTime.seconds)")
                   //print("Current frame time :: \(currentframeTime)");
                       
                   self.pixelBufferAdaptor!.append(images[currentFrame], withPresentationTime: currentframeTime)
                       // increment frame
                       currentFrame += 1;
                   }
               }
           }
    
    private func finishVideoRecordingAndSave() {
            self.videoInput!.markAsFinished();
            self.assetWriter?.finishWriting(completionHandler: {
                print("output url : \(self.assetWriter?.outputURL)");
                
                PHPhotoLibrary.requestAuthorization({ (status) in
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: (self.assetWriter?.outputURL)!)
                    })
                })
                // Clear the original array
                self.videoBuffer?.removeAll()
            })
        }
}
