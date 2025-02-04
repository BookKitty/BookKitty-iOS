//
//  Vars.swift
//  DesignSystem
//
//  Created by MaxBook on 1/29/25.
//

import UIKit

/// 각종 사이즈 상수값 관리
public enum Vars {
    // MARK: - Padding Values

    /// 레이아웃에서 패딩(inset) 영역 지정용 / large / 32
    public static let paddingLarge: CGFloat = 32
    /// 레이아웃에서 패딩(inset) 영역 지정용 / regular / 24
    public static let paddingReg: CGFloat = 24
    /// 레이아웃에서 패딩(inset) 영역 지정용 / small / 16
    public static let paddingSmall: CGFloat = 16

    // MARK: - view Values

    /// 카드뷰 컴포넌트의 높이값  / 320
    public static let viewSize320: CGFloat = 320
    /// 보통 크기의 카드뷰 관련값  / 240
    public static let viewSize240: CGFloat = 240
    /// 텍스트뷰와 같이 큰 컴포넌트의 높이값  / 160
    public static let viewSizeHuge: CGFloat = 160
    /// 텍스트뷰와 같이 큰 컴포넌트의 높이값  / 120
    public static let viewSizeXLarge: CGFloat = 120
    /// 버튼 등의 컴포넌트 사이즈 지정용. 대체로 높이값 / large / 72
    public static let viewSizeLarge: CGFloat = 72
    /// 버튼 등의 컴포넌트 사이즈 지정용. 대체로 높이값 / regular / 48
    public static let viewSizeReg: CGFloat = 48
    /// 버튼 등의 컴포넌트 사이즈 지정용. 대체로 높이값 / small / 40
    public static let viewSizeSmall: CGFloat = 40
    /// 버튼 등의 컴포넌트 사이즈 지정용. 대체로 높이값 / tiny / 24
    public static let viewSizeTiny: CGFloat = 24

    // MARK: - Radius Values

    /// UI 컴포넌트의 모서리 라운딩 사이즈 / large / 36
    public static let radiusLarge: CGFloat = 36
    /// UI 컴포넌트의 모서리 라운딩 사이즈 / regular / 24
    public static let radiusReg: CGFloat = 24
    /// UI 컴포넌트의 모서리 라운딩 사이즈 / small / 20
    public static let radiusSmall: CGFloat = 20
    /// UI 컴포넌트의 모서리 라운딩 사이즈 / tiny / 12
    public static let radiusTiny: CGFloat = 12
    /// UI 컴포넌트의 모서리 라운딩 사이즈 / mini / 8
    public static let radiusMini: CGFloat = 8

    // MARK: - Item Spacing Values

    /// UI 컴포넌트 간의 상하 거리 간격 조정용 사이즈 / 4
    public static let spacing4: CGFloat = 4
    /// UI 컴포넌트 간의 상하 거리 간격 조정용 사이즈 / 8
    public static let spacing8: CGFloat = 8
    /// UI 컴포넌트 간의 상하 거리 간격 조정용 사이즈 / 12
    public static let spacing12: CGFloat = 12
    /// UI 컴포넌트 간의 상하 거리 간격 조정용 사이즈 / 20
    public static let spacing20: CGFloat = 20
    /// UI 컴포넌트 간의 상하 거리 간격 조정용 사이즈 / 24
    public static let spacing24: CGFloat = 24
    /// UI 컴포넌트 간의 상하 거리 간격 조정용 사이즈 / 32
    public static let spacing32: CGFloat = 32
    /// UI 컴포넌트 간의 상하 거리 간격 조정용 사이즈 / 48
    public static let spacing48: CGFloat = 48
    /// UI 컴포넌트 간의 상하 거리 간격 조정용 사이즈 / 72
    public static let spacing72: CGFloat = 72

    // MARK: - Image values

    /// 책 커버 이미지용 사이즈. 가로값 고정용 / 200
    public static let imageFixedHeight: CGFloat = 144
    /// 책 커버 이미지용 사이즈. 매우 작은 이미지 용. 가로값 고정용 / 64
    public static let imageFixedHeightSmall: CGFloat = 64
    /// 책 커버 이미지용 사이즈. 세로값 고정용 / 128
    public static let imageFixedWidth: CGFloat = 116
    /// 책 커버 이미지용 사이즈. 세로값 고정용 / 144
    public static let imageFixedWidthLarge: CGFloat = 144

    // MARK: - etc

    /// 상단 네비게이션바 높이용 사이즈 / 56
    public static let gnbHeight: CGFloat = 56

    public static func setContainerInset(_ inset: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }
}
