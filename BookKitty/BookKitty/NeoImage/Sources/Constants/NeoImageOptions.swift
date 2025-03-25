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

    public let transition: ImageTransition

    /// 캐시 만료 정책
    public let cacheExpiration: StorageExpiration
    public var cancelOnDisappear = false

    // MARK: - Lifecycle

    public init(
        transition: ImageTransition = .none,
        cacheExpiration: StorageExpiration = .days(7)
    ) {
        NeoLogger.shared.debug("initialized")
        self.transition = transition
        self.cacheExpiration = cacheExpiration
    }
}

/// 이미지 전환 효과 열거형
public enum ImageTransition: Sendable, Equatable {
    /// 전환 효과 없음
    case none
    /// 페이드 인 효과
    case fade(TimeInterval)
    /// 플립 효과
    case flip(TimeInterval)
}

extension NeoImageOptions {
    /// 기본 옵션 (프로세서 없음, 전환 효과 없음, 재시도 없음, 7일 캐시)
    public static let `default` = NeoImageOptions()

    /// 페이드 인 효과가 있는 옵션
    public static let fade = NeoImageOptions(transition: .fade(0.3))
}
