//
//  ProgramView.swift
//  iptv
//
//  Created by Alexandr Kolganov on 02.12.16.
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
            self.textView.attributedText = setProgramText(program!)
        }
        else {
            self.textView.text = "The program guide is not available"
        }
        self.setProgressBar(program)
    }
    
    func setProgramText(_ program:EpgProgram) -> NSAttributedString {
        
        
        let titleFont = UIFont.boldSystemFont(ofSize: 36)
        let descFont = UIFont.systemFont(ofSize: 36)
        
        var foregroundColor = UIColor.darkGray
        if let styleColor = Style.current?.panelTextColor {
            foregroundColor = styleColor
        }
        
        let timeFormatAttributes : [String : Any]  = [ NSFontAttributeName: titleFont, NSForegroundColorAttributeName: foregroundColor ]
        
        let titleAttributes : [String : Any] = [ NSFontAttributeName: titleFont, NSForegroundColorAttributeName: foregroundColor ]
        let descAttributes : [String : Any] = [ NSFontAttributeName: descFont, NSForegroundColorAttributeName: foregroundColor]
        
        
        //start date
        
        
        let attributedText = NSMutableAttributedString()
        
        
        //time
        if let startDate = program.start as? Date {
            
            let timeString = startDate.toFormatString("HH:mm") + " "
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
        
        let now = Date()
        guard let start = program?.start as? Date,
            let end = program?.stop as? Date,
            start < now,
            now < end
            else {
                self.progressView.isHidden = true
                return
        }
        
        self.progressView.isHidden = false
        let length = Float(end.timeIntervalSince(start))
        let gone = Float(now.timeIntervalSince(start))
        self.progressView.progress = gone / length
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
                attrString.addAttribute(NSForegroundColorAttributeName, value: selectedColor, range:NSMakeRange(0, attrText.length))
                self.textView.attributedText = attrString
            }
            self.view.layer.borderWidth = 5.0
            self.view.layer.borderColor = selectedColor.cgColor
        }
        
        if context.previouslyFocusedItem as? ProgramCollectionCell == self {
            if let attrText = self.textView.attributedText {
                let attrString = NSMutableAttributedString(attributedString: attrText)
                attrString.addAttribute(NSForegroundColorAttributeName, value: textColor, range:NSMakeRange(0, attrText.length))
                self.textView.attributedText = attrString
                self.view.layer.borderWidth = 0.0
                
            }
        }
    }
    
    
}

class ProgramCollectionView : UICollectionView {

    /*
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        get {
            let envs = super.preferredFocusEnvironments
            
            return envs
        }
    }
    */
}



class ProgramView : PanelView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var channel : ChannelInfo?
    var programs : [EpgProgram] = []
    
    weak var dayLabel: UILabel!
    
    weak var programCollectionView: UICollectionView! {
        didSet {
            programCollectionView.dataSource = self
            programCollectionView.delegate = self
            programCollectionView.remembersLastFocusedIndexPath = false
        }
    }
    
    
    func update(_ channel:ChannelInfo) {
        self.channel = channel
        let allPrograms = ProgramManager.instance.getPrograms(forChannel:channel.name)
        //rest only today +- 1 day programs
        
        
        let beginDay = NSCalendar.current.startOfDay(for: Date())
        let minData = beginDay.addingTimeInterval(-24*60*60)
        let maxData = beginDay.addingTimeInterval(24*60*60)
        
        programs = [EpgProgram]()
        for program in allPrograms {
            if let startDate = program.start as? Date {
                if startDate >= minData && startDate < maxData {
                    programs.append(program)
                }
            }
        }
        
        //sort programs
        programs.sort(by: { $0.start!.timeIntervalSince1970 < $1.start!.timeIntervalSince1970 })
        
        print("ChannelVC::play for channel:\(channel.name) find programs:\(programs.count)" )
        //programCollectionView.reloadData()
        programCollectionView.reloadSections(IndexSet(integer:0))
        //scroll to now element
        if let ind = findIndexNow() {
            programCollectionView.scrollToItem(at: IndexPath(row:ind, section:0), at: .left, animated: false)
        }
        labelDayUpdate()
    }
    
    func findIndexNow() -> Int? {
        
        for i in 0 ..< programs.count {
            if let startDate = programs[i].start as? Date , startDate <= Date(),
                let endDate = programs[i].stop as? Date , endDate > Date()  {
                return i
            }
        }
        return nil
        
    }
    
    
    func labelDayUpdate() {
        
        let dayinSec = TimeInterval(24.0*60*60)
        
        var programDate = Date()
        
        let visibleIndexPaths = programCollectionView.indexPathsForVisibleItems
        if programs.count > 0 && visibleIndexPaths.count > 0 {
            let indexPath = visibleIndexPaths[0]
            if (indexPath.row < programs.count) {
                if let date = programs[indexPath.row].start as? Date {
                    programDate = date
                }
            }
        }
        
        
        var text = ""
        let beginDay = NSCalendar.current.startOfDay(for: Date())
        
        let interval = programDate.timeIntervalSince(beginDay)
        if(interval > 0) {
            if(interval <= dayinSec) {
                text += "Today "
            }
            else if(interval > dayinSec && interval < dayinSec*2) {
                text += "Tommorow "
            }
        }
        else {
            if interval > -dayinSec {
                text += "Yestarday "
            }
        }
        text += programDate.toFormatString("dd.MM")
        
        if channel != nil {
            text += ": \(channel!.name)"
        }
        
        dayLabel.text = text
        
    }
    
    
    
    //collectionView delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return programs.count > 0 ?  programs.count : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.row
        
        let cell = self.programCollectionView.dequeueReusableCell(withReuseIdentifier: ProgramCollectionCell.programCellId, for: indexPath) as! ProgramCollectionCell
        
        var program :EpgProgram? = nil
        if index < programs.count {
            program = programs[index]
        }
        cell.setProgram(program)
        
        return cell
        
    }
    
/*
    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        if let ind = findIndexNow() {
            print("set to index: \(ind), time: \(programs[ind].start)")
            return IndexPath(row: ind, section: 0)
        }
        return nil
    }
 */
    
    
    func collectionView(_: UICollectionView, didUpdateFocusIn: UICollectionViewFocusUpdateContext, with: UIFocusAnimationCoordinator)  {
        //print("programView update focus")
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = programCollectionView.frame.size.width / 2
        let height = programCollectionView.frame.size.height
        return CGSize(width: width, height: height)
    }
}
