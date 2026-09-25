//
//  ViewRenderer.swift
//  PinItHere
//
//  Created by YY.COUPLE on 2025-09-23.
//

import SwiftUI
import UIKit
import RealityKit
import LocalSharedPackage

final class ViewRenderer: NSObject {
    @MainActor
    static func render<V: View>(_ view: V,
                                pixelSize: CGSize,
                                scale: CGFloat = 2.0,
                                isOpaque: Bool = true) -> CGImage? {
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = .init(pixelSize)
        renderer.scale = scale
        renderer.isOpaque = isOpaque
        return renderer.uiImage?.cgImage
    }
    
    /// 用 CGImage 生成 Unlit 材质（不受光照影响，像纸更接近原图）
    @MainActor
    public static func unlitMaterial(from cgImage: CGImage?, backgroundColor: UIColor) -> UnlitMaterial? {
        
        var mat = UnlitMaterial()
        
        if let image = cgImage,
           let texture = try? TextureResource(image: image, options: .init(semantic: .color)) {
            mat.color = .init(tint: backgroundColor, texture: .init(texture))
            
        } else {
            mat.color = .init(tint: backgroundColor)
            
        }
        
        return mat
    }
    
}

final class IndicatorSprites: NSObject {
    static let cornerTexture: TextureResource = {
        let img = ImageManager.fetchAssetsImage(.ARIndicator_oneQuarterCorner)!
        return try! TextureResource(image: img.cgImage!, options: .init(semantic: .color))
    }()
    
    static let crossTexture: TextureResource = {
        let img = ImageManager.fetchAssetsImage(.ARIndicator_crosshairs)!
        return try! TextureResource(image: img.cgImage!, options: .init(semantic: .color))
    }()
    
    /// PNG 仅用透明通道当 mask；颜色完全来自 `tint`
    static func unlitMasked(
        tint: UIColor,
        texture: TextureResource,
        alphaScale: Float = 1.0
    ) -> UnlitMaterial {
        var m = UnlitMaterial()
        
        // 颜色 = 纯色 tint（不使用 PNG 的 RGB）
        m.color = .init(tint: tint, texture: .init(texture))
        
        // 关键：始终把 blending 设为 .transparent，并把 PNG 当作 “不透明度贴图”
        m.blending = .transparent(opacity: .init(scale: 1.0))
        
        // 指示器一般需要双面可见
        m.faceCulling = .none
        return m
    }

    static func pbr(
        tint: UIColor,
        texture: TextureResource,
        alphaScale: Float = 1.0
    ) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        // 颜色只用 tint（不挂 color 纹理，避免被原图影响）
        m.baseColor = .init(tint: tint)
        m.metallic  = .init(floatLiteral: 0)
        m.roughness = .init(floatLiteral: 1)
        // 关键：透明度来自 maskTexture（即你的 PNG 的 alpha）
        m.blending  = .transparent(opacity: .init(scale: alphaScale, texture: .init(texture)))
        m.faceCulling = .none
        return m
    }
}
