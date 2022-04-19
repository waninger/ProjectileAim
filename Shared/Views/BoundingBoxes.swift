//
//  BondingBoxes.swift
//  ProjectileAim
//
//  Created by Mikael Waninger on 2022-04-13.
//

import Foundation
import RealityKit
import ARKit

class BoundingBox{
    var entity:AnchorEntity?
    var matrix = simd_float4x4()
    
    static func CreateBoundingbox(transform: simd_float4x4){
        let box = MeshResource.generatePlane(width: 1.2, depth: 0.03)
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let diceEntity = ModelEntity(mesh: box, materials: [material])
        //entity = AnchorEntity(anchor: ARAnchor(transform: transform))
        
    }
}
