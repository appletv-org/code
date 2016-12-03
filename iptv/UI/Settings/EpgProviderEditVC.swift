//
//  ProgramProviders.swift
//  iptv
//
//  Created by Alexandr Kolganov on 20.10.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import CoreData


struct TimeShift {
    
    var sign : Bool = true // plus
    var hour : Int = 0
    var minute : Int = 0
    
    init(_ number:Int = 0) {
        self.fromInt(number)
    }
    
    mutating func fromInt(_ number: Int) {
        sign = true
        var rest = number / 60
        if rest < 0 {
            sign = false
            rest = -rest
        }
        minute = rest % 60
        hour = rest / 60
    }
    
    func toInt() -> Int {
        var number = (hour*60 + minute)*60
        return sign ? number : -number
    }
    
}



struct UpdateTime {
    static let days = [ "Never",
                        "Everyday",
                        "Sunday",
                        "Monday",
                        "Tuesday",
                        "Wendesday",
                        "Thursday",
                        "Friday",
                        "Saturday"
                        ]
    
    var day : Int = 0 //-1 - Never, 0-Everyday, 1-Sunday, ..., 7-Saturday
    var hour : Int = 0
    var minute : Int = 0
    
    init(_ number:Int = 0) {
        self.fromInt(number)
    }

    
    mutating func fromInt(_ number: Int) {
        
        if number < 0 {
            day = -1
            hour = 0
            minute = 0
        }
        else {
            var rest = number / 60 //minutes
            minute = rest % 60
            rest = rest / 60     //hours
            hour = rest % 24
            rest = rest / 24     //days
            day = rest
        }
    }
    
    func toInt() -> Int {
        if day < 0  {
            return -1
        }
        else {
            return ((day * 24 + hour)*60 + minute) * 60
        }
    }
                       
    
}

class EpgProviderEditVC: UIViewController {
    
    
    static let useForVariants = ["Channel logo & TV programs", "Only TV programs" , "Only channel logo"]
    
    var providerInfo: EpgProviderInfo? = nil
    var shiftTime =  TimeShift()
    var updateTime = UpdateTime()
    var useForIndex = 0
    
    
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var urlField: UITextField!
    
    //update settings
    @IBOutlet weak var updateDayButton: UIButton!
    @IBAction func updateDayAction(_ sender: UIButton) {
        self.simpleAlertChooser(title: "Choose update day", message: "" , buttonTitles: UpdateTime.days, completion:  { (ind) in
            self.updateTime.day = ind-1
            self.updateDayButton.setTitle(UpdateTime.days[ind], for: .normal)
            print("you choose \(UpdateTime.days[ind])")
        })
    }
    @IBOutlet weak var updateHourField: UITextField!
    
    @IBOutlet weak var updateMinutesField: UITextField!
    
    @IBOutlet weak var updateNowButton: UIButton!
    @IBAction func updateNowAction(_ sender: UIButton) {
        if providerInfo != nil {
            ProgramManager.instance.updateData(providerInfo!)
        }
    }
    
    @IBOutlet weak var clearButton: UIButton!
    @IBAction func clearAction(_ sender: UIButton) {
        if providerInfo != nil {
            ProgramManager.instance.clearData(providerInfo!)
        }

    }
    
    //Time shift
    @IBOutlet weak var shiftSignButton: UIButton!
    @IBAction func signAction(_ sender: UIButton) {
        shiftTime.sign = !shiftTime.sign
        shiftSignButton.setTitle(shiftTime.sign ? "+" : "-", for: .normal)
    }
    @IBOutlet weak var shiftHourField: UITextField!
    @IBOutlet weak var shiftMinutesField: UITextField!
    
    @IBOutlet weak var useForButton: UIButton!
    @IBAction func useForAction(_ sender: UIButton) {
        self.simpleAlertChooser(title: "Select the purpose for which the provider is used", message: "" ,
                                buttonTitles: EpgProviderEditVC.useForVariants,
                                completion:  { (ind) in
            self.useForIndex = ind
            self.useForButton.setTitle(EpgProviderEditVC.useForVariants[ind], for: .normal)
        })
    }
    
    
    @IBOutlet weak var errorLabel: UILabel!
    
    
    @IBAction func saveAction(_ sender: AnyObject) {
        let err = save()
        if err != nil {
            errorLabel.text = errMsg(err!)
            errorLabel.textColor = UIColor.red
        }
        else {
            _ = self.navigationController?.popViewController(animated: true) 
        }
    }
    
