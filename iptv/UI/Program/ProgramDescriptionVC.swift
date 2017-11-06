//
//  ProgramDescriptionVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 13.01.17.
//  Copyright © 2017 Home. All rights reserved.
//

import UIKit

class ProgramDescriptionVC : FocusedViewController {
    
    var channelName = ""
    var startTime = Date()
    
    @IBOutlet weak var channelInfo: UILabel!
    @IBOutlet weak var removeEpgButton: UIButton!
    @IBOutlet weak var programDescription: UITextView!
    
    @IBAction func removeEpgAction(_ sender: Any) {
        ProgramManager.instance.delChannelLink(channelName)
        self.dismiss(animated: true, completion: nil)
    }
    
    static func loadFromIB() -> ProgramDescriptionVC {
        let storyboard = UIStoryboard(name: "Program", bundle: Bundle.main)
        let programDescriptionVC = storyboard.instantiateViewController(withIdentifier: "ProgramDescriptionVC") as! ProgramDescriptionVC
        return programDescriptionVC
    }

    static let titleFont = UIFont.boldSystemFont(ofSize: 36)
    static let descFont = UIFont.systemFont(ofSize: 36)
    static let foregroundColor = UIColor.darkGray
    static let titleAttributes : [NSAttributedStringKey : Any] = [ NSAttributedStringKey.font: titleFont, NSAttributedStringKey.foregroundColor: ProgramDescriptionVC.foregroundColor ]
    static let descAttributes : [NSAttributedStringKey : Any] = [ NSAttributedStringKey.font: descFont, NSAttributedStringKey.foregroundColor: ProgramDescriptionVC.foregroundColor]


    override func viewDidLoad() {
        
        let existChannelLink = ProgramManager.instance.existChannelLink(channelName)
        removeEpgButton.isHidden = !existChannelLink
        //set channelInfo focused
        programDescription.isSelectable = true
        programDescription.panGestureRecognizer.allowedTouchTypes = [NSNumber(value:UITouchType.indirect.rawValue)]
        
        
        //info
        channelInfo.text = channelName + "     (" + startTime.toFormatString("dd.MM HH:mm") + ")"
        
        
        //program from epg providers
        let pm = ProgramManager.instance
        
        let attributedText = NSMutableAttributedString()
        
        for provider in pm.epgProviders  where provider.parseProgram {
            
            let programs = pm.getProviderPrograms(provider: provider, channel:channelName, from:startTime, to:startTime)
            if programs.count > 0 {
                let program = programs[0]
                
                //provider
                var text = provider.name
                attributedText.append(NSAttributedString( string: text + "\n", attributes: ProgramDescriptionVC.titleAttributes))
                
                // time and title
                text = ""
                if let startDate = program.start as Date? {
                    text += startDate.toFormatString("HH:mm")
                }
                if let stopDate = program.stop as Date? {
                    text += " - " + stopDate.toFormatString("HH:mm")
                }

                if let title = program.title {
                    text += "   " + title
                }
                attributedText.append(NSAttributedString( string: text + "\n", attributes: ProgramDescriptionVC.titleAttributes  ))
                
                //desc
                if let desc = program.desc {
                    attributedText.append(NSAttributedString( string: desc + "\n", attributes: ProgramDescriptionVC.descAttributes ))
                }
                attributedText.append(NSAttributedString( string: "\n", attributes: ProgramDescriptionVC.descAttributes ))
                

            }
        }
        
        programDescription.attributedText = attributedText
    }
}
