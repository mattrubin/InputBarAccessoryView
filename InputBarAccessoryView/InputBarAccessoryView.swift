//
//  InputBarAccessoryView.swift
//  InputBarAccessoryView
//
//  Copyright © 2017-2018 Nathan Tannar.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Nathan Tannar on 8/18/17.
//

import UIKit

public class InputBarAccessoryView: UIView {
    public let textView = UITextView().configure { textView in
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 4
        textView.layer.borderWidth = 1 / UIScreen.main.scale
        textView.layer.borderColor = UIColor(named: "DividerColor")?.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 6, left: 4, bottom: 4, right: 4)
        textView.scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                                      left: .leastNonzeroMagnitude,
                                                      bottom: .leastNonzeroMagnitude,
                                                      right: .leastNonzeroMagnitude)
        textView.isScrollEnabled = false
    }

    let separator = UIView().configure {
        $0.backgroundColor = UIColor(named: "DividerColor")
    }

    // Cached Layout Metrics

    private let padding: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    private var cachedIntrinsicContentSize: CGSize?

    private var maxTextViewHeight: CGFloat = 0 {
        didSet {
            textViewHeightConstraint.constant = maxTextViewHeight
        }
    }

    // Layout Constraints

    private lazy var textViewLayoutConstraints = [
        textView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: padding.top),
        textView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding.bottom),
        textView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: padding.left),
        textView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -padding.right)
    ]

    private lazy var textViewHeightConstraint = textView.heightAnchor.constraint(lessThanOrEqualToConstant: maxTextViewHeight)

    private lazy var separatorLayoutConstraints = [
        separator.topAnchor.constraint(equalTo: topAnchor),
        separator.leadingAnchor.constraint(equalTo: leadingAnchor),
        separator.trailingAnchor.constraint(equalTo: trailingAnchor),
        separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
    ]

    // MARK: - Initialization
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    
    private func setup() {
        backgroundColor = UIColor(named: "BackgroundColor")
        autoresizingMask = [.flexibleHeight]

        setupSubviews()
        setupObservers()
    }

    private func setupSubviews() {
        addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(separatorLayoutConstraints)

        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(textViewLayoutConstraints)

        // Constraints Within the contentView
        maxTextViewHeight = calculateMaxTextViewHeight()
        addConstraint(textViewHeightConstraint)
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputBarAccessoryView.orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputBarAccessoryView.textDidChange),
                                               name: UITextView.textDidChangeNotification, object: textView)
    }

    // MARK: - Override

    override public func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if newSuperview == nil {
            NSLayoutConstraint.deactivate(textViewLayoutConstraints)
        } else {
            NSLayoutConstraint.activate(textViewLayoutConstraints)
        }
    }

    override public func layoutIfNeeded() {
        super.layoutIfNeeded()
        textView.layoutIfNeeded()
    }

    override public var intrinsicContentSize: CGSize {
        if let intrinsicContentSize = cachedIntrinsicContentSize {
            return intrinsicContentSize
        }

        var textViewHeight = preferredTextViewHeight()
        if textViewHeight >= maxTextViewHeight {
            textViewHeight = maxTextViewHeight
            textView.isScrollEnabled = true
        } else {
            textView.isScrollEnabled = false
        }

        let preferredHeight = padding.top + textViewHeight + padding.bottom
        let intrinsicContentSize = CGSize(width: UIView.noIntrinsicMetric, height: preferredHeight)

        cachedIntrinsicContentSize = intrinsicContentSize
        return intrinsicContentSize
    }

    override public func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        cachedIntrinsicContentSize = nil
    }

    // MARK: - Size Calculation

    private func preferredTextViewHeight() -> CGFloat {
        let maxTextViewSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        return textView.sizeThatFits(maxTextViewSize).height.rounded(.down)
    }

    private func calculateMaxTextViewHeight() -> CGFloat {
        if traitCollection.verticalSizeClass == .regular {
            return (UIScreen.main.bounds.height / 3).rounded(.down)
        }
        return (UIScreen.main.bounds.height / 5).rounded(.down)
    }
    
    // MARK: - Notifications/Hooks
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            maxTextViewHeight = calculateMaxTextViewHeight()
        }
    }
    
    @objc
    private func orientationDidChange() {
        maxTextViewHeight = calculateMaxTextViewHeight()
        invalidateIntrinsicContentSize()
    }

    @objc
    private func textDidChange() {
        let trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // FIXME: sendButton.isEnabled = !trimmedText.isEmpty

        // Prevent un-needed content size invalidation
        let shouldInvalidateIntrinsicContentSize = preferredTextViewHeight() != textView.bounds.height
        if shouldInvalidateIntrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }
}

private extension NSObjectProtocol {
    func configure(with body: (Self) -> Void) -> Self {
        body(self)
        return self
    }
}
