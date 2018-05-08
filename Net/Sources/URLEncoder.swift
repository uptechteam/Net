//
//  URLEncoder.swift
//  Net
//
//  Created by Arthur Myronenko on 5/7/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

open class URLEncoder {

  public init() { }

  open func encode(_ parameters: [String: String]) -> Data? {
    let urlQueryCharacterSet = CharacterSet.urlQueryAllowed
    return parameters
      .compactMap { (key, value) -> String? in
        guard
          let encodedKey = key.addingPercentEncoding(withAllowedCharacters: urlQueryCharacterSet),
          let encodedValue = value.addingPercentEncoding(withAllowedCharacters: urlQueryCharacterSet) else
        { return nil }
        return "\(encodedKey)=\(encodedValue)"
      }
      .joined(separator: "&")
      .data(using: .utf8)
  }
}
