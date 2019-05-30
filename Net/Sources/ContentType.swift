//
//  ContentType.swift
//  Net
//
//  Created by Arthur Myronenko on 2/2/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public enum ContentType {
  case json
  case urlEncoded
  case formData(boundary: String)
}

extension ContentType {
  public var header: String {
    switch self {
    case let .formData(boundary):
      return "multipart/form-data; boundary=\(boundary)"
    case .urlEncoded:
      return "application/x-www-form-urlencoded"
    case .json:
      return "application/json; charset=utf-8"
    }
  }
}
