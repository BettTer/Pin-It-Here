//
//  BaseDataProcessor.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-05-31.
//

import UIKit

public class BaseDataProcessor: NSObject {
    public let baseLoader = DataProcessorLoader()
    
    required override init() {
        super.init()
    }
    
    /// Subclass Implementing this method and calls markAsLoading(), markAsLoaded(), markAsFailed(error)
//    open func reloadData() {
//
//    }
    
}

public class DataProcessorLoader: NSObject {
    public enum LoadState {
        case notStarted
        case loading
        case loaded
        case failed(Error)
    }

    private var state: LoadState = .notStarted
    public var currentState: LoadState {
        return state
    }
    
    private var continuations: [CheckedContinuation<Void, Never>] = []
    
    
    public func isLoaded() -> Bool {
        if case .loaded = state { return true }
        return false
    }
    
    public func markAsLoading() {
        state = .loading
    }

    public func markAsLoaded() {
        state = .loaded
        
        let continuationsToResume = continuations
        continuations.removeAll()

        DispatchQueue.main.async {
            for continuation in continuationsToResume {
                continuation.resume()
            }
        }
    }
    
    public func markAsFailed(_ error: Error) {
        state = .failed(error)
        
        let continuationsToResume = continuations
        continuations.removeAll()

        DispatchQueue.main.async {
            for continuation in continuationsToResume {
                continuation.resume()
            }
        }
    }
    
    private func resumeAllContinuations() {
        continuations.forEach { $0.resume() }
        continuations.removeAll()
    }

    func waitUntilLoaded() async {
        switch state {
        case .loaded, .failed:
            return
        default:
            break
        }
        
        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }
}
