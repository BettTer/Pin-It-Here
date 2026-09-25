//
//  ARFinalSceneView.swift
//  PinItHere
//
//  放置集合 (livePlacements) 与 恢复集合 (restoredEntities) 并行渲染。
//  恢复优先级按 preferredRestoreMethod -> 自动降级：WorldMap -> GeoAnchor -> 近似计算。
//  放置：立即按指示器命中在“放置集合”上屏（世界锚），同时投递 NoteAnchor，并异步抓取 WorldMap 存入记录。
//  恢复：每帧驱动一次“尚未渲染”的唯一记录；WorldMap/GeoAnchor 只触发一次，会话锚回来后在 didAdd 中切换所有权。
//  近似：T_cam_now * T_rel 悬空；仅当背面≤10cm且法线近似平行才吸附。
//

import ARKit
import RealityKit
import SwiftUI
import Combine
import simd
import CoreLocation
import LocalSharedPackage

// MARK: - View
struct ARFinalSceneView: UIViewRepresentable {
    enum Readiness {
        case bad, scanning, ready
    }

    // Inputs
    var backgroundColor: UIColor
    @Binding var placeCommand: PlacePaperCommand?
    @Binding var updateTexture: CGImage?
    @Binding var needToRemoveAllPapers: Bool?

    // Callbacks
    var onIndicatorStateChanged: ((Readiness) -> Void)? = nil
    var onIndicatorTransformChanged: ((simd_float4x4?) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(
            backgroundColor: backgroundColor,
            onIndicatorStateChanged: onIndicatorStateChanged,
            onIndicatorTransformChanged: onIndicatorTransformChanged
        )
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        config.worldAlignment = .gravityAndHeading
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        if let record = NoteRecordStoreManager.shared.onlyRecord,
           let map = ARWorldMap.fetchWorldMap(from: record.worldMapData) {
            config.initialWorldMap = map
            LOG.p("RESTORE", "initialWorldMap attached from record id=\(record.id)")
        }
        
        context.coordinator.arView = arView
        arView.session.delegate = context.coordinator
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        // 指示器 + 中心 tracked raycast
        context.coordinator.makePlacementIndicator(paperSizeMeters: .init(width: 0.21, height: 0.297))

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        if let cmd = placeCommand {
            context.coordinator.placePaper(cmd)
            DispatchQueue.main.async { self.placeCommand = nil }
        }
        if updateTexture != nil {
//            context.coordinator.updateLastPaperTexture(img)
            DispatchQueue.main.async { self.updateTexture = nil }
        }
        if let remove = needToRemoveAllPapers, remove {
            context.coordinator.removeAllPapers()
            DispatchQueue.main.async { self.needToRemoveAllPapers = nil }
        }

        context.coordinator.latestTextureFromParent = updateTexture ?? context.coordinator.latestTextureFromParent
        context.coordinator.onIndicatorStateChanged = onIndicatorStateChanged
        context.coordinator.onIndicatorTransformChanged = onIndicatorTransformChanged
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.delegate = nil
        uiView.session.pause()
    }
}

// MARK: - Coordinator
extension ARFinalSceneView {
    final class Coordinator: NSObject {
        // MARK: - Input
        weak var arView: ARView?
        var backgroundColor: UIColor
        var onIndicatorStateChanged: ((Readiness) -> Void)?
        var onIndicatorTransformChanged: ((simd_float4x4?) -> Void)?
        var latestTextureFromParent: CGImage?

        // MARK: - 指示器
        private let indicatorOffset: Float = 0.03
        private var indicatorAnchor = AnchorEntity(world: matrix_identity_float4x4)
        public var indicatorParts: [ModelEntity] = []

