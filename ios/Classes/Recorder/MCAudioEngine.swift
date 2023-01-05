//
//  MCAudioEngine.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation
import AVFAudio

class MCAudioEngine: MCRecorder {
    
    private let bus: AVAudioNodeBus = 0
    
    private var _engine: AVAudioEngine?
    
    private var _dataLength: Int = 0
    
    private var _fileHandle: FileHandle?
    
    private var _dbData: Data?
    // 标记位，用来计算实时 db
    private var _prePosition: Int = 0
    private var _dateCumul: Double = 0
    private var _previousTS: Double = 0

    convenience init(config: MCRecorderConfig) {
        self.init()
        self.config = config
    }
    
    private func prepare() -> Bool {
        guard let config = self.config else {
            return false
        }
        
        if (_engine != nil) {
            return true
        }
        
        let isSuccess = setupSession(config: config)
        if (isSuccess == false) {
            return false
        }
        
        let created = createFileHandle(config: config)
        if (created == false) {
            return false
        }
        
        let engine = AVAudioEngine.init()
        let format = engine.inputNode.outputFormat(forBus: bus)
        let sampleRate = format.settings[AVSampleRateKey] as? Double ?? config.sampleRate
        let bufferSize = Double(config.period) / 1000.0 * sampleRate
        print("bufferSize: \(bufferSize)")
        
        var settings = format.settings
        settings[AVSampleRateKey] = config.sampleRate
        settings[AVLinearPCMBitDepthKey] = config.pcmBitRate.rawValue
        settings[AVNumberOfChannelsKey] = config.channel.rawValue
        settings[AVLinearPCMIsFloatKey] = false
        let newFormat = AVAudioFormat.init(settings: settings) ?? format
        let converter = AVAudioConverter.init(from: format, to: newFormat)
        updateFileHeader()
        engine.inputNode.installTap(onBus: bus, bufferSize: AVAudioFrameCount(bufferSize), format: format) {[weak self] pcmBuffer, timer in
            let convertedBuffer = AVAudioPCMBuffer.init(pcmFormat: newFormat, frameCapacity: pcmBuffer.frameCapacity)
            let inputBlock : AVAudioConverterInputBlock = { (inNumPackets, outStatus) -> AVAudioBuffer? in
                outStatus.pointee = AVAudioConverterInputStatus.haveData;
                return pcmBuffer;
            }
            var error: NSError? = nil
            guard let result = converter?.convert(to: convertedBuffer!, error: &error, withInputFrom: inputBlock) else {
                return
            }
            if (result == .haveData) {
                guard let data = convertedBuffer?.toData() else {
                    return
                }
                self?.saveAudio(data: data, config: config)
                self?._prePosition = 0
                self?._dbData = data
            }
        }
        engine.prepare()
        _engine = engine
        _dataLength = 0
        _dbData = nil
        _prePosition = 0
        _dateCumul = 0
        _previousTS = 0
        self.duration = 0
        return true
    }
    
    private func saveAudio(data: Data?, config: MCRecorderConfig) {
        guard let mData = data else {
            return
        }
        _fileHandle?.write(mData)
        _dataLength += mData.count
        updateFileHeader()
    }
    
    private func updateFileHeader() {
        guard let config = self.config else {
            return
        }
        let wavHeader = MCUtils.createWaveHeader(sampleRate: Int32(config.sampleRate), channels: Int16(config.channel.rawValue), bitRate: Int16(config.pcmBitRate.rawValue), dataLength: Int32(_dataLength))
        _fileHandle?.seek(toFileOffset: 0)
        _fileHandle?.write(wavHeader)
        _fileHandle?.seekToEndOfFile()
    }
    
    private func createFileHandle(config: MCRecorderConfig) -> Bool {
        if (config.filePath.isEmpty) {
            return false
        }
        do {
            if (FileManager.default.fileExists(atPath: config.filePath)) {
                try FileManager.default.removeItem(atPath: config.filePath)
            }
            let created = FileManager.default.createFile(atPath: config.filePath, contents: nil, attributes: nil)
            if (created) {
                try _fileHandle = FileHandle.init(forWritingTo: URL.init(fileURLWithPath: config.filePath))
            } else {
                return false
            }
        } catch {
            print("engine prepare handle create error, \(error)")
            return false
        }
        return true
    }
    
    private func setupSession(config: MCRecorderConfig) -> Bool {
        let audiosession = AVAudioSession.sharedInstance()
        var options: AVAudioSession.CategoryOptions = [.allowBluetooth]
        do{
            try audiosession.setPreferredSampleRate(config.sampleRate)
            try audiosession.setPreferredIOBufferDuration(Double(config.period) / 1000.0);
            if #available(iOS 10.0, *) {
                options.insert(.allowAirPlay)
                options.insert(.allowBluetoothA2DP)
                try audiosession.setCategory(.playAndRecord, mode: .default, options: options)
            } else {
                try audiosession.setCategory(.playAndRecord, options: options)
                try audiosession.setMode(.default)
            }
            try audiosession.setActive(true)
        } catch {
            print("engine prepare session set error, \(error)")
            return false
        }
        return true
    }
    
    override func start() -> Bool {
        guard let config = self.config else {
            return false
        }
        if (prepare()) {
            do {
                try _engine?.start()
            } catch {
                return false
            }
            fireTimer(interval: config.period)
            _previousTS = CACurrentMediaTime()
            return true
        }
        return false
    }
    
    override func pause() -> Bool {
        _engine?.pause()
        pauseTimer()
        _dateCumul = CACurrentMediaTime() - _previousTS
        _previousTS = 0
        return true
    }
    
    override func resume() -> Bool{
        
        guard let config = self.config,
              setupSession(config: config) else {
                  return false
              }
        do {
            try _engine?.start()
        } catch {
            return false
        }
        fireTimer(interval: config.period)
        _previousTS = CACurrentMediaTime()
        return true
    }
    
    override func stop() -> Bool {
        _engine?.inputNode.removeTap(onBus: bus)
        _engine?.stop()
        _engine = nil
        _dbData = nil
        _dataLength = 0
        _prePosition = 0
        _previousTS = 0
        _dateCumul = 0
        self.duration = 0
        
        if #available(iOS 13.0, *) {
            do {
                defer {
                    _fileHandle = nil
                }
                try _fileHandle?.close()
            } catch {
                return false
            }
        } else {
            _fileHandle?.closeFile()
            _fileHandle = nil
        }
        invalidateTimer()
        finishHandle()
        return true
    }
    
    override func progressUpdated() {
        print("dbData \(_dbData?.count ?? 0)")
        guard let config = self.config,
              let dbData = _dbData else {
                  return
              }
        let start = _prePosition
        let dataLength = dbData.count
        print("start \(start), dbDataLength \(dataLength)")
        if (start >= dataLength) {
            return
        }
        var end = Int(Double(start) + config.oneSecondLength() * (Double(config.period) / 1000))
        if (dataLength <= end) {
            end = dataLength
        }
        _prePosition = end
        let data = dbData.subdata(in: start..<Int(end))
        let db = data.getInt16Volume()
        
        var duration = _dateCumul;
        if (_previousTS != 0) {
            duration += CACurrentMediaTime() - _previousTS;
        }
        
        delegate?.recorderInfoChanged(TimeInterval(duration), db)
        
        self.duration = duration
        super.progressUpdated()
    }
    
    private func finishHandle() {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
            self?.delegate?.recorderDidFinish(successfully: true)
        }
    }
}
