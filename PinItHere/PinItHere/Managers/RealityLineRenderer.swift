//
//  RealityManager.swift
//  PinItHere
//
//  Created by YY.COUPLE on 2025-09-25.
//

import Foundation
import RealityKit

final class RealityLineRenderer: NSObject {
    public static let shared = RealityLineRenderer()
    
    /// 生成 1/4 圆片（扇形），法线 +Y，位于 X–Z 平面
    func quarterDiskMesh(
        radius r: Float,
        segments: Int = 32,
        quadrant: Int
    ) -> MeshResource {
        // quadrant: 0=右上(+x,+z), 1=左上(-x,+z), 2=左下(-x,-z), 3=右下(+x,-z)
        let ranges: [(Float, Float)] = [
            (0, .pi/2),
            (.pi/2, .pi),
            (.pi, 3 * .pi/2),
            (3 * .pi/2, 2 * .pi)
        ]
        let (start, end) = ranges[quadrant]

        var pos: [SIMD3<Float>] = [.init(0,0,0)]
        var nor: [SIMD3<Float>] = [.init(0,1,0)]
        for i in 0...segments {
            let t = Float(i)/Float(segments)
            let a = start + (end - start) * t
            pos.append(.init(cos(a)*r, 0, sin(a)*r))
            nor.append(.init(0,1,0))
        }
        var idx: [UInt32] = []
        for i in 1...segments {
            idx += [0, UInt32(i), UInt32(i+1)]
        }
        var d = MeshDescriptor(name: "QuarterDisk")
        d.positions = .init(pos)
        d.normals   = .init(nor)
        d.primitives = .triangles(idx)
        return try! MeshResource.generate(from: [d])
    }
    
    /// 生成整圆圆盘（位于 X–Z 平面，法线 +Y）
    func fullDiskMesh(radius r: Float, segments: Int = 48) -> MeshResource {
        var positions: [SIMD3<Float>] = [.init(0, 0, 0)]  // 中心
        var normals:   [SIMD3<Float>] = [.init(0, 1, 0)]

        for i in 0...segments {
            let t = Float(i) / Float(segments)
            let a = 2 * .pi * t
            positions.append(.init(cos(a) * r, 0, sin(a) * r))
            normals.append(.init(0, 1, 0))
        }

        var indices: [UInt32] = []
        for i in 1...segments {
            indices += [0, UInt32(i), UInt32(i + 1)]
        }

        var d = MeshDescriptor(name: "FullDisk")
        d.positions = .init(positions)
        d.normals   = .init(normals)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }
}