        // MARK: - Raycast/Readiness
        private var mappingGoodFrames = 0
        private let mappingGoodFramesThreshold = 7
        private(set) var readiness: Readiness = .bad {
            didSet {
                guard readiness != oldValue else { return }
                
                switch readiness {
                case .bad:
                    setIndicatorTint(.systemRed)
                case .scanning:
                    setIndicatorTint(.systemYellow)
                case .ready:
                    setIndicatorTint(.systemGreen)
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.onIndicatorStateChanged?(self?.readiness ?? .bad)
                }
            }
        }
        private var lastIndicatorTransform: simd_float4x4? {
            didSet {
                DispatchQueue.main.async { [weak self] in
                    self?.onIndicatorTransformChanged?(self?.lastIndicatorTransform)
                }
            }
        }

        // MARK: - 渲染集合
        /// 临时放置通道（世界锚）
        private var livePlacements: [String: AnchorEntity] = [:]
        /// 恢复通道
        private var restoredEntities: [String: AnchorEntity] = [:]

        // * WorldMap 重试
        private var approxSpawned = false
        
        // 组件：用于累计“满足吸附条件”的连续帧数
        struct SnapCounterComponent: Component { var count: Int }
        
        private var lastMappingStatus: ARFrame.WorldMappingStatus?
        private var lastTrackingState: String?
        
        // 记录等待的 recordId -> 回调
        private var pendingSaveClosures: [String: () -> Void] = [:]
        private var didAddGeoAnchor = false

        init(backgroundColor: UIColor,
             onIndicatorStateChanged: ((Readiness) -> Void)?,
             onIndicatorTransformChanged: ((simd_float4x4?) -> Void)?) {
            self.backgroundColor = backgroundColor
            self.onIndicatorStateChanged = onIndicatorStateChanged
            self.onIndicatorTransformChanged = onIndicatorTransformChanged
        }
    }
}

// MARK: - Indicator
extension ARFinalSceneView.Coordinator {
    /// 生成指示器
    private func makeBracketCrosshair_RectOnly(
        size: SIMD2<Float>, line t: Float, leg L: Float, cross C: Float, color: UIColor, overlap ov: Float = 0.008
    ) -> Entity {
        func bar(width: Float, depth: Float) -> ModelEntity {
            let mesh = MeshResource.generatePlane(width: width, depth: depth, cornerRadius: 0)
            var m = UnlitMaterial(); m.color = .init(tint: color)
            m.faceCulling = .none
            return ModelEntity(mesh: mesh, materials: [m])
        }
        let width = size.x, height = size.y
        let root = Entity(); var parts: [ModelEntity] = []
        func add(_ e: ModelEntity) { root.addChild(e); parts.append(e) }

        do { let v = bar(width: t, depth: L+ov); v.position = [-width/2, 0,  height/2 - L/2]; add(v)
             let h = bar(width: L+ov, depth: t);   h.position = [-width/2 + L/2, 0,  height/2]; add(h) }
        do { let v = bar(width: t, depth: L+ov); v.position = [ width/2, 0,  height/2 - L/2]; add(v)
             let h = bar(width: L+ov, depth: t);   h.position = [ width/2 - L/2, 0,  height/2]; add(h) }
        do { let v = bar(width: t, depth: L+ov); v.position = [ width/2, 0, -height/2 + L/2]; add(v)
             let h = bar(width: L+ov, depth: t);   h.position = [ width/2 - L/2, 0, -height/2]; add(h) }
        do { let v = bar(width: t, depth: L+ov); v.position = [-width/2, 0, -height/2 + L/2]; add(v)
             let h = bar(width: L+ov, depth: t);   h.position = [-width/2 + L/2, 0, -height/2]; add(h) }
        do { let h = bar(width: C+ov, depth: t); h.position = [0,0,0]; add(h)
             let v = bar(width: t, depth: C+ov); v.position = [0,0,0]; add(v) }

        indicatorParts = parts
        return root
    }
    
    /// 放置指示器
    func makePlacementIndicator(paperSizeMeters: CGSize) {
        let outline = makeBracketCrosshair_RectOnly(
            size: SIMD2(Float(paperSizeMeters.width), Float(paperSizeMeters.height)),
            line: 0.008, leg: 0.05, cross: 0.07, color: .systemRed
        )
        indicatorAnchor.addChild(outline)
        arView?.scene.addAnchor(indicatorAnchor)
        indicatorAnchor.isEnabled = false
    }

