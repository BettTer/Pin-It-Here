//
//  BaseScrollStackView.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-06.
//

//import UIKit
//import SnapKit
//
//class BaseScrollStackView: UIView {
//    // MARK: - UI
//    public let scrollView = UIScrollView()
//    public let containerView = UIView()
//    public let stackView = UIStackView()
//
//    // MARK: - Data
//    
//    
//    // MARK: - Init
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupViews()
//        setupConstraints()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupViews()
//        setupConstraints()
//    }
//    
//    public func setCommonProperties(stackSpacing: CGFloat,
//                                    horizontalInset: CGFloat,
//                                    verticalInset: CGFloat) {
//        stackView.spacing = stackSpacing
//        stackView.snp.updateConstraints { make in
//            make.top.bottom.equalToSuperview().inset(verticalInset)
//            make.left.right.equalToSuperview().inset(horizontalInset)
//        }
//        
//    }
//    
//    public func addLabelToStackView(_ label: UILabel) {
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.numberOfLines = 0
//        label.setContentHuggingPriority(.required, for: .vertical)
//        label.setContentCompressionResistancePriority(.required, for: .vertical)
//        
//        stackView.addArrangedSubview(label)
//    }
//    
//    func addDetermineSizeViewToScrollStack(itemView: UIView, height: CGFloat) -> UIView {
//        let backgroundView = UIView()
//        backgroundView.backgroundColor = UIColor.clear
//        stackView.addArrangedSubview(backgroundView)
//        backgroundView.snp.makeConstraints { make in
//            make.height.equalTo(height)
//        }
//
//        backgroundView.addSubview(itemView)
//        itemView.snp.makeConstraints { make in
//            make.top.left.bottom.equalToSuperview()
//        }
//        
//        return backgroundView
//    }
//    
//}

//// MARK: - Methods
//extension BaseScrollStackView {
//    private func setupViews() {
//        addSubview(scrollView)
//        scrollView.addSubview(containerView)
//        containerView.addSubview(stackView)
//
//        stackView.axis = .vertical
//        // Vertical spacing
//        stackView.spacing = 8
//        stackView.alignment = .fill
//        stackView.distribution = .fill
//    }
//    
//    private func setupConstraints() {
//        scrollView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//
//        containerView.snp.makeConstraints { make in
//            make.edges.equalTo(scrollView.contentLayoutGuide)
//            // key: limit width, not scroll horizontally
//            make.width.equalTo(scrollView.frameLayoutGuide)
//        }
//
//        stackView.snp.makeConstraints { make in
//            // inner edge
//            make.edges.equalToSuperview().inset(16)
//        }
//    }
//
//    
//}

import UIKit

class BaseScrollStackView: UIView {
    // MARK: - UI
    public let scrollView = UIScrollView()
    public let containerView = UIView()
    public let stackView = UIStackView()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }

    public func setCommonProperties(stackSpacing: CGFloat,
                                    horizontalInset: CGFloat,
                                    verticalInset: CGFloat) {
        stackView.spacing = stackSpacing

        // 更新 stackView 的边距约束
        stackTopConstraint?.constant = verticalInset
        stackBottomConstraint?.constant = -verticalInset
        stackLeadingConstraint?.constant = horizontalInset
        stackTrailingConstraint?.constant = -horizontalInset
    }

    public func addLabelToStackView(_ label: UILabel) {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        stackView.addArrangedSubview(label)
    }

    func addDetermineSizeViewToScrollStack(itemView: UIView, height: CGFloat) -> UIView {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .clear
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.heightAnchor.constraint(equalToConstant: height)
        ])

        itemView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(itemView)

        NSLayoutConstraint.activate([
            itemView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            itemView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            itemView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])

        return backgroundView
    }

    // MARK: - Constraints
    private var stackTopConstraint: NSLayoutConstraint?
    private var stackBottomConstraint: NSLayoutConstraint?
    private var stackLeadingConstraint: NSLayoutConstraint?
    private var stackTrailingConstraint: NSLayoutConstraint?
}

// MARK: - Setup
extension BaseScrollStackView {
    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(stackView)

        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .fill
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),

            containerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        stackTopConstraint = stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16)
        stackBottomConstraint = stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        stackLeadingConstraint = stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16)
        stackTrailingConstraint = stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            stackTopConstraint!,
            stackBottomConstraint!,
            stackLeadingConstraint!,
            stackTrailingConstraint!
        ])
    }
}
