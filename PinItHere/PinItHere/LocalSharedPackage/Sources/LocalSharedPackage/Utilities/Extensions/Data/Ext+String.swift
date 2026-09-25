//
//  Ext+String.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-03.
//

import Foundation
import UIKit

extension String {
    public var boolValue: Bool {
        return ["yes", "true", ].contains(self.lowercased())
    }
    
    public func image(fontSize: CGFloat = 55, padding: CGFloat = 10) -> UIImage {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        // 计算字符实际占用的边界
        let textSize = (self as NSString).size(withAttributes: attributes)
        
        // 给定额外 padding，避免裁剪
        let size = CGSize(width: textSize.width + padding * 2,
                          height: textSize.height + padding * 2)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let drawPoint = CGPoint(x: padding, y: padding)
            (self as NSString).draw(at: drawPoint, withAttributes: attributes)
        }
    }
    
    public subscript (i: Int) -> String {
        return self[(i ..< i + 1)]
    }

    public subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(count, r.lowerBound)),
                                            upper: min(count, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        let rangeLast: Range<Index> = start..<end
        return String(self[rangeLast])
    }
    
    public func removeAllLeadingTrailingNonAlphanumeric() -> String {
        let pattern = #"^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        let range = NSRange(location: 0, length: self.utf16.count)
        let cleaned = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        return cleaned
    }
}

extension NSAttributedString {
    public static func buildAttributedText(from parts: [(String?, UIFont, UIColor)]) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        for part in parts {
            let (text, font, color) = part
            guard let text = text else {
                continue
            }
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            let attributedPart = NSAttributedString(string: text, attributes: attributes)
            
            attributedText.append(attributedPart)
        }
        
        return attributedText
    }
    
    public func fetchInfoParts() -> [(String?, UIFont, UIColor)] {
        var parts: [(String?, UIFont, UIColor)] = []
        
        self.enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { attributes, range, _ in
            let substring = self.attributedSubstring(from: range).string
            
            let font = (attributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
            let color = (attributes[.foregroundColor] as? UIColor) ?? UIColor.label
            
            parts.append((substring, font, color))
        }
        
        return parts
        
    }
    
    public enum ContentPart {
        case text(String?)
        case image(UIImage, CGFloat = -3) // 图片 + 可选大小 + 偏移
    }
    
    public static func buildAttributedTextWithImage(from parts: [(ContentPart, UIFont, UIColor)]) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        for part in parts {
            let (content, font, color) = part
            
            switch content {
            case .text(let text):
                if let contentText = text {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: color
                    ]
                    let attributedPart = NSAttributedString(string: contentText, attributes: attributes)
                    attributedText.append(attributedPart)
                    
                }

            case .image(let image, let offsetY):
                let attachment = OriginalSizeAttachment()
                attachment.image = image.withRenderingMode(.alwaysOriginal)
                attachment.baselineOffset = offsetY
                attributedText.append(NSAttributedString(attachment: attachment))
            }

        }
        
        return attributedText
    }
    
    public func fetchInfoPartsWithImage() -> [(ContentPart, UIFont, UIColor)] {
        var parts: [(ContentPart, UIFont, UIColor)] = []
        
        self.enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { attributes, range, _ in
            let font = (attributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
            let color = (attributes[.foregroundColor] as? UIColor) ?? UIColor.label
            
            if let attachment = attributes[.attachment] as? NSTextAttachment,
               let image = attachment.image {
                parts.append((.image(image, attachment.bounds.origin.y), UIFont.systemFont(ofSize: attachment.bounds.size.height), color))
                
            } else {
                let substring = self.attributedSubstring(from: range).string
                parts.append((.text(substring), font, color))
                
            }
        }
        
        return parts
    }
    
}


final class OriginalSizeAttachment: NSTextAttachment {
    var baselineOffset: CGFloat = 0

    override func attachmentBounds(for textContainer: NSTextContainer?,
                                   proposedLineFragment lineFrag: CGRect,
                                   glyphPosition position: CGPoint,
                                   characterIndex charIndex: Int) -> CGRect {
        guard let img = image else { return .zero }
        // 用「点」尺寸，保持 1:1
        return CGRect(x: 0, y: baselineOffset, width: img.size.width, height: img.size.height)
    }
}
