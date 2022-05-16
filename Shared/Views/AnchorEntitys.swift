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
            entity.name = "mugg"
            let box = MeshResource.generateBox(width: 0.01, height: 0.01, depth: 0.03)
            let material = SimpleMaterial(color: .orange,isMetallic: false)
            let diceEntity = ModelEntity(mesh: box, materials: [material])
            entity.addChild(diceEntity)
        case "Scan_10-13-8":
            entity.name = "mål"
            let box = MeshResource.generatePlane(width: 1.2, depth: 0.03)
            let material = SimpleMaterial(color: .blue, isMetallic: true)
            let diceEntity = ModelEntity(mesh: box, materials: [material])
            entity.addChild(diceEntity)
        case "plane":
            entity.name = "plane"
            let box = MeshResource.generatePlane(width: 0.3, depth: 0.3)
            let material = SimpleMaterial(color: .blue, isMetallic: false)
            let diceEntity = ModelEntity(mesh: box, materials: [material])
            entity.addChild(diceEntity)
        case "parabola":
            entity.name = "parabola"
            let ball = MeshResource.generateSphere(radius: 0.01)
            let material = SimpleMaterial(color: .yellow, isMetallic: false)
            let point = ModelEntity(mesh: ball, materials: [material])
            entity.addChild(point)
        default:
            let box = MeshResource.generateBox(size: 0.02, cornerRadius: 0.05)
            let material = SimpleMaterial(color: .blue, isMetallic: true)
            let diceEntity = ModelEntity(mesh: box, materials: [material])
            entity.addChild(diceEntity)
        }
        return entity
    }
}
