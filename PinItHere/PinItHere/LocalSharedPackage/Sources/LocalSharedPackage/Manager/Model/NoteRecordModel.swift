//
//  NoteRecordModel.swift
//  LocalSharedPackage
//
//  Created by YY.COUPLE on 2025-09-26.
//

import Foundation
import Combine
import simd
import CoreLocation
import CoreMotion
import RealityKit
import ARKit

public struct NoteRecordModel: Codable, Identifiable, Sendable {
    public enum RestoreSource: String, Codable, Sendable {
        case worldMap
        case geoAnchor
        case approximate
    }
    
    public var id: String
    public var createdAt: Date = .now
    public var usedRestore: RestoreSource? = nil
    
    // MARK: - Self
    /// 材质
    public var textureKey: String?
    /// 纸条尺寸（米）
    public var sizeData: Vec2Codable
    public var transformData: Mat4x4Codable
    /// 相机相对位姿（放置当时）：T_rel = inv(T_cam_at_place) * T_paper
    /// 作为“浮空恢复”的兜底，不依赖平面或 ARMap
    public var cameraRelAtPlacementData: Mat4x4Codable?
    
    // MARK: - Else
    /// ARMap
    public var worldMapData: Data?
    /// Anchor
    public var anchorData: AnchorData
    /// GPS
    public var gpsData: GPSData?
    
    // MARK: - 只读
    public var transform: simd_float4x4 {
        return transformData.matrix
    }
    public var size: SIMD2<Float> {
        return sizeData.vector
    }
    public var cameraRelAtPlacement: simd_float4x4? {
        return cameraRelAtPlacementData?.matrix
    }
    
    public init(
        id: String = UUID().uuidString,
        textureKey: String?,
        size: SIMD2<Float>,
        transform: simd_float4x4,
        cameraRelAtPlacement: simd_float4x4?,
        worldMapData: Data?,
        anchorData: AnchorData,
        gpsData: GPSData?,
    ) {
        self.id = id
        self.textureKey = textureKey
        self.sizeData = Vec2Codable.init(size)
        self.transformData = Mat4x4Codable.init(transform)
        self.cameraRelAtPlacementData = cameraRelAtPlacement.map { Mat4x4Codable.init($0) }
        
        self.worldMapData = worldMapData
        self.anchorData = anchorData
        self.gpsData = gpsData
    }
}

/// 锚信息
public struct AnchorData: Codable, Sendable {
    /// 与 ARAnchor.name 保持一致，用于会话恢复与匹配（paper::<id>）
    public var anchorName: String
    /// 创建时间
    public var createdAt: Date

    public init(anchorName: String, createdAt: Date = .now) {
        self.anchorName = anchorName
        self.createdAt = createdAt
    }
}

/// GPS信息
public struct GPSData: Codable, Sendable {
    // 放置时的“位置参考原点”（设备位置）
    public var originLat: Double
    public var originLon: Double
    public var originAlt: Double
    public var horizontalAccuracy: Double
    public var verticalAccuracy: Double
    
    // 相对 origin 的 ENU 偏移（米）
    public var deltaE: Float
    public var deltaU: Float
    public var deltaN: Float
    
    // 纸条绕重力轴对“真北”的朝向（弧度，[-pi,pi]）
    public var paperYawFromNorth: Float
    
    // ✅ 新增：平面法线在 ENU 下的分量（单位向量）
    public var normalE: Float?
    public var normalU: Float?
    public var normalN: Float?
    
    public init(
        location: CLLocation,
        deltaE: Float, deltaU: Float, deltaN: Float,
        paperYawFromNorth: Float,
        normalE: Float?, normalU: Float?, normalN: Float?
    ) {
        self.originLat = location.coordinate.latitude
        self.originLon = location.coordinate.longitude
        self.originAlt = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        
        self.deltaE = deltaE
        self.deltaN = deltaN
        self.deltaU = deltaU
        
        self.paperYawFromNorth = paperYawFromNorth
        
        self.normalE = normalE
        self.normalU = normalU
        self.normalN = normalN

    }
    
