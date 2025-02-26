//
//  NeoImageOptions.swift
//  NeoImage
//
//  Created by Neoself on 2/23/25.
//

import UIKit

/// 이미지 다운로드 및 처리에 관한 옵션을 정의하는 구조체
public struct NeoImageOptions: Sendable {
    // MARK: - Properties

    /// 이미지 프로세서
    public let processor: ImageProcessing?

    /// 이미지 전환 효과
    public let transition: ImageTransition

    /// 다시 시도 전략
    public let retryStrategy: RetryStrategy

    /// 캐시 만료 정책
    public let cacheExpiration: StorageExpiration

    // MARK: - Lifecycle

    public init(
        processor: ImageProcessing? = nil,
        transition: ImageTransition = .none,
        retryStrategy: RetryStrategy = .none,
        cacheExpiration: StorageExpiration = .days(7)
    ) {
        self.processor = processor
        self.transition = transition
        self.retryStrategy = retryStrategy
        self.cacheExpiration = cacheExpiration
    }
}

/// 이미지 전환 효과 열거형
public enum ImageTransition: Sendable {
    /// 전환 효과 없음
    case none
    /// 페이드 인 효과
    case fade(TimeInterval)
    /// 플립 효과
    case flip(TimeInterval)
}

/// 재시도 전략 열거형
public enum RetryStrategy: Sendable {
    /// 재시도 하지 않음
    case none
    /// 지정된 횟수만큼 재시도
    case times(Int)
    /// 지정된 횟수와 대기 시간으로 재시도
    case timesWithDelay(times: Int, delay: TimeInterval)
}

extension NeoImageOptions {
    /// 기본 옵션 (프로세서 없음, 전환 효과 없음, 재시도 없음, 7일 캐시)
    public static let `default` = NeoImageOptions()

    /// 페이드 인 효과가 있는 옵션
    public static let fade = NeoImageOptions(transition: .fade(0.3))

    /// 재시도가 있는 옵션
    public static let retry = NeoImageOptions(retryStrategy: .times(3))
}
