import XCTest

@testable import com_awareframework_ios_sensor_screen

class Tests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testObserver() {

        class Observer: ScreenObserver {
            weak var screenLockedExpectation: XCTestExpectation?
            weak var screenUnlockedExpectation: XCTestExpectation?
            weak var screenBrightnessExpectation: XCTestExpectation?

            func onScreenOn() {
            }

            func onScreenOff() {
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
        let sensor = ScreenSensor.init(ScreenSensor.Config().apply { config in
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

    func testControllers() {

        let sensor = ScreenSensor.init()

        /// test set label action ///
        let expectSetLabel = expectation(description: "set label")
        let newLabel = "hello"
        let labelObserver = NotificationCenter.default.addObserver(
            forName: .actionAwareScreenSetLabel, object: nil, queue: .main
        ) { (notification) in
            let dict = notification.userInfo
            if let d = dict as? [String: String] {
                XCTAssertEqual(d[ScreenSensor.EXTRA_LABEL], newLabel)
            } else {
                XCTFail()
            }
            expectSetLabel.fulfill()
        }
        sensor.set(label: newLabel)
        wait(for: [expectSetLabel], timeout: 5)
        NotificationCenter.default.removeObserver(labelObserver)

        /// test sync action ////
        let expectSync = expectation(description: "sync")
        let syncObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name.actionAwareScreenSync, object: nil, queue: .main
        ) { (notification) in
            expectSync.fulfill()
            print("sync")
        }
        sensor.sync()
        wait(for: [expectSync], timeout: 5)
        NotificationCenter.default.removeObserver(syncObserver)

        //// test start action ////
        let expectStart = expectation(description: "start")
        let observer = NotificationCenter.default.addObserver(
            forName: .actionAwareScreenStart,
            object: nil,
            queue: .main
        ) { (notification) in
            expectStart.fulfill()
            print("start")
        }
        sensor.start()
        wait(for: [expectStart], timeout: 5)
        NotificationCenter.default.removeObserver(observer)

        /// test stop action ////
        let expectStop = expectation(description: "stop")
        let stopObserver = NotificationCenter.default.addObserver(
            forName: .actionAwareScreenStop, object: nil, queue: .main
        ) { (notification) in
            expectStop.fulfill()
            print("stop")
        }
        sensor.stop()
        wait(for: [expectStop], timeout: 5)
        NotificationCenter.default.removeObserver(stopObserver)

    }

    func testScreenData() {
        var data = ScreenData()
        let dict = data.toDictionary()
        XCTAssertEqual(dict["screenStatus"] as! Int, -1)

        data.screenStatus = 1
        let newDict = data.toDictionary()
        XCTAssertEqual(newDict["screenStatus"] as! Int, 1)
    }

    func testScreenBrightnessData() {
        var data = ScreenBrightnessData()
        let dict = data.toDictionary()
        XCTAssertEqual(dict["brightness"] as! Double, -1)

        data.brightness = 0.7
        let newDict = data.toDictionary()
        XCTAssertEqual(newDict["brightness"] as! Double, 0.7)
    }

    func testSyncModule() throws {
        throw XCTSkip("Sync integration test requires external server configuration and is excluded from unit tests.")
    }
}
