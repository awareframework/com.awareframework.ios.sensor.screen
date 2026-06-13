//
//  ScreenSensor.swift
//  com.aware.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/10/23.
//

import UIKit
import com_awareframework_ios_core

extension Notification.Name {
    public static let actionAwareScreen = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN)
    public static let actionAwareScreenStart = Notification.Name(
        ScreenSensor.ACTION_AWARE_SCREEN_START)
    public static let actionAwareScreenStop = Notification.Name(
        ScreenSensor.ACTION_AWARE_SCREEN_STOP)
    public static let actionAwareScreenSync = Notification.Name(
        ScreenSensor.ACTION_AWARE_SCREEN_SYNC)
    public static let actionAwareScreenSetLabel = Notification.Name(
        ScreenSensor.ACTION_AWARE_SCREEN_SET_LABEL)

    public static let actionAwareScreenOn = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_ON)
    public static let actionAwareScreenOff = Notification.Name(ScreenSensor.ACTION_AWARE_SCREEN_OFF)
    public static let actionAwareScreenLocked = Notification.Name(
        ScreenSensor.ACTION_AWARE_SCREEN_LOCKED)
    public static let actionAwareScreenUnlocked = Notification.Name(
        ScreenSensor.ACTION_AWARE_SCREEN_UNLOCKED)

    public static let actionAwareScreenSyncCompletion = Notification.Name(
        ScreenSensor.ACTION_AWARE_SCREEN_SYNC_COMPLETION)

}

public protocol ScreenObserver {
    func onScreenOn()
    func onScreenOff()
    func onScreenLocked()
    func onScreenUnlocked()
    func onScreenBrightnessChanged(data: ScreenBrightnessData)
}

public class ScreenSensor: AwareSensor {

    public static let TAG = "AWARE::Screen"

    public static let ACTION_AWARE_SCREEN = "com.awareframework.ios.sensor.screen"
    public static let ACTION_AWARE_SCREEN_START =
        "com.awareframework.ios.sensor.screen.SENSOR_START"
    public static let ACTION_AWARE_SCREEN_STOP = "com.awareframework.ios.sensor.screen.SENSOR_STOP"
    public static let ACTION_AWARE_SCREEN_SET_LABEL =
        "com.awareframework.ios.sensor.screen.SET_LABEL"
    public static let EXTRA_LABEL = "label"
    public static let ACTION_AWARE_SCREEN_SYNC = "com.awareframework.ios.sensor.screen.SENSOR_SYNC"

    public static let ACTION_AWARE_SCREEN_SYNC_COMPLETION =
        "com.awareframework.ios.sensor.screeen.SENSOR_SYNC_COMPLETION"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
    public static let EXTRA_OBJECT_TYPE = "objectType"
    public static let EXTRA_TABLE_NAME = "tableName"

    /**
     * Broadcasted event: screen is on
     */
    public static let ACTION_AWARE_SCREEN_ON =
        "com.awareframework.ios.sensor.screen.ACTION_AWARE_SCREEN_ON"

    /**
     * Broadcasted event: screen is off
     */
    public static let ACTION_AWARE_SCREEN_OFF =
        "com.awareframework.ios.sensor.screen.ACTION_AWARE_SCREEN_OFF"

    /**
     * Broadcasted event: screen is locked
     */
    public static let ACTION_AWARE_SCREEN_LOCKED =
        "com.awareframework.ios.sensor.screen.ACTION_AWARE_SCREEN_LOCKED"

    /**
     * Broadcasted event: screen is unlocked
     */
    public static let ACTION_AWARE_SCREEN_UNLOCKED =
        "com.awareframework.ios.sensor.screen.ACTION_AWARE_SCREEN_UNLOCKED"

    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_AWARE_TOUCH_CLICKED =
        "com.awareframework.ios.sensor.screen.ACTION_AWARE_TOUCH_CLICKED"

    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_AWARE_TOUCH_LONG_CLICKED =
        "com.awareframework.ios.sensor.screen.ACTION_AWARE_TOUCH_LONG_CLICKED"

    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_AWARE_TOUCH_SCROLLED_UP =
        "com.awareframework.ios.sensor.screen.ACTION_AWARE_TOUCH_SCROLLED_UP"

