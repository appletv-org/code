//
//  PlayerViewDelegate.swift
//  tvorg
//
//  Created by Alexandr Kolganov on 09.04.17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation.AVPlayer

public typealias PVStatus = AVPlayerStatus
public typealias PVItemStatus = AVPlayerItemStatus

public enum PlayerStatus {
    case    idle,
            loading,
            playing,
            stopped
}

public protocol PlayerProtocol {
    var url: URL? { get set }
    func play();
    func pause();
    func reset();
    func stop();
}

/*
public extension PlayerProtocol {
    func play()  { fatalError(#function + "Must be overridden") }
    func pause() { fatalError(#function + "Must be overridden") }
    func reset() { fatalError(#function + "Must be overridden") }
    func stop()  { fatalError(#function + "Must be overridden") }
}
 */

public class PlayerView : UIView, PlayerProtocol {
    
    public var url: URL?
    public var isMute = false
    public var name = ""
    public var fillMode : PlayerViewFillMode! = .resize
    weak var delegate:PlayerViewDelegate?
    
    public func play()  { fatalError(#function + "Must be overridden") }
    public func pause() { fatalError(#function + "Must be overridden") }
    public func reset() { fatalError(#function + "Must be overridden") }
    public func stop()  { fatalError(#function + "Must be overridden") }
    
}



public protocol PlayerViewDelegate: class {
    func changeStatus(player: PlayerView, status:PlayerStatus, error: Error?)
    //func playerVideo(player: PlayerView, statusItemPlayer: PVItemStatus, error: Error?)
}

public extension PlayerViewDelegate {
    func playerVideo(player: PlayerProtocol, statusItemPlayer: PVItemStatus, error: Error?) {
    }
}

public enum PlayerViewFillMode {
    case resizeAspect
    case resizeAspectFill
    case resize
    
    init?(videoGravity: String){
        switch videoGravity {
        case AVLayerVideoGravityResizeAspect:
            self = .resizeAspect
        case AVLayerVideoGravityResizeAspectFill:
            self = .resizeAspectFill
        case AVLayerVideoGravityResize:
            self = .resize
        default:
            return nil
        }
    }
    
    var AVLayerVideoGravity:String {
        get {
            switch self {
            case .resizeAspect:
                return AVLayerVideoGravityResizeAspect
            case .resizeAspectFill:
                return AVLayerVideoGravityResizeAspectFill
            case .resize:
                return AVLayerVideoGravityResize
            }
        }
    }
}
