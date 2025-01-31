//
//  MyLibraryViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift

/// 내 서재 화면을 위한 ViewModel
/// 사용자의 책 목록을 관리하고 표시하는 책임을 가짐
final class MyLibraryViewModel: ViewModelType {
    // MARK: Lifecycle

    init(bookRepository: BookRepository) {
        self.bookRepository = bookRepository
    }

    // MARK: Internal

    /// ViewModel이 처리할 수 있는 입력 이벤트들을 정의
    struct Input {
        /// viewDidLoad 시 발생하는 이벤트
        let viewDidLoad: Observable<Void>
        /// 책 항목이 탭되었을 때 발생하는 이벤트
        /// BookDetail 이동과 동시에 Book 전달
        let bookTapped: Observable<Book>
        /// 스크롤이 끝에 닿았을 때 발생하는 이벤트
        let reachedScrollEnd: Observable<Void>
    }

    /// ViewModel이 View에게 전달할 출력 데이터들을 정의
    struct Output {
        /// 화면에 표시될 책 목록
        let bookList: Driver<[Book]>
    }

    let disposeBag = DisposeBag()

    /// 책 상세 화면으로 이동할 때 사용되는 이벤트 스트림
    var navigateToBookDetail = PublishRelay<Book>()

    /// Input을 Output으로 변환하는 메서드
    /// - Parameter input: 사용자 및 시스템 이벤트
    /// - Returns: 화면에 표시될 데이터 스트림
    func transform(_ input: Input) -> Output {
        // 책이 탭되었을 때 상세 화면 이동 이벤트 발생
        input.bookTapped
            .bind(to: navigateToBookDetail)
            .disposed(by: disposeBag)

        // 화면 로드 시 책 목록 가져오기
        input.viewDidLoad
            .withUnretained(self)
            .map { _ in
                self.bookRepository.fetchBookList(
                    offset: self.offset,
                    limit: self.limit
                )
            }
            .bind(to: bookList)
            .disposed(by: disposeBag)

        // 스크롤이 끝에 닿았을 때 책 목록 추가 (무한 스크롤 기능)
        input.reachedScrollEnd
            .withUnretained(self)
            .map { _ in
                guard !self.isLoading else {
                    return self.books
                }
                self.isLoading = true
                self.offset += self.limit
                let fetchedBooks = self.bookRepository.fetchBookList(
                    offset: self.offset,
                    limit: self.limit
                )
                self.isLoading = false
                return fetchedBooks
            }
            .bind(to: bookList)
            .disposed(by: disposeBag)

        return Output(
            bookList: bookList.asDriver()
        )
    }

    // MARK: Private

    private let bookList = BehaviorRelay<[Book]>(value: [])

    private var offset = 0
    private let limit = 15
    private var books: [Book] = []
    private var isLoading = false

    /// 책 데이터 관리를 위한 Repository
    private let bookRepository: BookRepository
}
