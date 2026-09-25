//
//  File.swift
//  LocalSharedPackage
//
//  Created by YY.COUPLE on 2025-09-24.
//

import Foundation
import UIKit
import SwiftUI

public class ImageManager: NSObject {
    public static func resizedImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? image
    }
}

// MARK: - SFSymbol Images
extension ImageManager {
    public enum SFSymbolName: String {
        // MARK: - LaunchScreen
        case arrowForward = "arrow.forward.circle"
        case close = "xmark.circle"
        case heartList = "heart.text.clipboard"
        case heartCircle = "heart.circle"
        case powermeter = "powermeter"
        case circle_1 = "1.circle.fill"
        case circle_2 = "2.circle.fill"
        case circle_3 = "3.circle.fill"
        case circle_4 = "4.circle.fill"
        
    }
    
    public static func fetchSFSymbol(_ name: SFSymbolName, color: UIColor? = nil, pointSize: CGFloat? = nil) -> UIImage? {
        var configuration: UIImage.SymbolConfiguration?

        if let size = pointSize {
            configuration = UIImage.SymbolConfiguration(pointSize: size, weight: .regular)
        }

        var image = UIImage(systemName: name.rawValue, withConfiguration: configuration)

        if let color = color {
            image = image?.withTintColor(color, renderingMode: .alwaysOriginal)
        }

        return image
    }
    
    public static func swiftUI_fetchSFSymbol(_ name: SFSymbolName, color: Color = .primary, pointSize: CGFloat = 17, weight: Font.Weight = .regular, needBorder: Bool = false, needToSetFrame: Bool = true) -> some View {
        
        ZStack {
            let realSize = pointSize * 0.65
            
            if needBorder {
                RoundedRectangle(cornerRadius: pointSize / 2)
                    .stroke(color, lineWidth: 1.5)
                    .frame(width: pointSize, height: pointSize)
                
                Image(systemName:name.rawValue)
                    .resizable()
                    .scaledToFit()
                    .fontWeight(weight)
                    .foregroundColor(color)
                    .padding(0)
                    .frame(width: realSize, height: realSize)
                
            } else {
                
                if needToSetFrame {
                    Image(systemName:name.rawValue)
                        .resizable()
                        .scaledToFit()
                        .fontWeight(weight)
                        .foregroundColor(color)
                        .padding(0)
                        .frame(width: pointSize, height: pointSize)
                } else {
                    Image(systemName:name.rawValue)
                        .resizable()
                        .scaledToFit()
                        .fontWeight(weight)
                        .foregroundColor(color)
                        .padding(0)
                    
                }
            }

        }
    }
    
    public static func swiftUI_fetchSFSymbolImage(_ name: SFSymbolName) -> Image {
        Image(systemName:name.rawValue)
    }
    
    
    public static func resizableSolidColor(_ color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)))
        }
        return image.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
    }
}

// MARK: - Assets Images
extension ImageManager {
    public enum AssetsImageKey: String {
        case ARIndicator_crosshairs = "ARIndicator_crosshairs"
        case ARIndicator_oneQuarterCorner = "ARIndicator_one-quarterCorner"
    }
    
    public static func fetchAssetsImage(
        _ key: AssetsImageKey,
        color: UIColor? = nil,
        size: CGSize? = nil
    ) -> UIImage? {
        guard let baseImage = UIImage(named: key.rawValue) else {
            assertionFailure("Missing image: \(key.rawValue)")
            return nil
        }
        
        let image = color != nil
            ? baseImage.withTintColor(color!, renderingMode: .alwaysOriginal)
            : baseImage
        
        if let size = size {
            return resizedImage(image, to: size)
        }
        
        return image
    }
    
    public static func swiftUI_fetchAssetsImage(
        _ key: AssetsImageKey,
        color: Color?,
        size: CGSize
    ) -> some View {
        
        VStack {
            if let color = color {
                Image(key.rawValue)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .foregroundColor(color)
                
            } else {
                Image(key.rawValue)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                
            }
        }
    }
}
