//
//  MCRecorderException.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation

enum MCRecorderException: String {
    case noPermission
    case interrupted
    case encodeError
    case illegalArgument
    case noSpace
    case durationExceeded
    case unknown
}
