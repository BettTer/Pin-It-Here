//
//  EXT+ARScene.swift
//  PinItHere
//
//  Created by YY.COUPLE on 2025-09-26.
//

import ARKit
import RealityKit
import SwiftUI
import Combine
import simd


extension ARFinalSceneView.Coordinator {
    /// 根据图片生成四角“括号” + 中心十字准星
    /// - Parameters:
    ///   - size: 大小
    ///   - unit: 边长
    ///   - color: 颜色
    /// - Returns: 四角“括号” + 中心十字准星
    private func makeImageIndicator(
        size: SIMD2<Float>,
        unit: Float,
        color: UIColor
    ) -> ModelEntity {

        func sprite(_ tex: TextureResource, rotateRad: Float = 0) -> ModelEntity {
            // 正方形小平面承载 sprite 贴图（不拉伸）
            let mesh = MeshResource.generatePlane(width: unit, depth: unit)
            let mat  = IndicatorSprites.pbr(tint: color, texture: tex)
            let e    = ModelEntity(mesh: mesh, materials: [mat])
            if rotateRad != 0 {
                e.transform.rotation *= simd_quatf(angle: rotateRad, axis: [0,1,0])
            }
            return e
        }

        let root = ModelEntity()
        let w = size.x, h = size.y
        let hw = w/2 - unit/2
        let hh = h/2 - unit/2

        // 四角（用同一角图，绕 Y 轴旋转）
        let topLeft = sprite(IndicatorSprites.cornerTexture, rotateRad: .pi)
        topLeft.position = [-hw, 0,  hh]
        
        let topRight = sprite(IndicatorSprites.cornerTexture, rotateRad: -.pi/2)
        topRight.position = [ hw, 0,  hh]
        
        let bottomLeft = sprite(IndicatorSprites.cornerTexture, rotateRad:  .pi/2)
        bottomLeft.position = [-hw, 0, -hh]
        
        let bottomRight = sprite(IndicatorSprites.cornerTexture, rotateRad: 0)
        bottomRight.position = [ hw, 0, -hh]
        

        // 中心十字（同样正方形，不拉伸）
        let cross = sprite(IndicatorSprites.crossTexture)
        cross.position = [0,0,0]
        
        let parts = [topLeft, topRight, bottomRight, bottomLeft, cross]
        parts.forEach { root.addChild($0) }
        
        indicatorParts = parts
        
        return root
    }
}