    public func fetchCLLocation() -> CLLocation {
        let location = CLLocation.init(
            coordinate: CLLocationCoordinate2D.init(latitude: originLat, longitude: originLon),
            altitude: originAlt,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            timestamp: .now
        )
        
        return location
    }
}

// MARK: - ENU / 复原 计算
public extension GPSData {
    /// L0（保存时）→ L1（当前）的 ENU 位移：ΔENU = (E, U, N)
    func deltaENU_toCurrent(_ current: CLLocation) -> SIMD3<Float> {
        // 弧度
        let lat0 = Float(originLat * .pi / 180)
        let lat1 = Float(current.coordinate.latitude * .pi / 180)

        // 每度经纬对应的米数（局部化）
        let metersPerDegLat: Float = 111_132
        let metersPerDegLon: Float = cos((lat0 + lat1) * 0.5) * 111_320

        let dLat = Float(current.coordinate.latitude - originLat)
        let dLon = Float(current.coordinate.longitude - originLon)
        let dAlt = Float(current.altitude - originAlt)

        let north = dLat * metersPerDegLat
        let east  = dLon * metersPerDegLon
        let up    = dAlt

        return SIMD3<Float>(east, up, north) // (E, U, N)
    }
    
    /// 基于 GPS + 真北：跨设备/跨会话复原纸条的世界变换
    /// - 参数：
    ///   - TcamNow: 当前 ARKit 相机 4x4 变换
    ///   - current: 当前 CLLocation（L1）
    ///   - headingDeg: 当前 trueHeading（度）
    /// - 返回：纸条世界 4x4（仅 yaw，不含 pitch/roll，与你的冻结策略一致）
    func makePaperWorldTransform(
        TcamNow: simd_float4x4,
        current: CLLocation,
        headingDeg: CLLocationDirection
    ) -> simd_float4x4 {
        // 1) 位置：相机位置 + ENU 差分
        let d0     = SIMD3<Float>(deltaE, deltaU, deltaN)
        let dL     = deltaENU_toCurrent(current)
        let dNowEN = d0 - dL
        
        let Rw2e   = MathHelper.makeWorldToENURotation(trueHeadingDeg: headingDeg)
        let Re2w   = simd_inverse(Rw2e)
        let vWorld = Re2w * dNowEN
        
        let pCam   = MathHelper.translation(TcamNow)
        let p      = pCam + vWorld
        
        // ---- 旋转：优先用“保存时法线的 ENU 分量”，旋回到世界做 Y 列 ----
        var N: SIMD3<Float>
        if let e = normalE, let u = normalU, let n = normalN {
            let nENU = SIMD3<Float>(e, u, n)
            N = simd_normalize(Re2w * nENU)        // ENU -> World
        } else {
            // 兼容旧数据（没有法线）：退化为“只保留 yaw”，可能会“躺平”
            let upY  = SIMD3<Float>(0,1,0)
            let yaw  = Float(headingDeg * .pi / 180.0) + paperYawFromNorth
            let R_yaw = MathHelper.rotationAround4x4(axis: upY, angle: yaw)
            var Tpos  = matrix_identity_float4x4
            Tpos = MathHelper.setTransformPosition(Tpos, p)
            return simd_mul(R_yaw, Tpos)
        }

        // ---- 从法线 N 构造正交基：U(右), V(前), N(法线=Y列) ----
        // 先选一个不与 N 共线的参考轴 r0，避免退化
        let upY = SIMD3<Float>(0,1,0)
        let r0: SIMD3<Float> = (abs(N.y) > 0.95) ? SIMD3<Float>(0,0,1) : upY
        var U = simd_normalize(simd_cross(r0, N))      // 右
        if !U.isValid {
            U = simd_normalize(simd_cross(SIMD3<Float>(1,0,0), N))     // 再兜底一次
        }
        let V = simd_normalize(simd_cross(N, U))        // 前

        // 组装 4x4：X=U, Y=N(法线), Z=V, 平移=p   （RealityKit 平面：Y 为法线）
        var T = MathHelper.makeTransform(basisU: U, basisV: V, basisN: N, position: p)

        // （可选）如需保持“纸张面内的上边缘方向”一致，可额外存一个“面内轴”的 ENU 分量再绕 N 微调
        return T
    }
}
