//
//  ScreenSensor.swift
//  com.aware.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/10/23.
//

import UIKit
import com_awareframework_ios_sensor_core
import SwiftyJSON

extension Notification.Name {
    public static let actionAwareScreen       = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN)
    public static let actionAwareScreenStart  = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_START)
    public static let actionAwareScreenStop   = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_STOP)
    public static let actionAwareScreenSync   = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_SYNC)
    public static let actionAwareScreenSetLabel = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_SET_LABEL)
    
    public static let actionAwareScreenOn     = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_ON)
    public static let actionAwareScreenOff    = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_OFF)
    public static let actionAwareScreenLocked = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_LOCKED)
    public static let actionAwareScreenUnlocked  = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_UNLOCKED)
}

public protocol ScreenObserver{
    func onScreenOn()
    func onScreenOff()
    func onScreenLocked()
    func onScreenUnlocked()
}

public class ScreenSensor: AwareSensor {
    
    public static let TAG = "AWARE::Screen"
    
    public static let ACTION_AWARE_SCREEN = "com.awareframework.ios.sensor.screen"
    public static let ACTION_AWARE_SCREEN_START = "com.awareframework.ios.sensor.screen.SENSOR_START"
    public static let ACTION_AWARE_SCREEN_STOP = "com.awareframework.ios.sensor.screen.SENSOR_STOP"
    public static let ACTION_AWARE_SCREEN_SET_LABEL = "com.awareframework.ios.sensor.screen.SET_LABEL"
    public static let EXTRA_LABEL = "label"
    public static let ACTION_AWARE_SCREEN_SYNC = "com.awareframework.ios.sensor.screen.SENSOR_SYNC"
    
    /**
     * Broadcasted event: screen is on
     */
    public static let ACTION_AWARE_SCREEN_ON = "com.awareframework.ios.sensor.screen.ACTION_AWARE_SCREEN_ON"
    
    /**
     * Broadcasted event: screen is off
     */
    public static let ACTION_AWARE_SCREEN_OFF = "com.awareframework.ios.sensor.screen.ACTION_AWARE_SCREEN_OFF"
    
    /**
     * Broadcasted event: screen is locked
     */
    public static let ACTION_AWARE_SCREEN_LOCKED = "com.awareframework.ios.sensor.screen.ACTION_AWARE_SCREEN_LOCKED"
    
    /**
     * Broadcasted event: screen is unlocked
     */
    public static let ACTION_AWARE_SCREEN_UNLOCKED = "com.awareframework.ios.sensor.screen.ACTION_AWARE_SCREEN_UNLOCKED"
    
    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_AWARE_TOUCH_CLICKED = "com.awareframework.ios.sensor.screen.ACTION_AWARE_TOUCH_CLICKED"

    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_AWARE_TOUCH_LONG_CLICKED = "com.awareframework.ios.sensor.screen.ACTION_AWARE_TOUCH_LONG_CLICKED"
    
    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_AWARE_TOUCH_SCROLLED_UP = "com.awareframework.ios.sensor.screen.ACTION_AWARE_TOUCH_SCROLLED_UP"
    
    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_AWARE_TOUCH_SCROLLED_DOWN = "com.awareframework.ios.sensor.screen.ACTION_AWARE_TOUCH_SCROLLED_DOWN"
    
    /**
     * Screen status: OFF = 0
     */
    public static let STATUS_SCREEN_OFF = 0
    
    /**
     * Screen status: ON = 1
     */
    public static let STATUS_SCREEN_ON = 1
    
    /**
     * Screen status: LOCKED = 2
     */
    public static let STATUS_SCREEN_LOCKED = 2
    
    /**
     * Screen status: UNLOCKED = 3
     */
    public static let STATUS_SCREEN_UNLOCKED = 3
    
    
    public var CONFIG = Config()
    
    public class Config:SensorConfig {
        public var sensorObserver:ScreenObserver? = nil
        
