//
//  Ext+UIColor.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-15.
//

import Foundation
import UIKit

extension UIColor {
    public static func hexStringToUIColor (_ hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    public func hexString() -> String {
        let components = self.cgColor.components
        
        var r: CGFloat = 0.0
        if let datas = components, datas.count > 0 {
            r = datas[0]
        }
        
        var g: CGFloat = 0.0
        if let datas = components, datas.count > 1 {
            g = datas[1]
        }
        
        var b: CGFloat = 0.0
        if let datas = components, datas.count > 2 {
            b = datas[2]
        }
        

        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
     }

}
