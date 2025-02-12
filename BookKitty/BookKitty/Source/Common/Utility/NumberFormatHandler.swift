//
//  NumberFormatHandler.swift
//  BookKitty
//
//  Created by 전성규 on 2/12/25.
//

import Foundation

enum NumberFormatHandler {
    // MARK: - Static Properties

    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    // MARK: - Static Functions

    static func formatWithComma(from numberString: String) -> String? {
        guard let number = Double(numberString) else {
            return nil
        }
        return numberFormatter.string(from: NSNumber(value: number))
    }
}
