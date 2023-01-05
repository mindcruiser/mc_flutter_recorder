//
//  MCUtils.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation

class MCUtils {
    
    static func createWaveHeader(sampleRate: Int32, channels: Int16, bitRate: Int16, dataLength: Int32) -> Data {
         let chunkSize:Int32 = 36 + dataLength
         let subChunkSize:Int32 = 16
         let format:Int16 = 1
         let byteRate:Int32 = sampleRate * Int32(channels * bitRate / 8)
         let blockAlign: Int16 = channels * bitRate / 8

         let header = NSMutableData()

         header.append([UInt8]("RIFF".utf8), length: 4)
         header.append(intToByteArray(chunkSize), length: 4)

         //WAVE
         header.append([UInt8]("WAVE".utf8), length: 4)

         //FMT
         header.append([UInt8]("fmt ".utf8), length: 4)

         header.append(intToByteArray(subChunkSize), length: 4)
         header.append(shortToByteArray(format), length: 2)
         header.append(shortToByteArray(channels), length: 2)
         header.append(intToByteArray(sampleRate), length: 4)
         header.append(intToByteArray(byteRate), length: 4)
         header.append(shortToByteArray(blockAlign), length: 2)
         header.append(shortToByteArray(bitRate), length: 2)

         header.append([UInt8]("data".utf8), length: 4)
         header.append(intToByteArray(dataLength), length: 4)

        return Data.init(bytes: header.bytes, count: header.length)
    }
    
    static func intToByteArray(_ i: Int32) -> [UInt8] {
        return [
            //little endian
            UInt8(truncatingIfNeeded: (i      ) & 0xff),
            UInt8(truncatingIfNeeded: (i >>  8) & 0xff),
            UInt8(truncatingIfNeeded: (i >> 16) & 0xff),
            UInt8(truncatingIfNeeded: (i >> 24) & 0xff)
        ]
    }
    
    static func shortToByteArray(_ i: Int16) -> [UInt8] {
        return [
            //little endian
            UInt8(truncatingIfNeeded: (i      ) & 0xff),
            UInt8(truncatingIfNeeded: (i >>  8) & 0xff)
        ]
    }
}