    /// 修改指示器颜色
    private func setIndicatorTint(_ color: UIColor) {
        for part in indicatorParts {
            if var mat = part.model?.materials.first as? UnlitMaterial {
                mat.color.tint = color
                part.model?.materials = [mat]
            }
        }
    }
}

// MARK: - Raycast & Readiness
extension ARFinalSceneView.Coordinator {
    /// 快速放置检测
    private func quickPlacementProbe() -> Bool {
        guard let arView else { return false }

        // 准星
        let c = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)

        // 3) 尝试“严格/稳定”的命中：existingPlaneGeometry
        //    - 仅命中已经由 ARKit 识别出的平面（有 ARPlaneAnchor + 网格几何）
        //    - 命中质量更高、更不抖，但在“刚开始扫描、还没识别出平面”时可能没有结果
        if let q1 = arView.makeRaycastQuery(from: c, allowing: .existingPlaneGeometry, alignment: .any),
           arView.session.raycast(q1).first != nil {
            return true
        }

        // 4) 回退到“宽松/更早出现”的命中：estimatedPlane
        //    - 基于相机特征点云对平面做即时估算，出现更早，但可能抖动、精度不如 existingPlaneGeometry
        if let q2 = arView.makeRaycastQuery(from: c, allowing: .estimatedPlane, alignment: .any),
           arView.session.raycast(q2).first != nil {
            return true
        }

        // 5) 两种都没命中，认为当前不可放置
        return false
    }
    
    /// 更新就绪状态
    private func updateReadiness(with frame: ARFrame) {
        let trackingOK: Bool = { if case .normal = frame.camera.trackingState { return true } else { return false } }()
        let hasHit = (lastIndicatorTransform != nil)

        readiness = {
            if trackingOK && hasHit {
                if frame.worldMappingStatus == .mapped {
                    return (mappingGoodFrames >= mappingGoodFramesThreshold) ? .ready : .scanning
                } else {
                    return .scanning
                }
            } else {
                return .bad
            }
        }()
    }

    /// 是否已被渲染
    @inline(__always)
    private func isRendered(_ id: String) -> Bool {
        let r = (livePlacements[id] != nil) || (restoredEntities[id] != nil)
        LOG.p("RENDER", "isRendered(\(id)) -> \(r ? "YES" : "NO")")
        return r
    }
        
    /// 每帧镭射更新指示器: 优先 existingPlane, 其次 estimatedPlane 命中则立即覆盖指示器与 lastIndicatorTransform 不依赖 trackedRaycast 回调时机
    private func perFrameCenterRaycastUpdate() {
        guard let arView = arView else { return }
        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)

        // 是否已有任何 plane（比等 didAdd 更激进：直接看当前帧 anchors）
        let hasPlanes = (arView.session.currentFrame?.anchors.contains { $0 is ARPlaneAnchor } ?? false)

        // 先 existingPlaneGeometry
        if let q1 = arView.makeRaycastQuery(from: center, allowing: .existingPlaneGeometry, alignment: .any),
           hasPlanes,
           let hit = arView.session.raycast(q1).first {
            let tf = MathHelper.offsetAlongPlaneNormal(hit.worldTransform, delta: indicatorOffset)
            indicatorAnchor.transform = Transform(matrix: tf)
            if !indicatorAnchor.isEnabled {
                indicatorAnchor.isEnabled = true
            }
            lastIndicatorTransform = hit.worldTransform
            return
        }

        // 再 estimatedPlane 兜底
        if let q2 = arView.makeRaycastQuery(from: center, allowing: .estimatedPlane, alignment: .any),
           let hit = arView.session.raycast(q2).first {
            let tf = MathHelper.offsetAlongPlaneNormal(hit.worldTransform, delta: indicatorOffset)
            indicatorAnchor.transform = Transform(matrix: tf)
            if !indicatorAnchor.isEnabled {
                indicatorAnchor.isEnabled = true
            }
            lastIndicatorTransform = hit.worldTransform
            return
        }

        // 都没有就隐藏
        if indicatorAnchor.isEnabled {
            indicatorAnchor.isEnabled = false
        }
        lastIndicatorTransform = nil
    }
}

