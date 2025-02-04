//
//  String+Extensions.swift
//  DesignSystem
//
//  Created by MaxBook on 2/4/25.
//

import UIKit

extension String {
    func loadAsyncImage(_ completion: @escaping @Sendable (UIImage?) -> Void) {
        guard let url = URL(string: self) else {
            print("잘못된 URL 형식: \(self)")
            completion(nil)
            
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                print("이미지 가져오기 실패: \(error)")
                completion(nil)
                return
            }

            guard let data, let image = UIImage(data: data) else {
                print("이미지 데이터가 올바르지 않음")
                completion(nil)
                
                return
            }

            completion(image)
        }.resume()
    }
}
