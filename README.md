# Aware Accelerometer

[![CI Status](https://img.shields.io/travis/awareframework/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://travis-ci.org/awareframework/com.awareframework.ios.sensor.accelerometer)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.accelerometer)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.accelerometer)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.accelerometer)

## Requirements
iOS 10 or later

## Installation

com.aware.ios.sensor.accelerometer is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'com.awareframework.ios.sensor.accelerometer'
```

Import com.awareframework.ios.sensor.accelerometer library into your source code.
```swift
import com_awareframework_ios_sensor_accelerometer
```

## Data Representations

### Accelerometer Data

Contains the raw sensor data.

| Field     | Type   | Description                                                         |
| --------- | ------ | ------------------------------------------------------------------- |
| x         | Double | the acceleration force along the x axis, including gravity, in G (G=9.8m/s²)|
| y         | Double | the acceleration force along the y axis, including gravity, in G (G=9.8m/s²) |
| z         | Double | the acceleration force along the z axis, including gravity, in G (G=9.8m/s²) |
| label     | String | Customizable label. Useful for data calibration or traceability     |
| deviceId  | String | AWARE device UUID                                                   |
| label     | String | Customizable label. Useful for data calibration or traceability     |
| timestamp | Long   | unixtime milliseconds since 1970                                    |
| timezone  | Int    | [Raw timezone offset][1] of the device                              |
| os        | String | Operating system of the device (ex. android)                        |


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
   condig.deviceId = UUID.init().uuidString
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
Yuuki Nishiyama, tetujin@ht.sfc.keio.ac.jp

## Related Links
* [Apple Document | Getting Raw Accelerometer Events](https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events)