// MARK: - Placement
extension ARFinalSceneView.Coordinator {
    func placePaper(_ cmd: PlacePaperCommand) {
        guard let arView, let frame = arView.session.currentFrame else {
            return
        }
        
        updateReadiness(with: frame)
        guard readiness == .ready else {
            LOG.p("PLACE", "blocked by readiness=\(readiness)")
            return
        }
        guard let Tplace = lastIndicatorTransform else {
            LOG.p("PLACE", "no placementHitTransform()")
            return
        }
        
        let id = UUID().uuidString
        LOG.p("PLACE", "id=\(id) pos=(\(Tplace.columns.3.x),\(Tplace.columns.3.y),\(Tplace.columns.3.z))")

        let size = SIMD2(Float(cmd.paperSizeMeters.width), Float(cmd.paperSizeMeters.height))
        let anchorName = "paper::\(id)"

        // 记录（相机相对兜底；worldMap 等待异步抓）
        let Tcam  = frame.camera.transform
        let Trel = simd_mul(simd_inverse(Tcam), Tplace)
        let gpsData = generateGPSData(cameraTransform: Tcam, indicatorTransform: Tplace)
        
        let rec = NoteRecordModel.init(
            id: id,
            textureKey: "New Note",
            size: size,
            transform: Tplace,
            cameraRelAtPlacement: Trel,
            worldMapData: nil, anchorData: AnchorData(anchorName: anchorName), gpsData: gpsData
        )
        
        NoteRecordStoreManager.shared.upsert(rec)

        // 立即上屏（放置通道 -> 世界锚）
        let worldAnchorEntity = AnchorEntity(world: Tplace)
        worldAnchorEntity.name = "\(anchorName)::live"
        let paper = generateModelEntity(rec, color: .systemYellow)
        worldAnchorEntity.addChild(paper)
        arView.scene.addAnchor(worldAnchorEntity)
        livePlacements[id] = worldAnchorEntity
        LOG.p("PLACE", "added world anchor (live) id=\(id)")

        // 投递会话锚（用于之后 ARMap 恢复）
        let noteAnchor = NoteAnchor(recordId: id, sizeMeters: size, transform: Tplace)
        arView.session.add(anchor: noteAnchor)
        LOG.p("PLACE", "submitted NoteAnchor id=\(id)")
        
        // 抓取 WorldMap 存盘（仅更新记录，不参与屏）
        saveWorldMapForRecord(rec, recordId: id)
        
    }
    
    private func saveWorldMapForRecord(_ rec: NoteRecordModel, recordId id: String) {
        var recordCopy = rec
        waitForNoteAnchorInSession(recordId: id) {
            Task { [weak self] in
                guard let `self` = self,
                      let arView = self.arView else {
                    return
                }
                
                let data = await arView.session.fetchCurrentWorldMapData()
                let info = data == nil ? "nil" : "ok(\(data!.count)B)"
                LOG.p("WMAP", "getCurrentWorldMap -> \(info)")
                guard let data else {
                    return
                }
                
                recordCopy.worldMapData = data
                NoteRecordStoreManager.shared.upsert(recordCopy)
                LOG.p("PaperStore", "saved for \(id)!")
            }
        }
    }
    
