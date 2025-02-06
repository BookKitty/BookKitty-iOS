//
//  DateFormatHandler.swift
//  BookKitty
//
//  Created by 권승용 on 2/6/25.
//

import Foundation

/// 원하는 DateFormat으로 변경해주는 구조체
struct DateFormatHandler {
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current
        return dateFormatter
    }()

    func dateString(from date: Date) -> String {
        DateFormatHandler.dateFormatter.string(from: date)
    }
}
