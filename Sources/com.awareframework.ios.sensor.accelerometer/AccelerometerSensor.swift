//
//  Accelerometer.swift
//  aware-core
//
//  Created by Yuuki Nishiyama on 2017/12/30.
//  Copyright © 2017 Yuuki Nishiyama. All rights reserved.
//

import CoreMotion
import Foundation
import GRDB
import com_awareframework_ios_core

extension Notification.Name {
    public static let actionAwareAccelerometer = Notification.Name(
        AccelerometerSensor.ACTION_AWARE_ACCELEROMETER)
    public static let actionAwareAccelerometerStart = Notification.Name(
        AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_START)
    public static let actionAwareAccelerometerStop = Notification.Name(
        AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_STOP)
    public static let actionAwareAccelerometerSetLabel = Notification.Name(
        AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_SET_LABEL)
    public static let actionAwareAccelerometerSync = Notification.Name(
        AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_SYNC)
    public static let actionAwareAccelerometerSyncCompletion = Notification.Name(
        AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_SYNC_COMPLETION)
}

public protocol AccelerometerObserver {
    func onDataChanged(data: AccelerometerData)
}

extension AccelerometerSensor {
    /// keys ///
    public static let ACTION_AWARE_ACCELEROMETER = "com.awareframework.ios.sensor.accelerometer"
    public static let ACTION_AWARE_ACCELEROMETER_START =
        "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_START"
    public static let ACTION_AWARE_ACCELEROMETER_STOP =
        "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_STOP"
    public static let ACTION_AWARE_ACCELEROMETER_SYNC =
        "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_SYNC"
    public static let ACTION_AWARE_ACCELEROMETER_SYNC_COMPLETION =
        "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_SYNC_SUCCESS_COMPLETION"
    public static let ACTION_AWARE_ACCELEROMETER_SET_LABEL =
        "com.awareframework.ios.sensor.accelerometer.ACTION_AWARE_ACCELEROMETER_SET_LABEL"
    public static var EXTRA_LABEL = "label"
    public static let TAG = "com.awareframework.ios.sensor.accelerometer"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
}

public class AccelerometerSensor: AwareSensor {

    /// config ///
    public var CONFIG = AccelerometerSensor.Config()

    ////////////////////////////////////
    public var motion = CMMotionManager()
    //    var dataBuffer:Array<AccelerometerData>  = Array<AccelerometerData>()
    var dataBuffer: [AccelerometerData] = []
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.awareframework.ios.sensor.accelerometer.motion.queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    var bufferTimeout: Double = 0.0
    public var LAST_VALUE: CMAccelerometerData?
    private var LAST_TS: Double = 0.0
    private var LAST_SAVE: Double = 0.0
    private var bootReferenceTime: Double = 0

    public class Config: SensorConfig {
        /**
         * The defualt value of Android is 200000 microsecond.
         * The value means 5Hz
         */
        public var samplingFrequencyHz: Int = 5  // Hz

        public var saveIntervalSeconds: Double = 60
        /**
         * Accelerometer threshold (Double).  Do not record consecutive points if
         * change in value of all axes is less than this.
         */
        public var threshold: Double = 0
        public var sensorObserver: AccelerometerObserver?

        public override init() {
            super.init()
            self.dbTableName = AccelerometerData.TABLE_NAME
            self.dbPath = "aware_accelerometer"
        }

        public override func set(config: [String: Any]) {
            super.set(config: config)
            if let saveIntervalSeconds = config["saveIntervalSeconds"] as? Double {
                self.saveIntervalSeconds = saveIntervalSeconds
            }

            if let threshold = config["threshold"] as? Double {
                self.threshold = threshold
            }

            if let samplingFrequencyHz = config["samplingFrequencyHz"] as? Int {
                self.samplingFrequencyHz = samplingFrequencyHz
            }
        }

        public func apply(closure: (_ config: AccelerometerSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }

    }

    public override convenience init() {
        self.init()
        configureSyncConfig()
    }

    private func configureSyncConfig() {
        super.syncConfig = DbSyncConfig().apply(closure: { config in
            config.serverType = self.CONFIG.serverType
            config.debug = self.CONFIG.debug
            config.batchSize = 1000
            config.dispatchQueue = DispatchQueue(
                label: "com.awareframework.ios.sensor.accelerometer.sync.queue")
            config.completionHandler = { (status, error) in
                var userInfo: [String: Any] = [AccelerometerSensor.EXTRA_STATUS: status]
                if let e = error {
                    userInfo[AccelerometerSensor.EXTRA_ERROR] = e
                }
                self.notificationCenter.post(
                    name: .actionAwareAccelerometerSyncCompletion, object: self, userInfo: userInfo)
            }
        })
    }