    private func waitForNoteAnchorInSession(recordId id: String, completion: @escaping () -> Void) {
        // 1) 先检查当前是否已存在
        if let anchors = arView?.session.currentFrame?.anchors {
            let found = anchors.contains {
                if let n = $0 as? NoteAnchor { return n.recordId == id }
                if let name = $0.name { return name.hasPrefix("paper::\(id)") }
                return false
            }
            if found {
                LOG.p("WMAP", "NoteAnchor \(id) already in session")
                completion()
                return
            }
        }
        // 2) 等待将来 didAdd 通知
        LOG.p("WMAP", "Wait for NoteAnchor \(id) in session")
        pendingSaveClosures[id] = completion
    }

//    func updateLastPaperTexture(_ image: CGImage) {
//        // 只改“最近一个放置”的材质（保持与原逻辑一致）
//        guard let last = livePlacements.values.first ?? restoredEntities.values.first,
//              let mat = ViewRenderer.unlitMaterial(from: image, backgroundColor: backgroundColor)
//        else { return }
//        if let plane = last.children.first as? ModelEntity {
//            plane.model?.materials = [mat]
//        }
//    }

    func removeAllPapers() {
        NoteRecordStoreManager.shared.remove(id: nil)
        guard let arView else { return }
        for (_, e) in livePlacements { arView.scene.removeAnchor(e) }
        for (_, e) in restoredEntities { arView.scene.removeAnchor(e) }
        livePlacements.removeAll()
        restoredEntities.removeAll()

        // 同步移除 ARSession 里的贴纸相关锚（NoteAnchor 或 name 前缀）
        let sessionAnchors = arView.session.currentFrame?.anchors ?? []
        for a in sessionAnchors {
            if let note = a as? NoteAnchor {
                arView.session.remove(anchor: note)
            } else if let name = a.name, name.hasPrefix("paper::") {
                arView.session.remove(anchor: a)
            }
        }
    }
}

// MARK: - ARSessionDelegate
extension ARFinalSceneView.Coordinator: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for a in anchors {
            LOG.p("ARSession.didAdd", "type=\(type(of: a)) name=\(a.name ?? "nil")")
            handleSessionAnchorIfPaper(a)

            // 触发等待中的保存逻辑
            if let note = a as? NoteAnchor {
                let rid = note.recordId
                if let cb = pendingSaveClosures.removeValue(forKey: rid) {
                    LOG.p("WMAP", "NoteAnchor \(rid) appeared, triggering save")
                    cb()
                    
                }
                
            } else if let name = a.name, name.hasPrefix("paper::") {
                var s = String(name.dropFirst("paper::".count))
                if let idx = s.firstIndex(of: ":") {
                    s = String(s.prefix(upTo: idx))
                }
                if let cb = pendingSaveClosures.removeValue(forKey: s) {
                    LOG.p("WMAP", "Named anchor for \(s) appeared, triggering save")
                    cb()
                }
            }
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // 先用“每帧一次性 Raycast”抢占最新命中
        perFrameCenterRaycastUpdate()
        
        mappingGoodFrames = (frame.worldMappingStatus == .mapped) ? (mappingGoodFrames + 1) : 0
        
        updateReadiness(with: frame)
        driveRestoreChainIfNeeded(using: frame)
        
        maybeSnapFloatingEntitiesToBackPlane(frame: frame)
        
        if lastMappingStatus != frame.worldMappingStatus {
            lastMappingStatus = frame.worldMappingStatus
            LOG.p("SLAM", "worldMappingStatus=\(frame.worldMappingStatus.rawValue)")
        }
        let tStr: String = {
            switch frame.camera.trackingState {
            case .normal: return "normal"
            case .notAvailable: return "notAvailable"
            case .limited(let r): return "limited(\(r))"
            }
        }()
        if lastTrackingState != tStr {
            lastTrackingState = tStr
            LOG.p("SLAM", "trackingState=\(tStr)")
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        LOG.p("ARSession", "didFail error=\(error.localizedDescription)")
            let ns = error as NSError
            LOG.p("ARSession", "domain=\(ns.domain) code=\(ns.code) userInfo=\(ns.userInfo)")
    }
    
    private func handleSessionAnchorIfPaper(_ a: ARAnchor) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var rid: String?

