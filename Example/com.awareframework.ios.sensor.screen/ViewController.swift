//
//  ViewController.swift
//  com.awareframework.ios.sensor.screen
//
//  Created by tetujin on 11/20/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

import UIKit
import com_awareframework_ios_sensor_screen

class ViewController: UIViewController {

    var sensor:ScreenSensor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        sensor = ScreenSensor.init(ScreenSensor.Config().apply{config in
            config.debug = true
            config.sensorObserver = Observer()
        })
        sensor?.start()
    }

    class Observer:ScreenObserver {
        func onScreenOn() {
            print(#function)
        }
        
        func onScreenOff() {
            print(#function)
        }
        
        func onScreenLocked() {
            print(#function)
        }
        
        func onScreenUnlocked() {
            print(#function)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

