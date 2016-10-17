//
//  ChannelsVC.swift
//  iptv
//
//  Created by Александр Колганов on 16.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import AVKit

class ChannelsVC : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, DirectoryStackProtocol {

    var groupInfo : GroupInfo = ChannelManager.root
    var path: [String] = [ChannelManager.root.name]
    var currentItem : DirElement? = nil
    var focusedItem : UIFocusItem? = nil
    var currentChannelIndex: Int = 0
    
    //let player = AVPlayer()
    let mainPlayer = PlayerView()
    
    @IBOutlet weak var directoryStack: DirectoryStack!
    @IBOutlet weak var focusedDirectoryStack: FocusedView!
    @IBOutlet weak var channelsView: UICollectionView!
    
    @IBOutlet weak var playerView: FocusedView!
    @IBOutlet weak var controlView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        channelsView.delegate = self
        channelsView.dataSource = self
        channelsView.remembersLastFocusedIndexPath = true
        
        controlView.layer.borderWidth = 5
        controlView.layer.borderColor = UIColor.red.cgColor
        
        directoryStack.layer.borderWidth = 5
        directoryStack.layer.borderColor = UIColor.green.cgColor
        
        channelsView.layer.borderWidth = 5
        channelsView.layer.borderColor = UIColor.green.cgColor

        
        directoryStack.delegate = self
        directoryStack.path = self.path
        
        focusedDirectoryStack.focusedFunc = { () -> [UIFocusEnvironment]? in
            if ((self.focusedItem as? ChannelCell) != nil) {
                let stackSubViews = self.directoryStack.arrangedSubviews
                if(stackSubViews.count >= 3) {
                    return [stackSubViews[stackSubViews.count-3]]
                }
            }
            return [self.channelsView]
        }
        
        controlView.isHidden = true
        
        // Add tap gesture recognizer to view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        playerView.addGestureRecognizer(tapGesture)
        
        //Add swipe gesture recognizer
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        swipeGesture.direction = [.left, .right]
        playerView.addGestureRecognizer(swipeGesture)


    }
    

    
    override func viewDidLayoutSubviews() {
        /*
         let playerLayer = AVPlayerLayer(player: player)
         playerLayer.frame = self.playerView.bounds
         self.playerView.layer.addSublayer(playerLayer)
         */
        mainPlayer.frame = playerView.frame
        mainPlayer.backgroundColor = UIColor.red
        playerView.addSubview(mainPlayer)
        mainPlayer.fillMode = .resizeAspectFill
        mainPlayer.url = URL(string: "http://alevko.iptvspy.ru/iptv/BYRB66FU3T4UZP/101/index.m3u8")
        mainPlayer.play()
        
        
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        get {
            return [controlView, playerView]
        }
    }

    // this method is called when a tap is recognized
    func handleTap(sender: UITapGestureRecognizer) {
        if controlView.isHidden {
            controlView.isHidden = false
            playerView.canFocused = false
            self.setNeedsFocusUpdate()
        }
    }
        
    func handleSwipe(sender: UISwipeGestureRecognizer) {
        if controlView.isHidden {
            if(sender.direction == .right) {
                currentChannelIndex += 1
                if currentChannelIndex >= groupInfo.channels.count {
                    currentChannelIndex = 0
                }
            }
            else {
                currentChannelIndex -= 1
                if currentChannelIndex < 0 {
                    currentChannelIndex = groupInfo.channels.count - 1
                }
            }
            playChannelIndex(currentChannelIndex)
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //directory Stack Protocol
    func changeStackPath(_ path: [String]) {
        if let group = ChannelManager.findGroup(path) {
            self.path = path
            self.groupInfo = group
            self.channelsView.reloadData()
        }
    }
    
    
    func changePath(_ path: [String]) {
        changeStackPath(path)
        directoryStack.changePath(path)
    }
    
    //---- UICollectionViewDataSource ------
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  groupInfo.groups.count + groupInfo.channels.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.channelsView.dequeueReusableCell(withReuseIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as! ChannelCell
        
        var index = indexPath.row
        
        if index < groupInfo.groups.count {
            cell.element = .group(groupInfo.groups[index])
            return cell
        }
        
        index -= groupInfo.groups.count
        if index < groupInfo.channels.count {
            cell.element = .channel(groupInfo.channels[index])
        }
        
        return cell
    }
    
    //---- UICollectionViewDelegate ------
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var index = indexPath.row
        
        if index < groupInfo.groups.count {
            var newPath = path.map({$0})
            newPath.append(groupInfo.groups[index].name)
            changePath(newPath)
            directoryStack.path = newPath
            return
        }
        
        index -= groupInfo.groups.count
        playChannelIndex(index)
        
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if let nextFocusedItem = context.nextFocusedItem {
            //print("nextFocusedItem : \(nextFocusedItem)")
            focusedItem = nextFocusedItem
            if let cellItem = nextFocusedItem as? ChannelCell {
                currentItem = cellItem.element
            }
        }
        
        /*
         if let previouslyFocusedItem = context.previouslyFocusedItem {
         print("previouslyFocusedItem : \(previouslyFocusedItem)")
         }
         */
        
    }
    
    func playChannelIndex(_ index: Int) {
        currentChannelIndex = index
        play(groupInfo.channels[index])
    }

    func play(_ channel:ChannelInfo) {
        controlView.isHidden = true
        playerView.canFocused = true
 
        mainPlayer.resetPlayer()
        mainPlayer.url = URL(string:channel.url)
        mainPlayer.play()
    }

}

