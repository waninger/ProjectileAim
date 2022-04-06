//
//  Depth.swift
//  ProjectileAim
//
//  Created by Mikael Waninger on 2022-03-29.
//

import Foundation
import AVFoundation

struct hello{
    static func sayHello() -> String{
        print("hello")
        return "hello there world"
    }
}
func initCamera(){
    guard let device = AVCaptureDevice.default(for: .video) else { return }
    let session = AVCaptureSession()
    let output = AVCaptureVideoDataOutput()
    
    let input = try AVCaptureDeviceInput(device:device)
    
    session.addInput(input)
    session.addOutput(output)
    
}

