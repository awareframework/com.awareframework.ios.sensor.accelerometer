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
import CoreMotion

extension Notification.Name {
    public static let actionAwareAccelerometer      = Notification.Name(AccelerometerSensor.ACTION_AWARE_ACCELEROMETER)
    public static let actionAwareAccelerometerStart = Notification.Name(AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_START)
    public static let actionAwareAccelerometerStop  = Notification.Name(AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_STOP)
    public static let actionAwareAccelerometerSetLabel  = Notification.Name(AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_SET_LABEL)
    public static let actionAwareAccelerometerSync  = Notification.Name(AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_SYNC)
    public static let actionAwareAccelerometerSyncCompletion  = Notification.Name(AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_SYNC_COMPLETION)
}

public protocol AccelerometerObserver {
    func onDataChanged(data: AccelerometerData)
}

public extension AccelerometerSensor {
    /// keys ///
    static let ACTION_AWARE_ACCELEROMETER       = "com.awareframework.ios.sensor.accelerometer"
    static let ACTION_AWARE_ACCELEROMETER_START = "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_START"
    static let ACTION_AWARE_ACCELEROMETER_STOP  = "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_STOP"
    static let ACTION_AWARE_ACCELEROMETER_SYNC  = "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_SYNC"
    static let ACTION_AWARE_ACCELEROMETER_SYNC_COMPLETION = "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_SYNC_SUCCESS_COMPLETION"
    static let ACTION_AWARE_ACCELEROMETER_SET_LABEL = "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_SET_LABEL"
    static var EXTRA_LABEL  = "label"
    static let TAG = "com.awareframework.ios.sensor.accelerometer"
    static let EXTRA_STATUS = "status"
    static let EXTRA_ERROR = "error"
}

public class AccelerometerSensor:AwareSensor {
    
    /// config ///
    public var CONFIG = AccelerometerSensor.Config()
    
    ////////////////////////////////////
    var timer:Timer?
    public var motion = CMMotionManager()
    var dataBuffer:Array<AccelerometerData>  = Array<AccelerometerData>()
    
    var bufferTimeout:Double = 0.0
    public var LAST_VALUE:CMAccelerometerData?
    private var LAST_TS:Double = 0.0
    private var LAST_SAVE:Double = 0.0

    public class Config:SensorConfig{
        /**
         * The defualt value of Android is 200000 microsecond.
         * The value means 5Hz
         */
        public var frequency:Int    = 5 // Hz
        public var period:Double    = 0 // min
        /**
         * Accelerometer threshold (Double).  Do not record consecutive points if
         * change in value of all axes is less than this.
         */
        public var threshold: Double = 0
        public var sensorObserver:AccelerometerObserver?
        
        public override init() {
            super.init()
            self.dbPath = "aware_accelerometer"
        }
        
        public override func set(config: Dictionary<String, Any>) {
            super.set(config: config)
            if let period = config["period"] as? Double {
                self.period = period
            }
            
            if let threshold = config ["threshold"] as? Double {
                self.threshold = threshold
            }
            
            if let frequency = config["frequency"] as? Int {
                self.frequency = frequency
            }
        }
        
        public func apply(closure: (_ config: AccelerometerSensor.Config ) -> Void) -> Self {
            closure(self)
            return self
        }

    }
    
    public override convenience init() {
        self.init(AccelerometerSensor.Config())
    }
    
    public init(_ config:AccelerometerSensor.Config) {
        super.init()
        self.CONFIG = config
        self.initializeDbEngine(config: config)
        if config.debug { print(AccelerometerSensor.TAG,"Accelerometer sensor is created.") }
    }
    
