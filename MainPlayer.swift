//
//  MainPlayer.swift
//  tvorg
//
//  Created by Alexandr Kolganov on 08/11/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

class MainPlayer : CommonPlayer {
    
    override func setup() {
        super.setup()
        
        self.layer.borderWidth = 10
        self.layer.borderColor = UIColor.clear.cgColor
        self.name = "main"
        
    }
    
    override func setPlayer(_ playerView: PlayerView) {
        playerView.name = "main"
        playerView.isMute = false
        super.setPlayer(playerView)
        
    }
    
}
