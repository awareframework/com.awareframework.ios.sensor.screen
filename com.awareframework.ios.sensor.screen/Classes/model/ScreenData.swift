//
//  ScreenData.swift
//  com.aware.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/10/23.
//

import UIKit
import com_awareframework_ios_sensor_core

public class ScreenData: AwareObject {
    public static var TABLE_NAME = "screenData"
    
    @objc dynamic public var screenStatus:Int = -1
    
    override public func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["screenStatus"] = screenStatus
        return dict
    }
}
