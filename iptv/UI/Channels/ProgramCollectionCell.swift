//
//  ProgramCollectionCell.swift
//  iptv
//
//  Created by Alexandr Kolganov on 08.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ProgramCollectionCell : UICollectionViewCell {
    
    static let programCellId = "ProgramCell"
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var progressView: UIProgressView!
    
    func setProgram(_ program:EpgProgram?) {
        if program != nil {
            textView.attributedText = setProgramText(program!)
        }
        else {
            textView.text = UICommonString.programNotFound
        }
        print("ProgramCollectionCell: \(String(describing: textView.text)) ")
        self.setProgressBar(program)
    }
    
    func setProgramText(_ program:EpgProgram) -> NSAttributedString {
        
        
        let titleFont = UIFont.boldSystemFont(ofSize: 36)
        let descFont = UIFont.systemFont(ofSize: 36)
        
        var foregroundColor = UIColor.darkGray
        if let styleColor = Style.current?.panelTextColor {
            foregroundColor = styleColor
        }
        
        let timeFormatAttributes : [NSAttributedStringKey : Any]  = [ NSAttributedStringKey.font: titleFont, NSAttributedStringKey.foregroundColor: foregroundColor ]
        
        let titleAttributes : [NSAttributedStringKey : Any] = [ NSAttributedStringKey.font: titleFont, NSAttributedStringKey.foregroundColor: foregroundColor ]
        let descAttributes : [NSAttributedStringKey : Any] = [ NSAttributedStringKey.font: descFont, NSAttributedStringKey.foregroundColor: foregroundColor]
        
        
        //start date
        
        
        let attributedText = NSMutableAttributedString()
        
        
        //time
        let startStop = ProgramManager.startStopTime(program)
        
        if startStop.start != nil {
            
            let timeString = startStop.start!.toFormatString("HH:mm") + " "
            attributedText.append(NSAttributedString( string: timeString, attributes: timeFormatAttributes))
        }
        
        //title
        if let title = program.title {
            attributedText.append(NSAttributedString( string: title + "\n", attributes: titleAttributes  ))
        }
        
        //desc
        if let desc = program.desc {
            attributedText.append(NSAttributedString( string: desc, attributes: descAttributes ))
        }
        
        return attributedText
        
    }
    
    func setProgressBar(_ program:EpgProgram?) {
        
        if program != nil {
            let now = Date()
            let startStop = ProgramManager.startStopTime(program!)
            if      let start = startStop.start,
                let stop = startStop.stop,
                start < now, stop > now {
                
                self.progressView.isHidden = false
                let length = Float(stop.timeIntervalSince(start))
                let gone = Float(now.timeIntervalSince(start))
                self.progressView.progress = gone / length
                return
            }
        }
        
        self.progressView.isHidden = true
        
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        var selectedColor = UIColor.white
        var textColor = UIColor.darkGray
        if let style = Style.current {
            if style.panelTextColor != nil {
                textColor = style.panelTextColor!
            }
            if style.panelSelectedColor != nil {
                selectedColor = style.panelSelectedColor!
            }
        }
        
        if context.nextFocusedItem as? ProgramCollectionCell == self {
            if let attrText = self.textView.attributedText {
                let attrString = NSMutableAttributedString(attributedString: attrText)
                attrString.addAttribute(NSAttributedStringKey.foregroundColor, value: selectedColor, range:NSMakeRange(0, attrText.length))
                self.textView.attributedText = attrString
            }
            self.view.layer.borderWidth = 5.0
            self.view.layer.borderColor = selectedColor.cgColor
        }
        
        if context.previouslyFocusedItem as? ProgramCollectionCell == self {
            if let attrText = self.textView.attributedText {
                let attrString = NSMutableAttributedString(attributedString: attrText)
                attrString.addAttribute(NSAttributedStringKey.foregroundColor, value: textColor, range:NSMakeRange(0, attrText.length))
                self.textView.attributedText = attrString
                self.view.layer.borderWidth = 0.0
                
            }
        }
    }
    
    
}

