//
//  NumberFormatHandler.swift
//  BookKitty
//
//  Created by 전성규 on 2/12/25.
//

import Foundation

enum NumberFormatHandler {
    static func formatWithComma(from numberString: String) -> String? {
        guard let number = Int(numberString) else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        return formatter.string(from: NSNumber(value: number))
    }
}
