# AWARE: Screen

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

The screen sensor monitors the screen statuses, such as turning on and off, locked and unlocked.

## Requirements
iOS 13 or later

## Installation


You can integrate this framework into your project via Swift Package Manager (SwiftPM).

### SwiftPM
1. Open Package Manager Windows
    * Open `Xcode` -> Select `Menu Bar` -> `File` -> `App Package Dependencies...`

2. Find the package using the manager
    * Select `Search Package URL` and type `git@github.com:awareframework/com.awareframework.ios.sensor.screen.git`

3. Import the package into your target.


## ScreenSensor
+ `init(config:ScreenSensor.Config?)`: Initializes the screen sensor with the optional configuration.
+ `start()`: Starts the screen sensor with the optional configuration.
+ `stop()`: Stops the service.


### ScreenSensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: ScreenObserver`: Callback for live data updates.
+ `enabled: Bool`: Sensor is enabled or not. (default = `false`)
+ `debug: Bool`: Enable/disable logging. (default = `false`)
+ `label: String`: Label for the data. (default = `""`)
+ `deviceId: String`: Id of the device that will be associated with the events and the sensor. (default = `""`)
+ `dbEncryptionKey: String?`: Encryption key for the database. (default = `nil`)
+ `dbType: DatabaseType`: Which db engine to use for saving data. (default = `.none`)
+ `dbPath: String`: Path of the database. (default = `"aware_screen"`)
+ `dbHost: String?`: Host for syncing the database. (default = `nil`)

## Broadcasts

+ `ScreenSensor.ACTION_AWARE_SCREEN_ON`: fired when the screen is on.
+ `ScreenSensor.ACTION_AWARE_SCREEN_OFF`: fired when the screen is off.
+ `ScreenSensor.ACTION_AWARE_SCREEN_LOCKED`: fired when the screen is locked.
+ `ScreenSensor.ACTION_AWARE_SCREEN_UNLOCKED`: fired when the screen is unlocked.

## Data Representations

### Screen Data

Contains the screen profiles.

| Field        | Type   | Description                                                            |
| ------------ | ------ | ---------------------------------------------------------------------- |
| screenStatus | Int    | screen status, one of the following: 0=off, 1=on, 2=locked, 3=unlocked |
| deviceId     | String | AWARE device UUID                                                      |
| label        | String | Customizable label. Useful for data calibration or traceability        |
| timestamp    | Int64  | Unixtime milliseconds since 1970                                       |
| timezone     | Int    | Timezone of the device                                                 |
| os           | String | Operating system of the device (e.g., ios)                             |
| jsonVersion  | Int    | JSON schema version                                                    |

### Screen Brightness Data

Contains the screen brightness level.

| Field       | Type   | Description                                                            |
| ----------- | ------ | ---------------------------------------------------------------------- |
| brightness  | Double | Screen brightness level [0.0–1.0], or -1 if unavailable               |
| deviceId    | String | AWARE device UUID                                                      |
| label       | String | Customizable label. Useful for data calibration or traceability        |
| timestamp   | Int64  | Unixtime milliseconds since 1970                                       |
| timezone    | Int    | Timezone of the device                                                 |
| os          | String | Operating system of the device (e.g., ios)                             |
| jsonVersion | Int    | JSON schema version                                                    |

## Example Usage

```swift
var screenSensor = ScreenSensor.init(ScreenSensor.Config().apply { config in
    config.sensorObserver = Observer()
    config.debug = true
})
screenSensor?.start()
```

```swift
class Observer:ScreenObserver{
    func onScreenOn() {
        // Your code here ...
    }

    func onScreenOff() {
        // Your code here ...
    }

    func onScreenLocked() {
        // Your code here ...
    }

    func onScreenUnlocked() {
        // Your code here ...
    }
}
```

## Author

Yuuki Nishiyama (The University of Tokyo), nishiyama@csis.u-tokyo.ac.jp

## License

Copyright (c) 2025 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

