//
//  AccelerometerEvent.swift
//  CoreAware
//
//  Created by Yuuki Nishiyama on 2018/03/02.
//

import Foundation
import RealmSwift
import com_awareframework_ios_sensor_core

public class AccelerometerData: AwareObject {
    
    public static var TABLE_NAME = "accelerometerData"
    
    @objc dynamic public var eventTimestamp : Int64 = 0
    @objc dynamic public var x : Double = 0.0
    @objc dynamic public var y : Double = 0.0
    @objc dynamic public var z : Double = 0.0
    @objc dynamic public var accuracy : Int = 0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["x"] = x
        dict["y"] = y
        dict["z"] = z
        dict["eventTimestamp"] = eventTimestamp
        dict["accuracy"] = accuracy
        return dict
    }
}
