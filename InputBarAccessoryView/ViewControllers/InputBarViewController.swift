//
//  InputBarViewController.swift
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
//  Created by Nathan Tannar on 9/13/18.
//

import UIKit

/// An simple `UIViewController` subclass that is ready to work
/// with an `inputAccessoryView`
open class InputBarViewController: UIViewController {

    /// A powerful InputAccessoryView ideal for messaging applications
    let inputBar = InputBarAccessoryView()

    open override var inputAccessoryView: UIView? {
        return inputBar
    }

    open override var canBecomeFirstResponder: Bool {
        return true
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        inputBar.textView.resignFirstResponder()
        return super.resignFirstResponder()
    }
}