            if let note = a as? NoteAnchor {
                rid = note.recordId
                LOG.p("RESTORE", "didAdd NoteAnchor id=\(note.recordId)")
                
            } else if let name = a.name, name.hasPrefix("paper::") {
                var s = String(name.dropFirst("paper::".count))
                if let idx = s.firstIndex(of: ":") { s = String(s.prefix(upTo: idx)) }
                rid = s
                LOG.p("RESTORE", "didAdd Named ARAnchor id=\(rid!)")
                
            }

            guard let id = rid, let rec = NoteRecordStoreManager.shared.lookup(id: id) else {
                LOG.p("RESTORE", "skip anchor (no recordId)")
                return
            }

            // 🔁 清理旧实例，保证只有一个“真身”
            if let live = self.livePlacements.removeValue(forKey: id) {
                self.arView?.scene.removeAnchor(live)
                LOG.p("RESTORE", "removed live world anchor id=\(id)")
            }
            if let rest = self.restoredEntities.removeValue(forKey: id) {
                self.arView?.scene.removeAnchor(rest)
                LOG.p("RESTORE", "removed old restored anchor id=\(id)")
            }

            // 绑定“会话锚”重新上屏（真正归位）
            let e = AnchorEntity(anchor: a)
            e.name = a.name ?? "paper::\(id)"
            let paper = self.generateModelEntity(rec, color: .systemGray)
            
            e.addChild(paper)
            self.arView?.scene.addAnchor(e)
            self.restoredEntities[id] = e
            LOG.p("RESTORE", "attached to session anchor id=\(id) (type=\(type(of: a)))")
            
            var rec2 = rec
            if a is NoteAnchor {
                // 来自 WorldMap 的 NoteAnchor（或同会话：不影响逻辑）
                rec2.usedRestore = .worldMap
                NoteRecordStoreManager.shared.upsert(rec2)
                LOG.p("RESTORE", "usedRestore=worldMap (didAdd NoteAnchor)")
            } else {
                // 其他命名 ARAnchor 不写
            }
            
            if let arView = self.arView, let cam = arView.session.currentFrame?.camera {
                let TpaperW = e.transformMatrix(relativeTo: nil) * paper.transformMatrix(relativeTo: e)
                let n = simd_normalize(SIMD3<Float>(TpaperW.columns.1.x, TpaperW.columns.1.y, TpaperW.columns.1.z))
                let zCam = -simd_normalize(SIMD3<Float>(cam.transform.columns.2.x, cam.transform.columns.2.y, cam.transform.columns.2.z))
                let cosang = simd_dot(n, zCam)
                let deg = acos(max(-1,min(1,cosang))) * 180 / .pi
                LOG.p("VIS", "angle(paperNormal, cameraForward)=\(Int(deg))° (≈90° means edge-on)")
            }
        }
    }
}

// MARK: - Restore chain
extension ARFinalSceneView.Coordinator {
    private func driveRestoreChainIfNeeded(using frame: ARFrame) {
        guard let rec = NoteRecordStoreManager.shared.onlyRecord else { return }

        // ✅ WorldMap 已成功 → 停机
        if rec.usedRestore == .worldMap {
            return
        }
        
        if !approxSpawned && restoredEntities[rec.id] == nil && livePlacements[rec.id] == nil {
            if tryRestoreViaApproximate(rec, frame: frame) {
                approxSpawned = true
                var recUpd = rec
                if recUpd.usedRestore == nil {
                    recUpd.usedRestore = .approximate
                    NoteRecordStoreManager.shared.upsert(recUpd)
                    LOG.p("RESTORE", "usedRestore=approximate (spawned)")
                }
            }
        }
    }

