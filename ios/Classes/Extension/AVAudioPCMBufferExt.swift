//
//  AVAudioPCMBufferExt.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import AVFoundation

extension AVAudioPCMBuffer {
    
    func toData() -> Data {
        
        if (self.int16ChannelData == nil) {
            let audioBuffer = self.audioBufferList.pointee.mBuffers
            return Data.init(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
        } else {
            let channelCount = 1  // given PCMBuffer channel count is 1
            let channels = UnsafeBufferPointer(start: self.int16ChannelData, count: channelCount)
            return Data(bytes: channels[0], count:Int(self.frameCapacity * self.format.streamDescription.pointee.mBytesPerFrame))
        }
    }
}
