//
//  DataExt.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation

extension Data {
    func getInt16Volume() -> Double {
        var pcmAll: Int = 0
        let int16Array = self.withUnsafeBytes { Array($0.bindMemory(to: Int16.self)) }
        for value in int16Array {
            pcmAll += Int(value) * Int(value)
        }
        let mean: Double = Double(pcmAll) / Double(int16Array.count)
        let volume: Double = 10 * log10(mean)
        return volume
    }
}
