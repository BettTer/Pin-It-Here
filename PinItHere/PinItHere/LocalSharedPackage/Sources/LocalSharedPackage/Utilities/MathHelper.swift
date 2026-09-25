//
//  MathHelper.swift
//  LocalSharedPackage
//
//  Created by YY.COUPLE on 2025-09-27.
//  Refined by ChatGPT (iOS+AR+AI)
//
//  结构化整理：
//  - Frames & Rotations：坐标系构造、旋转矩阵、向量对齐
//  - Polygon & Geometry：多边形内外判定、最近边界点、平面局部投影
//  - Utilities：角度差、设定位姿的平移列等
//

import Foundation
import simd
import ARKit

public class MathHelper: NSObject {}

// MARK: - ENU & Yaw helpers (placement-time)
public extension MathHelper {
    /// 从 AR 世界坐标构造 world->ENU 旋转：U 对齐世界Y；N 对齐 true north（绕U旋转一个 -trueHeading）
    /// 约定：我们让 ENU 在数学上对应 (E=+x, U=+y, N=+z)，这样和 RealityKit 的列向量直觉一致。
    static func makeWorldToENURotation(trueHeadingDeg: Double) -> simd_float3x3 {
        let headingRad = Float(trueHeadingDeg * .pi / 180.0)

        // 世界坐标选择：y 为 up
        let U_world = SIMD3<Float>(0, 1, 0)

        // 先把世界水平 XZ 的“世界北”对齐到 +Z（ENU的N）
        // 现实中“世界北”并不一定是某个固定轴，所以这里直接用绕U轴的旋转把“世界前向=+Z”校正到 true north:
        // 我们要把“世界 +Z”旋转到“地理北”方向 => 旋转量 = -(trueHeading)（右手系）
        let R_yaw = MathHelper.rotationAround3x3(axis: U_world, angle: -headingRad)

        // 由于我们约定 ENU 的 (x=E, y=U, z=N)，而世界 up 已经与 U 对齐，R_yaw 后即可认为 world->ENU
        return R_yaw
    }
    
}

// MARK: - Rotations
public extension MathHelper {
    /// 围绕任意轴的 3x3 旋转（核心实现：罗德里格公式）
    /// - Parameters:
    ///   - axis: 旋转轴（任意方向，内部会归一化）
    ///   - angle: 旋转角（弧度）
    /// - Returns: 3x3 旋转矩阵
    static func rotationAround3x3(axis: SIMD3<Float>, angle: Float) -> simd_float3x3 {
        let n = simd_normalize(axis)
        let c = cos(angle), s = sin(angle)
        let x = n.x, y = n.y, z = n.z
        return simd_float3x3(
            SIMD3(c + (1-c)*x*x,   (1-c)*x*y - s*z, (1-c)*x*z + s*y),
            SIMD3((1-c)*y*x + s*z, c + (1-c)*y*y,   (1-c)*y*z - s*x),
            SIMD3((1-c)*z*x - s*y, (1-c)*z*y + s*x, c + (1-c)*z*z)
        )
    }

    /// 围绕任意轴的 4x4 旋转（在 3x3 基础上补齐齐次一列）
    /// - Parameters:
    ///   - axis: 旋转轴（任意方向，内部会归一化）
    ///   - angle: 旋转角（弧度）
    /// - Returns: 4x4 旋转矩阵（齐次坐标）
    static func rotationAround4x4(axis: SIMD3<Float>, angle: Float) -> simd_float4x4 {
        let R = rotationAround3x3(axis: axis, angle: angle)
        let col0 = SIMD4<Float>(R.columns.0, 0)
        let col1 = SIMD4<Float>(R.columns.1, 0)
        let col2 = SIMD4<Float>(R.columns.2, 0)
        let col3 = SIMD4<Float>(0, 0, 0, 1)
        return simd_float4x4(col0, col1, col2, col3)
    }

