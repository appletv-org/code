//
//  ProgramVC.swift
//  iptv
//
//  Created by Александр Колганов on 16.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


class PrintPreferFocusedView : UIView {
    
    override var canBecomeFocused : Bool {
        get {
            return true
        }
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        
        var envs = [UIFocusEnvironment]()
        for view in self.subviews {
            if view.canBecomeFocused {
                envs.append(view as UIFocusEnvironment)
            }
        }
        print("focused")
        return envs
    }
}

class ProgramVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

