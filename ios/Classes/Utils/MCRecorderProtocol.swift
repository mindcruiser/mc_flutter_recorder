//
//  MCRecorderProtocol.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation


@objc protocol MCRecorderProtocol {
    //    var config: MCRecorderConfig? { get }
    //    var delegate: MCRecorderDelegate? { get set }
    
    //    func prepare() -> Bool
    func start() -> Bool
    func pause() -> Bool
    func resume() -> Bool
    func stop() -> Bool
}

protocol MCRecorderDelegate: AnyObject {
    
    func recorderInfoChanged(_ duration: TimeInterval, _ db: Double)
    
    func recorderDidFinish(successfully flag: Bool)
    
    func recorderEncodeError(error: Error?)
    
    func recorderException(_ exception: MCRecorderException, _ message: String)
}


protocol MCRecorderManagerDelegate: AnyObject {
    
    func updateRecorderInfo(_ duration: TimeInterval, _ db: Double)
    
    func updateRecorderState(_ state: MCRecorderState)
    
    func updateRecorderException(_ exception: MCRecorderException, _ message: String)
}