    @IBOutlet weak var deleteButton: UIButton!
    @IBAction func deleteAction(_ sender: Any) {
        if providerInfo != nil {
            _ = ProgramManager.instance.delProvider(providerInfo!.name)
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //viewToFocus = self.nameField
        if providerInfo != nil {
            shiftTime.fromInt(providerInfo!.shiftTime)
            updateTime.fromInt(providerInfo!.updateTime)
            loadFields(providerInfo)
            addNavigationTitle(providerInfo!.name)
            
            
        }
        else {
            addNavigationTitle("New provider")
        }
        
        if providerInfo == nil {
            deleteButton.isEnabled = false
        }
        
        
        updateHourField.delegate = self
        updateMinutesField.delegate = self
        shiftHourField.delegate = self
        shiftMinutesField.delegate = self
        
        if  providerInfo != nil,
                    let dbProvider = ProgramManager.instance.getDbProvider(providerInfo!.name),
                    let errorText = dbProvider.error {
            errorLabel.text = "error: " + errorText
        }
        
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
        
    }
    
    func save() -> Error? {
        
        let newProviderInfo = EpgProviderInfo()
        saveFields(newProviderInfo)
        var err : Error?
        if(providerInfo == nil) {
            err = ProgramManager.instance.addProvider(newProviderInfo)
        }
        else {
            err = ProgramManager.instance.updateProvider(name:providerInfo!.name, provider:newProviderInfo)
        }
        
        return err
        
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
        shiftSignButton.setTitle(shiftTime.sign ? "+" : "-",  for: .normal)
        shiftHourField.text = String(format:"%02d", shiftTime.hour)
        shiftMinutesField.text = String(format:"%02d", shiftTime.minute)
        
        updateDayButton.setTitle(UpdateTime.days[updateTime.day + 1], for: .normal)
        updateHourField.text = String(format:"%02d", updateTime.hour)
        updateMinutesField.text = String(format:"%02d", updateTime.minute)
        
        useForIndex = 0
        if !provider!.parseIcons {
            useForIndex = 1
        }
        if !provider!.parseProgram {
            useForIndex = 2
        }
        useForButton.setTitle(EpgProviderEditVC.useForVariants[useForIndex], for: .normal)
        
    }
    
    
    
    
    func saveFields(_ provider:EpgProviderInfo) {
        provider.name = nameField.text!
        provider.url = urlField.text!
    
        provider.shiftTime = shiftTime.toInt()
        provider.updateTime = updateTime.toInt()
        
        provider.parseIcons =  (useForIndex == 0 || useForIndex == 2)
        provider.parseProgram =  (useForIndex == 0 || useForIndex == 1)
        
    }
    
    func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.textColor = UIColor.red
    }
    
}

extension EpgProviderEditVC: UITextFieldDelegate {
    
    
    func checkHours(textField:UITextField, property:inout Int) {
        let num = Int(textField.text!)
        if num! < 0 || num! > 23  {
            showError("The hours must be in range 0-23")
        }
        else {
            property = num!
        }
        textField.text = String(format:"%02d", property)
    }
    
    func checkMinutes(textField:UITextField, property:inout Int) {
        let num = Int(textField.text!)
        if num! < 0 || num! > 59  {
            showError("The minutes must be in range 0-59")
        }
        else {
            property = num!
        }
        textField.text = String(format:"%02d", property)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {

        switch(textField) {
        case self.updateHourField:
            checkHours(textField:textField, property:&(updateTime.hour))
        case self.shiftHourField:
            checkHours(textField:textField, property:&(shiftTime.hour))
        case self.updateMinutesField:
            checkMinutes(textField:textField, property:&(updateTime.minute))
        case self.shiftMinutesField:
            checkMinutes(textField:textField, property:&(shiftTime.minute))
        default:
            break
        }
    }
    
    
}

