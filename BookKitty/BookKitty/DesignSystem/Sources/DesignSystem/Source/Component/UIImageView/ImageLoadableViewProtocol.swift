//
//  ImageLoadableViewProtocol.swift
//  DesignSystem
//
//  Created by MaxBook on 2/4/25.
//

@MainActor
public protocol ImageLoadableView: AnyObject {
    var onImageLoaded: (() -> Void)? { get set }
}
