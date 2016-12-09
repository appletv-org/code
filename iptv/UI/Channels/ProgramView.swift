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
    
    weak var programCollectionView: UICollectionView! {
        didSet {
            programCollectionView.dataSource = self
            programCollectionView.delegate = self
            programCollectionView.remembersLastFocusedIndexPath = false
        }
    }
    
    
    func update(_ channel:ChannelInfo) -> Bool {
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
        var isFindProgram = false
        if let ind = findIndexNow() {
            isFindProgram = true
            programCollectionView.scrollToItem(at: IndexPath(row:ind, section:0), at: .left, animated: false)
        }
        labelDayUpdate()
        
        return isFindProgram
        
    }
    
    func findIndexNow() -> Int? {
        
        for i in 0 ..< programs.count {
            let startStop = ProgramManager.startStopTime(programs[i])
            if      let start = startStop.start,
                    let stop = startStop.stop,
                    start <= Date(), stop > Date() {
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
        return programs.count > 0 ? programs.count : 1
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
