//
//  AddEpgLinkVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 14.01.17.
//  Copyright © 2017 Home. All rights reserved.
//

import UIKit


class ChooseEpgChannelCell : UITableViewCell {
    
    @IBOutlet weak var epgChannelNameLabel: UILabel!
    @IBOutlet weak var currentProgramLabel: UILabel!
}

class AddEpgLinkVC : FocusedViewController {
    
    var channelName = ""
    var epgPrograms = [String:EpgProgram]()
    var filterText = ""
    var filterPrograms = ["Loading..."]
    
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var filterTextField: UITextField!
    
    @IBOutlet weak var epgTableView: UITableView!
    
    static func loadFromIB() -> AddEpgLinkVC {
        let storyboard = UIStoryboard(name: "Program", bundle: Bundle.main)
        let addEpgLinkVC = storyboard.instantiateViewController(withIdentifier: "AddEpgLinkVC") as! AddEpgLinkVC
        return addEpgLinkVC
    }
    
    override func viewDidLoad() {
        channelNameLabel.text = "Set EPG for channel \"\(channelName)\""
        epgTableView.dataSource = self
        epgTableView.delegate = self
        filterTextField.delegate = self
        
        DispatchQueue.global().async {
            
            //loading all channels with programs
            var channelPrograms = [String:EpgProgram]()
            
            let now = NSDate()
            let predicate = NSPredicate(format: "start <= %@ AND %@ < stop", now,  now)
            let programs : [EpgProgram] = CoreDataManager.simpleRequest(predicate)
            
            for program in programs {
                if  let channelName = program.channel?.name,
                    channelPrograms[channelName] == nil
                {
                    channelPrograms[channelName] = program
                }
            }
            self.epgPrograms = channelPrograms
            self.filterPrograms = Array(self.epgPrograms.keys).sorted()
            DispatchQueue.main.async {
                self.epgTableView.reloadData()
            }
            
        }

    }
}

extension AddEpgLinkVC : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterPrograms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseEpgChannelCell") as? ChooseEpgChannelCell {
            
            if indexPath.row < filterPrograms.count {
                let epgChannelName = filterPrograms[indexPath.row]
                cell.epgChannelNameLabel.text = epgChannelName
                if let epgProgram = epgPrograms[epgChannelName] {
                    var text = ""
                    if let startDate = epgProgram.start as Date? {
                        text += startDate.toFormatString("HH:mm ")
                    }
                    if let finishDate = epgProgram.stop as Date? {
                        text += finishDate.toFormatString("- HH:mm ")
                    }
                    if let title = epgProgram.title {
                        text += title
                    }
                    cell.currentProgramLabel.text = text
                }
                else {
                    cell.currentProgramLabel.text = epgChannelName
                }
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.row < filterPrograms.count
        else { return }
        
        let epgChannelName = filterPrograms[indexPath.row]
        if epgPrograms[epgChannelName] != nil {
        
            
            var buttons = [String]()
            buttons.append("Link with EPG \"\(epgChannelName)\"")
            buttons.append("Cancel")
            
            self.simpleAlertChooser(title: "Set EPG for channel \"\(channelName)\"", message: "", buttonTitles: buttons, prefferButton: 0)
            { (selectButton) in
                if selectButton == 0 {
                    ProgramManager.instance.addChannelLink(channel:self.channelName, epg:epgChannelName)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

}

extension AddEpgLinkVC : UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        
        var newFilterText = ""
        if  textField.text != nil {
            newFilterText = textField.text!.lowercased()
        }
        
        if newFilterText != filterText {
            
            if newFilterText != "" {
                let newKeys = epgPrograms.keys.filter({$0.lowercased().contains(newFilterText)})
                filterPrograms = Array(newKeys).sorted()
                
            }
            else {
                let newKeys = epgPrograms.keys
                filterPrograms = Array(newKeys).sorted()
            }
            filterText = newFilterText
            
            if filterPrograms.count == 0 {
                filterPrograms = ["Not found programs"]
            }
            
            epgTableView.reloadData()
        }
    }
    
}
 
