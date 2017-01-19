//
//  SettingsVC.swift
//  iptv
//
//  Created by Александр Колганов on 16.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoLabel: UILabel!
    
    lazy var urlString:String? = {
        return HttpServer.instance().serverURL?.absoluteString
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        infoLabel.text = ""
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension SettingsVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellId = "SetupCell\(indexPath.row)"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let index = context.nextFocusedIndexPath?.row,
            urlString != nil {
            var text = "You can go to link: \n\"\(urlString!)\"\n in your browser to "
            if index == 0 {
                text += "add m3u file and quickly add channel and remote group"
            }
            else {
                text += "quickly add epg sources"
            }
            text += " (use copy/paste to enter url)"
            infoLabel.text = text
        }
    }

}



