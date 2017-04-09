//
//  ProgramVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 13.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ProgramVCProgramCell : UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    var program :EpgProgram? {
        didSet {
            label.textColor = UIColor.black
            if program == nil {
                label.text = UICommonString.programNotFound
            }
            else {
                var text = ""
                let startStopTime = ProgramManager.startStopTime(program!)
                if let start = startStopTime.start {
                    text += start.toFormatString("HH:mm") + ". "
                }
                
                text +=  (program!.title ?? "") + "\n" + (program!.desc ?? "")
                label.text = text
                
                if( (program!.start! as Date) < Date() &&  (program!.stop! as Date) > Date() ) {
                    //label.textColor = UIColor.red
                    label.font = label.font.bold()
                }
                else {
                    label.font = label.font.regular()
                }
            }
        }
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        coordinator.addCoordinatedAnimations(
            {
                if self.isFocused
                {
                    self.label.backgroundColor = UIColor.yellow
                    
                    UIView.animate(withDuration: 0.2,
                                   animations: {
                                    self.transform = CGAffineTransform(scaleX: 1.05, y: 1.2)
                    },
                                   completion: { finished in
                                    UIView.animate(withDuration: 0.2,
                                                   animations:{
                                                    self.transform = .identity
                                    },
                                                   completion: nil
                                    )
                    }
                    )
                }
                else
                {
                    self.label.backgroundColor = UIColor.white
                }
        },
            completion: nil)
    }

}

class ProgramVCProgramCollection : FocusedCollectionView {
    weak var programVC: ProgramVC!
    
    var sectionCount : Int = 1
    var programs = [EpgProgram]() {
        didSet {
            
            if programs.count == 0 {
                sectionCount = 1
            }
            else {
                sectionCount = (programs.count + 2)/3
            }
            self.reloadData()
            
            //set focused index
            if let index = programs.index( where: {($0.start! as Date) < Date() &&  ($0.stop! as Date) > Date()} ) {
                self.focusedIndex = indexToIndexPath(index)
            }
            
        }
    }

    func indexToIndexPath(_ index: Int) -> IndexPath {
        if programs.count == 0 {
            return IndexPath(row: 0, section: 0)
        }
        
        let row = index / sectionCount
        let section = index % sectionCount
        return IndexPath(row: row, section: section)
    }

    func IndexPathToIndex(_ indexPath: IndexPath) -> Int {
        return indexPath.row * sectionCount + indexPath.section
    }


}

extension ProgramVCProgramCollection : UICollectionViewDataSource, UICollectionViewDelegate {
    
    

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionCount
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if programs.count <= 1  {
            return 1
        }
        
        let index = indexToIndexPath(programs.count - 1)
        if section < index.section {
            return 3
        }
        else {
            return 2
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = self.dequeueReusableCell(withReuseIdentifier: "ProgramVCProgramCell", for: indexPath) as! ProgramVCProgramCell
        let index = IndexPathToIndex(indexPath)
        if programs.count <= index  {
            cell.program = nil
        }
        else {
            cell.program = programs[index]
        }
        
        
        return cell

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
        let index = IndexPathToIndex(indexPath)
        if index < programs.count {
        //print( "didSelectItemAt \(programs[index].title)")
            if  let channelName = programs[index].channel?.name,
                let startTime = programs[index].start as Date?
            {
                let programDescriptionVC = ProgramDescriptionVC.loadFromIB()
                programDescriptionVC.channelName = channelName
                programDescriptionVC.startTime = startTime
                programVC.present(programDescriptionVC, animated: true, completion: nil)
            }
        }
    }
    
}




