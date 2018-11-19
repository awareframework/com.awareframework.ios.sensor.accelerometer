# Aware Accelerometer

[![CI Status](https://img.shields.io/travis/tetujin/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://travis-ci.org/tetujin/com.awareframework.ios.sensor.accelerometer)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.accelerometer)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.accelerometer)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.accelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.accelerometer)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

com.aware.ios.sensor.accelerometer is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'com.awareframework.ios.sensor.accelerometer'
```

### Example usage
Import Accelerometer sensor library (com_aware_ios_sensor_accelerometer) to your target class.

```swift
import com_awareframework_ios_sensor_accelerometer
```

Generate an accelerometer sensor instance and start/stop the sensor.

```swift
let accelerometer = Accelerometer.init(Accelerometer.Config().apply{ config in
config.sensorObserver = { (data, error) in
// Your code here..
}
config.period   = 0.5
condig.deviceId = UUID.init().uuidString
config.debug    = true
})
accelerometer.start()
accelerometer.stop()
```

## Author

Yuuki Nishiyama, tetujin@ht.sfc.keio.ac.jp
