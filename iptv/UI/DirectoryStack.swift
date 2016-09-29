//
//  DirectoryStack.swift
//  iptv
//
//  Created by Александр Колганов on 27.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

protocol DirectoryStackProtocol {
    func changeStackPath(_ path: [String])
}



//last object is expand view control with focused property
class DirectoryStack:UIStackView {
    
    var _path : [String] = [ChannelManager.root.name]
    var delegate : DirectoryStackProtocol?
    
    
    func createButton(_ title:String) -> UIButton {
        let button = UIButton(type: .roundedRect)
        button.setTitle(title, for: .normal)
        button.setTitleColor(tintColor, for: .disabled)
        button.addTarget(self, action: #selector(DirectoryStack.changeDirAction(_:)), for: .primaryActionTriggered)
        return button
    }
    
    
    
    var path : [String] {
        get {
            return _path
        }
        set(newPath) {
            changePath(newPath)
        }
        
    }
    
    func changePath(_ path: [String]) -> Void{
        //delete all button except last item
        while arrangedSubviews.count > 1 {
            arrangedSubviews[arrangedSubviews.count - 2].removeFromSuperview()
        }
        //insert buttons
        for i in 0...path.count-1 {
            let button = createButton(path[i])
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            button.tag = i
            if i == path.count-1 {
                button.isEnabled = false
            }
            insertArrangedSubview(button, at: i)
        }
        _path = path
    }

    
    
    @objc func changeDirAction(_ sender:UIButton?) {
        let index = sender!.tag
        let newPath = Array(path[0...index])
        changePath(newPath)
        delegate?.changeStackPath(newPath)        
     }
    
}
