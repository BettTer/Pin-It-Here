//
//  Ext+DiDictionary.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-05-29.
//

import Foundation

extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        return try Dictionary<T, Value>(uniqueKeysWithValues: self.map { (try transform($0.key), $0.value) })
    }
}
