//
//  File.swift
//  LocalSharedPackage
//
//  Created by YY.COUPLE on 2025-10-01.
//

import Foundation
import simd

public extension simd_float4x4 {
    var position: SIMD3<Float> { SIMD3(columns.3.x, columns.3.y, columns.3.z) }
    var right:    SIMD3<Float> { simd_normalize(SIMD3(columns.0.x, columns.0.y, columns.0.z)) } // X
    var up:       SIMD3<Float> { simd_normalize(SIMD3(columns.1.x, columns.1.y, columns.1.z)) } // Y (plane normal)
    var forward:  SIMD3<Float> { simd_normalize(SIMD3(columns.2.x, columns.2.y, columns.2.z)) } // Z
}

public extension SIMD3<Float> {
    func stringValue() -> String {
        String(format:"(%.3f, %.3f, %.3f)", x, y, z)
    }
}

public extension SIMD3 where Scalar == Float {
    var isValid: Bool {
        return x.isFinite && y.isFinite && z.isFinite && simd_length_squared(self) > 1e-6
    }
}


public struct Mat4x4Codable: Codable, Sendable {
    /// 16 个数，列主序或行主序保持一致即可
    var m: [Float]
    public init(_ mat: simd_float4x4) {
        m = [
            mat.columns.0.x, mat.columns.0.y, mat.columns.0.z, mat.columns.0.w,
            mat.columns.1.x, mat.columns.1.y, mat.columns.1.z, mat.columns.1.w,
            mat.columns.2.x, mat.columns.2.y, mat.columns.2.z, mat.columns.2.w,
            mat.columns.3.x, mat.columns.3.y, mat.columns.3.z, mat.columns.3.w
        ]
    }
    public var matrix: simd_float4x4 {
        simd_float4x4(
            SIMD4(m[0], m[1], m[2], m[3]),
            SIMD4(m[4], m[5], m[6], m[7]),
            SIMD4(m[8], m[9], m[10], m[11]),
            SIMD4(m[12], m[13], m[14], m[15])
        )
    }
}