        public override init(){
            super.init()
            dbPath = "aware_screen"
        }
        
        public func apply(closure:(_ config: ScreenSensor.Config ) -> Void ) -> Self {
            closure(self)
            return self
        }
    }
    
    public override convenience init() {
        self.init(ScreenSensor.Config())
    }
    
    public init(_ config:ScreenSensor.Config){
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
    }
    
    public override func start() {
        setDeviceLockEventbserver()
        self.notificationCenter.post(name: .actionAwareScreenStart, object: nil)
    }
    
    public override func stop() {
        removeDeviceLockEventbserver()
        self.notificationCenter.post(name: .actionAwareScreenStop,  object:nil)
    }
    
    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine {
            engine.startSync(ScreenData.TABLE_NAME, ScreenData.self, DbSyncConfig.init().apply{ config in
                config.debug = self.CONFIG.debug
            })
            self.notificationCenter.post(name: .actionAwareScreenSync, object: nil )
        }
    }
    
    var lastEventTimestamp:Double = 0
    
    func setDeviceLockEventbserver() {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        Unmanaged.passUnretained(self).toOpaque(),
                                        displayStatusChangedCallback,
                                        "com.apple"+".springboard.lockcomplete" as CFString,
                                        nil,
                                        .deliverImmediately)
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        Unmanaged.passUnretained(self).toOpaque(),
                                        displayStatusChangedCallback,
                                        "com.apple"+".springboard.lockstate" as CFString,
                                        nil,
                                        .deliverImmediately)
    }
    
    func removeDeviceLockEventbserver(){
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(), Unmanaged.passUnretained(self).toOpaque(), nil, nil)
    }
    
    private let displayStatusChangedCallback: CFNotificationCallback = { _, cfObserver, cfName, _, _ in
        guard let lockState = cfName?.rawValue as String? else {
            return
        }
        let catcher = Unmanaged<ScreenSensor>.fromOpaque(UnsafeRawPointer(OpaquePointer(cfObserver)!)).takeUnretainedValue()
        catcher.displayStatusChanged(lockState)
    }
    
    private func displayStatusChanged(_ lockState: String) {
        // print(Date().timeIntervalSince1970, "lockState = \(lockState)")
        if (lockState == "com.apple."+"springboard.lockcomplete") {
            self.screenLocked()
        } else {
            self.screenUnlocked()
        }
        self.notificationCenter.post(name: .actionAwareScreen, object: nil)
    }
    
    public func screenLocked(){
        let screenData = ScreenData()
        screenData.screenStatus = ScreenSensor.STATUS_SCREEN_LOCKED
        if let engine = self.dbEngine {
            engine.save(screenData, ScreenData.TABLE_NAME)
        }
        if self.CONFIG.debug { print("locked") }
        if let observer = self.CONFIG.sensorObserver{
            observer.onScreenLocked()
        }
        self.notificationCenter.post(name: .actionAwareScreenLocked, object: nil)
        // set last event timestamp for ignore a screenUnlock event after a screenLock event
        lastEventTimestamp = Date().timeIntervalSince1970
    }
    
    public func screenUnlocked(){
        let screenData = ScreenData()
        if(lastEventTimestamp + 0.1 < Date().timeIntervalSince1970){
            screenData.screenStatus = ScreenSensor.STATUS_SCREEN_UNLOCKED
            if let engine = self.dbEngine {
                engine.save(screenData, ScreenData.TABLE_NAME)
            }
            if self.CONFIG.debug { print("unlocked")}
            if let observer = self.CONFIG.sensorObserver{
                observer.onScreenUnlocked()
            }
            self.notificationCenter.post(name: .actionAwareScreenUnlocked, object: nil)
        }
    }
    
    public func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionAwareScreenSetLabel, object: nil, userInfo: [ScreenSensor.EXTRA_LABEL:label])
    }
}
