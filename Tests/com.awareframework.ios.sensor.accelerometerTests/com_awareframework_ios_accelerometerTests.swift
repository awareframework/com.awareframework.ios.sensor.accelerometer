//
//  Test.swift
//  com.awareframework.ios.sensor.accelerometer
//
//  Created by Yuuki Nishiyama on 2025/03/26.
//

import XCTest
import com_awareframework_ios_sensor_accelerometer
import com_awareframework_ios_core

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testStorage(){
        #if targetEnvironment(simulator)
        print("Controller tests (start and stop) require a real device.")
        #else
        
        class Observer:AccelerometerObserver {
            weak var arExpectation: XCTestExpectation?
            func onDataChanged(data: AccelerometerData) {
                if let expect = arExpectation {
                    expect.fulfill()
                    arExpectation = nil
                }
            }
        }
        
        let arExpect = expectation(description: "Accelerometer Observer")
        let observer = Observer()
        observer.arExpectation = arExpect
        let sensor = AccelerometerSensor.init(AccelerometerSensor.Config().apply{config in
            config.debug = true
            config.frequency = 10
            config.period = 0
            config.sensorObserver = observer
            config.dbType = .sqlite
        })
        
        let arStorageeExpect = expectation(description: "Activity Recognition Storagee")
        var isDone = false
        let obs = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareAccelerometer,
                                                         object: nil,
                                                         queue: .main) { (notification) in
            if let engine = sensor.dbEngine {
                if let results = engine.fetch(filter: nil, limit: nil) {
                    if !isDone{
                        arStorageeExpect.fulfill()
                        print(results)
                        XCTAssertNotEqual(results.count, 0)
                        isDone = true
                    }
                }else{
                    XCTFail()
                }
            }else{
                 XCTFail()
            }
        }
        // sensor.setLastUpdateDateTime(Date().addingTimeInterval(-1*60*15))
        sensor.start()
        
        wait(for: [arExpect,arStorageeExpect], timeout: 30)
        sensor.stop()
        sensor.CONFIG.sensorObserver = nil
        NotificationCenter.default.removeObserver(obs)
        
        #endif
        
    }
    
    func testControllers(){
        
        let sensor = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.debug = true
        })
        
        /// test set label action ///
        let expectSetLabel = expectation(description: "set label")
        let newLabel = "hello"
        let labelObserver = NotificationCenter.default.addObserver(forName: .actionAwareAccelerometerSetLabel, object: nil, queue: .main) { (notification) in
            let dict = notification.userInfo;
            if let d = dict as? Dictionary<String,String>{
                XCTAssertEqual(d[AccelerometerSensor.EXTRA_LABEL], newLabel)
            }else{
                XCTFail()
            }
            expectSetLabel.fulfill()
        }
        sensor.set(label:newLabel)
        wait(for: [expectSetLabel], timeout: 5)
        NotificationCenter.default.removeObserver(labelObserver)
        
        
        /// test sync action ////
        let expectSync = expectation(description: "sync")
        let syncObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareAccelerometerSync, object: nil, queue: .main) { (notification) in
            expectSync.fulfill()
            print("sync")
        }
        sensor.sync()
        wait(for: [expectSync], timeout: 10)
        NotificationCenter.default.removeObserver(syncObserver)
        
        
        #if targetEnvironment(simulator)
        
        print("Controller tests (start and stop) require a real device.")
        
        #else
        
        //// test start action ////
        let expectStart = expectation(description: "start")
        let observer = NotificationCenter.default.addObserver(forName: .actionAwareAccelerometerStart,
                                                              object: nil,
                                                              queue: .main) { (notification) in
                                                                expectStart.fulfill()
                                                                print("start")
        }
        sensor.start()
        wait(for: [expectStart], timeout: 5)
        NotificationCenter.default.removeObserver(observer)
        
        
        /// test stop action ////
        let expectStop = expectation(description: "stop")
        let stopObserver = NotificationCenter.default.addObserver(forName: .actionAwareAccelerometerStop, object: nil, queue: .main) { (notification) in
            expectStop.fulfill()
            print("stop")
        }
        sensor.stop()
        wait(for: [expectStop], timeout: 5)
        NotificationCenter.default.removeObserver(stopObserver)
        
        #endif
        
    }
    
    func testConfig(){
        
        let frequency = 1

        // default check
        var sensor = AccelerometerSensor(AccelerometerSensor.Config())
        XCTAssertEqual(5, sensor.CONFIG.frequency)
        
        sensor = AccelerometerSensor.init(AccelerometerSensor.Config.init().apply{config in
            config.frequency = frequency
        })
        XCTAssertEqual(frequency, sensor.CONFIG.frequency)
        
        sensor = AccelerometerSensor.init(AccelerometerSensor.Config(["frequency":frequency]))
        XCTAssertEqual(frequency, sensor.CONFIG.frequency)
        
        sensor = AccelerometerSensor.init(AccelerometerSensor.Config())
        sensor.CONFIG.set(config: ["frequency":frequency])
        XCTAssertEqual(frequency, sensor.CONFIG.frequency)
        
        sensor.CONFIG.frequency = -10
        XCTAssertEqual(sensor.CONFIG.frequency, -10)
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
    func testActivityRecognitionData (){
        let dict = AccelerometerData(x: 1, y: 2 , z: 3, timestamp: 4).toDictionary()
        XCTAssertEqual(dict["x"] as? Double, 1)
        XCTAssertEqual(dict["y"] as? Double, 2)
        XCTAssertEqual(dict["z"] as? Double, 3)
        XCTAssertEqual(dict["timestamp"] as? Int64, 4)
    }
    
    
    
    func testSyncModule(){
        #if targetEnvironment(simulator)
        
        print("This test requires a real ActivityRecognition.")
        
        #else
        // success //
        let sensor = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .sqlite
            config.dbHost = "node.awareframework.com:1001"
            config.dbPath = "sync_db"
        })
        if let engine = sensor.dbEngine as? SQLiteEngine {
            engine.removeAll()
            for i in 0..<100 {
                engine.save(AccelerometerData(x: Double(i), y: Double(i), z: Double(i), timestamp: Int64(i)).toDictionary())
            }
        }
        let successExpectation = XCTestExpectation(description: "success sync")
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareAccelerometerSyncCompletion,
                                                              object: sensor, queue: .main) { (notification) in
                                                                if let userInfo = notification.userInfo{
                                                                    if let status = userInfo["status"] as? Bool {
                                                                        if status == true {
                                                                            successExpectation.fulfill()
                                                                        }
                                                                    }
                                                                }
        }
        sensor.sync(force: true)
        wait(for: [successExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(observer)
        
        ////////////////////////////////////
        
        // failure //
        let sensor2 = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .sqlite
            config.dbHost = "node.awareframework.com.com" // wrong url
            config.dbPath = "sync_db"
        })
        let failureExpectation = XCTestExpectation(description: "failure sync")
        let failureObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareAccelerometerSyncCompletion,
                                                                     object: sensor2, queue: .main) { (notification) in
                                                                        if let userInfo = notification.userInfo{
                                                                            if let status = userInfo["status"] as? Bool {
                                                                                if status == false {
                                                                                    failureExpectation.fulfill()
                                                                                }
                                                                            }
                                                                        }
        }
        if let engine = sensor2.dbEngine as? SQLiteEngine {
            engine.removeAll()
            for i in 0..<100 {
                engine.save(AccelerometerData(x: Double(i), y: Double(i), z: Double(i), timestamp: Int64(i)).toDictionary())
            }
        }
        sensor2.sync(force: true)
        wait(for: [failureExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(failureObserver)
        
        #endif
    }
    

    
}

