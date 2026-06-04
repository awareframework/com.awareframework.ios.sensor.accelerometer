//
//  AccelerometerEvent.swift
//  CoreAware
//
//  Created by Yuuki Nishiyama on 2018/03/02.
//

import Foundation
import com_awareframework_ios_core
import GRDB

public struct AccelerometerData: BaseDbModelSQLite {
    public var timezone: Int = AwareUtils.getTimeZone()
    public var os: String = "iOS"
    public var jsonVersion: Int = 1
    
    public var id: Int64?
    public var timestamp: Int64
    public var deviceId: String = AwareUtils.getCommonDeviceId()
    public var label: String
    
    public static let databaseTableName = "accelerometer"  // 新しいテーブル名
    
//    public var eventTimestamp : Int64 = 0
    public var x : Double = 0.0
    public var y : Double = 0.0
    public var z : Double = 0.0
    
    public init(x:Double, y:Double, z:Double, timestamp:Int64, label:String="") {
        self.x=x
        self.y=y
        self.z=z
        self.timestamp = timestamp
        self.label = label
    }
    
    public init(_ dict: Dictionary<String, Any>) {
        self.timestamp = dict["timestamp"] as? Int64 ?? 0
        self.label = dict["label"] as? String ?? ""
        self.x = dict["x"] as? Double ?? 0
        self.y = dict["y"] as? Double ?? 0
        self.z = dict["z"] as? Double ?? 0
        self.deviceId = dict["deviceId"] as? String ?? ""
//        self.eventTimestamp = dict["eventTime"] as? Int64 ?? 0
    }
    
    public static func createTable(queue: GRDB.DatabaseQueue ) {
        do {
            try queue.write { db in
                try db.create(table: AccelerometerData.databaseTableName, ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("deviceId", .text).notNull()
                    t.column("timestamp", .integer).notNull()
                    t.column("label", .text).notNull()
                    t.column("x", .double).notNull()
                    t.column("y", .double).notNull()
                    t.column("z", .double).notNull()
//                    t.column("eventTime", .integer).notNull()
                    t.column("os", .text).notNull()
                    t.column("timezone", .integer).notNull()
                    t.column("jsonVersion", .integer).notNull()
                }
                try migrateTableIfNeeded(db)
            }
        } catch {
            print(error)
        }
    }
    
    private static func migrateTableIfNeeded(_ db: GRDB.Database) throws {
        let columns = Set(try db.columns(in: AccelerometerData.databaseTableName).map(\.name))
        if columns.contains("timezone") == false {
            try db.alter(table: AccelerometerData.databaseTableName) { t in
                t.add(column: "timezone", .integer).notNull().defaults(to: AwareUtils.getTimeZone())
            }
        }
        if columns.contains("os") == false {
            try db.alter(table: AccelerometerData.databaseTableName) { t in
                t.add(column: "os", .text).notNull().defaults(to: "iOS")
            }
        }
        if columns.contains("jsonVersion") == false {
            try db.alter(table: AccelerometerData.databaseTableName) { t in
                t.add(column: "jsonVersion", .integer).notNull().defaults(to: 1)
            }
        }
    }
    
    
    public func toDictionary() -> Dictionary<String, Any> {
        return [
            "id": self.id ?? -1,
            "timestamp":timestamp,
            "deviceId":deviceId,
            "label":label,
            "x":x,
            "y":y,
            "z":z,
//            "eventTimestamp": eventTimestamp
        ]
    }
}
