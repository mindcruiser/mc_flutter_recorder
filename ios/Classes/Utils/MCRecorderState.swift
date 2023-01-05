//
//  MCRecorderState.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation

enum MCRecorderState: String {
    case notInitialized
    case initialized
    case recording
    case pausing
    case stopped
    case finalized
}
