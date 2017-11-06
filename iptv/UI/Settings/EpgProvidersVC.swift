//
//  ProgramProviders.swift
//  iptv
//
//  Created by Alexandr Kolganov on 20.10.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import CoreData



class EpgProviderCell : UITableViewCell {
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var channels: UILabel!
    @IBOutlet weak var dateInterval: UILabel!
    @IBOutlet weak var actions: UISegmentedControl!
}

class EpgProvidersVC: FocusedViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var editModeSegmentedControl: UISegmentedControl!
    

    
    @IBAction func addAction(_ sender: Any) {
        if let epgEditVC = self.storyboard?.instantiateViewController(withIdentifier: "EpgProviderEditVC") as? EpgProviderEditVC {
            self.navigationController?.pushViewController(epgEditVC, animated: true)
        }
        
        
    }
    
    //var _dbEpgProviders : [String : EpgProvider?]
     
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.remembersLastFocusedIndexPath = true
        tableView.isEditing = false
        
        addNavigationTitle("EPG sources")
        
        
        NotificationCenter.default.addObserver(forName: ProgramManager.epgNotification, object: nil, queue: nil) { (notification) in
            self.reloadData()
        }

        
        let tapChangeModeButton = UITapGestureRecognizer( target: self, action:  #selector(changeModeAction))
        editModeSegmentedControl.addGestureRecognizer(tapChangeModeButton)

        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func reloadData() {
        DispatchQueue.main.async {
            if ProgramManager.instance.epgProviders.count < 2 {
                self.editModeSegmentedControl.isEnabled = false
                self.editModeSegmentedControl.selectedSegmentIndex = 0
                if self.tableView.isEditing {
                    self.tableView.isEditing = false
                }
            }
            else {
                self.editModeSegmentedControl.isEnabled = true
            }
            self.tableView.reloadData()
        }
    }
    
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        /*
        let nextFocusedItem = context.nextFocusedItem
        let prevFocusedItem = context.previouslyFocusedItem
        
        let nextCellItem = nextFocusedItem as? UITableViewCell
        let prevCellItem = prevFocusedItem as? UITableViewCell
        
        if nextCellItem != nil {
            //available move
        }
        
        if prevCellItem != nil && nextCellItem != nil {
            prevCellItem!.textLabel?.textColor = UIColor.black
        }
        */
    
    }
    
    
    @objc func changeModeAction(sender: UITapGestureRecognizer) {
        
        if editModeSegmentedControl.selectedSegmentIndex == 0 {
            tableView.isEditing = false
        }
        else {
            tableView.isEditing = true
        }
    }
}


extension EpgProvidersVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ProgramManager.instance.epgProviders.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "EpgProviderCell") as? EpgProviderCell {
            let providers = ProgramManager.instance.epgProviders
            if indexPath.row < providers.count {
                let provider = providers[indexPath.row]
                cell.name.text = provider.name
                
                
                cell.dateInterval.text = ""
                cell.channels.text = "0"
                cell.status.text = "not processing"
                
                if let dbProvider = ProgramManager.instance.getDbProvider(provider.name) {
                    
                    if (dbProvider.lastUpdate as Date?) != nil {
                       
                    }
                    cell.channels.text = String(dbProvider.channelCount)
                    if let startDate = dbProvider.startDate as Date?,
                       let finishDate = dbProvider.finishDate as Date? {
                        cell.dateInterval.text = startDate.toFormatString("dd.MM HH:mm") + " - " + finishDate.toFormatString("dd.MM HH:mm")
                    }
                    
                    var statusText = ""
                    switch(provider.status) {
                    case .waiting:
                        statusText = "waiting..."
                    case .processing:
                        statusText = "processing..."
                    default:
                        if dbProvider.error != nil && !dbProvider.error!.isEmpty {
                           statusText = dbProvider.error!
                        }
                        else if let updateDate = dbProvider.lastUpdate as Date? {
                           statusText = "updated " + updateDate.toFormatString("dd.MM HH:mm")
                        }
                    }
                    cell.status.text = statusText
                }
            }
            return cell
        }
        return UITableViewCell()

        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }


    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("move row from:\(sourceIndexPath.row) to: \(destinationIndexPath.row)")
        ProgramManager.instance.replaceProviders(from:sourceIndexPath.row,  to:destinationIndexPath.row)
    }
    
    
}

extension EpgProvidersVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let epgEditVC = self.storyboard?.instantiateViewController(withIdentifier: "EpgProviderEditVC") as? EpgProviderEditVC {
            if indexPath.row < ProgramManager.instance.epgProviders.count  {
                epgEditVC.providerInfo = ProgramManager.instance.epgProviders[indexPath.row]
                self.navigationController?.pushViewController(epgEditVC, animated: true)
            }
        }

    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }

    
    
}
