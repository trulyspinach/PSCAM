# PSCAM
Playstation Camera Driver for macOS.

## Featuring:
* Video stream from left camera into macOS applications that use CoreMedia, such as FaceTime, Zoom, Skype and etc.
* A standalone userspace application for booting PS Camera(s) that are in USB Boot mode.
* Lots of spaghetti code.

## How to use
* You need a Mac, or Hackintosh, that have USB3 port avaliable. 
* An AUX to USB adapter. Luckly you can get one from Sony for [free, if eligible](https://www.playstation.com/en-us/support/hardware/playstation-camera-adaptor/).
* Compile this from source code, then run PSCAM.app to boot up the camera.
* Install PSCAMCMDAL.plugin to CoreMediaIO plugin folder.
* Re-launch the CoreMedia application if necessary.

## Roadmap
This is just a list of feature that I think would be useful, does not mean that I am working on them.

* Combine right camera for a wider viewport.
* Perform stereo matching and output processed frame, such as blured background or virual green screen.
* Decode audio feed from 4 microphone array.

## Notes
One day, I found myself suddenly in need of a webcam from video conferencing. Obviously the first solution that came to my mind was to purchase one, but then after couple of hours spent selecting I simply can not conclude a final decision. Meanwhile this old Playstation Camera was sitting there calmly, while enjoying its meal of dust. This pile of code was born to give it a new purpose and save me from making decisions buying a new webcam.

## Contribution and help
* If you found this useful, or encountered any problem, please feel free to open up an issue and let me know.


## Credits
* [libusb](https://libusb.info)
* [libuvc](https://github.com/libuvc/libuvc)
* [Luke No... I am PlayStation Camera, part 2](https://psxdev.github.io/luke2.html)
* [SimpleDALPlugin](https://github.com/seanchas116/SimpleDALPlugin) and [coremediaio-dal-minimal-example](https://github.com/johnboiles/coremediaio-dal-minimal-example)
