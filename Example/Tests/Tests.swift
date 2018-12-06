import XCTest
import RealmSwift
import com_awareframework_ios_sensor_screen

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
    
    func testSync(){
        //        let sensor = ScreenSensor.init(ScreenSensor.Config().apply{ config in
        //            config.debug = true
        //            config.dbType = .REALM
        //        })
        //        sensor.start();
        //        sensor.enable();
        //        sensor.sync(force: true)
        
        //        let syncManager = DbSyncManager.Builder()
        //            .setBatteryOnly(false)
        //            .setWifiOnly(false)
        //            .setSyncInterval(1)
        //            .build()
        //
        //        syncManager.start()
    }
    
    func testObserver(){

        class Observer:ScreenObserver{
            
            weak var screenLockedExpectation: XCTestExpectation?
            weak var screenUnlockedExpectation: XCTestExpectation?
            
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
            
        }
        
        let lockObserverExpect = expectation(description: "lock observer")
        let unlockObserverExpect = expectation(description: "unlock observer")
        let observer = Observer()
        
        observer.screenLockedExpectation = lockObserverExpect
        observer.screenUnlockedExpectation = unlockObserverExpect
        let sensor = ScreenSensor.init(ScreenSensor.Config().apply{ config in
            config.sensorObserver = observer
            config.debug = true
        })
        sensor.start()
        
        sensor.screenLocked()
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (timer) in
            sensor.screenUnlocked()
        }
        
        wait(for: [lockObserverExpect, unlockObserverExpect], timeout: 3)
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
    
}
