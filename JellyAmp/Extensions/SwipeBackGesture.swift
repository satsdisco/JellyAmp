//
//  SwipeBackGesture.swift
//  JellyAmp
//
//  Re-enables iOS interactive pop (swipe-back) gesture when
//  .navigationBarBackButtonHidden(true) is used with a custom back button.
//

import SwiftUI
import UIKit

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
