//
//  ARGPSSceneView.swift
//  PinItHere
//
//  Created by YY.COUPLE on 2025-10-03.
//

import SwiftUI
import ARKit
import RealityKit
import CoreLocation
import simd
import LocalSharedPackage

/// 仅用于测试“GPS 近似复原”的独立场景视图：
/// - 仅使用 WorldTracking（gravityAndHeading）
/// - 不注入 WorldMap、不使用 GeoTracking
/// - 依据 NoteRecordModel.gpsData + 当前定位/真北，跨设备/跨会话复原纸条
///
/// 用法：
/// ARGPSSceneView(record: rec, enableBackSnap: true)
struct ARGPSSceneView: UIViewRepresentable {

    /// 传入要复原的记录（要求包含 gpsData）
    let record: NoteRecordModel

    /// 是否启用“背后平面吸附”（可帮助贴到墙/地面背后 ≤10cm 的平面）
    var enableBackSnap: Bool = true

    /// 允许的定位精度阈值（米）
    var maxHorizontalAccuracy: CLLocationAccuracy = 50

    /// 允许的朝向精度阈值（度）
    var maxHeadingAccuracy: CLLocationDirection = 10

    // 回调：可选，观察状态
    var onRestored: ((Bool) -> Void)? = nil   // true=成功近似复原并上屏
    var onLog: ((String) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(record: record,
                    enableBackSnap: enableBackSnap,
                    maxHorizontalAccuracy: maxHorizontalAccuracy,
                    maxHeadingAccuracy: maxHeadingAccuracy,
                    onRestored: onRestored,
                    onLog: onLog)
    }

    func makeUIView(context: Context) -> ARView {
        let v = ARView(frame: .zero)
        v.automaticallyConfigureSession = false

        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading   // ✅ 与 ENU/真北一致
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal, .vertical]

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        context.coordinator.arView = v
        v.session.delegate = context.coordinator
        v.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        // 初始一个“等待提示”小十字（可选）
        context.coordinator.installWaitingReticle()

        return v
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // 没有动态更新需求。测试期间保持简洁即可。
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.delegate = nil
        uiView.session.pause()
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?

        let record: NoteRecordModel
        let enableBackSnap: Bool
        let maxHorizontalAccuracy: CLLocationAccuracy
        let maxHeadingAccuracy: CLLocationDirection
        let onRestored: ((Bool) -> Void)?
        let onLog: ((String) -> Void)?

        private var placed = false
        private var restoredAnchor: AnchorEntity?
        private var reticle: Entity?

        // 吸附稳定帧（防抖）
        private struct SnapCounterComponent: Component { var count: Int }
        private let requireStableFrames = 3

        init(record: NoteRecordModel,
             enableBackSnap: Bool,
             maxHorizontalAccuracy: CLLocationAccuracy,
             maxHeadingAccuracy: CLLocationDirection,
             onRestored: ((Bool) -> Void)?,
             onLog: ((String) -> Void)?) {
            self.record = record
            self.enableBackSnap = enableBackSnap
            self.maxHorizontalAccuracy = maxHorizontalAccuracy
            self.maxHeadingAccuracy = maxHeadingAccuracy
            self.onRestored = onRestored
            self.onLog = onLog
        }

