/// Copyright (c) 2021 Razeware LLC
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

import SwiftUI
import RealityKit
import ARKit

struct RealityKitView: UIViewRepresentable {
    private var worldConfiguration = ARWorldTrackingConfiguration()

    func makeUIView(context: Context) -> ARView {
        setupObjectDetection()
        
        let view = ARView()
        let session = view.session
        session.delegate = CameraData.shared
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        view.addSubview(coachingOverlay)
        session.run(worldConfiguration)
       return view
    }

    func updateUIView(_ view: ARView, context: Context) {
    }
    
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
        worldConfiguration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
    }

}


struct ContentView: View {
  var body: some View {
      RealityKitView()
          .ignoresSafeArea()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
