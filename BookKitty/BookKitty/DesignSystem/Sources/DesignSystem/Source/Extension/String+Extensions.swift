//
//  String+Extensions.swift
//  DesignSystem
//
//  Created by MaxBook on 2/4/25.
//

import UIKit

extension String {
    public func loadAsyncImage(_ completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: self) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                print("이미지 가져오기 실패: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            guard let data, let image = UIImage(data: data) else {
                print("이미지 데이터가 올바르지 않음")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