    /**
     * Start accelerometer sensor module
     */
    public override func start() {
        // Make sure the accelerometer hardware is available.
        if self.motion.isAccelerometerAvailable {
            self.motion.accelerometerUpdateInterval = 1.0/Double(CONFIG.frequency)
            self.motion.startAccelerometerUpdates()
            
            // Configure a timer to fetch the data.
            self.timer = Timer(fire: Date(), interval: 1.0/Double(CONFIG.frequency), repeats: true, block: { (timer) in
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
                    let x = accData.acceleration.x
                    let y = accData.acceleration.y
                    let z = accData.acceleration.z
                    if let lastValue = self.LAST_VALUE {
                        if self.CONFIG.threshold > 0 &&
                            abs(x - lastValue.acceleration.x) * 9.8 < self.CONFIG.threshold &&
                            abs(y - lastValue.acceleration.y) * 9.8 < self.CONFIG.threshold &&
                            abs(z - lastValue.acceleration.z) * 9.8 < self.CONFIG.threshold {
                            return
                        }
                    }
                    
                    self.LAST_VALUE = accData
                    
                    let currentTime:Double = Date().timeIntervalSince1970
                    self.LAST_TS = currentTime
                    
                    let data = AccelerometerData()
                    data.timestamp = Int64(currentTime*1000)
                    data.x = x
                    data.y = y
                    data.z = z
                    data.eventTimestamp = Int64(accData.timestamp*1000)
                    data.label = self.CONFIG.label
                    
                    if let observer = self.CONFIG.sensorObserver {
                        observer.onDataChanged(data: data)
                    }
                    
                    self.dataBuffer.append(data)
                    ////////////////////////////////////////
                    
                    if currentTime < self.LAST_SAVE + (self.CONFIG.period * 60) {
                        return
                    }
                    
                    let dataArray = Array(self.dataBuffer)
                    OperationQueue().addOperation({ () -> Void in
                        self.dbEngine?.save(dataArray){ error in
                            if error != nil {
                                if self.CONFIG.debug {
                                    print(AccelerometerSensor.TAG, error.debugDescription)
                                }
                                return
                            }
                            // send notification in the main thread
                            DispatchQueue.main.async {
                                self.notificationCenter.post(name: .actionAwareAccelerometer , object: self)
                            }
                        }
                    })
                    
                    self.dataBuffer.removeAll()
                    self.LAST_SAVE = currentTime
                }
            })
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
            
            if self.CONFIG.debug { print(AccelerometerSensor.TAG, "Accelerometer sensor active: \(self.CONFIG.frequency) hz") }
            self.notificationCenter.post(name: .actionAwareAccelerometerStart, object: self)
        }
    }

    /**
     * Stop accelerometer sensor module
     */
    public override func stop() {
        if self.motion.isAccelerometerAvailable{
            if let timer = self.timer {
                self.motion.stopAccelerometerUpdates()
                timer.invalidate()
                if CONFIG.debug { print(AccelerometerSensor.TAG, "Accelerometer service is terminated...") }
                self.notificationCenter.post(name: .actionAwareAccelerometerStop, object: self)
            }
        }
    }

    /**
     * Sync accelerometer sensor module
     */
    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine {
            engine.startSync(AccelerometerData.TABLE_NAME, AccelerometerData.self, DbSyncConfig().apply(closure: { config in
                config.debug = true
                config.batchSize = 100
                config.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.accelerometer.sync.queue")
                config.completionHandler = { (status, error) in
                    var userInfo: Dictionary<String,Any> = [AccelerometerSensor.EXTRA_STATUS :status]
                    if let e = error {
                        userInfo[AccelerometerSensor.EXTRA_ERROR] = e
                    }
                    self.notificationCenter.post(name: .actionAwareAccelerometerSyncCompletion ,
                                                 object: self,
                                                 userInfo:userInfo)
                }
            }))
            self.notificationCenter.post(name: .actionAwareAccelerometerSync, object: self)
        }
    }
    
    /**
     * Set a label for a data
     */
    public override func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionAwareAccelerometerSetLabel, object: self, userInfo: [AccelerometerSensor.EXTRA_LABEL:label])
    }
    
//    struct AccData {
//        public var x:Double
//        public var y:Double
//        public var z:Double
//        init(_ x:Double, _ y:Double, _ z:Double) {
//            self.x = x
//            self.y = y
//            self.z = z
//        }
//    }
}
