//
//  PostJSONTargetType.swift
//  Net
//
//  Created by Arthur Myronenko on 5/3/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public protocol PostJSONTargetType: TargetType {
  associatedtype Parameters: Encodable
  var parameters: Parameters { get }
}

public extension PostJSONTargetType {
  var method: HTTPMethod {
    return .post
  }

  var contentType: ContentType? {
    return .json
  }

  func getBodyData() throws -> Data? {
    let encoder = JSONEncoder()
    return try encoder.encode(parameters)
  }
}
