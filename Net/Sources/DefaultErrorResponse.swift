//
//  DefaultErrorResponse.swift
//  Net
//
//  Created by Arthur Myronenko on 5/7/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

struct DefaultErrorResponse: Decodable {
  internal let error: String
  internal let errorDescription: String
}