    /// 计算将向量 `from` 旋到 `to` 的旋转（最短弧），用于对齐法线或朝向
    /// - Parameters:
    ///   - from: 源向量
    ///   - to: 目标向量
    /// - Returns: 4x4 旋转矩阵（齐次）
    static func rotationFromTo(_ from: SIMD3<Float>, _ to: SIMD3<Float>) -> simd_float4x4 {
        let v1 = simd_normalize(from)
        let v2 = simd_normalize(to)
        let dotVal = simd_dot(v1, v2)

        // 共线（同向）→ 单位旋转
        if dotVal > 0.9999 { return matrix_identity_float4x4 }

        // 完全反向 → 任取垂直轴做 180 度旋转
        if dotVal < -0.9999 {
            var axis = simd_cross(v1, SIMD3<Float>(1, 0, 0))
            if simd_length(axis) < 1e-3 {
                axis = simd_cross(v1, SIMD3<Float>(0, 1, 0))
            }
            return rotationAround4x4(axis: simd_normalize(axis), angle: .pi)
        }

        // 一般情况 → 轴为叉积方向，角为 arccos(dot)
        let axis = simd_normalize(simd_cross(v1, v2))
        let angle = acos(dotVal)
        return rotationAround4x4(axis: axis, angle: angle)
    }
}

// MARK: - Transform
public extension MathHelper {
    /// 仅修改 4x4 变换矩阵的平移列（位置），保持旋转/缩放不变
    /// - Parameters:
    ///   - T: 输入 4x4 变换矩阵
    ///   - p: 目标位置
    /// - Returns: 修改后矩阵
    static func setTransformPosition(_ T: simd_float4x4, _ p: SIMD3<Float>) -> simd_float4x4 {
        var out = T
        out.columns.3 = SIMD4<Float>(p.x, p.y, p.z, 1)
        return out
    }
    
    /// 将一个 4×4 世界变换矩阵 m，沿着它所在平面的“法线方向”平移 delta 米
    /// - Parameters:
    ///   - m: 矩阵
    ///   - delta: 米
    /// - Returns: 新矩阵
    @inline(__always)
    static func offsetAlongPlaneNormal(_ m: simd_float4x4, delta: Float) -> simd_float4x4 {
        var out = m
        let n = simd_normalize(SIMD3<Float>(m.columns.1.x, m.columns.1.y, m.columns.1.z))
        out.columns.3.x += n.x * delta;
        out.columns.3.y += n.y * delta;
        out.columns.3.z += n.z * delta
        return out
    }
    
    /// 构造 4x4 位姿矩阵（RealityKit/ARKit 约定：Y 列为法线/上向量）
    /// - Parameters:
    ///   - u: 平面/基的 X 轴（右）
    ///   - v: 平面/基的 Z 轴（前）
    ///   - n: 平面法线/上向量（Y）
    ///   - p: 位置（平移）
    /// - Returns: 4x4 齐次变换矩阵
    static func makeTransform(basisU u: SIMD3<Float>,
                                     basisV v: SIMD3<Float>,
                                     basisN n: SIMD3<Float>,
                                     position p: SIMD3<Float>) -> simd_float4x4 {
        var m = matrix_identity_float4x4
        m.columns.0 = SIMD4(u.x, u.y, u.z, 0) // X
        m.columns.1 = SIMD4(n.x, n.y, n.z, 0) // Y（法线）
        m.columns.2 = SIMD4(v.x, v.y, v.z, 0) // Z
        m.columns.3 = SIMD4(p.x, p.y, p.z, 1) // 平移
        return m
    }
    
    // 1) 取 4x4 的位置（平移列）
    @inline(__always)
    static func translation(_ T: simd_float4x4) -> SIMD3<Float> {
        SIMD3<Float>(T.columns.3.x, T.columns.3.y, T.columns.3.z)
    }

    // 2) 提取“绕世界 up(y)”的 yaw（范围 [-π, π]）
    @inline(__always)
    static func yawAroundWorldUp(_ T: simd_float4x4) -> Float {
        let f = SIMD3<Float>(T.columns.2.x, T.columns.2.y, T.columns.2.z) // 前向Z轴
        var yaw = atan2(f.x, f.z)   // ✅ 正号
        yaw = fmodf(yaw, 2*Float.pi)
        if yaw >  Float.pi { yaw -= 2*Float.pi }
        if yaw < -Float.pi { yaw += 2*Float.pi }
        return yaw
    }
}

// MARK: - Polygon & Geometry
public extension MathHelper {
    /// 将“世界坐标”点投影到给定 4x4 矩阵 `M` 的“局部坐标系”（等价于 `M.inverse * worldPoint`）
    /// - Parameters:
    ///   - world: 世界坐标点 (x,y,z)
    ///   - M: 局部→世界的 4x4 变换（齐次）
    /// - Returns: 在 `M` 局部坐标下的点 (x,y,z)
    @inline(__always)
    static func projectWorldPointToPlaneLocal(_ world: SIMD3<Float>, M: simd_float4x4) -> SIMD3<Float> {
        let inv = M.inverse
        let p4  = inv * SIMD4<Float>(world.x, world.y, world.z, 1)
        return SIMD3<Float>(p4.x, p4.y, p4.z)
    }