    // MARK: WorldMap
    private func tryRestoreViaWorldMap(_ rec: NoteRecordModel) -> Bool {
        guard restoredEntities[rec.id] == nil else {
            return true
        }
        
        guard let arView = arView,
              let data = rec.worldMapData,
              let map = ARWorldMap.fetchWorldMap(from: data) else {
            return false
        }
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        config.worldAlignment = .gravity
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        config.initialWorldMap = map

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = self
        LOG.p("RESTORE", "session.run() with initialWorldMap; delegate re-bound")
        return true
    }

    // MARK: Approximate (floating + optional back-parallel snap ≤10cm)
    // 替换原函数：创建时仅浮空，不做吸附
    private func tryRestoreViaApproximate(_ rec: NoteRecordModel, frame: ARFrame) -> Bool {
        guard let arView else { return false }
        guard !isRendered(rec.id) else { return true }
        
        LOG.p("APPROX", "spawn floating approx for id=\(rec.id)")

        let TcamNow = frame.camera.transform
        // 浮空预测：优先 T_rel，其次保存时 transform（同会话时有效）
        let Tpred = rec.cameraRelAtPlacement.map { simd_mul(TcamNow, $0) } ?? rec.transform
        
        let e: AnchorEntity
        
        if let g = rec.gpsData,
           let currentLocation = PreciseLocationProvider.shared.latestLocation,
           let headingDeg = PreciseLocationProvider.shared.latestHeadingTrue {
            let Tpaper = g.makePaperWorldTransform(
                TcamNow: frame.camera.transform,
                current: currentLocation,
                headingDeg: headingDeg)
            e = AnchorEntity(world: Tpaper)
            
        } else {
            // --- 冻结朝向：把浮空的旋转改为“保存时的重力-yaw”，避免跟着相机转 ---
            // 注意：这只在“近似恢复（无 map/geo）”里用，等锚回来后会被会话锚真正姿态接管。
            let up = SIMD3<Float>(0,1,0)

            // 从保存的 rec.transform 里抽出保存时的 yaw（绕重力轴）
            let yawSaved = MathHelper.yawAroundWorldUp(rec.transform)
            let R_yawSaved = MathHelper.rotationAround4x4(axis: up, angle: yawSaved)

            // 组合一个“位置=Tpred.position、朝向=R_yawSaved”的 transform
            var Tfloat = matrix_identity_float4x4
            Tfloat.columns.0 = simd_float4(1,0,0,0)
            Tfloat.columns.1 = simd_float4(0,1,0,0)
            Tfloat.columns.2 = simd_float4(0,0,1,0)
            Tfloat.columns.3 = simd_float4(Tpred.columns.3.x, Tpred.columns.3.y, Tpred.columns.3.z, 1)
            Tfloat = simd_mul(R_yawSaved, Tfloat)
            
            e = AnchorEntity(world: Tfloat)
        }

        // 首屏只浮空，不吸附
        e.name = "paper::\(rec.id)::approx"
        let paper = generateModelEntity(rec, color: .systemGray)
        e.addChild(paper)
        arView.scene.addAnchor(e)
        restoredEntities[rec.id] = e
        return true
    }
    
    // 新增：延迟吸附
    private func maybeSnapFloatingEntitiesToBackPlane(frame: ARFrame) {
        let planes = frame.anchors.compactMap { $0 as? ARPlaneAnchor }
        guard !planes.isEmpty else { return }

        let parallelAngleDeg: Float = 10.0
        let maxBackGap: Float = 0.10
        let cosThresh = cos(parallelAngleDeg * .pi / 180)
        let requireStableFrames = 3  // 连续 3 帧才执行吸附，可按体验调整

        for (id, e) in restoredEntities {
            guard e.name.hasSuffix("::approx") else { continue }

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
                let gap = simd_dot(pPred - origin, nPlane)  // >0 代表平面在纸条“背后”
                guard gap > 0, gap <= maxBackGap else { continue }
                if gap < bestGap { bestGap = gap; chosen = (origin, nPlane) }
            }

            // 连续帧计数
            var counter = e.components[SnapCounterComponent.self] ?? SnapCounterComponent(count: 0)
            counter.count = (chosen == nil) ? 0 : (counter.count + 1)
            e.components[SnapCounterComponent.self] = counter
            guard counter.count >= requireStableFrames, let c = chosen else { continue }

            // 满足稳定条件：一次性吸附（旋转对齐+投影）
            let projPos = pPred - c.n * simd_dot(pPred - c.origin, c.n)
            let R_align = MathHelper.rotationFromTo(nPaper, c.n)
            let Tfinal = MathHelper.setTransformPosition(simd_mul(R_align, T), projPos)

            e.transform = Transform(matrix: Tfinal)
            e.name = "paper::\(id)::approx-snapped"
            e.components[SnapCounterComponent.self] = nil
            
            LOG.p("APPROX", "consider id=\(id) name=\(e.name)")
        }
    }
}

