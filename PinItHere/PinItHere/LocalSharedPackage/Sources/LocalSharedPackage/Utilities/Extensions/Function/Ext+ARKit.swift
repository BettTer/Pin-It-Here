//
//  File.swift
//  LocalSharedPackage
//
//  Created by YY.COUPLE on 2025-09-29.
//

import Foundation
import ARKit

public extension ARSession {
    func fetchCurrentWorldMapData(callback: @escaping @Sendable (Data?) -> Void) {
        getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else {
                return
            }
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                callback(data)
        
            } catch {
                print("fetchCurrentWorldMapData error:", error)
                callback(nil)
            }
        }
    }
    
    func fetchCurrentWorldMapData() async -> Data? {
        await withCheckedContinuation { continuation in
            getCurrentWorldMap { worldMap, error in
                guard let map = worldMap else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let data = try NSKeyedArchiver.archivedData(
                        withRootObject: map,
                        requiringSecureCoding: true
                    )
                    continuation.resume(returning: data)
                } catch {
                    print("fetchCurrentWorldMapData error:", error)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
}

public extension ARWorldMap {
    static func fetchWorldMap(from data: Data?) -> ARWorldMap? {
        guard let data = data else { return nil }
        
        do {
            if let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                return map
            }
        } catch {
            print("unarchive error:", error)
        }
        return nil
    }
}
