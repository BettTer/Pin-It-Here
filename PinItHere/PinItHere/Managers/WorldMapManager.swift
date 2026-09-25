//
//  File.swift
//  LocalSharedPackage
//
//  Created by YY.COUPLE on 2025-09-26.
//

import ARKit

public class WorldMapManager: @unchecked Sendable {
    public static let shared: WorldMapManager = WorldMapManager()
    
    private let url: URL
    init(filename: String = "worldmap.bin") {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        url = doc.appendingPathComponent(filename)
    }
    
    public func save(session: ARSession, completion: @escaping @Sendable (Bool) -> Void) {
        session.getCurrentWorldMap { map, _ in
            guard let map else {
                completion(false)
                return
            }
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.url, options: .atomic)
                completion(true)
            } catch { completion(false) }
        }
    }
    
    public func load() -> ARWorldMap? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)

            // ✅ 关键：在解档前注册自定义类映射（全名 & 简名都注册，兼容不同模块名）
            let full = NSStringFromClass(NoteAnchor.self) // 例如 "LocalSharedPackage.NoteAnchor"
            let simple = (full as NSString).components(separatedBy: ".").last! // "NoteAnchor"
            NSKeyedUnarchiver.setClass(NoteAnchor.self, forClassName: full)
            NSKeyedUnarchiver.setClass(NoteAnchor.self, forClassName: simple)

            // 现在去解档
            let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)

            // 调试：看看里面到底有啥 anchor（第二次进来时，这里应能看到 NoteAnchor 和带 name 的锚）
            #if DEBUG
            if let m = map {
                print("Loaded WorldMap anchors dump:")
                for a in m.anchors {
                    print(" • type=\(type(of: a)) name=\(a.name ?? "nil") id=\(a.identifier)")
                }
            }
            #endif
            return map
        } catch {
            print("WorldMap load failed: \(error)")
            return nil
        }
    }
}