class ProgramVCChannelCell : UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    var channelName : String!
    
    func setChannel(channel:String, provider:EpgProviderInfo?) {
        channelName = channel
        
        
        label.text = channel
        bottomLabel.text = channel
        imageView.image = UIImage(named:"channel")
    
        if provider == nil {
            ProgramManager.instance.getIcon(channel: channel, completion: { (data) in
                if          data != nil,
                            let image = UIImage(data: data!) {
                    self.imageView.image = image
                    self.label.text = ""
                }
            })
        }
        else {
            ProgramManager.instance.getProviderIcon(channel: channel, provider:provider!.name, completion: { (data) in
                if      data != nil,
                        let image = UIImage(data: data!) {
                    self.imageView.image = image
                    self.label.text = ""
                }
            })
        }
        
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        super.didUpdateFocus(in:context, with:coordinator)
        
        coordinator.addCoordinatedAnimations(
        {
            if self.isFocused
            {
                self.containerView.backgroundColor = UIColor.yellow
                self.bottomLabel.text = self.channelName
                
                UIView.animate(withDuration: 0.2,
                    animations: {
                        self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                    },
                    completion: { finished in
                        UIView.animate(withDuration: 0.2,
                            animations:{
                                self.transform = .identity
                            },
                            completion: nil
                        )
                    }
                )
            }
            else
            {
                if let _  = context.nextFocusedItem as? ProgramVCChannelCell {
                    
                    self.containerView.backgroundColor = UIColor.clear
                    self.bottomLabel.text = ""
                }
                //self.layer.borderColor = UIColor.yellow.cgColor

            }
        },
        completion: nil)
    }
}

class ProgramVCChannelCollection  : FocusedCollectionView {
    weak var programVC: ProgramVC!

}

extension ProgramVCChannelCollection : UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return programVC.channelNames.count
    }

    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    @available(tvOS 6.0, *)
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        
        let channel = programVC.channelNames[indexPath.section]
        
        let cell = self.dequeueReusableCell(withReuseIdentifier: "ProgramVCChannelCell", for: indexPath) as! ProgramVCChannelCell
        cell.setChannel(channel: channel, provider: programVC.epgProvider)
        return cell
    }
    
    
}

extension ProgramVCChannelCollection : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        if let indexPath = context.nextFocusedIndexPath {
            let channel = programVC.channelNames[indexPath.section]
            self.programVC.updatePrograms(channel)
        }

    }

}

class ProgramVC : FocusedViewController {


    //filter parameters
    var path : [String]? {
        
        didSet {
            if path == nil {
                channelLabel.text = "All EPG channels"
            }
            else {
                var text = "Channels ->" + path!.joined(separator: " -> ")
                if      let group = ChannelManager.findGroup(path!),
                        group.groups.count > 0 {
                    if path!.count != 0 {
                        text += " -> "
                    }
                    text += "All"
                }
                channelLabel.text = text
            }
        }

    }
    
    var epgProvider : EpgProviderInfo? {
        didSet {
            if epgProvider == nil {
                epgLabel.text = "All"
            }
            else {
                epgLabel.text = epgProvider!.name
            }
        }
    }
    var fromTime : Date?
    var toTime : Date?
    

    //state parameters
    var channelNames = [String]() //name of channels
    var channelName : String?
    var programs = [EpgProgram]()

    @IBOutlet weak var channelCollectionView: ProgramVCChannelCollection!
    @IBOutlet weak var programCollectionView: ProgramVCProgramCollection!
    
    
    @IBAction func prevDayAction(_ sender: Any) {
        changeTime(-24*60*60)
    }
    
    @IBAction func nextDayAction(_ sender: Any) {
        changeTime(24*60*60)
    }
    
    @IBOutlet weak var nextDayAction: UIButton!
    @IBOutlet weak var dataLabel: UILabel!
    
    @IBAction func channelAction(_ sender: Any) {
        let groupVC = SelectChannelGroupVC.loadFromIB()
        groupVC.modalPresentationStyle = .overFullScreen
        groupVC.groupPath = path
        groupVC.delegate = self
        self.present(groupVC, animated: false, completion: nil)
    }
    
    @IBOutlet weak var channelLabel: UILabel!
    
