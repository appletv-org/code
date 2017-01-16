//
//  ProgramView.swift
//  iptv
//
//  Created by Alexandr Kolganov on 02.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit



class ProgramView : PanelView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var channel : ChannelInfo?
    var programs : [EpgProgram] = []
    
    weak var dayLabel: UILabel!
    weak var actionButtons: UISegmentedControl!
    weak var programCollectionView: UICollectionView! {
        didSet {
            programCollectionView.dataSource = self
            programCollectionView.delegate = self
            programCollectionView.remembersLastFocusedIndexPath = false
        }
    }
    
    weak var channelsVC: ChannelsVC! {
        didSet {
            dayLabel = channelsVC.dayLabel
            actionButtons = channelsVC.actionButtons
            programCollectionView = channelsVC.programCollectionView
        }
    }
    
    func update(_ channel:ChannelInfo) -> Bool {//return - find program with current time
        self.channel = channel
        
        let beginDay = NSCalendar.current.startOfDay(for: Date())
        let minData = beginDay.addingTimeInterval(-24*60*60)
        let maxData = beginDay.addingTimeInterval(2*24*60*60)

        //rest only today +- 1 day programs
        programs = ProgramManager.instance.getPrograms(channel:channel.name, from:minData, to:maxData)
        
        //sort programs
        programs.sort(by: { $0.start!.timeIntervalSince1970 < $1.start!.timeIntervalSince1970 })
        
        print("ChannelVC::play for channel:\(channel.name) find programs:\(programs.count)" )
        //programCollectionView.reloadData()
        programCollectionView.reloadSections(IndexSet(integer:0))
        //scroll to now element
        
        let indNow = findIndexNow()
        if let index = indNow.index {
            programCollectionView.scrollToItem(at: IndexPath(row:index, section:0), at: .left, animated: false)
        }
        labelDayUpdate()
        
                
        return indNow.isNow
        
    }
    
    func findIndexNow() -> (index:Int?, isNow:Bool) {
        
        if programs.count == 0 {
            return (nil,false)
        }
        
        //find near index
        let now = Date()
        var nearIndex = 0
        var minStartTimeInterval = TimeInterval(10000000)
        
        for i in 0 ..< programs.count {
            let startStop = ProgramManager.startStopTime(programs[i])
            
            if      let start = startStop.start,
                    let stop = startStop.stop
            {
                if start <= now && stop > now {
                    return (i, true)
                }
                let timeInterval = abs(start.timeIntervalSinceNow)
                if timeInterval < minStartTimeInterval {
                    nearIndex = i
                    minStartTimeInterval = timeInterval
                }
            }
        }
        return (nearIndex, false)
    }
    
    
    func labelDayUpdate(_ programDate:Date? = nil) {
        
        let dayinSec = TimeInterval(24.0*60*60)
                
        var text = ""
        if channel != nil {
            text += "\(channel!.name)"
        }

        if programDate != nil {
            text += ":    "
            //current day
            let beginDay = NSCalendar.current.startOfDay(for: Date())
            
            let interval = programDate!.timeIntervalSince(beginDay)
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
                    text += "Yesterday "
                }
            }
            text += programDate!.toFormatString("dd.MM")
        }
        
        
        dayLabel.text = text
        
    }
    
    
    
    //collectionView delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return programs.count > 0 ? programs.count : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.row
        
        let cell = self.programCollectionView.dequeueReusableCell(withReuseIdentifier: ProgramCollectionCell.programCellId, for: indexPath) as! ProgramCollectionCell
        
        var program :EpgProgram? = nil
        if index < programs.count {
            program = programs[index]
            print( "cellForItemAt \(programs[index].title)")
        }
        cell.setProgram(program)
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        if index < programs.count {
            //print( "didSelectItemAt \(programs[index].title)")
            if let channelName = channel?.name,
               let startTime = programs[index].start as? Date
            {
                let programDescriptionVC = ProgramDescriptionVC.loadFromIB()
                programDescriptionVC.channelName = channelName
                programDescriptionVC.startTime = startTime
                channelsVC.present(programDescriptionVC, animated: true, completion: nil)
            }
        }
        else {
            if let channelName = channel?.name {
                let addEpgLinkVC = AddEpgLinkVC.loadFromIB()
                addEpgLinkVC.channelName = channelName
                channelsVC.present(addEpgLinkVC, animated: true, completion: nil)
            }
            
        }
        
    }

    
    
    func collectionView(_: UICollectionView, didUpdateFocusIn: UICollectionViewFocusUpdateContext, with: UIFocusAnimationCoordinator)  {
        if let indexPath = didUpdateFocusIn.nextFocusedIndexPath,
           indexPath.row < programs.count
        {
            let program = programs[indexPath.row]
            print( "didUpdateFocusIn \(programs[indexPath.row].title)")
            labelDayUpdate(program.start as? Date)
        }
    
        
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
