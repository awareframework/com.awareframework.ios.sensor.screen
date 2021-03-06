//
//  ScreenBrightness.swift
//  com.awareframework.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/12/11.
//

import UIKit
import com_awareframework_ios_sensor_core

public class ScreenBrightnessData: AwareObject {
    public static var TABLE_NAME = "screenBrightnessData"
    
    /*
    This property is only supported on the main screen. The value of this property should be a number between 0.0 and 1.0, inclusive.
    
    Brightness changes made by an app remain in effect until the device is locked, regardless of whether the app is closed. The system brightness (which the user can set in Settings or Control Center) is restored the next time the display is turned on.
 */
    @objc dynamic public var brightness:Double = -1
    
    override public func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["brightness"] = brightness
        return dict
    }
}
