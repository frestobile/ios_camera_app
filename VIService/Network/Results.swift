//
//  Results.swift
//  VIService
//
//  Created by Frestobile on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)
}

