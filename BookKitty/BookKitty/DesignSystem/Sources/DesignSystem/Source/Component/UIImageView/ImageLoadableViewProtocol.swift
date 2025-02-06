//
//  ImageLoadableViewProtocol.swift
//  DesignSystem
//
//  Created by 임성수 on 2/4/25.
//

@MainActor
public protocol ImageLoadableView: AnyObject {
    var onImageLoaded: (() -> Void)? { get set }
}