    /// 判断“平面局部点”是否在边界内（带 margin），并返回最近边界点（局部 3D）
    /// - Parameters:
    ///   - pointLocal: 平面局部 3D (x,y,z)（注意：几何计算使用 (x,z) 作为面内二维）
    ///   - boundary2D: ARPlaneAnchor 提供的边界点（局部，使用 (x,z)）
    ///   - alignment: 平面对齐方式（此实现用 (x,z) 无需区分 H/V）
    ///   - margin: 距离边界 ≤ margin 也视为 inside
    /// - Returns:
    ///   - inside: 是否在（或贴近）边界内
    ///   - nearestPointLocal: 最近边界点（保持 y 不变，回填 x/z）
    ///   - edgeDistance: 最近边界距离（米）
    static func polygonInsideAndNearestLocal(
        pointLocal: SIMD3<Float>,
        boundary2D: [SIMD2<Float>],
        alignment: ARPlaneAnchor.Alignment,
        margin: Float
    ) -> (inside: Bool, nearestPointLocal: SIMD3<Float>, edgeDistance: Float) {

        guard boundary2D.count >= 3 else {
            return (false, pointLocal, .greatestFiniteMagnitude)
        }

        // 统一用 (x,z) 作为 2D 平面几何坐标
        let p2 = SIMD2<Float>(pointLocal.x, pointLocal.z)

        let (q2, dist) = nearestOnBoundary(p2, boundary2D)
        let qLocal = SIMD3<Float>(q2.x, pointLocal.y, q2.y)

        if dist <= margin {
            return (true, qLocal, dist)  // 贴边也算 inside
        } else {
            return (false, qLocal, dist)
        }
    }
}

// MARK: - Utilities
public extension MathHelper {
    /// 计算两个角度的最小绝对差（弧度），结果 ∈ [0, π]
    /// - Parameters:
    ///   - a: 角度 a（弧度）
    ///   - b: 角度 b（弧度）
    /// - Returns: |a - b| 的环状最小差
    @inline(__always)
    static func angularDiff(_ a: Float, _ b: Float) -> Float {
        var d = fmodf(a - b, 2 * .pi)
        if d > .pi  { d -= 2 * .pi }
        if d < -.pi { d += 2 * .pi }
        return abs(d)
    }
}

// MARK: - Private helpers (Polygon)
private extension MathHelper {
    /// 点是否在多边形内（射线法，2D）
    static func pointInPolygon(_ p: SIMD2<Float>, _ poly: [SIMD2<Float>]) -> Bool {
        guard poly.count >= 3 else { return false }
        var inside = false
        var j = poly.count - 1
        for i in 0..<poly.count {
            let a = poly[i], b = poly[j]
            let cross = ((a.y > p.y) != (b.y > p.y)) &&
                        (p.x < (b.x - a.x) * (p.y - a.y) / max(b.y - a.y, 1e-12) + a.x)
            if cross { inside.toggle() }
            j = i
        }
        return inside
    }

    /// 线段上离点最近的点（2D）
    static func closestPointOnSegment(_ p: SIMD2<Float>, _ a: SIMD2<Float>, _ b: SIMD2<Float>) -> SIMD2<Float> {
        let ab = b - a
        let denom = simd_length_squared(ab)
        if denom <= Float.leastNonzeroMagnitude { return a }
        let t = max(0, min(1, simd_dot(p - a, ab) / denom))
        return a + t * ab
    }

    /// 多边形边界上的最近点（2D）
    static func nearestOnBoundary(_ p: SIMD2<Float>, _ poly: [SIMD2<Float>]) -> (q: SIMD2<Float>, dist: Float) {
        var bestQ = poly[0]
        var bestD = Float.greatestFiniteMagnitude
        for i in 0..<poly.count {
            let a = poly[i], b = poly[(i+1) % poly.count]
            let q = closestPointOnSegment(p, a, b)
            let d = simd_length(p - q)
            if d < bestD { bestD = d; bestQ = q }
        }
        return (bestQ, bestD)
    }
}
