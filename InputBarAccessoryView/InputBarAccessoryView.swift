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

    /// A content UIView that holds the left/right/bottom InputStackViews and InputTextView. Anchored to the bottom of the
    /// topStackView and inset by the padding UIEdgeInsets
    open var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        return inputTextView
    }()
    
    /// A InputBarButtonItem used as the send button and initially placed in the rightStackView
    open var sendButton: InputBarSendButton = {
        return InputBarSendButton()
            .configure {
                $0.setSize(CGSize(width: 52, height: 36), animated: false)
                $0.isEnabled = false
                $0.title = "Send"
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
                $0.translatesAutoresizingMaskIntoConstraints = false
            }.onTouchUpInside {
                $0.inputBarAccessoryView?.didSelectSendButton()
        }
    }()

    /**
     The anchor contants used to add horizontal inset from the InputBarAccessoryView and the
     window. By default, an `inputAccessoryView` spans the entire width of the UIWindow. You
     can manage these insets if you wish to implement designs that do not have the bar spanning
     the entire width.

     ## Important Notes ##

     USE AT YOUR OWN RISK

     ````
     H:|-(frameInsets.left)-[InputBarAccessoryView]-(frameInsets.right)-|
     ````

     */
    open var frameInsets: HorizontalEdgePadding = .zero {
        didSet {
            updateFrameInsets()
        }
    }
    
    /**
     The anchor contants used by the InputStackView's and InputTextView to create padding
     within the InputBarAccessoryView
     
     ## Important Notes ##
     
     ````
     V:|...[InputStackView.top]-(padding.top)-[contentView]-(padding.bottom)-|
     
     H:|-(frameInsets.left)-(padding.left)-[contentView]-(padding.right)-(frameInsets.right)-|
     ````
     
     */
    open var padding: UIEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12) {
        didSet {
            updatePadding()
        }
    }

    /**
     The anchor constants used by the InputStackView
     
     ````
     V:|...-(padding.top)-(textViewPadding.top)-[InputTextView]-(textViewPadding.bottom)-[InputStackView.bottom]-...|
     
     H:|...-[InputStackView.left]-(textViewPadding.left)-[InputTextView]-(textViewPadding.right)-[InputStackView.right]-...|
     ````
     
     */
    open var textViewPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8) {
        didSet {
            updateTextViewPadding()
        }
    }
    
    /// Returns the most recent size calculated by `calculateIntrinsicContentSize()`
    open override var intrinsicContentSize: CGSize {
        return cachedIntrinsicContentSize
    }
    
    /// The intrinsicContentSize can change a lot so the delegate method
    /// `inputBar(self, didChangeIntrinsicContentTo: size)` only needs to be called
    /// when it's different
    public private(set) var previousIntrinsicContentSize: CGSize?
    
    /// The most recent calculation of the intrinsicContentSize
    private lazy var cachedIntrinsicContentSize: CGSize = calculateIntrinsicContentSize()
    
    /// A boolean that indicates if the maxTextViewHeight has been met. Keeping track of this
    /// improves the performance
    public private(set) var isOverMaxTextViewHeight = false
    
    /// A boolean that when set as `TRUE` will always enable the `InputTextView` to be anchored to the
    /// height of `maxTextViewHeight`
    /// The default value is `FALSE`
    public private(set) var shouldForceTextViewMaxHeight = false
    
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
    
    private var textViewLayoutSet: NSLayoutConstraintSet?
    private var textViewHeightAnchor: NSLayoutConstraint?
    private var sendButtonLayoutSet: NSLayoutConstraintSet?
    private var contentViewLayoutSet: NSLayoutConstraintSet?
    private var windowAnchor: NSLayoutConstraint?

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

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        setupConstraints(to: window)
    }
    
    // MARK: - Setup
    
    /// Sets up the default properties
    open func setup() {

        backgroundColor = .white
        autoresizingMask = [.flexibleHeight]
        setupSubviews()
        setupConstraints()
        setupObservers()
        setupGestureRecognizers()
    }
    
    /// Adds the required notification observers
    private func setupObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputBarAccessoryView.orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputBarAccessoryView.inputTextViewDidChange),
                                               name: UITextView.textDidChangeNotification, object: inputTextView)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputBarAccessoryView.inputTextViewDidBeginEditing),
                                               name: UITextView.textDidBeginEditingNotification, object: inputTextView)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputBarAccessoryView.inputTextViewDidEndEditing),
                                               name: UITextView.textDidEndEditingNotification, object: inputTextView)
    }
    
    /// Adds a UISwipeGestureRecognizer for each direction to the InputTextView
    private func setupGestureRecognizers() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.left, .right]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self,
                                                   action: #selector(InputBarAccessoryView.didSwipeTextView(_:)))
            gesture.direction = direction
            inputTextView.addGestureRecognizer(gesture)
        }
    }
    
    /// Adds all of the subviews
    private func setupSubviews() {
        
        addSubview(contentView)
        contentView.addSubview(inputTextView)
        contentView.addSubview(sendButton)
    }
    
    /// Sets up the initial constraints of each subview
    private func setupConstraints() {
        
        // The constraints within the InputBarAccessoryView
        translatesAutoresizingMaskIntoConstraints = false

        contentViewLayoutSet = NSLayoutConstraintSet(
            top:    contentView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
            bottom: contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.bottom),
            left:   contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: padding.left + frameInsets.left),
            right:  contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: -(padding.right + frameInsets.right))
        )
        
        if #available(iOS 11.0, *) {
            // Switch to safeAreaLayoutGuide
            contentViewLayoutSet?.bottom = contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding.bottom)
            contentViewLayoutSet?.left = contentView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: padding.left + frameInsets.left)
            contentViewLayoutSet?.right = contentView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -(padding.right + frameInsets.right))
        }
        
        // Constraints Within the contentView
        textViewLayoutSet = NSLayoutConstraintSet(
            top:    inputTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: textViewPadding.top),
            bottom: inputTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -textViewPadding.bottom),
            left:   inputTextView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: textViewPadding.left),
            right:  inputTextView.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -textViewPadding.right)
        )
        maxTextViewHeight = calculateMaxTextViewHeight()
        textViewHeightAnchor = inputTextView.heightAnchor.constraint(equalToConstant: maxTextViewHeight)

        sendButtonLayoutSet = NSLayoutConstraintSet(
            top:    sendButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            bottom: sendButton.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 0),
            right:  sendButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0)
        )
    }
    
    /// Respect window safeAreaInsets
    /// Adds a constraint to anchor the bottomAnchor of the contentView to the window's safeAreaLayoutGuide.bottomAnchor
    ///
    /// - Parameter window: The window to anchor to
    private func setupConstraints(to window: UIWindow?) {
        if #available(iOS 11.0, *) {
            if let window = window {
                guard window.safeAreaInsets.bottom > 0 else { return }
                windowAnchor?.isActive = false
                windowAnchor = contentView.bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: window.safeAreaLayoutGuide.bottomAnchor, multiplier: 1)
                windowAnchor?.constant = -padding.bottom
                windowAnchor?.priority = UILayoutPriority(rawValue: 750)
                windowAnchor?.isActive = true
            }
        }
    }
    
    // MARK: - Constraint Layout Updates

    private func updateFrameInsets() {
        updatePadding()
    }
    
    /// Updates the constraint constants that correspond to the padding UIEdgeInsets
    private func updatePadding() {
        contentViewLayoutSet?.top?.constant = padding.top
        contentViewLayoutSet?.left?.constant = padding.left + frameInsets.left
        contentViewLayoutSet?.right?.constant = -(padding.right + frameInsets.right)
        contentViewLayoutSet?.bottom?.constant = -padding.bottom
        windowAnchor?.constant = -padding.bottom
    }
    
    /// Updates the constraint constants that correspond to the textViewPadding UIEdgeInsets
    private func updateTextViewPadding() {
        textViewLayoutSet?.top?.constant = textViewPadding.top
        textViewLayoutSet?.left?.constant = textViewPadding.left
        textViewLayoutSet?.right?.constant = -textViewPadding.right
        textViewLayoutSet?.bottom?.constant = -textViewPadding.bottom
    }

    /// Invalidates the view’s intrinsic content size
    open override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        cachedIntrinsicContentSize = calculateIntrinsicContentSize()
        if previousIntrinsicContentSize != cachedIntrinsicContentSize {
            delegate?.inputBar(self, didChangeIntrinsicContentTo: cachedIntrinsicContentSize)
            previousIntrinsicContentSize = cachedIntrinsicContentSize
        }
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
                textViewHeightAnchor?.isActive = false || shouldForceTextViewMaxHeight
                inputTextView.isScrollEnabled = false
                isOverMaxTextViewHeight = false
                inputTextView.invalidateIntrinsicContentSize()
            }
        }
        
        // Calculate the required height
        let totalPadding = padding.top + padding.bottom + textViewPadding.top + textViewPadding.bottom
        let requiredHeight = inputTextViewHeight + totalPadding
        return CGSize(width: UIView.noIntrinsicMetric, height: requiredHeight)
    }

    open override func layoutIfNeeded() {
        super.layoutIfNeeded()
        inputTextView.layoutIfNeeded()
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard frameInsets.left != 0 || frameInsets.right != 0 else {
            return super.point(inside: point, with: event)
        }
        // Allow touches to pass through base view
        return subviews.contains {
            !$0.isHidden && $0.point(inside: convert(point, to: $0), with: event)
        }
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
        contentViewLayoutSet?.activate()
        textViewLayoutSet?.activate()
        sendButtonLayoutSet?.activate()
    }
    
    /// Deactivates the NSLayoutConstraintSet's
    private func deactivateConstraints() {
         contentViewLayoutSet?.deactivate()
        textViewLayoutSet?.deactivate()
        sendButtonLayoutSet?.deactivate()
    }

    /// Sets the `shouldForceTextViewMaxHeight` property
    ///
    /// - Parameters:
    ///   - newValue: New boolean value
    ///   - animated: If the layout should be animated
    open func setShouldForceMaxTextViewHeight(to newValue: Bool, animated: Bool) {
        performLayout(animated) {
            self.shouldForceTextViewMaxHeight = newValue
            self.textViewHeightAnchor?.isActive = newValue
            guard self.superview?.superview != nil else { return }
            self.superview?.superview?.layoutIfNeeded()
        }
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
            sendButton.isEnabled = !trimmedText.isEmpty
        }
        
        // Capture change before iterating over the InputItem's
        let shouldInvalidateIntrinsicContentSize = requiredInputTextViewHeight != inputTextView.bounds.height
        
        delegate?.inputBar(self, textViewTextDidChangeTo: trimmedText)
        
        if shouldInvalidateIntrinsicContentSize {
            // Prevent un-needed content size invalidation
            invalidateIntrinsicContentSize()
        }
    }
    
    /// Calls each items `keyboardEditingBeginsAction` method
    @objc
    open func inputTextViewDidBeginEditing() {
    }
    
    /// Calls each items `keyboardEditingEndsAction` method
    @objc
    open func inputTextViewDidEndEditing() {
    }
        
    // MARK: - User Actions
    
    /// Calls each items `keyboardSwipeGestureAction` method
    /// Calls the delegates `didSwipeTextViewWith` method
    @objc
    open func didSwipeTextView(_ gesture: UISwipeGestureRecognizer) {
        delegate?.inputBar(self, didSwipeTextViewWith: gesture)
    }
    
    /// Calls the delegates `didPressSendButtonWith` method
    /// Assumes that the InputTextView's text has been set to empty and calls `inputTextViewDidChange()`
    /// Invalidates each of the InputPlugins
    open func didSelectSendButton() {
        delegate?.inputBar(self, didPressSendButtonWith: inputTextView.text)
    }
}
