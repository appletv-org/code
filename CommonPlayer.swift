//
//  CommonPlayer.swift
//  tvorg
//
//  Created by Alexandr Kolganov on 08/11/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

class CommonPlayer: UIView, PlayerViewDelegate {
    
    var playerView: PlayerView?
    weak var delegate: PlayerViewDelegate?
    var name: String = ""
    
    func play(url: URL) {
        
        if(playerView != nil) {
            playerView!.reset()
        }
        
        if(!OtherSettings.preferVLC && url.pathExtension == "m3u8" && (url.scheme == "http" || url.scheme == "https")) {
            if(playerView == nil || playerView as? VlcPlayerView != nil) {
                self.setPlayer(ApplePlayerView())
            }
        }
        else {
            if(playerView == nil || playerView as? ApplePlayerView != nil) {
                self.setPlayer(VlcPlayerView())
            }
        }
        
        self.playerView!.name = self.name
        self.playerView!.url = url
        self.playerView!.play()
        //self.playerView!.isMute = true
    }
    
    func setPlayer(_ playerView: PlayerView) {
        /*
         if(self.playerView != nil) {
         self.playerView!.removeFromSuperview()
         }
         */
        self.addSubview(playerView)
        playerView.frame = CGRect(origin: CGPoint.zero, size: self.frame.size)
        self.playerView = playerView
        self.playerView?.delegate = self
    }
    
    func setup() {
        self.backgroundColor = UIColor.black
        self.playerView?.fillMode = .resize
    }
    
    func changeStatus(player: PlayerView, status: PlayerStatus, error: Error?) {
        self.delegate?.changeStatus(player: player, status: status, error: error)
    }
}
