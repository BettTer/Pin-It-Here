//
//  File.swift
//  LocalSharedPackage
//
//  Created by YY.COUPLE on 2025-10-01.
//

import Foundation
import ARKit

// MARK: - 废弃数据
extension NoteRecordModel {
    /// 平面信息
    public struct PlaneAttachmentData: Codable, Sendable {
        /// 放置时命中的平面是水平还是垂直（或未知）
        public var alignment: ARPlaneAnchor.Alignment?  // .horizontal / .vertical / nil
        
        /// 保存当时的射线命中点（世界坐标）
        public var hitPointWorld: Vec3Codable
        
        /// 平面法线（世界坐标系下）
        public var planeNormal: Vec3Codable            // n
        
        /// 平面“切向”基向量（世界坐标系下）。
        /// u 是平面内 X 轴，v 是平面内 Z 轴（右手系，保证 u⊥v⊥n）
        public var planeTangentU: Vec3Codable          // u
        public var planeTangentV: Vec3Codable          // v
        
        /// 将纸条投影到平面后的 2D 坐标（以 u,v 为轴，单位：米）
        public var uvOnPlane: Vec2Codable             // (u0, v0)
        
        /// 纸条绕法线的朝向（弧度，[-π, π]）
        public var yawOnPlane: Float                    // θ
        
        /// 纸条离平面的高度（米，避免共面闪烁，建议 0.002~0.005）
        public var heightOffset: Float                  // h
        
        /// 平面估计的高度（对水平面而言；单位：米，世界坐标 y）
        /// 用于“候选平面”相似度筛选（例如桌面高度 0.75m ± 0.1m）
        public var estimatedPlaneHeightY: Float?
        
        /// 可选：ARPlane 的分类（仅支持设备可用且当时命中了 ARPlaneAnchor）
        public var classificationRawValue: Int?         // ARPlaneAnchor.Classification?.rawValue
        
        
        private enum CodingKeys: String, CodingKey {
            case alignment              // 用 Int 存 alignment.rawValue
            case hitPointWorld
            case planeNormal
            case planeTangentU
            case planeTangentV
            case uvOnPlane
            case yawOnPlane
            case heightOffset
            case estimatedPlaneHeightY
            case classificationRawValue
        }
        
        public init(
            alignment: ARPlaneAnchor.Alignment? = nil,
            hitPointWorld: Vec3Codable,
            planeNormal: Vec3Codable,
            planeTangentU: Vec3Codable,
            planeTangentV: Vec3Codable,
            uvOnPlane: Vec2Codable,
            yawOnPlane: Float,
            heightOffset: Float,
            estimatedPlaneHeightY: Float? = nil,
            classificationRawValue: Int? = nil
        ) {
            self.alignment = alignment
            self.hitPointWorld = hitPointWorld
            self.planeNormal = planeNormal
            self.planeTangentU = planeTangentU
            self.planeTangentV = planeTangentV
            self.uvOnPlane = uvOnPlane
            self.yawOnPlane = yawOnPlane
            self.heightOffset = heightOffset
            self.estimatedPlaneHeightY = estimatedPlaneHeightY
            self.classificationRawValue = classificationRawValue
        }
        
        // 自定义解码：把 alignment 当作 Int? 读出来再转成 Alignment
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            
            if let raw = try c.decodeIfPresent(Int.self, forKey: .alignment) {
                self.alignment = ARPlaneAnchor.Alignment(rawValue: raw)
            } else {
                self.alignment = nil
            }
            
            self.hitPointWorld   = try c.decode(Vec3Codable.self, forKey: .hitPointWorld)
            self.planeNormal   = try c.decode(Vec3Codable.self, forKey: .planeNormal)
            self.planeTangentU = try c.decode(Vec3Codable.self, forKey: .planeTangentU)
            self.planeTangentV = try c.decode(Vec3Codable.self, forKey: .planeTangentV)
            self.uvOnPlane     = try c.decode(Vec2Codable.self, forKey: .uvOnPlane)
            
            self.yawOnPlane    = try c.decode(Float.self, forKey: .yawOnPlane)
            self.heightOffset  = try c.decode(Float.self, forKey: .heightOffset)
            
            self.estimatedPlaneHeightY = try c.decodeIfPresent(Float.self, forKey: .estimatedPlaneHeightY)
            self.classificationRawValue = try c.decodeIfPresent(Int.self, forKey: .classificationRawValue)
        }
        
        // 自定义编码：把 alignment 编成 Int?
        public func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encodeIfPresent(alignment?.rawValue, forKey: .alignment)
            try c.encode(hitPointWorld,   forKey: .hitPointWorld)
            try c.encode(planeNormal,   forKey: .planeNormal)
            try c.encode(planeTangentU, forKey: .planeTangentU)
            try c.encode(planeTangentV, forKey: .planeTangentV)
            try c.encode(uvOnPlane,     forKey: .uvOnPlane)
            try c.encode(yawOnPlane,    forKey: .yawOnPlane)
            try c.encode(heightOffset,  forKey: .heightOffset)
            try c.encodeIfPresent(estimatedPlaneHeightY, forKey: .estimatedPlaneHeightY)
            try c.encodeIfPresent(classificationRawValue, forKey: .classificationRawValue)
        }
    }

    /// LiDAR Mesh
    public struct MeshPatchData: Codable, Sendable {
        /// 以平面坐标为中心截取的局部顶点（米，世界坐标）
        public var samplePointsWorld: [Vec3Codable]    // 限制数量，例如 200~500 个

        /// 采样中心（命中点）世界坐标，便于粗匹配
        public var centroidWorld: Vec3Codable

        /// 采样尺度（截取半径、正方形半边长等），用于快速剔除
        public var sampleScale: Float
        
        public init(samplePointsWorld: [Vec3Codable], centroidWorld: Vec3Codable, sampleScale: Float) {
            self.samplePointsWorld = samplePointsWorld
            self.centroidWorld = centroidWorld
            self.sampleScale = sampleScale
        }
    }
    
}
