//
//  BaseData.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-10.
//

import Foundation
import UIKit
import SwiftUI
import RealityKit

public class UsefulTools: NSObject {
    /// Set, Array does't work
    public static func describe(_ value: Any) -> [String] {
        let mirror = Mirror(reflecting: value)
        var result: [String] = []

        for child in mirror.children {
            guard let label = child.label else { continue }

            let childMirror = Mirror(reflecting: child.value)
            if childMirror.children.isEmpty {
                result.append("\(label)=\(child.value)")
            } else {
                // 递归展开
                let subResults = describe(child.value).map { "\(label).\($0)" }
                result.append(contentsOf: subResults)
            }
        }

        return result
    }
}

public struct UsefulTools_SUIV {
    @ViewBuilder
    static public func buildTextWithUnderline(
        _ text: String,
        font: Font,
        textColor: Color,
        lineColor: Color,
        lineThickness: CGFloat = 2.5,
        offset: CGFloat = 3.5,
    ) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(textColor)
            .overlay(
                Rectangle()
                    .fill(lineColor)
                    .frame(height: lineThickness)
                    .offset(y: offset),
                alignment: .bottom
            )
    }
    
}

// MARK: - Debug LOG
public class LOG: NSObject {
    public static let verbose: Bool = true
    
    @inline(__always)
    public static func p(_ tag: String, _ s: @autoclosure () -> String) {
        guard verbose else { return }; print("\(tag) \(s())")
    }
}

@MainActor
public struct Screen {
    public static var width: CGFloat {
        UIScreen.main.bounds.width
    }
    public static var height: CGFloat {
        UIScreen.main.bounds.height
    }
    public static var safeAreaInsets: UIEdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }
}

@MainActor
public struct HapticManager {
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    public static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

public struct SUIVFrameReader: UIViewRepresentable {
    var onUpdate: (CGRect) -> Void
    
    public init(onUpdate: @escaping (CGRect) -> Void) {
        self.onUpdate = onUpdate
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let superview = uiView.superview {
                let frame = superview.convert(uiView.frame, to: nil) // 获取全局 frame
                onUpdate(frame)
            }
        }
        
    }
}


public actor SerialExecutor {
    public init() {
        
    }
    
    func enqueue<T: Sendable>(_ work: @escaping @Sendable () async -> T) async -> T {
        return await work()
    }
}


public actor AnimationQueue {
    public init() {
        
    }
    
    private var currentTask: Task<Void, Never>? = nil

    public func enqueue(_ operation: @escaping @Sendable () async -> Void) {
        let previousTask = currentTask

        currentTask = Task {
            // 等待上一个 task 执行完成
            await previousTask?.value

            // 执行当前 operation
            await operation()
        }
    }
}

public extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

public extension Locale {
    func fetchPriorityLanguageCode() -> String? {
        if let langCode = language.languageCode?.identifier {
            let baseLang = langCode.prefix(2)
            return String(baseLang)
        }
        
        return nil
    }
    
}
