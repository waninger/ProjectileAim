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

        switch anchor.name{
 
        case "mugg":
            let box = MeshResource.generateBox(width: 1, height: 1, depth: 0.03)
            let material = SimpleMaterial(color: .orange,isMetallic: false)
            let diceEntity = ModelEntity(mesh: box, materials: [material])
            entity.addChild(diceEntity)
        case "Scan_10-13-8":
            let box = MeshResource.generatePlane(width: 1.2, depth: 0.03)
            let material = SimpleMaterial(color: .blue, isMetallic: true)
            let diceEntity = ModelEntity(mesh: box, materials: [material])
            entity.addChild(diceEntity)
        default:
            let box = MeshResource.generateBox(size: 0.5, cornerRadius: 0.05)
            let material = SimpleMaterial(color: .blue, isMetallic: true)
            let diceEntity = ModelEntity(mesh: box, materials: [material])
            entity.addChild(diceEntity)
        }
        return entity
    }
    static func CreateBoundingbox(anchor:ARAnchor)->AnchorEntity{
        
        let entity = AnchorEntity(anchor: anchor)
        
        let box = MeshResource.generateBox(size: 0.2, cornerRadius: 0.05)
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let diceEntity = ModelEntity(mesh: box, materials: [material])
        entity.addChild(diceEntity)
        print(entity.transform, entity.name)
        return entity
    }
}
