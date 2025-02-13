//
//  AlertPresentableError.swift
//  BookKitty
//
//  Created by 권승용 on 2/13/25.
//

import Foundation

protocol AlertPresentableError: Error {
    var title: String { get }
    var body: String { get }
    var buttonTitle: String { get }
}
