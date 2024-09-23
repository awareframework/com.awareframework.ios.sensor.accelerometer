//
//  ViewController.swift
//  com.awareframework.ios.sensor.accelerometer
//
//  Created by tetujin on 11/19/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

import UIKit
import com_awareframework_ios_sensor_accelerometer

class ViewController: UIViewController {

    var sensor:AccelerometerSensor?
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        sensor = AccelerometerSensor(AccelerometerSensor.Config().apply{config in
            config.debug = true
            config.dbType = .REALM
            config.dbPath = "accelerometer"
            config.frequency = 1
            config.period = 0.1
            // config.dbHost = "node.awareframework.com:1001"
            config.dbHost = "node.awareframework.com/dgc_test"
            config.sensorObserver = Observer()
        })
        sensor?.start()
        sensor?.sync(force: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    class Observer:AccelerometerObserver{
       func onDataChanged(data: AccelerometerData){
          // Your code here...
            print(data)
       }
    }
}



