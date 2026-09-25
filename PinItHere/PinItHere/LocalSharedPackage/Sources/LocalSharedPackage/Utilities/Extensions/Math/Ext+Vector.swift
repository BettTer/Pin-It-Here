//
//  File.swift
//  LocalSharedPackage
//
//  Created by YY.COUPLE on 2025-09-27.
//

import Foundation
import Combine

public struct Vec2Codable: Codable, Sendable {
    /// 存两个数
    var v: [Float]
    public init(_ vec: SIMD2<Float>) {
        v = [vec.x, vec.y]
    }
    public var vector: SIMD2<Float> {
        SIMD2(v[0], v[1])
    }
}

public struct Vec3Codable: Codable, Sendable {
    /// 存三个数
    var v: [Float]
    public init(_ vec: SIMD3<Float>) {
        v = [vec.x, vec.y, vec.z]
    }
    public var vector: SIMD3<Float> {
        SIMD3(v[0], v[1], v[2])
    }
}
