//
//  TimerSwitch.swift
//  tvorg
//
//  Created by Alexandr Kolganov on 05/11/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

//simple sheduleTimer with invalidate previos un
class TimerTask {
    
    var timer : Timer?
    
    
    func setTask(time: Double, block: @escaping (Timer) -> Void) {
        
        self.timer?.invalidate()
        
        self.timer = Timer.scheduledTimer(
            withTimeInterval: time,
            repeats: false,
            block: {(timer) in
                block(timer)
                self.timer = nil
            }
        )
    }
    
    func invalidate() {
        self.timer?.invalidate()
    }
    
  
    
}
