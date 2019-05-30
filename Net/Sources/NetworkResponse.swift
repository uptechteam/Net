//
//  NetworkResponse.swift
//  Net
//
//  Created by Arthur Myronenko on 5/3/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public struct NetworkResponse: Equatable {
  public let statusCode: Int
  public let data: Data
}