// MARK: - Helpers (WorldMap, Geo)
extension ARFinalSceneView.Coordinator {
    // 简化版 ENU 偏移到经纬度（近似，小范围有效）
    private func offsetCoordinate(originLat: Double, originLon: Double, dE: Double, dN: Double) -> (lat: Double, lon: Double) {
        let R = 6378137.0
        let dLat = (dN / R) * 180.0 / .pi
        let dLon = (dE / (R * cos(originLat * .pi / 180.0))) * 180.0 / .pi
        return (originLat + dLat, originLon + dLon)
    }
}

// MARK: - Generate
extension ARFinalSceneView.Coordinator {
    fileprivate func generateModelEntity(_ model: NoteRecordModel, color: UIColor) -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: model.size.x, depth: model.size.y, cornerRadius: 0.005)
        var m = UnlitMaterial()
        m.color = .init(tint: color)
        m.faceCulling = .none
        return ModelEntity(mesh: mesh, materials: [m])
    }
    
    fileprivate func generateGPSData(
        cameraTransform: simd_float4x4,
        indicatorTransform: simd_float4x4,
    ) -> GPSData? {
        guard let loc = PreciseLocationProvider.shared.latestLocation else {
            return nil
        }
        
        guard let headingDeg = PreciseLocationProvider.shared.latestHeadingTrue else {
            let gpsData = GPSData.init(
                location: loc,
                deltaE: 0, deltaU: 0, deltaN: 0,
                paperYawFromNorth: 0,
                normalE: nil, normalU: nil, normalN: nil
            )
            
            return gpsData
        }
        
        // 1) 世界相对位移 -> ENU
        let pOriginW = MathHelper.translation(cameraTransform)   // 用相机位置作“origin 世界点”的近似（也可以用命中点）
        let pNoteW   = MathHelper.translation(indicatorTransform)
        let vWorld   = pNoteW - pOriginW
        let Rw2e = MathHelper.makeWorldToENURotation(trueHeadingDeg: headingDeg)
        
        let vENU = Rw2e * vWorld    // 约定：vENU.x=E, vENU.y=U, vENU.z=N
        let deltaE = vENU.x
        let deltaU = vENU.y
        let deltaN = vENU.z
        
        // 2) 纸条相对“真北”的偏航（弧度，[-π,π]）
        let yawWorld = MathHelper.yawAroundWorldUp(indicatorTransform)
        let yawNorth = Float(headingDeg * .pi / 180.0)
        let paperYawFromNorth = yawWorld - yawNorth
        
        // 3) 取“纸条平面法线”（世界系）：Y 列就是法线
        let nWorld = simd_normalize(SIMD3<Float>(
            indicatorTransform.columns.1.x,
            indicatorTransform.columns.1.y,
            indicatorTransform.columns.1.z
        ))
        let nENU   = Rw2e * nWorld
        
        let gpsData = GPSData(
            location: loc,
            deltaE: deltaE, deltaU: deltaU, deltaN: deltaN,
            paperYawFromNorth: paperYawFromNorth,
            normalE: nENU.x, normalU: nENU.y, normalN: nENU.z   // ✅ 新增
        )
        
        return gpsData
    }
}
