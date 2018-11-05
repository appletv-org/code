//
//  ChannelSettingMetadataVC
//  iptv
//
//  Created by Alexandr Kolganov on 23.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


class ChannelSettingMetadataVC : BottomController, VLCMediaDelegate {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currentChannel: ChannelInfo?
    
    override func viewDidLoad() {
        activityIndicator.isHidden = true
        VLCLibrary.shared().debugLogging = true
    }
    
    func refresh() {
        activityIndicator.isHidden = true
        infoLabel.text = ""
        
        if let dirElement = channelSettingVC.dirElement,
            case .channel(let channel) = dirElement
        {
            self.currentChannel = channel
            infoLabel.text = "url: \(self.currentChannel!.url) \n"
            if let url = URL(string:channel.url) {
                let media = VLCMedia(url: url)
                media.delegate = self
                let res = media.parse(withOptions: VLCMediaParsingOptions(VLCMediaParseLocal|VLCMediaFetchLocal|VLCMediaParseNetwork|VLCMediaFetchNetwork), timeout:3000)
                if(res != -1) {
                    activityIndicator.isHidden = false
                }
            }
            else {
                infoLabel.text = "url is wrong"
            }
        }
        
    }
    
    func mediaDidFinishParsing(_ media:VLCMedia) {
        var text = "url: \(self.currentChannel!.url) \n"
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
        activityIndicator.isHidden = true
        infoLabel.text = "text"
        
    }
    
    func mediaMetaDataDidChange(_ media:VLCMedia) {
        print( "media.parsedStatus: \(media.parsedStatus)")
    }
    
}
