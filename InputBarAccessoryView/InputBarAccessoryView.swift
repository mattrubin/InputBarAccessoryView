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
    
    // MARK: - Properties
    
    /// A delegate to broadcast notifications from the `InputBarAccessoryView`
    open weak var delegate: InputBarAccessoryViewDelegate?

    /// The InputTextView a user can input a message in
    open lazy var inputTextView: UITextView = { [weak self] in
        let inputTextView = UITextView()
        inputTextView.backgroundColor = .clear
        inputTextView.font = UIFont.preferredFont(forTextStyle: .body)
        inputTextView.isScrollEnabled = false
        inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                                           left: .leastNonzeroMagnitude,
                                                           bottom: .leastNonzeroMagnitude,
                                                           right: .leastNonzeroMagnitude)
        inputTextView.layer.borderWidth = 1
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        return inputTextView
    }()

    /**
     The anchor contants used by the InputStackView's and InputTextView to create padding
     within the InputBarAccessoryView
     
     ## Important Notes ##
     
     ````
     V:|...[InputStackView.top]-(padding.top)-[contentView]-(padding.bottom)-|
     
     H:|-(frameInsets.left)-(padding.left)-[contentView]-(padding.right)-(frameInsets.right)-|
     ````
     
     */
    let padding: UIEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

    /// Returns the most recent size calculated by `calculateIntrinsicContentSize()`
    open override var intrinsicContentSize: CGSize {
        return cachedIntrinsicContentSize
    }
    
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
            textViewHeightAnchor?.constant = maxTextViewHeight
        }
    }
    
    /// A boolean that determines whether the sendButton's `isEnabled` state should be managed automatically.
    open var shouldManageSendButtonEnabledState = true
    
    /// The height that will fit the current text in the InputTextView based on its current bounds
    public var requiredInputTextViewHeight: CGFloat {
        let maxTextViewSize = CGSize(width: inputTextView.bounds.width, height: .greatestFiniteMagnitude)
        return inputTextView.sizeThatFits(maxTextViewSize).height.rounded(.down)
    }

    // MARK: - Auto-Layout Constraint Sets
    
    private var textViewLayoutSet: [NSLayoutConstraint] = []
    private var textViewHeightAnchor: NSLayoutConstraint?

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

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard newSuperview != nil else {
            deactivateConstraints()
            return
        }
        activateConstraints()
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
                                               selector: #selector(InputBarAccessoryView.inputTextViewDidChange),
                                               name: UITextView.textDidChangeNotification, object: inputTextView)
    }
    
    /// Adds all of the subviews
    private func setupSubviews() {
        addSubview(inputTextView)
    }
    
    /// Sets up the initial constraints of each subview
    private func setupConstraints() {
        
        // The constraints within the InputBarAccessoryView
        translatesAutoresizingMaskIntoConstraints = false

        textViewLayoutSet = [
            inputTextView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
            inputTextView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding.bottom),
            inputTextView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: padding.left),
            inputTextView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -padding.right)
        ]
        addConstraints(textViewLayoutSet)
        
        // Constraints Within the contentView
        maxTextViewHeight = calculateMaxTextViewHeight()
        textViewHeightAnchor = inputTextView.heightAnchor.constraint(equalToConstant: maxTextViewHeight)
    }

    // MARK: - Constraint Layout Updates

    /// Invalidates the view’s intrinsic content size
    open override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        cachedIntrinsicContentSize = calculateIntrinsicContentSize()
    }
    
    /// Calculates the correct intrinsicContentSize of the InputBarAccessoryView
    ///
    /// - Returns: The required intrinsicContentSize
    open func calculateIntrinsicContentSize() -> CGSize {
        
        var inputTextViewHeight = requiredInputTextViewHeight
        if inputTextViewHeight >= maxTextViewHeight {
            if !isOverMaxTextViewHeight {
                textViewHeightAnchor?.isActive = true
                inputTextView.isScrollEnabled = true
                isOverMaxTextViewHeight = true
            }
            inputTextViewHeight = maxTextViewHeight
        } else {
            if isOverMaxTextViewHeight {
                textViewHeightAnchor?.isActive = false
                inputTextView.isScrollEnabled = false
                isOverMaxTextViewHeight = false
                inputTextView.invalidateIntrinsicContentSize()
            }
        }
        
        // Calculate the required height
        let totalPadding = padding.top + padding.bottom
        let requiredHeight = inputTextViewHeight + totalPadding
        return CGSize(width: UIView.noIntrinsicMetric, height: requiredHeight)
    }

    open override func layoutIfNeeded() {
        super.layoutIfNeeded()
        inputTextView.layoutIfNeeded()
    }

    /// Returns the max height the InputTextView can grow to based on the UIScreen
    ///
    /// - Returns: Max Height
    open func calculateMaxTextViewHeight() -> CGFloat {
        if traitCollection.verticalSizeClass == .regular {
            return (UIScreen.main.bounds.height / 3).rounded(.down)
        }
        return (UIScreen.main.bounds.height / 5).rounded(.down)
    }
    
    // MARK: - Layout Helper Methods
    

    /// Performs a layout over the main thread
    ///
    /// - Parameters:
    ///   - animated: If the layout should be animated
    ///   - animations: Animation logic
    internal func performLayout(_ animated: Bool, _ animations: @escaping () -> Void) {
        deactivateConstraints()
        if animated {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: animations)
            }
        } else {
            UIView.performWithoutAnimation { animations() }
        }
        activateConstraints()
    }
    
    /// Activates the NSLayoutConstraintSet's
    private func activateConstraints() {
        NSLayoutConstraint.activate(textViewLayoutSet)
    }
    
    /// Deactivates the NSLayoutConstraintSet's
    private func deactivateConstraints() {
        NSLayoutConstraint.deactivate(textViewLayoutSet)
    }

    // MARK: - Notifications/Hooks
    
    /// Invalidates the intrinsicContentSize
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            if shouldAutoUpdateMaxTextViewHeight {
                maxTextViewHeight = calculateMaxTextViewHeight()
            } else {
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// Invalidates the intrinsicContentSize
    @objc
    open func orientationDidChange() {
        if shouldAutoUpdateMaxTextViewHeight {
            maxTextViewHeight = calculateMaxTextViewHeight()
        }
        invalidateIntrinsicContentSize()
    }

    /// Enables/Disables the sendButton based on the InputTextView's text being empty
    /// Calls each items `textViewDidChangeAction` method
    /// Calls the delegates `textViewTextDidChangeTo` method
    /// Invalidates the intrinsicContentSize
    @objc
    open func inputTextViewDidChange() {
        
        let trimmedText = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if shouldManageSendButtonEnabledState {
            //sendButton.isEnabled = !trimmedText.isEmpty
        }
        
        // Capture change before iterating over the InputItem's
        let shouldInvalidateIntrinsicContentSize = requiredInputTextViewHeight != inputTextView.bounds.height
        
        delegate?.inputBar(self, textViewTextDidChangeTo: trimmedText)
        
        if shouldInvalidateIntrinsicContentSize {
            // Prevent un-needed content size invalidation
            invalidateIntrinsicContentSize()
        }
    }
}