    /**
     * NOTE: Does not support on iOS
     */
    public static let ACTION_AWARE_TOUCH_SCROLLED_DOWN =
        "com.awareframework.ios.sensor.screen.ACTION_AWARE_TOUCH_SCROLLED_DOWN"

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

    var screenBrigthnessObserver: NSObjectProtocol? = nil

    var timer: Timer? = nil

    var LAST_VALUE: Double = 0

    public var CONFIG = Config()

    public class Config: SensorConfig {
        public var sensorObserver: ScreenObserver? = nil

        public override init() {
            super.init()
            dbPath = "aware_screen"
        }

        public func apply(closure: (_ config: ScreenSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }

    public override convenience init() {
        self.init(ScreenSensor.Config())
    }

    public init(_ config: ScreenSensor.Config) {
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
        super.syncConfig = DbSyncConfig().apply { syncConfig in
            syncConfig.serverType = config.serverType
            syncConfig.debug = config.debug
            syncConfig.batchSize = 1000
            syncConfig.dispatchQueue = DispatchQueue(
                label: "com.awareframework.ios.sensor.screen.sync.queue")
            syncConfig.completionHandler = { status, error in
                var userInfo: [String: Any] = [ScreenSensor.EXTRA_STATUS: status]
                if let error = error {
                    userInfo[ScreenSensor.EXTRA_ERROR] = error
                }
                self.notificationCenter.post(
                    name: .actionAwareScreenSyncCompletion, object: self, userInfo: userInfo)
            }
        }
        initializeTables()
    }

    deinit {
        if let observer = self.screenBrigthnessObserver {
            self.notificationCenter.removeObserver(observer)
        }
    }

    var LAST_SCREEN_STATE = false

    public override func start() {
        setDeviceLockEventbserver()
        self.notificationCenter.post(name: .actionAwareScreenStart, object: self)
        self.screenBrigthnessObserver = self.notificationCenter.addObserver(
            forName: UIScreen.brightnessDidChangeNotification, object: nil, queue: .main
        ) { (notification) in
            self.screenBrightnessChanged()

            if UIScreen.main.brightness == 0.0 {
                if self.LAST_SCREEN_STATE == true {
                    self.screenOff()
                    self.LAST_SCREEN_STATE = false
                }
            } else {
                if self.LAST_SCREEN_STATE == false {
                    self.screenOn()
                    self.LAST_SCREEN_STATE = true
                }
            }
        }
    }

    public override func stop() {
        removeDeviceLockEventbserver()
        self.notificationCenter.post(name: .actionAwareScreenStop, object: self)
        if let observer = self.screenBrigthnessObserver {
            self.notificationCenter.removeObserver(observer)
            self.screenBrigthnessObserver = nil
        }
    }

    public override func sync(force: Bool = false) {
        guard let syncConfig = super.syncConfig else {
            return
        }

        self.notificationCenter.post(name: .actionAwareScreenSync, object: self)
        self.startSequentialSync(
            for: [ScreenData.TABLE_NAME, ScreenBrightnessData.TABLE_NAME],
            syncConfig: syncConfig,
            currentIndex: 0,
            hasFailure: false,
            lastError: nil)
    }

    var lastEventTimestamp: Double = 0

    func setDeviceLockEventbserver() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            displayStatusChangedCallback,
            "com.apple" + ".springboard.lockcomplete" as CFString,
            nil,
            .deliverImmediately)
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            displayStatusChangedCallback,
            "com.apple" + ".springboard.lockstate" as CFString,
            nil,
            .deliverImmediately)
    }

    func removeDeviceLockEventbserver() {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque(), nil,
            nil)
    }

    private let displayStatusChangedCallback: CFNotificationCallback = {
        _, cfObserver, cfName, _, _ in
        guard let lockState = cfName?.rawValue as String? else {
            return
        }
        guard let cfObserver else {
            return
        }
        let catcher = Unmanaged<ScreenSensor>.fromOpaque(
            UnsafeRawPointer(cfObserver)
        ).takeUnretainedValue()
        DispatchQueue.main.async {
            catcher.displayStatusChanged(lockState)
        }
    }

    private func displayStatusChanged(_ lockState: String) {
        // print(Date().timeIntervalSince1970, "lockState = \(lockState)")
        if lockState == "com.apple." + "springboard.lockcomplete" {
            self.screenLocked()
        } else {
            self.screenUnlocked()
        }
        self.notificationCenter.post(name: .actionAwareScreen, object: self)
    }

    func screenLocked() {
        var screenData = ScreenData()
        screenData.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        screenData.screenStatus = ScreenSensor.STATUS_SCREEN_LOCKED
        screenData.label = self.CONFIG.label
        self.saveModels([screenData])
        if self.CONFIG.debug { print(ScreenSensor.TAG, "locked") }
        if let observer = self.CONFIG.sensorObserver {
            observer.onScreenLocked()
        }
        self.notificationCenter.post(name: .actionAwareScreenLocked, object: self)
        // set last event timestamp for ignore a screenUnlock event after a screenLock event
        lastEventTimestamp = Date().timeIntervalSince1970
        if let t = self.timer {
            t.invalidate()
            self.timer = nil
        }
    }

    func screenUnlocked() {
        var screenData = ScreenData()
        screenData.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        screenData.label = self.CONFIG.label
        if lastEventTimestamp + 0.1 < Date().timeIntervalSince1970 {
            screenData.screenStatus = ScreenSensor.STATUS_SCREEN_UNLOCKED
            self.saveModels([screenData])
            if self.CONFIG.debug { print(ScreenSensor.TAG, "unlocked") }
            if let observer = self.CONFIG.sensorObserver {
                observer.onScreenUnlocked()
            }
            self.notificationCenter.post(name: .actionAwareScreenUnlocked, object: self)
            if self.timer == nil {
                self.timer = Timer.scheduledTimer(
                    withTimeInterval: 60.0, repeats: true,
                    block: { (timer) in
                        self.screenBrightnessChanged()
                    })
                self.screenBrightnessChanged()
            }
        }
    }

    func screenOn() {
        var screenData = ScreenData()
        screenData.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        screenData.label = self.CONFIG.label
        screenData.screenStatus = ScreenSensor.STATUS_SCREEN_ON
        self.saveModels([screenData])
        if self.CONFIG.debug { print(ScreenSensor.TAG, "screen on") }
        if let observer = self.CONFIG.sensorObserver {
            observer.onScreenOn()
        }
        self.notificationCenter.post(name: .actionAwareScreenOn, object: self)
    }

    func screenOff() {
        var screenData = ScreenData()
        screenData.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        screenData.label = self.CONFIG.label
        screenData.screenStatus = ScreenSensor.STATUS_SCREEN_OFF
        self.saveModels([screenData])
        if self.CONFIG.debug { print(ScreenSensor.TAG, "screen off") }
        if let observer = self.CONFIG.sensorObserver {
            observer.onScreenOff()
        }
        self.notificationCenter.post(name: .actionAwareScreenOff, object: self)
    }

    func screenBrightnessChanged() {

        let brightness = Double(UIScreen.main.brightness)

        // print("gap",fabs(LAST_VALUE - brightness))
        if fabs(LAST_VALUE - brightness) > 0.1 {  // 10%
            var data = ScreenBrightnessData()
            data.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            data.brightness = brightness
            data.label = self.CONFIG.label
            if let observer = self.CONFIG.sensorObserver {
                observer.onScreenBrightnessChanged(data: data)
            }
            self.saveModels([data])
            LAST_VALUE = brightness
        }
    }

    public override func set(label: String) {
        self.CONFIG.label = label
        self.notificationCenter.post(
            name: .actionAwareScreenSetLabel, object: self,
            userInfo: [ScreenSensor.EXTRA_LABEL: label])
    }

    private func initializeTables() {
        guard let queue = (self.dbEngine as? SQLiteEngine)?.getSQLiteInstance() else {
            return
        }

        do {
            try ScreenData.createTable(queue: queue)
            try ScreenBrightnessData.createTable(queue: queue)
        } catch {
            if self.CONFIG.debug { print(error) }
        }
    }

    private func saveModels<T: BaseDbModelSQLite>(_ models: [T]) {
        guard let engine = self.dbEngine as? SQLiteEngine else {
            return
        }
        engine.save(models)
    }

    private func makeSyncConfig(
        from baseConfig: DbSyncConfig, completionHandler: DbSyncCompletionHandler?
    ) -> DbSyncConfig {
        let syncConfig = DbSyncConfig()
        syncConfig.removeAfterSync = baseConfig.removeAfterSync
        syncConfig.batchSize = baseConfig.batchSize
        syncConfig.markAsSynced = baseConfig.markAsSynced
        syncConfig.skipSyncedData = baseConfig.skipSyncedData
        syncConfig.keepLastData = baseConfig.keepLastData
        syncConfig.deviceId = baseConfig.deviceId
        syncConfig.debug = baseConfig.debug
        syncConfig.debugLevel = baseConfig.debugLevel
        syncConfig.progressHandler = baseConfig.progressHandler
        syncConfig.dispatchQueue = baseConfig.dispatchQueue
        syncConfig.backgroundSession = baseConfig.backgroundSession
        syncConfig.compactDataFormat = baseConfig.compactDataFormat
        syncConfig.serverType = baseConfig.serverType
        syncConfig.test = baseConfig.test
        syncConfig.completionHandler = completionHandler
        return syncConfig
    }

    private func makeSyncEngine(for tableName: String) -> Engine {
        return Engine.Builder()
            .setPath(self.CONFIG.dbPath)
            .setType(self.CONFIG.dbType)
            .setHost(self.CONFIG.dbHost)
            .setEncryptionKey(self.CONFIG.dbEncryptionKey)
            .setTableName(tableName)
            .build()
    }

    private func startSequentialSync(
        for tables: [String],
        syncConfig: DbSyncConfig,
        currentIndex: Int,
        hasFailure: Bool,
        lastError: Error?
    ) {
        if currentIndex >= tables.count {
            syncConfig.completionHandler?(hasFailure == false, lastError)
            return
        }

        let tableName = tables[currentIndex]
        let engine = self.makeSyncEngine(for: tableName)
        let perTableConfig = self.makeSyncConfig(from: syncConfig) { status, error in
            var userInfo: [String: Any] = [
                ScreenSensor.EXTRA_STATUS: status,
                ScreenSensor.EXTRA_TABLE_NAME: tableName,
            ]
            if tableName == ScreenData.TABLE_NAME {
                userInfo[ScreenSensor.EXTRA_OBJECT_TYPE] = ScreenData.self
            } else {
                userInfo[ScreenSensor.EXTRA_OBJECT_TYPE] = ScreenBrightnessData.self
            }
            if let error = error {
                userInfo[ScreenSensor.EXTRA_ERROR] = error
            }
            self.notificationCenter.post(
                name: .actionAwareScreenSyncCompletion, object: self, userInfo: userInfo)

            self.startSequentialSync(
                for: tables,
                syncConfig: syncConfig,
                currentIndex: currentIndex + 1,
                hasFailure: hasFailure || status == false,
                lastError: error ?? lastError)
        }
        engine.startSync(perTableConfig)
    }
}
