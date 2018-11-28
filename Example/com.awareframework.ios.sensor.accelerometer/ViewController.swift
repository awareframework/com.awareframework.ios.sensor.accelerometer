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
        sensor = AccelerometerSensor.init(AccelerometerSensor.Config().apply{config in
            config.debug = true
            config.dbType = .REALM
            config.frequency = 30
        })
        sensor?.start()
        self.sensor?.sync(force: true)
        
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (timer) in
            self.sensor?.sync(force: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