    @IBAction func epgAction(_ sender: Any) {
        
        var providerNames =  ProgramManager.instance.epgProviders.map({$0.name})
        providerNames = ["All"] + providerNames
        
        var index = 0
        if      epgProvider != nil,
                let i = providerNames.index(of:epgProvider!.name) {
            index = i
            
        }
        self.simpleAlertChooser(title: "Choose EPG provider", message: "", buttonTitles: providerNames, prefferButton:index, completion: { index in
            var newProvider:EpgProviderInfo? = nil
            if index > 0 {
                newProvider = ProgramManager.instance.epgProviders[index-1]
            }
            if newProvider != self.epgProvider {
                self.epgProvider = newProvider
                self.updateChannels()

            }
        })
    }
    
    @IBOutlet weak var epgLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        

        channelCollectionView.programVC = self
        channelCollectionView.dataSource = channelCollectionView
        channelCollectionView.delegate = channelCollectionView
        channelCollectionView.remembersLastFocusedIndexPath = false
        
        programCollectionView.programVC = self
        programCollectionView.dataSource = programCollectionView
        programCollectionView.delegate = programCollectionView
        
        self.viewToFocus = channelCollectionView
        
        path = []
        fromTime = NSCalendar.current.startOfDay(for: Date())
        toTime = fromTime!.addingTimeInterval(24*60*60)


        updateChannels()

    }
    
    
    func updateChannels() {
        
        channelNames = []
        if path != nil {
            if var group = ChannelManager.findGroup(path!) {
                if group.groups.count > 0 {
                    group = ChannelManager.findGroup(["All"], group:group)!
                }
                channelNames = group.channels.map({$0.name})
            }
        }
        else {
            var setChannels = Set<String>()
            var epgProviders = [EpgProviderInfo]()
            
            if epgProvider != nil {
                epgProviders = [epgProvider!]
            }
            else {
                epgProviders = ProgramManager.instance.epgProviders
            }
                
            for provider in epgProviders {
                if      let dbProvider = ProgramManager.instance.getDbProvider(provider.name),
                        let dbchannels = dbProvider.channels {
                    for dbChannel in dbchannels {
                        if let epgChannel = dbChannel as? EpgChannel {
                            setChannels.insert(epgChannel.name!)
                        }
                    }
                }
            }
            channelNames = Array(setChannels)
        }
        channelCollectionView.reloadData()
        if channelNames.count > 0 {
            channelCollectionView.focusedIndex = IndexPath(row: 0, section: 0)
            updatePrograms(channelNames[0])
            
        }
    }
    
    func updatePrograms(_ channel:String) {

        channelName = channel
        var programs = [EpgProgram]()        
        if epgProvider == nil {
            programs = ProgramManager.instance.getPrograms(channel: channel, from:fromTime, to:toTime)
        }
        else {
            programs = ProgramManager.instance.getProviderPrograms(provider:epgProvider!, channel: channel, from:fromTime, to:toTime )
        }
        programCollectionView.programs = programs
    }
    
    func changeTime(_ timeInterval:Int) {
        fromTime?.addTimeInterval(TimeInterval(timeInterval))
        toTime?.addTimeInterval(TimeInterval(timeInterval))
        
        //get date
        if      let start = fromTime,
                let _ = toTime {
            
            var text = ""
            let ti = start.timeIntervalSince(Date())
            if(ti < 0 && ti > -24*60*60) {
                text = "Today"
            }
            else if(ti < -24*60*60 && ti > -2*24*60*60) {
                text = "Yesterday"
            }
            else if(ti > 0 && ti < 24*60*60) {
                text = "Tomorrow"
            }
            else {
                text = start.toFormatString("dd.MM YYYY")
            }
            dataLabel.text = text
        }
        if channelName != nil {
            updatePrograms(channelName!)
        }
        
    }
}

extension ProgramVC : SelectChannelGroupDelegate {
    func selectedGroup(_ path: [String]?) {
        
        if path == nil && self.path == nil {
            return
        }
        
        if path != nil && self.path != nil && path! == self.path! {
            return
        }
        
        self.path = path
        updateChannels()
                
    }
}