        // MARK: - ARSessionDelegate

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard !placed else {
                if enableBackSnap { maybeSnapToBackPlane(frame: frame) }
                return
            }
            // 尝试 GPS 近似复原（只有一次成功上屏）
            tryRestoreViaGPSIfPossible(frame: frame)
        }

        // MARK: - GPS approximate restore (cross-device/session)

        private func tryRestoreViaGPSIfPossible(frame: ARFrame) {
            guard let arView = arView else { return }

            // 必备数据
            guard let g = record.gpsData else {
                log("GPS: record has no gpsData, skip")
                finish(false); return
            }
            guard let L1 = PreciseLocationProvider.shared.latestLocation else {
                log("GPS: no current location yet"); return
            }
            guard let headingDeg = PreciseLocationProvider.shared.latestHeadingTrue else {
                log("GPS: no true heading yet"); return
            }

            // 守门：定位/朝向质量
//            guard L1.horizontalAccuracy > 0, L1.horizontalAccuracy <= maxHorizontalAccuracy else {
//                log("GPS: poor horiz acc = \(Int(L1.horizontalAccuracy))m"); return
//            }
//
//            if let acc = PreciseLocationProvider.shared.lastHeading?.headingAccuracy,
//               acc > maxHeadingAccuracy {
//                log("GPS: poor heading acc = \(Int(acc))°"); return
//            }
            
            // 用你封装到 GPSData 里的方法，生成世界 transform
            let Tcam = frame.camera.transform
            let Tpaper = g.makePaperWorldTransform(
                TcamNow: Tcam,
                current: L1,
                headingDeg: headingDeg
            )

            // 上屏（灰色，表示“近似”）
            let anchor = AnchorEntity(world: Tpaper)
            anchor.name = "gps::\(record.id)::approx"
            let paper = generatePaperEntity(record, color: .systemGray)
            anchor.addChild(paper)
            arView.scene.addAnchor(anchor)

            self.restoredAnchor = anchor
            self.placed = true
            self.reticle?.isEnabled = false

            log("GPS: restored with acc=\(Int(L1.horizontalAccuracy))m, heading=\(Int(headingDeg))°")
            finish(true)
        }

        // MARK: - Optional: Snap to back-parallel plane (≤10cm)

        private func maybeSnapToBackPlane(frame: ARFrame) {
            guard let e = restoredAnchor, e.name.hasSuffix("::approx") else { return }
            let planes = frame.anchors.compactMap { $0 as? ARPlaneAnchor }
            guard !planes.isEmpty else { return }

            let parallelAngleDeg: Float = 10.0
            let maxBackGap: Float = 0.10
            let cosThresh = cos(parallelAngleDeg * .pi / 180)

            let T = e.transformMatrix(relativeTo: nil)
            let pPred = SIMD3<Float>(T.columns.3.x, T.columns.3.y, T.columns.3.z)
            let nPaper = simd_normalize(SIMD3<Float>(T.columns.1.x, T.columns.1.y, T.columns.1.z))

            var chosen: (origin: SIMD3<Float>, n: SIMD3<Float>)?
            var bestGap: Float = .greatestFiniteMagnitude

            for pl in planes {
                let M = pl.transform
                let nPlane = simd_normalize(SIMD3<Float>(M.columns.1.x, M.columns.1.y, M.columns.1.z))
                let origin = SIMD3<Float>(M.columns.3.x, M.columns.3.y, M.columns.3.z)
                let cosNP = simd_dot(nPlane, nPaper)
                guard cosNP >= cosThresh else { continue }
                let gap = simd_dot(pPred - origin, nPlane)  // >0 表示平面在纸条背后
                guard gap > 0, gap <= maxBackGap else { continue }
                if gap < bestGap { bestGap = gap; chosen = (origin, nPlane) }
            }

            // 连续帧计数
            var counter = e.components[SnapCounterComponent.self] ?? SnapCounterComponent(count: 0)
            counter.count = (chosen == nil) ? 0 : (counter.count + 1)
            e.components[SnapCounterComponent.self] = counter
            guard counter.count >= requireStableFrames, let c = chosen else { return }

            // 对齐 + 投影
            let projPos = pPred - c.n * simd_dot(pPred - c.origin, c.n)
            let R_align = MathHelper.rotationFromTo(nPaper, c.n)
            let Tfinal = MathHelper.setTransformPosition(simd_mul(R_align, T), projPos)

            e.transform = Transform(matrix: Tfinal)
            e.name = e.name.replacingOccurrences(of: "::approx", with: "::approx-snapped")
        }

        // MARK: - Helpers

        private func generatePaperEntity(_ model: NoteRecordModel, color: UIColor) -> ModelEntity {
            // 与你 ARFinalSceneView 一致：正面/背面都可见
            let mesh = MeshResource.generatePlane(width: model.size.x, depth: model.size.y, cornerRadius: 0.005)
            var m = UnlitMaterial()
            m.color = .init(tint: color)
            m.faceCulling = .none
            let e = ModelEntity(mesh: mesh, materials: [m])
            return e
        }

        public func installWaitingReticle() {
            // 简单的十字，表示“等待定位/朝向”
            guard let arView else { return }
            let line: Float = 0.08
            let thickness: Float = 0.004

            func bar(w: Float, d: Float) -> ModelEntity {
                let mesh = MeshResource.generatePlane(width: w, depth: d, cornerRadius: 0)
                var m = UnlitMaterial(); m.color = .init(tint: .systemOrange); m.faceCulling = .none
                return ModelEntity(mesh: mesh, materials: [m])
            }

            let root = Entity()
            let h = bar(w: line, d: thickness)
            let v = bar(w: thickness, d: line)
            root.addChild(h); root.addChild(v)

            let a = AnchorEntity(.camera) // 相机坐标下轻量提示
            a.position = [0, 0, -0.6]
            a.addChild(root)
            arView.scene.addAnchor(a)
            self.reticle = a
        }

        private func log(_ s: String) {
            onLog?(s)
            LOG.p("ARGPS", s) // 复用你现有的日志工具
        }

        private func finish(_ ok: Bool) {
            onRestored?(ok)
        }
    }
}
