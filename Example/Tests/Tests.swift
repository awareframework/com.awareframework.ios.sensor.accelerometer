import XCTest
import RealmSwift
import com_awareframework_ios_sensor_accelerometer
import com_awareframework_ios_sensor_core

class Tests: XCTestCase{
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    var token1:NotificationToken? = nil
    var token2:NotificationToken? = nil
    
    func testSensorModule(){
        
        #if targetEnvironment(simulator)
        
        print("This test requires a real device.")
        
        #else
        /////////// 30 FPS //////
        let sensor = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.frequency = 30
            config.dbPath = "acc_sensor_module"
        })
        sensor.start() // start sensor
        
        let expect = expectation(description: "Sensing test (30FPS)")
        if let realmEngine = sensor.dbEngine as? RealmEngine {
            // remove old data
            realmEngine.removeAll(AccelerometerData.self)
            // get a RealmEngine Instance
            if let realm = realmEngine.getRealmInstance() {
                // set Realm DB observer
                token1 = realm.observe { (notification, realm) in
                    switch notification {
                    case .didChange:
                        // check database size
                        let results = realm.objects(AccelerometerData.self)
                        print(results.count)
                        if(results.count > 20 && results.count < 40){
                            expect.fulfill()
                        }
                        break;
                    case .refreshRequired:
                        break;
                    }
                }
            }
        }
        
        wait(for: [expect], timeout: 70)
        sensor.stop()
        
        ///////// 1 fps ////////
        let sensor2 = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.frequency = 1
            config.dbPath = "acc_sensor_module_1hz"
        })
        sensor2.start() // start sensor
        
        let expect2 = expectation(description: "Sensing test (1 FPS)")
        if let realmEngine = sensor2.dbEngine as? RealmEngine {
            // remove old data
            realmEngine.removeAll(AccelerometerData.self)
            // get a RealmEngine Instance
            if let realm = realmEngine.getRealmInstance() {
                // set Realm DB observer
                token2 = realm.observe { (notification, realm) in
                    switch notification {
                    case .didChange:
                        // check database size
                        let results = realm.objects(AccelerometerData.self)
                        print(results.count)
                        if(results.count > 0 && results.count < 5){
                            expect2.fulfill()
                        }
                        break;
                    case .refreshRequired:
                        break;
                    }
                }
            }
        }
        wait(for: [expect2], timeout: 70)
        sensor2.stop()
        #endif
    }
    
    func testSyncModule(){
        #if targetEnvironment(simulator)
        
        print("This test requires a real device.")
        
        #else
        // success //
        let sensor = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com:1001"
            config.dbPath = "sync_acc_db"
        })
        if let engine = sensor.dbEngine as? RealmEngine {
            for _ in 0..<100 {
                engine.save(AccelerometerData())
            }
        }
        let successExpectation = XCTestExpectation(description: "success sync")
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareAccelerometerSyncSuccess,
                                               object: nil, queue: .main) { (notification) in
            successExpectation.fulfill()
        }
        sensor.sync(force: true)
        wait(for: [successExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(observer)
        
        ////////////////////////////////////
        
        // failure //
        let sensor2 = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com.com" // wrong url
            config.dbPath = "sync_acc_db"
        })
        let failureExpectation = XCTestExpectation(description: "failure sync")
        let failureObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareAccelerometerSyncFailure,
                                                              object: nil, queue: .main) { (notification) in
                                                                failureExpectation.fulfill()
        }
        if let engine = sensor2.dbEngine as? RealmEngine {
            for _ in 0..<100 {
                engine.save(AccelerometerData())
            }
        }
        sensor2.sync(force: true)
        wait(for: [failureExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(failureObserver)
        
        #endif
    }
    
    func testObserver(){
        #if targetEnvironment(simulator)
        
        print("This test requires a real device.")
        
        #else
    
        class Observer:AccelerometerObserver{
            // https://www.mokacoding.com/blog/testing-delegates-in-swift-with-xctest/
            // http://nsblogger.hatenablog.com/entry/2015/02/09/xctestexpectation_api_violation
            weak var asyncExpectation: XCTestExpectation?
            func onDataChanged(data: AccelerometerData) {
                if let syncExp = self.asyncExpectation {
                    syncExp.fulfill()
                    asyncExpectation = nil
                }
            }
        }
        
        let expectObserver = expectation(description: "observer")
        let observer = Observer()
        observer.asyncExpectation = expectObserver
        let sensor = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.sensorObserver = observer
        })
        sensor.start()
    
        waitForExpectations(timeout: 30) { (error) in
            if let e = error {
                print(e)
                XCTFail()
            }
        }
        sensor.stop()
        
        #endif

    }
    
    func testControllers(){
        
        let sensor = AccelerometerSensor.init(AccelerometerSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
        })
        
        /// set set label ///
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
        
        /// test sync ////
        let expectSync = expectation(description: "sync")
        let syncObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareAccelerometerSync , object: nil, queue: .main) { (notification) in
            expectSync.fulfill()
            print("sync")
        }
        sensor.sync()
        wait(for: [expectSync], timeout: 5)
        NotificationCenter.default.removeObserver(syncObserver)
        
        
        #if targetEnvironment(simulator)
        
        print("Controller tests (start and stop) require a real device.")
        
        #else

        //// test start ////
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
        
        
        /// test stop ////
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
    
    func testAccelerometerData(){
        let accData = AccelerometerData()
        
        let dict = accData.toDictionary()
        XCTAssertEqual(dict["x"] as! Double, 0)
        XCTAssertEqual(dict["y"] as! Double, 0)
        XCTAssertEqual(dict["z"] as! Double, 0)
        XCTAssertEqual(dict["eventTimestamp"] as! Int64, 0)
    }
    
    func testConfig(){
        let frequency = 1;
        let threshold = 0.5;
        let period    = 1.0;
        let config :Dictionary<String,Any> = ["frequency":frequency, "threshold":threshold, "period":period]
        
        var sensor = AccelerometerSensor.init(AccelerometerSensor.Config(config));
        XCTAssertEqual(frequency, sensor.CONFIG.frequency)
        XCTAssertEqual(threshold, sensor.CONFIG.threshold)
        XCTAssertEqual(period, sensor.CONFIG.period)

        sensor = AccelerometerSensor.init(AccelerometerSensor.Config().apply{config in
            config.frequency = frequency
            config.threshold = threshold
            config.period = period
        });
        XCTAssertEqual(frequency, sensor.CONFIG.frequency)
        XCTAssertEqual(threshold, sensor.CONFIG.threshold)
        XCTAssertEqual(period, sensor.CONFIG.period)

        sensor = AccelerometerSensor.init()
        sensor.CONFIG.set(config: config)
        XCTAssertEqual(frequency, sensor.CONFIG.frequency)
        XCTAssertEqual(threshold, sensor.CONFIG.threshold)
        XCTAssertEqual(period, sensor.CONFIG.period)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
