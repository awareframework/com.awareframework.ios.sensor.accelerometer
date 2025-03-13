# AWARE: Accelerometer

[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.accelerometer)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.accelerometer)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.accelerometer)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

This sensor module allows us to manage 3-axis accelerometer data which is provided by iOS CoreMotion Library. Please check the link below for details. 

> An accelerometer measures changes in velocity along one axis. All iOS devices have a three-axis accelerometer, which delivers acceleration values in each of the three axes. The values reported by the accelerometers are measured in increments of the gravitational acceleration, with the value 1.0 representing an acceleration of 9.8 meters per second (per second) in the given direction. Acceleration values may be positive or negative depending on the direction of the acceleration. 

[ Apple | Getting Raw Accelerometer Events ](https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events)

## Requirements
iOS 13 or later

## Installation


You can integrate this framework into your project via Swift Package Manager (SwiftPM) or CocoaPods.

### SwiftPM
1. Open Package Manager Windows
    * Open `Xcode` -> Select `Menu Bar` -> `File` -> `App Package Dependencies...` 

2. Find the package using the manager
    * Select `Search Package URL` and type `git@github.com:awareframework/com.awareframework.ios.sensor.accelerometer.git`

3. Import the package into your target.


### CocoaPods

com.aware.ios.sensor.accelerometer is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'com.awareframework.ios.sensor.accelerometer'
```

Import com.awareframework.ios.sensor.accelerometer library into your source code.
```swift
import com_awareframework_ios_sensor_accelerometer
```

## Public functions

### AccelerometerSensor

+ `init(config:AccelerometerSensor.Config?)` : Initializes the accelerometer sensor with the optional configuration.
+ `start()`: Starts the accelerometer sensor with the optional configuration.
+ `stop()`: Stops the service.

### AccelerometerSensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: AccelerometerObserver`: Callback for live data updates.
+ `frequency: Int`: Data samples to collect per second (Hz). (default = 5)
+ `period: Float`: Period to save data in minutes. (default = 1)
+ `threshold: Double`: If set, do not record consecutive points if change in value is less than the set value.
+ `enabled: Boolean` Sensor is enabled or not. (default = `false`)
+ `debug: Boolean` enable/disable logging to `Logcat`. (default = `false`)
+ `label: String` Label for the data. (default = "")
+ `deviceId: String` Id of the device that will be associated with the events and the sensor. (default = "")
+ `dbEncryptionKey` Encryption key for the database. (default = `null`)
+ `dbType: Engine` Which db engine to use for saving data. (default = `Engine.DatabaseType.NONE`)
+ `dbPath: String` Path of the database. (default = "aware_accelerometer")
+ `dbHost: String` Host for syncing the database. (default = `null`)

## Broadcasts

### Fired Broadcasts

+ `AccelerometerSensor.ACTION_AWARE_ACCELEROMETER` fired when accelerometer saved data to db after the period ends.

### Received Broadcasts

+ `AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_START`: received broadcast to start the sensor.
+ `AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_STOP`: received broadcast to stop the sensor.
+ `AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_SYNC`: received broadcast to send sync attempt to the host.
+ `AccelerometerSensor.ACTION_AWARE_ACCELEROMETER_SET_LABEL`: received broadcast to set the data label. Label is expected in the `AccelerometerSensor.EXTRA_LABEL` field of the intent extras.

## Data Representations

### Accelerometer Data

Contains the raw sensor data.

| Field     | Type   | Description                                                         |
| --------- | ------ | ------------------------------------------------------------------- |
| x         | Double | the acceleration force along the x axis, including gravity, in G (G=9.8m/s²)|
| y         | Double | the acceleration force along the y axis, including gravity, in G (G=9.8m/s²) |
| z         | Double | the acceleration force along the z axis, including gravity, in G (G=9.8m/s²) |
| label     | String | Customizable label. Useful for data calibration or traceability     |
| deviceId  | String | AWARE device UUID                                                                 |
| label     | String | Customizable label. Useful for data calibration or traceability     |
| timestamp | Int64   | Unixtime milliseconds since 1970                                          |
| timezone  | Int    | Timezone  of the device                                       |
| os        | String | Operating system of the device (ex. android)                              |


### Example usage
Import Accelerometer sensor library (com_aware_ios_sensor_accelerometer) to your target class.

```swift
import com_awareframework_ios_sensor_accelerometer
```

Generate an accelerometer sensor instance and start/stop the sensor.

```swift
let accelerometer = Accelerometer.init(Accelerometer.Config().apply{ config in
   config.sensorObserver = Observer()
   config.period   = 0.5
   config.deviceId = UUID.init().uuidString
   config.debug    = true
})

accelerometer?.start()

accelerometer?.stop()
```

```swift
class Observer:AccelerometerObserver{
   func onDataChanged(data: AccelerometerData){
      // Your code here...
   }
}
```

## Author
Yuuki Nishiyama, yuuki.nishiyama@oulu.fi

## Related Links
* [ Apple | Getting Raw Accelerometer Events ](https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events)
* [ Apple | CoreMotion ](https://developer.apple.com/documentation/coremotion)

## License
Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

