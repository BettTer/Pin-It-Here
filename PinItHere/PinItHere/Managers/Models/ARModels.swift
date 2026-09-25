//
//  ARModels.swift
//  PinItHere
//
//  Created by YY.COUPLE on 2025-09-23.
//

import Foundation
import ARKit
import simd
import CoreGraphics

/// 父层下发给 AR：在某个 transform 放一张带纹理的纸
struct PlacePaperCommand: Equatable {
    var worldTransform: matrix_float4x4
    var paperSizeMeters: CGSize          // 例如 A4: 0.21 x 0.297
    var texture: CGImage
}

/// AR 向父层上报：点击到了一个可用平面（给出 transform）
struct PlaneHitEvent: Equatable {
    var worldTransform: matrix_float4x4
}

@objc(NoteAnchor)
public final class NoteAnchor: ARAnchor, @unchecked Sendable {
    public let recordId: String              // 你的 NoteRecordModel.id
    public let sizeMeters: SIMD2<Float>      // 纸张尺寸，复原时可直接用
    
    public override class var supportsSecureCoding: Bool { true }

    public init(recordId: String, sizeMeters: SIMD2<Float>, transform: simd_float4x4) {
        self.recordId = recordId
        self.sizeMeters = sizeMeters
        // 保留名称用于人类可读/调试（不依赖它）
        super.init(name: "paper::\(recordId)", transform: transform)
    }

    // 归档反序列化
    public required init?(coder: NSCoder) {
        guard let rid = coder.decodeObject(of: NSString.self, forKey: "rid") as String? else { return nil
        }
        let w = coder.decodeFloat(forKey: "sx")
        let h = coder.decodeFloat(forKey: "sy")
        self.recordId = rid
        self.sizeMeters = .init(w, h)
        super.init(coder: coder)
    }
    
    // ✅ 必须实现：用于 ARKit 在运行期克隆锚（会话更新/合并等）
    public required init(anchor: ARAnchor) {
        guard let other = anchor as? NoteAnchor else {
            // 理论上 ARKit 只会用同类来克隆，这里出错说明类型不匹配
            fatalError("Attempted to init NoteAnchor from a non-NoteAnchor")
        }
        self.recordId = other.recordId
        self.sizeMeters = other.sizeMeters
        // 复制父类部分（transform、identifier等）
        super.init(anchor: other)
    }
    

    // 归档序列化
    public override func encode(with coder: NSCoder) {
        coder.encode(recordId as NSString, forKey: "rid")
        coder.encode(sizeMeters.x, forKey: "sx")
        coder.encode(sizeMeters.y, forKey: "sy")
        super.encode(with: coder)
    }
    
}
