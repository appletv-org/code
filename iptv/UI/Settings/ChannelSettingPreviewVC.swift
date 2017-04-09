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
    
    
    @IBOutlet weak var playerView: VlcPlayerView!
    @IBOutlet weak var videoSizeLabel: UILabel!
    
    
    override func viewDidLoad() {
        playerView.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerView.stopPlayer()
    }
    
    func refresh() {
        videoSizeLabel.text = "undefined"
        if let dirElement = channelSettingVC.dirElement,
            case .channel(let channel) = dirElement
        {
            playerView.resetPlayer()
            playerView.url = URL(string:channel.url)
            playerView.play()
            playerView.isMute = true
            playerView.name = "preview"
        }
        else {
            playerView.resetPlayer()
        }
    }
    
    
    
}

extension ChannelSettingPreviewVC : PlayerViewDelegate {
    
    //playerView Delegate
    func playerVideo(player: VlcPlayerView, statusItemPlayer: PVItemStatus, error: Error?) {
        
        
        if(error != nil) {
            return
        }
        
        if statusItemPlayer == .readyToPlay {
            /*
            if let size = playerView.player?.items()[0].presentationSize {
                videoSizeLabel.text = "\(Int(size.width)) x \(Int(size.height))"
            }
            */
            
        }
        
    }

    
}
