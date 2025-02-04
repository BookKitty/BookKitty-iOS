//
//  Fonts.swift
//  DesignSystem
//
//  Created by MaxBook on 1/29/25.
//

import UIKit

public enum HeadlineSize {
    case headline1
    case headline2
    case headline3
}

public enum Fonts {
    // MARK: - Default Font Styles

    /// 커버나 주요 메시지 용 폰트 / size : 40 / spacing : 52
    public static let displayRegular = UIFont.pretendard(ofSize: 48, weight: .regular)
    public static let displaySemiBold = UIFont.pretendard(ofSize: 48, weight: .semiBold)
    public static let displayExtraBold = UIFont.pretendard(ofSize: 48, weight: .extraBold)

    /// 섹션 제목, 페이지 제목 등에 사용되는 폰트. Headline1 / size : 32 / spacing : 42
    public static let headline1Regular = UIFont.pretendard(ofSize: 32, weight: .regular)
    public static let headline1SemiBold = UIFont.pretendard(ofSize: 32, weight: .semiBold)
    public static let headline1ExtraBold = UIFont.pretendard(ofSize: 32, weight: .extraBold)

    /// 섹션 제목, 페이지 제목 등에 사용되는 폰트. 계층 세분화 시 사용. Headline2 / size : 28 / spacing : 38
    public static let headline2Regular = UIFont.pretendard(ofSize: 28, weight: .regular)
    public static let headline2SemiBold = UIFont.pretendard(ofSize: 28, weight: .semiBold)
    public static let headline2ExtraBold = UIFont.pretendard(ofSize: 28, weight: .extraBold)

    /// 섹션 제목, 페이지 제목 등에 사용되는 폰트. 계층 세분화 시 사용. Headline3 / size : 24 / spacing : 34
    public static let headline3Regular = UIFont.pretendard(ofSize: 24, weight: .regular)
    public static let headline3SemiBold = UIFont.pretendard(ofSize: 24, weight: .semiBold)
    public static let headline3ExtraBold = UIFont.pretendard(ofSize: 24, weight: .extraBold)

    /// 섹션 소제목 혹은 가장 낮은 위계의 타이틀에 사용하는 폰트. / size : 20 / spacing : 28
    public static let titleRegular = UIFont.pretendard(ofSize: 20, weight: .regular)
    public static let titleSemiBold = UIFont.pretendard(ofSize: 20, weight: .semiBold)
    public static let titleExtraBold = UIFont.pretendard(ofSize: 20, weight: .extraBold)

    /// 기본 본문에 사용하는 폰트. / size : 16 / spacing : 24
    public static let bodyRegular = UIFont.pretendard(ofSize: 16, weight: .regular)
    public static let bodySemiBold = UIFont.pretendard(ofSize: 16, weight: .semiBold)
    public static let bodyExtraBold = UIFont.pretendard(ofSize: 16, weight: .extraBold)

    /// 보조용 텍스트, caption에 사용하는 폰트. / size : 13 / spacing : 18
    public static let captionRegular = UIFont.pretendard(ofSize: 13, weight: .regular)
    public static let captionSemiBold = UIFont.pretendard(ofSize: 13, weight: .semiBold)
    public static let captionExtraBold = UIFont.pretendard(ofSize: 13, weight: .extraBold)
}
