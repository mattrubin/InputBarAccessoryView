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
    weak var delegate: InputBarAccessoryViewDelegate?

    private(set) lazy var textView: UITextView = { [weak self] in
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        textView.scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                                      left: .leastNonzeroMagnitude,
                                                      bottom: .leastNonzeroMagnitude,
                                                      right: .leastNonzeroMagnitude)
        textView.layer.borderWidth = 1
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private let padding: UIEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

    /// The most recent calculation of the intrinsicContentSize
    private lazy var cachedIntrinsicContentSize: CGSize = calculateIntrinsicContentSize()

    private var maxTextViewHeight: CGFloat = 0 {
        didSet {
            textViewHeightConstraint.constant = maxTextViewHeight
        }
    }

    private lazy var textViewLayoutConstraints = [
        textView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
        textView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding.bottom),
        textView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: padding.left),
        textView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -padding.right)
    ]
    private lazy var textViewHeightConstraint = textView.heightAnchor.constraint(lessThanOrEqualToConstant: maxTextViewHeight)

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
    
    /// Sets up the default properties
    private func setup() {
        backgroundColor = .white
        autoresizingMask = [.flexibleHeight]
        setupSubviews()
        setupConstraints()
        setupObservers()
    }
    
    /// Adds the required notification observers
    private func setupObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputBarAccessoryView.orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputBarAccessoryView.textDidChange),
                                               name: UITextView.textDidChangeNotification, object: textView)
    }
    
    /// Adds all of the subviews
    private func setupSubviews() {
        addSubview(textView)
    }
    
    /// Sets up the initial constraints of each subview
    private func setupConstraints() {
        
        // The constraints within the InputBarAccessoryView
        translatesAutoresizingMaskIntoConstraints = false
        addConstraints(textViewLayoutConstraints)
        
        // Constraints Within the contentView
        maxTextViewHeight = calculateMaxTextViewHeight()
        addConstraint(textViewHeightConstraint)
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
        return cachedIntrinsicContentSize
    }

    override public func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        cachedIntrinsicContentSize = calculateIntrinsicContentSize()
    }

    // MARK: - Size Calculation

    private func preferredTextViewHeight() -> CGFloat {
        let maxTextViewSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        return textView.sizeThatFits(maxTextViewSize).height.rounded(.down)
    }

    private func calculateIntrinsicContentSize() -> CGSize {
        var inputTextViewHeight = preferredTextViewHeight()
        if inputTextViewHeight >= maxTextViewHeight {
            textView.isScrollEnabled = true
            inputTextViewHeight = maxTextViewHeight
        } else {
            textView.isScrollEnabled = false
        }
        
        // Calculate the required height
        let requiredHeight = padding.top + inputTextViewHeight + padding.bottom
        return CGSize(width: UIView.noIntrinsicMetric, height: requiredHeight)
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

        delegate?.inputBar(self, textViewTextDidChangeTo: trimmedText)
    }
}
