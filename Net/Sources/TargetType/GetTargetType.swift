//
//  GetTargetType.swift
//  Net
//
//  Created by Arthur Myronenko on 5/3/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

protocol GetTargetType: TargetType { }

extension GetTargetType {
  var method: HTTPMethod {
    return .get
  }

  var contentType: ContentType? {
    return nil
  }

  func getBodyData() throws -> Data? {
    return nil
  }
}
