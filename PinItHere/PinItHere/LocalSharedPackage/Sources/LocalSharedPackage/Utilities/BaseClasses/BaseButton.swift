//
//  BaseButton.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-05.
//

import UIKit

public class BaseButton: UIButton {
    private var originalConfiguration: UIButton.Configuration?
    public var needAutoCornerRadius: Bool = false
    
    // MARK: - ownIsHighlighted
    private var ownIsHighlighted: Bool = false
    private var needHighlightableStatus: Bool = false
    private var longPressRecognizer: UILongPressGestureRecognizer!
    private var isHighlightedChangedAction: ((BaseButton, Bool) -> Void)?
    
//    var needInstantSelectedEffect: Bool = false
//    override var isSelected: Bool {
//        didSet {
//            if isSelected != oldValue, needInstantSelectedEffect == true {
//                updateSelectionState()
//            }
//        }
//    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if needAutoCornerRadius {
            layer.cornerRadius = bounds.height / 2
            clipsToBounds = true
        }
    }
    
    public func setupHighlightableStatus(changedAction: @escaping (BaseButton, Bool) -> Void) {
        needHighlightableStatus = true
        
        isHighlightedChangedAction = changedAction
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        longPressRecognizer.minimumPressDuration = 0 // 立即响应
        longPressRecognizer.cancelsTouchesInView = false // 保留原始事件（如点击）
        addGestureRecognizer(longPressRecognizer)
    }
    
    @objc private func handlePress(_ recognizer: UILongPressGestureRecognizer) {
        guard needHighlightableStatus else {
            return
        }
        
        let location = recognizer.location(in: self)

        switch recognizer.state {
        case .began, .changed: // * 手指在按钮范围内
            ownIsHighlighted = bounds.contains(location)
            isHighlightedChangedAction?(self, ownIsHighlighted)
            
        case .ended, .cancelled, .failed:
            ownIsHighlighted = false
            isHighlightedChangedAction?(self, ownIsHighlighted)
            
        default:
            break
        }
    }

}

// MARK: - UI
extension BaseButton {
    public func setupShadow(_ color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        
        clipsToBounds = false
    }
    
    public func setupBorder(_ color: UIColor, width: CGFloat) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
    }
    
    private func updateSelectionState() {
        backgroundColor = UIColor.systemGray5
        DispatchQueue.main.asyncAfter(deadline: .now() + UIView.AnimationDuration) {[weak self] in
            self?.backgroundColor = UIColor.clear
        }
    }
}

// MARK: - UIButton.Configuration
extension BaseButton {
    public func setNoneStatus() {
        originalConfiguration = configuration
        
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = .clear
        config.baseBackgroundColor = .clear
        config.background.strokeColor = .clear
        config.cornerStyle = .capsule
        
        configuration = config
    }
    
    public func restoreStatus() {
        configuration = originalConfiguration
    }
    
}
