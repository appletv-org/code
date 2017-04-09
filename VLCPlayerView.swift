//
//  VLCPlayerView.swift
//  tvorg
//
//  Created by Alexandr Kolganov on 26.03.17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation.AVPlayer

public typealias PVStatus = AVPlayerStatus
public typealias PVItemStatus = AVPlayerItemStatus


public protocol PlayerViewDelegate: class {
    func playerVideo(player: VlcPlayerView, statusItemPlayer: PVItemStatus, error: Error?)
}

public extension PlayerViewDelegate {
    func playerVideo(player: VlcPlayerView, statusItemPlayer: PVItemStatus, error: Error?) {
    }
    
}

public enum PlayerViewFillMode {
    case resizeAspect
    case resizeAspectFill
    case resize
}

public class VlcPlayerView: UIView, VLCMediaPlayerDelegate {
    
    var name = ""
    
    var _mediaPlayer : VLCMediaPlayer?
    var mediaPlayer: VLCMediaPlayer {
        get {
            if(_mediaPlayer == nil) {
                _mediaPlayer = VLCMediaPlayer()
            }
            return _mediaPlayer!
        }
    }
    
    weak var delegate:PlayerViewDelegate?
    public var isMute = false {
        didSet {
            if(mediaPlayer.isPlaying) {
                mediaPlayer.audio.volume = 0
                //mediaPlayer.currentAudioTrackIndex = -1
            }
        }
    }
    
/*
    public func finit() {
        mediaPlayer.delegate = self
        mediaPlayer.drawable = self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.finit()
    }
 
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.finit()
    }
*/

    
    public var fillMode: PlayerViewFillMode! = .resize {
        didSet {
        }
    }
    
    public var url: URL? {
        didSet {
            if(self.url != nil) {
                let media = VLCMedia(url: self.url!)
                self.mediaPlayer.media = media
            }
            else {
                self.mediaPlayer.media = nil
            }
        }
    }
    
    
    
    public func play() {
        if( mediaPlayer.isPlaying) {
            mediaPlayer.stop()
        }
        mediaPlayer.delegate = self
        mediaPlayer.drawable = self
        mediaPlayer.play()
    }
    
    public func pause() {
        mediaPlayer.pause()
    }
    
    public func resetPlayer() {
        stopPlayer()
        //_mediaPlayer = nil
    }

    
    public func stopPlayer() {
        if(mediaPlayer.isPlaying) {
            mediaPlayer.stop()
        }
    }
    
    public func mediaPlayerStateChanged(_ aNotification:Notification) {
        
        print("\(name): state change \(VLCMediaPlayerStateToString(mediaPlayer.state) as String)")
        
        switch mediaPlayer.state  {
            
        case .error:
            delegate?.playerVideo(player:self, statusItemPlayer:AVPlayerItemStatus.failed, error: Err("error"))
        case .playing:
            delegate?.playerVideo(player:self, statusItemPlayer:AVPlayerItemStatus.readyToPlay, error: nil)
            if(self.isMute) {
                mediaPlayer.audio.volume = 0
                //mediaPlayer.currentAudioTrackIndex = -1
            }
        case .stopped:
            delegate?.playerVideo(player:self, statusItemPlayer:AVPlayerItemStatus.failed, error: Err("stopped"))
        default: break
            //print("default status")
        }
        
    }
    
    
    public func mediaPlayerTimeChanged(_ aNotification:Notification) {
        print("\(name): time change \(Date())")
    }
    public func mediaPlayerChapterChanged(_ aNotification:Notification) {
        print("\(name): chapter change")
    }
    public func mediaPlayerTitleChanged(_ aNotification:Notification) {
        print("\(name): title change")
    }

  }

