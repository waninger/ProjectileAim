//
//  ContentView.swift
//  ProjectileAim
//
//  Created by Mikael Waninger on 2022-04-13.
//

import SwiftUI
import RealityKit
import ARKit

struct RealityKitView: UIViewRepresentable {
    private var worldConfiguration = ARWorldTrackingConfiguration()
    @StateObject var cameraData = CameraData.shared

    func makeUIView(context: Context) -> ARView {
        setupObjectDetection()
        
        let view = ARView()        
        let session = view.session
        session.delegate = cameraData
                
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        view.addSubview(coachingOverlay)
        
        session.run(worldConfiguration)
        
       return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        while cameraData.newAnchors.count > 0 {
            let anchor = cameraData.newAnchors.removeFirst()
            view.session.add(anchor: anchor)
            let entity: AnchorEntity
            if anchor.name == "text" {
                var time = ""
                cameraData.speeds.forEach{ speed in
                    time.append(String(speed) + "\n")
                }
                entity = CreatAnchorEntity.CreateEntity(anchor: anchor, timeStamp: time)
                view.scene.addAnchor(entity)
            } else {
                if anchor.name != "parabola" {
                    entity = CreatAnchorEntity.CreateEntity(anchor: anchor, timeStamp: nil)
                    view.scene.addAnchor(entity)
                }
            }
        }
    }
    
    private func setupObjectDetection() {
      guard let referenceObjects = ARReferenceObject.referenceObjects(
        inGroupNamed: "AR", bundle: nil) else {
          fatalError("Missing expected asset catalog resources.")
      }

        worldConfiguration.detectionObjects = referenceObjects
        worldConfiguration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
    }
}


struct ContentView: View {
   
  var body: some View {
      RealityKitView()
          .ignoresSafeArea()
      Button("START") {
          print("start recording")
          CameraData.shared.startRecording()
      }
      
      Button("RESET") {
          CameraData.shared.resetValues()
      }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
      ContentView()
  }
}
