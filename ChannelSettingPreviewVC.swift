//
//  ChannelSettingPreviewVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 23.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import AVKit

class ChannelSettingPreviewVC : BottomController {
    
    
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var videoSizeLabel: UILabel!
    
    
    override func viewDidLoad() {
        playerView.delegate = self
    }
    
    func refresh() {
        videoSizeLabel.text = "undefined"
        if let dirElement = channelSettingVC.dirElement,
            case .channel(let channel) = dirElement
        {
            playerView.resetPlayer()
            playerView.url = URL(string:channel.url)
            playerView.play()
        }
        else {
            playerView.resetPlayer()
        }
        
        
    }
    
}

extension ChannelSettingPreviewVC : PlayerViewDelegate {
    
    //playerView Delegate
    func playerVideo(player: PlayerView, statusItemPlayer: PVItemStatus, error: Error?) {
        
        
        if(error != nil) {
            return
        }
        
        if statusItemPlayer == .readyToPlay {
            if let size = playerView.player?.items()[0].presentationSize {
                videoSizeLabel.text = "\(Int(size.width)) x \(Int(size.height))"
                
                /*
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    if let events = player.player?.items()[0].accessLog()?.events {
                        print ("events.count \(events.count)")
                        print ("audiobitrate \(events.last?.averageAudioBitrate)")
                        print ("videobitrate \(events.last?.averageAudioBitrate)")
                    }
                })
                 */

            }
            
        }
        
    }

    
}
