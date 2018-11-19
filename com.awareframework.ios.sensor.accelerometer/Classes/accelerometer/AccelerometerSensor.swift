//
//  Accelerometer.swift
//  aware-core
//
//  Created by Yuuki Nishiyama on 2017/12/30.
//  Copyright © 2017 Yuuki Nishiyama. All rights reserved.
//

import Foundation
import com_awareframework_ios_sensor_core
import RealmSwift
import SwiftyJSON
import CoreMotion

extension Notification.Name {
    public static let actionAwareAccelerometer      = Notification.Name(AccelerometerSensor.ACTION_AWARE_ACCELEROMETER)
    public static let actionAwareAccelerometerStart = Notification.Name(AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_START)
    public static let actionAwareAccelerometerStop  = Notification.Name(AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_STOP)
}

public protocol AccelerometerObserver {
    func onDataChanged(data: AccelerometerData)
}

public extension AccelerometerSensor {
    /// keys ///
    public static let ACTION_AWARE_ACCELEROMETER       = "ACTION_AWARE_ACCELEROMETER"
    public static let ACTION_AWARE_ACCELEROMETER_START = "ACTION_AWARE_ACCELEROMETER_START"
    public static let ACTION_AWARE_ACCELEROMETER_STOP  = "ACTION_AWARE_ACCELEROMETER_STOP"
    public static let ACTION_AWARE_ACCELEROMETER_LABEL = "ACTION_AWARE_ACCELEROMETER_LABEL"
    public static var EXTRA_LABEL  = "label"
    public static let TAG = "com.aware.accelerometer"
}

public class AccelerometerSensor:AwareSensor {
    
    /// config ///
    public var CONFIG = AccelerometerSensor.Config()
    
    ////////////////////////////////////
    var timer:Timer?
    var motion = CMMotionManager()
    var dataBuffer:Array<AccelerometerData>  = Array<AccelerometerData>()
    
    var bufferTimeout:Double = 0.0
    private var LAST_VALUE:AccData?
    private var LAST_TS:Double = 0.0
    private var LAST_SAVE:Double = 0.0

    public class Config:SensorConfig{
        /**
         * The defualt value of Android is 200000 microsecond.
         * The value means 5Hz
         */
        public var frequency:Double  = 5 // Hz
        public var period:Double     = 0 // min
        /**
         * Accelerometer threshold (Double).  Do not record consecutive points if
         * change in value of all axes is less than this.
         */
        public var threshold: Double = 0
        public var sensorObserver:AccelerometerObserver?
        
        public override init() {}
        
        public init(_ json:JSON){
            if let period = json["period"].double{
                self.period = period
            }
            
            if let threshold = json["threshold"].double{
                self.threshold = threshold
            }
            
            if let frequency = json["frequency"].double{
                self.frequency = frequency
            }
        }
        
        public func apply(closure: (_ config: AccelerometerSensor.Config ) -> Void) -> Self {
            closure(self)
            return self
        }

    }
    
    override convenience init() {
        self.init(AccelerometerSensor.Config())
    }
    
    public init(_ config:AccelerometerSensor.Config) {
        super.init()
        self.CONFIG = config
        self.initializeDbEngine(config: config)
        if config.debug { print(AccelerometerSensor.TAG,"Accelerometer sensor is created.") }
    }
    
    
    //////////////////////////
    public override func start() {
        // Make sure the accelerometer hardware is available.
        if self.motion.isAccelerometerAvailable {
            self.motion.accelerometerUpdateInterval = 1.0/CONFIG.frequency
            self.motion.startAccelerometerUpdates()
            
            // Configure a timer to fetch the data.
            self.timer = Timer(fire: Date(), interval: 1.0/CONFIG.frequency, repeats: true, block: { (timer) in
                // Get the accelerometer data.
                if let accData = self.motion.accelerometerData {
                    // https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events
                    /**
                     * An accelerometer measures changes in velocity along one axis. All iOS devices have a
                     * three-axis accelerometer, which delivers acceleration values in each of the three axes
                     * shown in Figure 1. The values reported by the accelerometers are measured in increments
                     * of the gravitational acceleration, with the value 1.0 representing an acceleration
                     * of 9.8 meters per second (per second) in the given direction. Acceleration values may
                     * be positive or negative depending on the direction of the acceleration.
                     */
                    let x = accData.acceleration.x // * 9.8
                    let y = accData.acceleration.y // * 9.8
                    let z = accData.acceleration.z // * 9.8
                    if let lastValue = self.LAST_VALUE {
                        if self.CONFIG.threshold > 0 &&
                            abs(x - lastValue.x) < self.CONFIG.threshold &&
                            abs(y - lastValue.y) < self.CONFIG.threshold &&
                            abs(z - lastValue.z) < self.CONFIG.threshold {
                            return
                        }
                    }
                    
                    let acc = AccData.init(x,y,z)
                    self.LAST_VALUE = acc
                    
                    let currentTime:Double = Date().timeIntervalSince1970
                    self.LAST_TS = currentTime
                    
                    let data = AccelerometerData()
                    data.timestamp = Int64(currentTime*1000)
                    data.x = x
                    data.y = y
                    data.z = z
                    data.eventTimestamp = Int64(accData.timestamp*1000)
                    
                    if let observer = self.CONFIG.sensorObserver {
                        observer.onDataChanged(data: data)
                    }
                    
                    self.dataBuffer.append(data)
                    ////////////////////////////////////////
                    
                    if self.dataBuffer.count < Int(self.CONFIG.frequency) && currentTime > self.LAST_SAVE + (self.CONFIG.period * 60) {
                        return
                    }
                    
                    let dataArray = Array(self.dataBuffer)
                    self.dbEngine?.save(dataArray, AccelerometerData.TABLE_NAME)
                    self.notificationCenter.post(name: .actionAwareAccelerometer , object: nil)
                    
                    self.dataBuffer.removeAll()
                    self.LAST_SAVE = currentTime
                }
            })
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
            
            if self.CONFIG.debug { print(AccelerometerSensor.TAG, "Accelerometer sensor active: \(self.CONFIG.frequency) hz") }
            self.notificationCenter.post(name: .actionAwareAccelerometerStart, object: nil)
        }
    }

    ///////////////////////
    public override func stop() {
        if self.motion.isAccelerometerAvailable{
            if let timer = self.timer {
                self.motion.stopAccelerometerUpdates()
                timer.invalidate()
                if CONFIG.debug { print(AccelerometerSensor.TAG, "Accelerometer service is terminated...") }
                self.notificationCenter.post(name: .actionAwareAccelerometerStop, object: nil)
            }
        }
    }

    ////////////////////////
    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine {
            engine.startSync(AccelerometerData.TABLE_NAME, DbSyncConfig().apply(closure: { config in
            
            }))
        }
    }
    
    struct AccData {
        public var x:Double
        public var y:Double
        public var z:Double
        init(_ x:Double, _ y:Double, _ z:Double) {
            self.x = x
            self.y = y
            self.z = z
        }
    }
}
