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
    public static let actionAwareScreenStart    = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_START)
    public static let actionAwareScreenStop    = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_STOP)
    public static let actionAwareScreenSync    = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_SYNC)
    
    public static let actionAwareScreenOn    = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_ON)
    public static let actionAwareScreenOff    = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_OFF)
    public static let actionAwareScreenLocked    = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_LOCKED)
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
    
    /**
     * Broadcasted event: screen is on
     */
    public static let ACTION_AWARE_SCREEN_ON = "ACTION_AWARE_SCREEN_ON"
    
    /**
     * Broadcasted event: screen is off
     */
    public static let ACTION_AWARE_SCREEN_OFF = "ACTION_AWARE_SCREEN_OFF"
    
    /**
     * Broadcasted event: screen is locked
     */
    public static let ACTION_AWARE_SCREEN_LOCKED = "ACTION_AWARE_SCREEN_LOCKED"
    
    /**
     * Broadcasted event: screen is unlocked
     */
    public static let ACTION_AWARE_SCREEN_UNLOCKED = "ACTION_AWARE_SCREEN_UNLOCKED"
    
    public static let ACTION_AWARE_TOUCH_CLICKED = "ACTION_AWARE_TOUCH_CLICKED"
    public static let ACTION_AWARE_TOUCH_LONG_CLICKED = "ACTION_AWARE_TOUCH_LONG_CLICKED"
    public static let ACTION_AWARE_TOUCH_SCROLLED_UP = "ACTION_AWARE_TOUCH_SCROLLED_UP"
    public static let ACTION_AWARE_TOUCH_SCROLLED_DOWN = "ACTION_AWARE_TOUCH_SCROLLED_DOWN"
    
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
    
    public static let ACTION_AWARE_SCREEN_START = "com.awareframework.android.sensor.screen.SENSOR_START"
    public static let ACTION_AWARE_SCREEN_STOP = "com.awareframework.android.sensor.screen.SENSOR_STOP"
    
    public static let ACTION_AWARE_SCREEN_SET_LABEL = "com.awareframework.android.sensor.screen.SET_LABEL"
    public static let EXTRA_LABEL = "label"
    
    public static let ACTION_AWARE_SCREEN_SYNC = "com.awareframework.android.sensor.screen.SENSOR_SYNC"
    
    var CONFIG = Config()
    
    public class Config:SensorConfig {
        public var sensorObserver:ScreenObserver? = nil
        
        public override init(){
            super.init()
            dbPath = "aware_screen"
        }
        
        public convenience init(_ json:JSON){
            self.init()
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
    }
    
    public override func stop() {
        removeDeviceLockEventbserver()
    }
    
    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine {
            engine.startSync(ScreenData.TABLE_NAME, DbSyncConfig.init().apply{ config in
                config.debug = self.CONFIG.debug
            } )
        }
    }
    
    ///////////////////
    
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
        let screenData = ScreenData()
        if (lockState == "com.apple."+"springboard.lockcomplete") {
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
        } else {
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
    }

}
