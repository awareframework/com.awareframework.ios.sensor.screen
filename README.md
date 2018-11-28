# AWARE: Screen

[![CI Status](https://img.shields.io/travis/awareframework/com.awareframework.ios.sensor.screen.svg?style=flat)](https://travis-ci.org/awareframework/com.awareframework.ios.sensor.screen)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.screen.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.screen)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.screen.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.screen)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.screen.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.screen)

The screen sensor monitors the screen statuses, such as turning on and off, locked and unlocked.

## Requirements
iOS 10 or later

## Installation

com.awareframework.ios.sensor.wifi is available through [CocoaPods](https://cocoapods.org). 

1. To install it, simply add the following line to your Podfile:

```ruby
pod 'com.awareframework.ios.sensor.screen'
```

2. Import com.awareframework.ios.sensor.screen library into your source code.
```swift
import com_awareframework_ios_sensor_screen
```

## ScreenSensor
* `init(config:ScreenSensor.Config?)` : Initializes the screen sensor with the optional configuration.
* `start()`: Starts the gyroscope sensor with the optional configuration.
* `stop()`: Stops the service.


### ScreenSensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: ScreenObserver`: Callback for live data updates.
+ `enabled: Boolean` Sensor is enabled or not. (default = `false`)
+ `debug: Boolean` enable/disable logging to `Logcat`. (default = `false`)
+ `label: String` Label for the data. (default = "")
+ `deviceId: String` Id of the device that will be associated with the events and the sensor. (default = "")
+ `dbEncryptionKey` Encryption key for the database. (default = `null`)
+ `dbType: Engine` Which db engine to use for saving data. (default = `Engine.DatabaseType.NONE`)
+ `dbPath: String` Path of the database. (default = "aware_screen")
+ `dbHost: String` Host for syncing the database. (default = `null`)

## Broadcasts

+ `ScreenSensor.ACTION_AWARE_SCREEN_ON` fired when the screen is on.
+ `ScreenSensor.ACTION_AWARE_SCREEN_OFF` fired when the screen is off.
+ `ScreenSensor.ACTION_AWARE_SCREEN_LOCKED` fired when the screen is locked.
+ `ScreenSensor.ACTION_AWARE_SCREEN_UNLOCKED` fired when the screen is unlocked.

## Data Representations

### Screen Data

Contains the screen profiles.

| Field        | Type   | Description                                                            |
| ------------ | ------ | ---------------------------------------------------------------------- |
| screenStatus | Int    | screen status, one of the following: 0=off, 1=on, 2=locked, 3=unlocked |
| deviceId     | String | AWARE device UUID                                                      |
| label        | String | Customizable label. Useful for data calibration or traceability        |
| timestamp    | Long   | Unixtime milliseconds since 1970                                       |
| timezone     | Int    | Timezone of the device                                 |
| os           | String | Operating system of the device (e.g., ios)                           |

## Example usage

```swift
var screenSensor = ScreenSensor.init(ScreenSensor.Config().apply{config in
    config.sensorObserver = Observer()
    config.debug = true
    config.dbType = .REALM
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

tetujin, tetujin@ht.sfc.keio.ac.jp

## License

Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

