/// Copyright (c) 2022 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import AVFoundation
// 1
class CameraManager: ObservableObject {
  // 2
  enum Status {
    case unconfigured
    case configured
    case unauthorized
    case failed
  }
  // 3
  static let shared = CameraManager()
  // 4
  private init() {
    configure()
  }
  // 5
  private func configure() {
    checkPermissions()
    sessionQueue.async {
      self.configureCaptureSession()
      self.session.startRunning()
    }
  }
  
  // 1
  @Published var error: CameraError?
  // 2
  let session = AVCaptureSession()
  // 3
  private let sessionQueue = DispatchQueue(label: "com.raywenderlich.SessionQ")
  // 4
  private let videoOutput = AVCaptureVideoDataOutput()
  // 5
  private var status = Status.unconfigured
  
  private func set(error: CameraError?) {
    DispatchQueue.main.async {
      self.error = error
    }
  }

  private func checkPermissions() {
    // 1
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:
      // 2
      sessionQueue.suspend()
      AVCaptureDevice.requestAccess(for: .video) { authorized in
        // 3
        if !authorized {
          self.status = .unauthorized
          self.set(error: .deniedAuthorization)
        }
        self.sessionQueue.resume()
      }
    // 4
    case .restricted:
      status = .unauthorized
      set(error: .restrictedAuthorization)
    case .denied:
      status = .unauthorized
      set(error: .deniedAuthorization)
    // 5
    case .authorized:
      break
    // 6
    @unknown default:
      status = .unauthorized
      set(error: .unknownAuthorization)
    }
  }

  private func configureCaptureSession() {
    guard status == .unconfigured else {
      return
    }
    session.beginConfiguration()
    defer {
      session.commitConfiguration()
    }
    
    let device = AVCaptureDevice.default(
      .builtInWideAngleCamera,
      for: .video,
      position: .front)
    
    guard let camera = device else {
      set(error: .cameraUnavailable)
      status = .failed
      return
    }
  
    do {
      // 1
      let cameraInput = try AVCaptureDeviceInput(device: camera)
      // 2
      if session.canAddInput(cameraInput) {
        session.addInput(cameraInput)
      } else {
        // 3
        set(error: .cannotAddInput)
        status = .failed
        return
      }
    } catch {
      // 4
      set(error: .createCaptureInput(error))
      status = .failed
      return
    }
    // 1
    if session.canAddOutput(videoOutput) {
      session.addOutput(videoOutput)
      // 2
      videoOutput.videoSettings =
        [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
      // 3
      let videoConnection = videoOutput.connection(with: .video)
      videoConnection?.videoOrientation = .portrait
    } else {
      // 4
      set(error: .cannotAddOutput)
      status = .failed
      return
    }

    status = .configured
  }
  
  func set(
    _ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
    queue: DispatchQueue
  ) {
    sessionQueue.async {
      self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
    }
  }

}
