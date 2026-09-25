//
//  File.swift
//  LocalSharedPackage
//
//  Created by YY.COUPLE on 2025-09-26.
//

import Foundation

public class NoteRecordStoreManager: BaseDataProcessor, @unchecked Sendable {
    public static let shared: NoteRecordStoreManager = NoteRecordStoreManager()
    public static let fileName: String = "SavedNoteRecords.json"
    
    public var url: URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return doc.appendingPathComponent(NoteRecordStoreManager.fileName)
    }
    
    public var records: [NoteRecordModel] = []
    
    public var onlyRecord: NoteRecordModel? {
        return records.first
    }
    
    public func tryToLoadData(completion: @Sendable @escaping () -> Void) {
        Task {
            switch baseLoader.currentState {
            case .notStarted, .failed:
                load()
                await baseLoader.waitUntilLoaded()
                
            case .loaded:
                break
                
            case .loading:
                await baseLoader.waitUntilLoaded()
                
            }
            
            completion()
        }
    }
    
    private func load() {
        baseLoader.markAsLoading()
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            baseLoader.markAsLoaded()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            records = try JSONDecoder().decode([NoteRecordModel].self, from: data)
            baseLoader.markAsLoaded()
            print("PaperStore markAsLoaded!")
            
        } catch {
            print("PaperStore load failed:", error)
            baseLoader.markAsFailed(error)
        }
    }
    
    public func save() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: url)
            print("PaperStore saved!")
            
        } catch {
            print("PaperStore save failed:", error)
        }
    }
    
    public func lookup(id: String) -> NoteRecordModel? {
        records.first{ $0.id == id }
    }
    
    public func upsert(_ model: NoteRecordModel) {
        records.removeAll()
        
        if let i = records.firstIndex(where: { $0.id == model.id }) {
            records[i] = model
        } else {
            records.append(model)
        }
        
        save()
    }
    
    public func remove(id: String?) {
        if let id = id {
            if let index = records.firstIndex(where: { $0.id == id }) {
                records.remove(at: index)
            }
            
        } else {
            records.removeAll()
        }
        
        save()
    }
    
}
