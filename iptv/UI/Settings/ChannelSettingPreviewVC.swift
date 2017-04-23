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
    //@IBOutlet weak var videoSizeLabel: UILabel!
    
    
    override func viewDidLoad() {
        //playerView.delegate = self as! PlayerViewDelegate
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerView.stop()
    }
    
    func refresh() {
        //videoSizeLabel.text = "undefined"
        if let dirElement = channelSettingVC.dirElement,
            case .channel(let channel) = dirElement
        {
            playerView.reset()
            playerView.url = URL(string:channel.url)
            playerView.isMute = true
            playerView.play()
            playerView.name = "preview"
        }
        else {
            playerView.reset()
        }
    }
    
    
    
}

/*
extension ChannelSettingPreviewVC : PlayerViewDelegate {
    
    //playerView Delegate
    func changeStatus(player: PlayerView, status: PlayerStatus, error: Error?) {
        
        if(error != nil) {
            return
        }
        
        if status == .playing {
            let media = self.playerView.mediaPlayer.media
            media?.delegate = self
            
            Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false, block: { (_) in
                let media = self.playerView.mediaPlayer.media
                if media != nil {
                    self.printTrackInfo(media!)
                    print( "\(media!.metaDictionary)")
                    print ( "\(media!.debugDescription)")
                }
            })
            //let res = media?.parse(withOptions: VLCMediaParsingOptions(VLCMediaParseLocal|VLCMediaFetchLocal|VLCMediaParseNetwork|VLCMediaFetchNetwork), timeout:3000)
            
            /*
            if let size = playerView.player?.items()[0].presentationSize {
                videoSizeLabel.text = "\(Int(size.width)) x \(Int(size.height))"
            }
            */
            
        }
        
    }

}

extension ChannelSettingPreviewVC : VLCMediaDelegate {

    func mediaDidFinishParsing(_ media:VLCMedia) {
        //activityIndicator.isHidden = true
        //infoLabel.text = "text"
        printTrackInfo(media)
        
    }
    
    func mediaMetaDataDidChange(_ media:VLCMedia) {
        print( "media.parsedStatus: \(media.parsedStatus)")
    }
    
    func printTrackInfo(_ media:VLCMedia) {
        var text = "" //"url: \(self.currentChannel!.url) \n"
        for track in media.tracksInformation {
            if  let trackInfo = track as? Dictionary<String, Any>,
                let type = trackInfo[VLCMediaTracksInformationType] as? String
            {
                switch(type) {
                case VLCMediaTracksInformationTypeVideo:
                    text += "Video dimensions:" +
                        "\(String(describing: trackInfo[VLCMediaTracksInformationVideoWidth]))x" +
                    "\(String(describing: trackInfo[VLCMediaTracksInformationVideoHeight]))"
                case VLCMediaTracksInformationTypeAudio:
                    text += "Audio sample rate:\(String(describing: trackInfo[VLCMediaTracksInformationAudioRate]))"
                case VLCMediaTracksInformationTypeText:
                    text += "Subtitres text Encoding:\(String(describing: trackInfo[VLCMediaTracksInformationTextEncoding]))"
                default:
                    text += "Unknown track"
                }
                text += " bitrate:\(String(describing: trackInfo[VLCMediaTracksInformationBitrate]))"
                text  += " description: \(String(describing: trackInfo[VLCMediaTracksInformationDescription]))"
                text += "\n"
                
            }
        }
        print(text)
       
    }
    
}

*/
