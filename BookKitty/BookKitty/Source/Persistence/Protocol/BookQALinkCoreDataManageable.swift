//
//  BookQALinkCoreDataManageable.swift
//  BookKitty
//
//  Created by 임성수 on 2/6/25.
//

/// BookQuestionAnswerLink 엔티티를 관리하는 코어 데이터 매니저 기능을 추상화하는 프로토콜
protocol BookQALinkCoreDataManageable {
    // 내부 요구사항은 추후 변경됩니다
    func create()
    func read()
}
