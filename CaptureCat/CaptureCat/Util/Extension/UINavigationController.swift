//
//  UINavigationController.swift
//  CaptureCat
//
//  Created by minsong kim on 10/23/25.
//

import UIKit

extension UINavigationController: UIKit.UIGestureRecognizerDelegate {
  override open func viewDidLoad() {
    super.viewDidLoad()
    
    interactivePopGestureRecognizer?.delegate = self
  }
  
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return viewControllers.count > 1
  }
}
