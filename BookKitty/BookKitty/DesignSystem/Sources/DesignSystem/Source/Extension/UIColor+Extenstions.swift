//
//  UIColor+Extenstions.swift
//  DesignSystem
//
//  Created by MaxBook on 1/31/25.
//

import UIKit

extension UIColor {
    /// `Colors.xcassets` 을 사용하기 위해 가져오기
    public static func designSystemColor(name: String) -> UIColor {
        UIColor(named: name, in: Bundle.module, compatibleWith: nil) ?? UIColor.white
    }
}
