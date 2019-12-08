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


public class VlcPlayerView: PlayerView, VLCMediaPlayerDelegate {
    
    var _mediaPlayer: VLCMediaPlayer?
    
    let options: [String] = [
        "--avcodec-fast",
        "--avcodec-hurry-up",
        "--http-reconnect"
    ]
    
    var mediaPlayer: VLCMediaPlayer {
        get {
            if(_mediaPlayer == nil) {
                _mediaPlayer = VLCMediaPlayer(options:options)
            }
            return _mediaPlayer!
        }
    }
    
    override public var isMute : Bool {
        didSet {
            mute()
        }
    }
    
    func mute() {
        /*
        print("prev audio volume: \(mediaPlayer.audio.volume)")
        mediaPlayer.audio.volume = Int32(self.isMute ? 0 : 1.0)
        print("now audio volume: \(mediaPlayer.audio.volume)")
         */
        if(self.isMute) {
            self.mediaPlayer.currentAudioTrackIndex = -1
        }
        else {
            if  let indexes = mediaPlayer.audioTrackIndexes,
                indexes.count > 0
            {
                self.mediaPlayer.currentAudioTrackIndex = indexes.last as! Int32
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
    
    override public var url: URL? {
        didSet {
            /*
            if self.status != .idle ||  self.status != .stopped {
                self.stop()
            }
             */
            if(self.url != nil) {
                //dangerous operation
                print("set media url: \(self.url!.absoluteString)")
                let media = VLCMedia(url: self.url!)
                self.mediaPlayer.media = media
            }
            else {
                self.mediaPlayer.media = nil
            }
        }
    }
    
    
    
    public override func play() {
        
        if self.status != .idle ||  self.status != .stopped {
            self.stop()
        }
        self.mediaPlayer.delegate = self
        self.mediaPlayer.drawable = self
        self.status = .loading
        self.mediaPlayer.play()
    }
    
    public override func pause() {
        self.mediaPlayer.pause()
        self.status = .stopped
    }
    
    public override func reset() {
        self.stop()
    }

    
    public override func stop() {
        if(self.status != .idle) {
            print("start stop")
            self.mediaPlayer.stop()
            self.status = .idle
            print("finish stop")
        }
    }
    
    public func mediaPlayerStateChanged(_ aNotification:Notification) {
        
        let stringState = try VLCMediaPlayerStateToString(self.mediaPlayer.state)
        print("\(name) vlc: state change \(stringState ?? "")")
        
        switch mediaPlayer.state  {
            
        case .error:
            delegate?.changeStatus(player:self, status: .idle, error: Err("error"))
            self.status = .idle
            //delegate?.playerVideo(player:self, statusItemPlayer:AVPlayerItemStatus.failed, error: Err("error"))
//        case .playing:
//            delegate?.changeStatus(player:self, status: .playing, error: nil)
//            // delegate?.playerVideo(player:self, statusItemPlayer:AVPlayerItemStatus.readyToPlay, error: nil)
//            if(self.isMute) {
//                // mediaPlayer.audio.volume = 0
//                mediaPlayer.currentAudioTrackIndex = isMute ? -1 : 0
//            }
        case .stopped:
            delegate?.changeStatus(player:self, status: .stopped, error: nil)
            self.status = .stopped
            //delegate?.playerVideo(player:self, statusItemPlayer:AVPlayerItemStatus.failed, error: Err("stopped"))
        default: break
            //print("default status")
        }
        
    }
    
    
    public func mediaPlayerTimeChanged(_ aNotification:Notification) {
        if(self.status == .loading) {
            self.status = .playing
            delegate?.changeStatus(player:self, status: .playing, error: nil)
            if(self.isMute) {
                self.mediaPlayer.currentAudioTrackIndex = isMute ? -1 : 0
            }
            
        }
        // print("\(name): time change \(Date())")
    }
    /*
    public func mediaPlayerChapterChanged(_ aNotification:Notification) {
        print("\(name): chapter change")
    }
    public func mediaPlayerTitleChanged(_ aNotification:Notification) {
        print("\(name): title change")
    }
     */
    

  }

