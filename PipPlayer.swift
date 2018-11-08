//
//  PipPlayer.swift
//  tvorg
//
//  Created by Alexandr Kolganov on 08/11/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

class PipPlayer : CommonPlayer {
    
    var path : [String]?
    
    func play(path: [String]?) {
        
        if path != nil,
            let dirElement = ChannelManager.findDirElement(path!),
            case let .channel(channelInfo) = dirElement
        {
            self.path = path
            self.play(url:URL(string:channelInfo.url)!)
        }
        if let playerView = self.playerView {
            playerView.isMute = true
        }
    }
    
    override func setPlayer(_ playerView: PlayerView) {
        playerView.name = "pip"
        playerView.isMute = true
        super.setPlayer(playerView)
        
    }
    
    override func setup() {
        super.setup()
        self.name = "pip"
    }
}
