//
//  UIView+Extensions.swift
//  DesignSystem
//
//  Created by MaxBook on 2/3/25.
//

import UIKit

extension UIView {
    public func setBasicShadow() {
        layer.shadowColor = Colors.shadow15.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 1
        layer.shadowRadius = 4
        layer.masksToBounds = false
    }

    public func setBiggerShadow() {
        layer.shadowColor = Colors.shadow25.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 1
        layer.shadowRadius = 8
        layer.masksToBounds = false
    }
}
