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

/// A powerful InputAccessoryView ideal for messaging applications
open class InputBarAccessoryView: UIView {
    /// A delegate to broadcast notifications from the `InputBarAccessoryView`
    weak var delegate: InputBarAccessoryViewDelegate?

    /// The InputTextView a user can input a message in
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
    
    /// A boolean that indicates if the maxTextViewHeight has been met. Keeping track of this
    /// improves the performance
    public private(set) var isOverMaxTextViewHeight = false
    
    /// A boolean that determines if the `maxTextViewHeight` should be maintained automatically.
    /// To control the maximum height of the view yourself, set this to `false`.
    open var shouldAutoUpdateMaxTextViewHeight = true

    /// The maximum height that the InputTextView can reach.
    /// This is set automatically when `shouldAutoUpdateMaxTextViewHeight` is true.
    /// To control the height yourself, make sure to set `shouldAutoUpdateMaxTextViewHeight` to false.
    open var maxTextViewHeight: CGFloat = 0 {
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
    private lazy var textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: maxTextViewHeight)

    // MARK: - Initialization
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    
    /// Sets up the default properties
    open func setup() {
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
        // textViewHeightConstraint.constant = maxTextViewHeight
    }

    // MARK: - Constraint Layout Updates

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if newSuperview == nil {
            NSLayoutConstraint.deactivate(textViewLayoutConstraints)
        } else {
            NSLayoutConstraint.activate(textViewLayoutConstraints)
        }
    }

    /// Returns the most recent size calculated by `calculateIntrinsicContentSize()`
    open override var intrinsicContentSize: CGSize {
        return cachedIntrinsicContentSize
    }

    /// Invalidates the view’s intrinsic content size
    open override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        cachedIntrinsicContentSize = calculateIntrinsicContentSize()
    }

    /// The height that will fit the current text in the InputTextView based on its current bounds
    private func preferredTextViewHeight() -> CGFloat {
        let maxTextViewSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        return textView.sizeThatFits(maxTextViewSize).height.rounded(.down)
    }

    /// Calculates the correct intrinsicContentSize of the InputBarAccessoryView
    ///
    /// - Returns: The required intrinsicContentSize
    private func calculateIntrinsicContentSize() -> CGSize {
        var inputTextViewHeight = preferredTextViewHeight()
        if inputTextViewHeight >= maxTextViewHeight {
            if !isOverMaxTextViewHeight {
                textViewHeightConstraint.isActive = true
                textView.isScrollEnabled = true
                isOverMaxTextViewHeight = true
            }
            inputTextViewHeight = maxTextViewHeight
        } else {
            if isOverMaxTextViewHeight {
                textViewHeightConstraint.isActive = false
                textView.isScrollEnabled = false
                isOverMaxTextViewHeight = false
                textView.invalidateIntrinsicContentSize()
            }
        }
        
        // Calculate the required height
        let requiredHeight = padding.top + inputTextViewHeight + padding.bottom
        return CGSize(width: UIView.noIntrinsicMetric, height: requiredHeight)
    }

    open override func layoutIfNeeded() {
        super.layoutIfNeeded()
        textView.layoutIfNeeded()
    }

    /// Returns the max height the InputTextView can grow to based on the UIScreen
    ///
    /// - Returns: Max Height
    private func calculateMaxTextViewHeight() -> CGFloat {
        if traitCollection.verticalSizeClass == .regular {
            return (UIScreen.main.bounds.height / 3).rounded(.down)
        }
        return (UIScreen.main.bounds.height / 5).rounded(.down)
    }
    
    // MARK: - Notifications/Hooks
    
    /// Invalidates the intrinsicContentSize
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            if shouldAutoUpdateMaxTextViewHeight {
                maxTextViewHeight = calculateMaxTextViewHeight()
            } else {
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// Invalidates the intrinsicContentSize
    @objc
    private func orientationDidChange() {
        if shouldAutoUpdateMaxTextViewHeight {
            maxTextViewHeight = calculateMaxTextViewHeight()
        }
        invalidateIntrinsicContentSize()
    }

    /// Enables/Disables the sendButton based on the InputTextView's text being empty
    /// Invalidates the intrinsicContentSize
    /// Calls the delegates `textViewTextDidChangeTo` method
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
