//
//  ChannelCell.swift
//  iptv
//
//  Created by Александр Колганов on 22.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelCell : UICollectionViewCell {
    
    static let reuseIdentifier = "ChannelCell"
    static let focusIncrease : CGFloat = 30

    static let imageGroup = UIImage(named: "group")
    static let imageChannel = UIImage(named: "channel")
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var _element : DirElement?
    var element : DirElement //group or channel
    {
        get {
            return _element!
        }
        set(newElement) {
            _element = newElement
            switch newElement {
            case .group(let group):
                    label.text = group.name
                    imageView.image = ChannelCell.imageGroup
                
            case .channel(let channel):
                    label.text = channel.name
                    imageView.image = ChannelCell.imageChannel
            }
        }
    }
    
    lazy var imageFocusInRect : CGRect = {
        self.layoutIfNeeded()
        return self.imageView.frame
    }()
    
    lazy var imageFocusOutRect : CGRect = {
        self.layoutIfNeeded()
        var frame = self.imageView.frame
        var newFrame = CGRect(x: frame.origin.x - focusIncrease, y:frame.origin.y - focusIncrease, width: frame.size.width + 2*focusIncrease, height: frame.size.height + 2 * focusIncrease)
        return newFrame
    }()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // These properties are also exposed in Interface Builder.
        //imageView.adjustsImageWhenAncestorFocused = true
        imageView.clipsToBounds = false
        
        label.alpha = 0.8
    }
    
    // MARK: UICollectionReusableView
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset the label's alpha value so it's initially hidden.
        label.alpha = 0.8
    }
    
    // MARK: UIFocusEnvironment
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        /*
         Update the label's alpha value using the `UIFocusAnimationCoordinator`.
         This will ensure all animations run alongside each other when the focus
         changes.
         */
        
        let imageSize = imageFocusInRect
        let imageFocusSize = imageFocusOutRect
        
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.imageView.frame = imageFocusSize
                self.label.alpha = 1.0
                // print("Update focus is focused \(self.label.text)")
            }
            else {
                self.label.alpha = 0.3
                self.imageView.frame = imageSize
                //print("Update focus is unfocused \(self.label.text)")
            }
            
        }, completion: nil)
    }
    
}
