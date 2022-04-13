//
//  AnchorEntitys.swift
//  ProjectileAim
//
//  Created by Mikael Waninger on 2022-04-13.
//

import Foundation
import ARKit
import RealityKit


class CreatAnchorEntity{
    static func CreateEntity(anchor:ARAnchor)->AnchorEntity{
        let entity = AnchorEntity(anchor: anchor)
        
        let box = MeshResource.generateBox(size: 0.5, cornerRadius: 0.05)
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let diceEntity = ModelEntity(mesh: box, materials: [material])
        entity.addChild(diceEntity)
        return entity
    }
}