    public init(_ config: AccelerometerSensor.Config) {
        super.init()
        self.CONFIG = config
        configureSyncConfig()
        self.initializeDbEngine(config: config)
        self.initializeTable()
        if config.debug { print(AccelerometerSensor.TAG, "Accelerometer sensor is created.") }

    }

    /**
     * Start accelerometer sensor module
     */
    public override func start() {
        // Make sure the accelerometer hardware is available.
        if self.motion.isAccelerometerAvailable && !self.motion.isAccelerometerActive {
            self.bootReferenceTime = Date().timeIntervalSince1970 - ProcessInfo.processInfo.systemUptime
            self.motion.accelerometerUpdateInterval = 1.0 / Double(CONFIG.samplingFrequencyHz)
            self.motion.startAccelerometerUpdates(to: motionQueue) { [weak self] accData, error in
                guard let self = self, let accData = accData else {
                    return
                }
                // https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events
                let x = accData.acceleration.x
                let y = accData.acceleration.y
                let z = accData.acceleration.z
                if let lastValue = self.LAST_VALUE {
                    if self.CONFIG.threshold > 0
                        && abs(x - lastValue.acceleration.x) * 9.8 < self.CONFIG.threshold
                        && abs(y - lastValue.acceleration.y) * 9.8 < self.CONFIG.threshold
                        && abs(z - lastValue.acceleration.z) * 9.8 < self.CONFIG.threshold
                    {
                        return
                    }
                }

                self.LAST_VALUE = accData

                let currentTime: Double = Date().timeIntervalSince1970
                self.LAST_TS = currentTime

                let data = AccelerometerData(
                    x: x,
                    y: y,
                    z: z,
                    timestamp: Int64(currentTime * 1000),
                    eventTimestamp: Int64((self.bootReferenceTime + accData.timestamp) * 1000),
                    label: self.CONFIG.label
                )

                if let observer = self.CONFIG.sensorObserver {
                    observer.onDataChanged(data: data)
                }

                self.dataBuffer.append(data)
                ////////////////////////////////////////

                if currentTime < self.LAST_SAVE + (self.CONFIG.saveIntervalSeconds) {
                    return
                }

                let dataArray = Array(self.dataBuffer)
                self.dataBuffer.removeAll()
                self.LAST_SAVE = currentTime

                OperationQueue().addOperation({ () -> Void in
                    self.dbEngine?.save(dataArray) { error in
                        if error != nil {
                            if self.CONFIG.debug {
                                print(AccelerometerSensor.TAG, error.debugDescription)
                            }
                            return
                        }
                        // send notification in the main thread
                        DispatchQueue.main.async {
                            self.notificationCenter.post(
                                name: .actionAwareAccelerometer, object: self)
                        }
                    }
                })
            }

            if self.CONFIG.debug {
                print(
                    AccelerometerSensor.TAG,
                    "Accelerometer sensor active: \(self.CONFIG.samplingFrequencyHz) hz")
            }
            self.notificationCenter.post(name: .actionAwareAccelerometerStart, object: self)
        }
    }

    /**
     * Stop accelerometer sensor module
     */
    public override func stop() {
        if self.motion.isAccelerometerAvailable {
            if self.motion.isAccelerometerActive {
                self.motion.stopAccelerometerUpdates()
                self.motionQueue.cancelAllOperations()
                if CONFIG.debug {
                    print(AccelerometerSensor.TAG, "Accelerometer service is terminated...")
                }
                self.notificationCenter.post(name: .actionAwareAccelerometerStop, object: self)
            }
        }
    }

    /**
     * Sync accelerometer sensor module
     */
    public override func sync(force: Bool = false) {
        self.notificationCenter.post(name: .actionAwareAccelerometerSync, object: self)
        guard let engine = self.dbEngine else {
            postSyncFailure("Accelerometer database engine is not initialized.")
            return
        }
        guard let syncConfig = super.syncConfig else {
            postSyncFailure("Accelerometer sync configuration is not initialized.")
            return
        }
        engine.startSync(syncConfig)
    }

    private func postSyncFailure(_ message: String) {
        let error = NSError(
            domain: AccelerometerSensor.TAG,
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        notificationCenter.post(
            name: .actionAwareAccelerometerSyncCompletion,
            object: self,
            userInfo: [
                AccelerometerSensor.EXTRA_STATUS: false,
                AccelerometerSensor.EXTRA_ERROR: error,
            ]
        )
    }

    /**
     * Set a label for a data
     */
    public override func set(label: String) {
        self.CONFIG.label = label
        self.notificationCenter.post(
            name: .actionAwareAccelerometerSetLabel, object: self,
            userInfo: [AccelerometerSensor.EXTRA_LABEL: label])
    }

    private func initializeTable() {
        guard let sqliteEngine = self.dbEngine as? SQLiteEngine,
            let queue = sqliteEngine.getSQLiteInstance()
        else {
            return
        }
        AccelerometerData.createTable(queue: queue)
    }
}
