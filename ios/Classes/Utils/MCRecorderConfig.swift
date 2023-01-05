//
//  MCRecorderConfig.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation

struct MCRecorderConfig {
    var filePath: String
    var sampleRate: Double
    var pcmBitRate: PCMBitRate
    var channel: RecorderChannel
    // ms
    var period: Int = 100
    var maxDuration: TimeInterval?
    var freeDisk: Int
    var interruptedBehavior: InterruptedBehavior
    
    func oneSecondLength() -> Double {
        return sampleRate * Double(pcmBitRate.rawValue * channel.rawValue / 8)
    }
}

enum PCMBitRate: Int {
    case PCM8Bit = 8
    case PCM16Bit = 16
    
    static func fromString(rate: String) -> PCMBitRate {
        switch rate {
        case "pcm8Bit":
            return .PCM8Bit
        case "pcm16Bit":
            return .PCM16Bit
        default:
            return .PCM16Bit
        }
    }
}

enum RecorderChannel: Int {
    case Mono = 1
    case Stereo
    
    static func fromString(channel: String) -> RecorderChannel {
        switch channel {
        case "Mono":
            return .Mono
        case "Stereo":
            return .Stereo
        default:
            return .Mono
        }
    }
}

enum InterruptedBehavior: String {
    case Pause
    case Stop
    
    static func fromString(behavior: String) -> InterruptedBehavior {
        switch behavior {
        case "pause":
            return .Pause
        case "stop":
            return .Stop
        default:
            return .Pause
        }
    }
}
