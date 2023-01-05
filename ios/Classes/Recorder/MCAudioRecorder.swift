//
//  MCAudioRecorder.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation
import AVFoundation

class MCAudioRecorder: MCRecorder {
    
    private var _recorder: AVAudioRecorder?
    
    convenience init(config: MCRecorderConfig) {
        self.init()
        self.config = config
    }
    
    private func prepare() -> Bool {
        guard let config = self.config,
              setSession() else {
                  return false
              }

        if (_recorder != nil) {
            return true
        }

        let fileURL = URL.init(fileURLWithPath: config.filePath)
        let settings: [String: Any] = [AVFormatIDKey: Int(kAudioFormatLinearPCM),
                                 AVEncoderBitRateKey: Int(config.pcmBitRate.rawValue),
                                     AVSampleRateKey: Float(config.sampleRate),
                               AVNumberOfChannelsKey: Int(config.channel.rawValue),
                            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue]
        print("audio recorder settings \(settings)")
        do {
            _recorder = try AVAudioRecorder.init(url: fileURL, settings: settings)
        } catch {
            print("audio recorder init error \(error)")
            return false;
        }
        _recorder?.delegate = self
        _recorder?.prepareToRecord()
        _recorder?.isMeteringEnabled = true
        self.duration = 0
        return true
    }
    
    private func setSession() -> Bool {
        let session = AVAudioSession.sharedInstance()
        var options: AVAudioSession.CategoryOptions = [.allowBluetooth]
        do {
            if #available(iOS 10.0, *) {
                options.insert(.allowAirPlay)
                options.insert(.allowBluetoothA2DP)
                try session.setCategory(.playAndRecord, mode: .default, options: options)
            } else {
                try session.setCategory(.playAndRecord, options: options)
            }
            try session.setActive(true)
        } catch {
            print("audio session init error \(error)")
            return false;
        }
        return true
    }
    
    override func start() -> Bool {
        guard let config = self.config else {
            return false
        }
        if (prepare()) {
            let success = _recorder?.record() ?? false
            if (success) {
                fireTimer(interval: config.period)
                let _ = super.start()
            }
            return success
        }
        return false;
    }
    
    override func pause() -> Bool {
        _recorder?.pause()
        pauseTimer()
        return super.pause()
    }
    
    override func resume() -> Bool {
        return start()
    }
    
    override func stop() -> Bool {
        _recorder?.stop()
        return super.stop()
    }
    
    override func progressUpdated() {
        guard let _ = self.config,
            let recorder = _recorder else {
            return
        }
        recorder.updateMeters()
        let db = min(pow(10.0, recorder.averagePower(forChannel: 0) / 20.0) * 160.0, 160.0)
        delegate?.recorderInfoChanged(duration, Double(db))
        super.progressUpdated()
    }
}

extension MCAudioRecorder : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        invalidateTimer()
        delegate?.recorderDidFinish(successfully: flag)
        _recorder = nil
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        invalidateTimer()
        recorder.stop()
        delegate?.recorderEncodeError(error: error)
        _recorder = nil
    }
}
