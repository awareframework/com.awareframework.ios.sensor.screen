import XCTest
import RealmSwift
@testable import com_awareframework_ios_sensor_screen
import com_awareframework_ios_sensor_core

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testObserver(){

        class Observer:ScreenObserver{
            weak var screenLockedExpectation: XCTestExpectation?
            weak var screenUnlockedExpectation: XCTestExpectation?
            weak var screenBrightnessExpectation: XCTestExpectation?
            
            func onScreenOn() {
                //
            }
            
            func onScreenOff() {
                //
            }
            
            func onScreenLocked() {
                screenLockedExpectation?.fulfill()
                print("lock")
            }
            
            func onScreenUnlocked() {
                screenUnlockedExpectation?.fulfill()
                print("unlock")
            }
            
            func onScreenBrightnessChanged(data: ScreenBrightnessData) {
                screenBrightnessExpectation?.fulfill()
                print(data)
            }
            
        }
        
        let lockObserverExpect = expectation(description: "lock observer")
        let unlockObserverExpect = expectation(description: "unlock observer")
        let brightnessObserverExpect = expectation(description: "brightness observer")
        let observer = Observer()
        
        observer.screenLockedExpectation = lockObserverExpect
        observer.screenUnlockedExpectation = unlockObserverExpect
        observer.screenBrightnessExpectation = brightnessObserverExpect
        let sensor = ScreenSensor.init(ScreenSensor.Config().apply{ config in
            config.sensorObserver = observer
            config.debug = true
        })
        sensor.start()
        
        sensor.screenLocked()
        sensor.screenBrightnessChanged()
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (timer) in
            sensor.screenUnlocked()
        }
        
        wait(for: [lockObserverExpect, unlockObserverExpect, brightnessObserverExpect], timeout: 3)
        sensor.stop()
        
    }
    
    func testControllers(){
        
        let sensor = ScreenSensor.init()
        
        /// test set label action ///
        let expectSetLabel = expectation(description: "set label")
        let newLabel = "hello"
        let labelObserver = NotificationCenter.default.addObserver(forName: .actionAwareScreenSetLabel, object: nil, queue: .main) { (notification) in
            let dict = notification.userInfo;
            if let d = dict as? Dictionary<String,String>{
                XCTAssertEqual(d[ScreenSensor.EXTRA_LABEL], newLabel)
            }else{
                XCTFail()
            }
            expectSetLabel.fulfill()
        }
        sensor.set(label:newLabel)
        wait(for: [expectSetLabel], timeout: 5)
        NotificationCenter.default.removeObserver(labelObserver)
        
        /// test sync action ////
        let expectSync = expectation(description: "sync")
        let syncObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareScreenSync , object: nil, queue: .main) { (notification) in
            expectSync.fulfill()
            print("sync")
        }
        sensor.sync()
        wait(for: [expectSync], timeout: 5)
        NotificationCenter.default.removeObserver(syncObserver)
        
        //// test start action ////
        let expectStart = expectation(description: "start")
        let observer = NotificationCenter.default.addObserver(forName: .actionAwareScreenStart,
                                                              object: nil,
                                                              queue: .main) { (notification) in
                                                                expectStart.fulfill()
                                                                print("start")
        }
        sensor.start()
        wait(for: [expectStart], timeout: 5)
        NotificationCenter.default.removeObserver(observer)
        
        
        /// test stop action ////
        let expectStop = expectation(description: "stop")
        let stopObserver = NotificationCenter.default.addObserver(forName: .actionAwareScreenStop, object: nil, queue: .main) { (notification) in
            expectStop.fulfill()
            print("stop")
        }
        sensor.stop()
        wait(for: [expectStop], timeout: 5)
        NotificationCenter.default.removeObserver(stopObserver)

    }
    
    func testScreenData(){
        let data = ScreenData()
        let dict = data.toDictionary()
        XCTAssertEqual(dict["screenStatus"] as! Int, -1)
        
        data.screenStatus = 1
        let newDict = data.toDictionary()
        XCTAssertEqual(newDict["screenStatus"] as! Int, 1)
    }
    
    func testSyncModule(){
        #if targetEnvironment(simulator)
        
        print("This test requires a real Screen.")
        
        #else
        // success //
        let sensor = ScreenSensor.init(ScreenSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com:1001"
            config.dbPath = "sync_db"
        })
        if let engine = sensor.dbEngine as? RealmEngine {
            engine.removeAll(ScreenData.self)
            for _ in 0..<100 {
                engine.save(ScreenData())
            }
        }
        let successExpectation = XCTestExpectation(description: "success sync")
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareScreenSyncCompletion,
                                                              object: sensor, queue: .main) { (notification) in
                                                                if let userInfo = notification.userInfo{
                                                                    if let status = userInfo["status"] as? Bool {
                                                                        if status == true {
                                                                            successExpectation.fulfill()
                                                                        }
                                                                    }
                                                                }
        }
        sensor.sync(force: true)
        wait(for: [successExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(observer)
        
        ////////////////////////////////////
        
        // failure //
        let sensor2 = ScreenSensor.init(ScreenSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com.com" // wrong url
            config.dbPath = "sync_db"
        })
        let failureExpectation = XCTestExpectation(description: "failure sync")
        let failureObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareScreenSyncCompletion,
                                                                     object: sensor2, queue: .main) { (notification) in
                                                                        if let userInfo = notification.userInfo{
                                                                            if let status = userInfo["status"] as? Bool {
                                                                                if status == false {
                                                                                    failureExpectation.fulfill()
                                                                                }
                                                                            }
                                                                        }
        }
        if let engine = sensor2.dbEngine as? RealmEngine {
            engine.removeAll(ScreenData.self)
            for _ in 0..<100 {
                engine.save(ScreenData())
            }
        }
        sensor2.sync(force: true)
        wait(for: [failureExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(failureObserver)
        
        #endif
    }

}
