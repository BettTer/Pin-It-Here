//
//  Ext+UIImage.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-03.
//

import UIKit

extension UIImage {
    public func buildPNGFile() -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID.init().uuidString).png")
        
        if let pngData = self.pngData() {
            try? pngData.write(to: tempURL)
            
            return tempURL
        }
        
        return nil
    }
    
}
