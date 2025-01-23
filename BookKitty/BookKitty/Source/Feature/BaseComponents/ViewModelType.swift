//
//  ViewModelType.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import RxSwift

/// MVVM 아키텍처에서 ViewModel의 기본 인터페이스를 정의하는 프로토콜
///
/// 모든 ViewModel은 이 프로토콜을 준수하여 일관된 구조를 유지합니다.
/// - Input: View로부터 받는 사용자 입력 및 이벤트를 정의하는 타입
/// - Output: ViewModel이 View에 전달하는 데이터와 상태를 정의하는 타입
protocol ViewModelType {
    /// View로부터 받는 입력 타입
    associatedtype Input

    /// View로 전달하는 출력 타입
    associatedtype Output

    /// RxSwift의 구독 해제를 관리하는 DisposeBag
    var disposeBag: DisposeBag { get }

    /// Input을 Output으로 변환하는 메서드
    /// - Parameter input: View로부터 받은 입력 데이터
    /// - Returns: 변환된 Output 데이터.
    func transform(_ input: Input) -> Output
}
