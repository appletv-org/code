//
//  ProgramProviders.swift
//  iptv
//
//  Created by Alexandr Kolganov on 20.10.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import CoreData

class EpgProviderSettingVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var urlField: UITextField!
    
    var focusedProvider: EpgProviderInfo? = nil
    
    @IBAction func saveAction(_ sender: AnyObject) {
        
        save()
    }
    
    @IBAction func Save_Update(_ sender: AnyObject) {
        if(save()) {
            update()
        }
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.remembersLastFocusedIndexPath = true
        
        let providers = ProgramManager.instance.epgProviders
        if providers.count > 0 {
            let provider = providers[0]
            loadFields(provider)
        }
        viewToFocus = self.tableView
    }
    
    
    var viewToFocus: UIView? = nil {
        didSet {
            if viewToFocus != nil {
                self.setNeedsFocusUpdate();
                self.updateFocusIfNeeded();
            }
        }
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        var ret = super.preferredFocusEnvironments
        if viewToFocus != nil {
            ret = [viewToFocus!]
            viewToFocus = nil
        }
        return ret
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        let nextFocusedItem = context.nextFocusedItem
        let prevFocusedItem = context.previouslyFocusedItem
        
        let nextCellItem = nextFocusedItem as? UITableViewCell
        let prevCellItem = prevFocusedItem as? UITableViewCell
        
        if nextCellItem != nil {
            //reload edit form for provider and change select color
            if let indexPath = tableView.indexPath(for: nextCellItem!) {
                let epgProviders = ProgramManager.instance.epgProviders
            
                if(indexPath.row < epgProviders.count) {
                    focusedProvider = epgProviders[indexPath.row]
                }
                else {
                    focusedProvider = nil
                }
                loadFields(focusedProvider)
                nextCellItem!.textLabel?.textColor = UIColor.blue
                
            }
        }
        
        if prevCellItem != nil && nextCellItem != nil {
            prevCellItem!.textLabel?.textColor = UIColor.black
        }
    
    }
    
    func save() -> Bool {
        if (nameField.text?.isEmpty)!  {
            self.showAlertError(title: "Error", message: "Empty name")
            return false
        }
        if (urlField.text?.isEmpty)!  {
            self.showAlertError(title: "Error", message: "Empty url")
            return false
        }
        
        
        if(focusedProvider == nil) {
            focusedProvider = EpgProviderInfo()
            ProgramManager.instance.epgProviders.append(focusedProvider!)
            saveFields(focusedProvider!)
            tableView.reloadData()
            
        }
        else {
            saveFields(focusedProvider!)
        }
        ProgramManager.instance.save()
        return true
        
    }
    
    func update() {
        ProgramManager.instance.updateProvider(focusedProvider!)
    }
    
    func loadFields(_ provider:EpgProviderInfo?) {
        if(provider == nil) {
            nameField.text = ""
            urlField.text = ""
        }
        else {
            nameField.text = provider!.name
            urlField.text = provider!.url
        }
    }
    
    func saveFields(_ provider:EpgProviderInfo) {
        provider.name = nameField.text!
        provider.url = urlField.text!
    }
    
    
    /*
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [tableView]
    }
     */

    
}


extension EpgProviderSettingVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ProgramManager.instance.epgProviders.count + 1
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpgProviderCell")!
        
        let providers = ProgramManager.instance.epgProviders
        if indexPath.row < providers.count {
            cell.textLabel!.text = providers[indexPath.row].name
        }
        else {
            cell.textLabel!.text = "New EPG provider"
        }
        return cell
        
    }
    
    
    
}

extension EpgProviderSettingVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
        let alertController = UIAlertController(title: "iOScreator", message:
            "Hello, world!", preferredStyle: UIAlertControllerStyle.alert)
        
        self.present(alertController, animated: true, completion: nil)
         */
        
    }
}
