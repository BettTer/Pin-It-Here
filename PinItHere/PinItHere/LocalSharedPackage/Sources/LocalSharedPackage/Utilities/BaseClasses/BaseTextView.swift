//
//  BaseTextView.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-10.
//

import UIKit

class BaseTextView: UITextView {
    // MARK: - UI
    let placeholderLabel = UILabel()
    private var tapGesture: UITapGestureRecognizer! {
        didSet {
            tapGesture.delegate = self
            addGestureRecognizer(tapGesture)
        }
    }
    
    
    // MARK: - Data
    private weak var externalDelegate: UITextViewDelegate?
    override var delegate: UITextViewDelegate? {
        get { return externalDelegate }
        set { externalDelegate = newValue }
    }
    
    override var intrinsicContentSize: CGSize {
        let height = fetchShouldExistHeight()
        
        if let maxHeight = maxHeight {
            return CGSize(width: bounds.width, height: min(height, maxHeight))
            
        } else {
            return CGSize(width: bounds.width, height: height)
            
        }
    }
    override var text: String! {
        didSet {
            textDidChange()
            
            if oldValue.count == 0 && needTextClickEvent {
                prepareForTextTapRecognition()
            }
        }
    }
    
    public var maxHeight: CGFloat?
    public var placeholder: String = "placeholder" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    public var needTextClickEvent = false
    public var textClickCallback: ((String) -> Void)?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupViews()
    }
    
    private func prepareForTextTapRecognition() {
        
        if text.count > 0 {
            // 模拟选中第一个字符
            let start = beginningOfDocument
            if let end = position(from: start, offset: 1),
               let range = textRange(from: start, to: end) {
                selectedTextRange = range
            }

            // 延迟取消选中，触发 input system 初始化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.selectedTextRange = nil
            }
        }
//        layoutManager.ensureLayout(for: textContainer)
//
//        if text.count > 0 {
//            let range = NSRange(location: 0, length: min(1, text.utf16.count))
//            _ = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
//        }
    }
    

}

// MARK: - Methods
extension BaseTextView {
    private func setupViews() {
        super.delegate = self
        returnKeyType = .go
        isScrollEnabled = false
        font = UIFont.systemFont(ofSize: 16)
        
//        layer.borderColor = UIColor.lightGray.cgColor
//        layer.borderWidth = 1
//        layer.cornerRadius = 8
//        clipsToBounds = true
        
        placeholderLabel.textColor = .systemGray2
        placeholderLabel.font = font
        addSubview(placeholderLabel)
        
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    }
    
    private func textDidChange() {
        updatePlaceholderVisibility()
        
        isScrollEnabled = false
        if let maxHeight = maxHeight, fetchShouldExistHeight() >= maxHeight {
            isScrollEnabled = true
        }
        
        invalidateIntrinsicContentSize()
    }
    
    private func fetchShouldExistHeight() -> CGFloat {
        let fittingSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let height = sizeThatFits(fittingSize).height
        return height
    }
    
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = isFirstResponder || !text.isEmpty
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard needTextClickEvent == true else {
            return
        }
        
        let location = gesture.location(in: self)
        let glyphIndex = layoutManager.glyphIndex(for: location, in: textContainer, fractionOfDistanceThroughGlyph: nil)
        let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
        
        if characterIndex < text.utf16.count {
            // 转换为 String.Index
            let utf16Index = text.utf16.index(text.utf16.startIndex, offsetBy: characterIndex)
            if let index = String.Index(utf16Index, within: text) {
                let scalar = text[index]
                textClickCallback?(String(scalar))
            }
        }
        

    }
}

// MARK: - UIGestureRecognizerDelegate
extension BaseTextView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard needTextClickEvent == true else {
            return false
        }
        
        // 如果当前正在选中文本，不响应 Tap 手势
        return selectedTextRange == nil
    }
}

// MARK: - UITextViewDelegate
extension BaseTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
        externalDelegate?.textViewDidBeginEditing?(textView)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
        externalDelegate?.textViewDidEndEditing?(textView)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textDidChange()
        externalDelegate?.textViewDidChange?(textView)
    }
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if let result = externalDelegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) {
            return result
        }
        return true
    }
}
