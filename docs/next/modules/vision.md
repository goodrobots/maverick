# Vision Module
Vision is an important (and fun) part of UAVs.  Maverick provides preinstalled and preconfigured components to support standard elements of Computer Vision and Video functionality, and more are being added all the time:

- [**Gstreamer**](/modules/vision#gstreamer): Industry standard software for capturing, transcoding and transmitting video
- [**OpenCV**](/modules/vision#opencv): Industry standard software for Computer Vision
- **Aruco**: Fiducial Tag library, for recognising tags/markers in video
- [**Visiond**](/modules/vision#visiond): A dynamic service that detects camera and encoding hardware, and automatically generates a gstreamer pipeline to transmit the video over the network - eg. wifi.  Very useful for FPV, it will in the future be useful for transmitting CV and other video
- [**Vision_seek**](/modules/vision#vision_seek): Similar to visiond, a daemon for streaming/saving video stream from a Seek Thermal imaging device.
- [**Flir One**](/modules/vision#flirone): Support for Flir One thermal imaging camera
- [**Vision_landing**](/modules/vision#vision_landing): Software that uses tags/markers (Aruco) as landing patterns, and controls Precision Landing in ArduCopter
- [**Camera-streaming-daemon**](/modules/vision#camera-streaming-daemon): RTSP Video server with service discovery publishing.
- [**Wifibroadcast**](/modules/vision#wifibroadcast): Innovative software that uses monitor/inject mode of compatible wifi adapters to provide connection-less wifi video with graceful degradation, similar to traditional analogue FPV.
- [**Collision-avoidance-library**](/modules/vision#collision-avoidance-library): Intel RealSense Collision Avoidance Library is a library/tool for investigating collision avoidance strategies.  It uses Intel RealSense cameras for depth perception and allows different detection methods and avoidance strategies.
- [**Orb_Slam2**](/modules/vision#orb_slam2): Fast library for performing monocular and stereo SLAM
- [**RTAB-Map**](/modules/vision#rtab-map): RGB-D Graph-Based SLAM

One key advantage of Maverick is that wherever possible it provides the same versions of software across all platforms.  This is very useful for porting code and functionality across platforms, as the underlying components often vary widely in their APIs/features.  As of Maverick 1.1.5, the component versions are:  
- Gstreamer: **1.12.4**
- OpenCV: **3.3.1**
- ROS: **Kinetic**  

There are a few exceptions, eg. Raspberry gstreamer has extensive modifications made to support the Raspberry VPU that handles the hardware video encoding so this platform is stuck with an  old version of gstreamer (1.10.4), and very recent versions of Ubuntu on Intel platforms use ROS Lunar.

### Gstreamer
Apart from the Raspberry platform as mentioned above, Gstreamer is a set version compiled from source on all platforms.  It includes certain optimizations and extra modules where appropriate for the platform - relevant hardware encoding modules for Odroid and Intel platforms.

The standard source-compiled gstreamer is installed into ~/software/gstreamer, and the necessary supporting environment is automatically set.  All other standard source-compiled Maverick software components such as OpenCV, ROS, Aruco, visiond, vision_landing etc all use this version of gstreamer.

It is possible to set the version of gstreamer in a localconf parameter (note this requires clearing the gstreamer install flag and waiting for a recompile, which can take up to several hours depending on the speed of the platform):  
`"maverick_vision::gstreamer::gstreamer_version": "1.12.0"`  
It is possible to install gstreamer from system packages by setting localconf parameter:  
`"maverick_vision::gstreamer::gstreamer_installtype": "native"`  

### OpenCV
Like gstreamer, OpenCV is compiled from source for a consistent version across all platforms.  Most current OS distributions provide the elderly OpenCV2.  OpenCV3 is a major release with many improvements and new features, Maverick provides the latest stable release - 3.3.0.  This version can be changed by setting localconf parameter:  
`"maverick_vision::opencv::opencv_version": "3.x.x"`  
Note that OpenCV takes a **long** time to compile on slower platforms (6 hours+ on a Raspberry).  Opencv-contrib is included as standard, this can be disabled during compile by setting localconf parameter:  
`"maverick_vision::opencv::contrib": false`  
There are two compile options which rarely need to be changed:  
 - `"maverick_vision::opencv::release": "Release"` can be changed to 'Debug' to produced debug libraries/binaries
 - `"maverick_vision::opencv::precompile_headers": false'` controls how the compile process uses precompile to speed up compilation.  However, it uses vast amounts of disk space so is turned off by default in Maverick

OpenCV is installed into ~/software/opencv and the necessary supporting environment is automatically set.  

OpenCV in the 'maverick-raspberry' profile or the 'Raspberry Pi (All models)' OS image is optimised for the Raspberry Pi 2/3 and the ARM NEON instruction set, and will not work on the single-core variants of the Raspberry (Pi Zero, Model A, original Model B).  OpenCV in the 'maverick-raspberrylite' or the 'Raspberry Pi Lite (Pi Zero/W)' OS image is less optimised but will run on any Raspberry variant.

### Visiond
Visiond is a Maverick-specific (python-based) daemon that automates the process of capturing, transcoding and transmitting video over the network.  It detects the attached camera and encoding hardware and constructs a gstreamer pipeline based on the detected hardware details.  There is a dynamic config file in *~/config/vision/maverick-visiond.conf* that allows easy configuration of the device, video format, resolution, framerate and network output.  To activate the config changes, restart the service:  
`maverick restart visiond`  
This service is started by default. To turn it off at boot, set a localconf parameter:  
`"maverick_vision::visiond::active": false`  

Visiond tries to autodetect the connected camera, the stream type (raw,mjpeg,h264), then optimal encoding type and the payloading, and also tries to autodetect and utilise any connected hardware encoding capabilities.  The config file can be used to override any part of the autodetected pipeline construction.  
For example, the Raspberry Pi with the Pi camera has a very specific set of requirements to stream video - it requires Raw stream from the first v4l2 video source with pixel format I420, attached directly to the hardware OMX h264 encoder, then rtph264pay payloading before sending to the udp output sink.  Visiond usually automatically detects all of this, but the config file can be used to specifically set these requirements, eg:
```
camera_device = /dev/video0
format = yuv
pixelformat = I420
encoder = h264
width = 1280
height = 720
framerate = 30
```

#### Connecting to visiond - RTSP mode
As of Maverick 1.1.5, visiond can be used as a central video server (RTSP Server), and multiple clients can connect over UDP/RTSP.  This is a much more convenient method of connection as the client IP addresses do not need to be known and set in the configuration file.  RTSP is now enabled and set by default in new config files.  To set older config files (~/config/vision/maverick-visiond.conf) to serve RTSP, set:  
```
output = rtsp
output_dest = 0.0.0.0
output_port = 5600
```

##### Maverick WebVision - RTSP
Maverick 1.1.5 introduces 'WebVision', a browser-based client for viewing video from visiond.  This uses a Chrome plugin from VXG that proxies the RTSP source into the browser, and requires a recent version of Chrome.  Future versions of WebVision will support mjpeg and webrtc streams.  From the Maverick front index web page, choose the 'WebVision - Live Video' link.  
WebVision runs a small Tornado web service and is reverse proxied from port 6793 to the main web port (80/443 by default).  To turn the tornado service off, set a localconf parameter:  
`"maverick_vision::webvision_active": false`  
WebVision reads the visiond config file (~/config/vision/maverick-visiond.conf) to determine the RTSP port, and takes the FQDN of the server from the server itself.  If this detected fqdn is not available from the browser clients, it can be manually set in the config file by setting the paramter:  
`webvision_hostname = maverick-raspberry.local`  

![Webvision Stove](../media/webvision-stove.jpg)
WebVision streaming in realtime visual representation of thermal data from Flir One imager.

##### Gstreamer client - RTSP
A gstreamer client pipeline like this should work to act as an RTSP client:  
```
gst-launch-1.0 rtspsrc location=rtsp://maverick-raspberrylite.local:5600/video latency=0 drop-on-latency=true caps="application/x-rtp, media=(string)video, clock-rate=(int)90000, encoding-name=(string)H264, payload=(int)96" ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! queue ! decodebin ! autovideosink sync=false
```
##### GCS client - RTSP
Mission Planner and QGroundControl support video streaming through RTSP.  Their pipelines are set in the software (although at least with Mission Planner the pipeline can be specified) and most default to udp port 5600 with h264 encoding and rtp264 payload.
In GQroundControl->Application Settings->General->Video, set the Video Source to 'RTSP Video Stream' and the RTSP URL to something like   'rtsp://192.168.1.xxx:5600/video'  
Note that in both QGC and Mission Planner, you have to specify the IP address of the maverick device, not the zeroconf hostname.  For some reason even on zeroconf enabled platforms this does not seem to work.
##### VLC - RTSP
VLC supports RTSP although extra effort is required to obtain decent latency as a 2 second buffer is added by default.  A simple client connection can be made by going to File->Network Connection, and in the URL box enter 'rtsp://maverick-raspberrylite.local:5600/video' and hit Open.  To reduce the latency in VLC, <a href='https://github.com/01org/camera-streaming-daemon/issues/45#issuecomment-303958941' target=_ghbug>refer here</a>.

#### Connecting to visiond - Outbound mode
Visiond (as with most gstreamer based video services) can send out video to a specified target, rather than multiple clients being able to connect to it - this is the traditional model for digital FPV video.  In this model you must specify the target IP address in the 'output_dest' parameter of the ~/config/vision/maverick-visiond.conf config file, and the target IP address is the IP address of the computer that the video will be displayed on.  Typically on Linux or MacOS this can be found with `ifconfig` or `ip a` commands, or `ipconfig` under windows.  The IP address should then be set in the visiond config along with the desired port and output type:  
```
output = udp
output_dest = 192.168.1.243
output_port = 5600
```
##### Gstreamer client
Gstreamer is the technology that is used to capture, transcode and stream the video from the onboard computer running Maverick, and a gstreamer client is needed to display the video.  This can be downloaded for most platforms from https://gstreamer.freedesktop.org/, and is often installed already on a Linux OS (or easily installed from the system software packages).  A client pipeline then needs to be constructed that closely matches the sending pipeline.  This is often a source of great confusion, but for the default autodetected pipelines constructed by maverick-visiond, a client pipeline like this should work:  
```
gst-launch-1.0 udpsrc port=5600 buffer-size=0 caps="application/x-rtp, media=(string)video, clock-rate=(int)90000, encoding-name=(string)H264, payload=(int)96" ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! queue ! decodebin ! autovideosink sync=false
```
##### GCS client
Most GCS (Ground Control Station) software used by Ardupilot/PX4 users such as Mission Planner and QGroundControl now support video streaming.  Their pipelines are set in the software (although at least with Mission Planner the pipeline can be specified) and most default to udp port 5600 with h264 encoding and rtp264 payload.  GQroundControl works with the default h264 udp stream that visiond presents, so the output can be set to:
```
output = udp
output_dest = 192.168.1.243
output_port = 5600
```
In QGroundControl General Application settings, in the Video section, the Video Source should be set to 'UDP Video Stream', UDP Port to 5600 and the video should show up in the HUD video window.

##### Troubleshooting
The first place to look is in the visiond logs, found in ~/var/log/vision/maverick_visiond.log and ~/var/log/vision/maverick_visiond.daemon.log.  These can show any errors, bugs or hardware problems but also shows the pipeline that has been constructed through specified or autodetected configuration.

### Vision_seek
Vision_seek is a service similar to visiond, for the Seek Thermal Compact and CompactPro thermal image cameras.  It captures the thermal data, transcodes and processes the data into a format suitable for visualisation, and then streams or saves the images or video to the network or file.  A nice simple setup is to plug the Seek camera directly into the USB port of a Raspberry Pi Zero (W).  
![](../media/pizero-seekthermal.jpg)
There is a config file in ~/config/vision/vision_seek.conf that allows a simple way to alter settings - to activate the changes,  restart the service:  
`maverick restart vision_seek`  
This service is not started by default.  To start it:  
`maverick start vision_seek`  
To enable it by default on boot, set a localconf parameter:  
`"maverick_vision::vision_seek::active": true`  
Note that the hardware support for the Seek Thermal camera is automatically applied during a configure run if the camera is plugged in and detected.  To force this support to be installed if building a platform that the Seek is likely to be used with, refer to the [hardware documentation for Seek Thermal devices](/modules/hardware#seek-thermal-cameras).  

Image of lunch, without dead pixel correction applied:  
![thermal lunch](../media/thermal-lunch.jpg)

Image of Intel Joule before and after some hard work (running Maverick vision_landing):  
![Thermal Joule](../media/joule-thermal.jpg")

#### Flat Field Correction (FFC)  
To create an FFC image that can be applied to vision_seek to improve image quality, first run the camera for a while to warm it up, then cover the lens with something thermally consistent (eg. a book, or DVD cover) and run:  
`~/software/libseek-thermal/bin/seek_create_flat_field -c seek ~/config/vision/seek_ffc.png`  
Then set the *FFC* setting in *~/config/vision/vision_seek.conf* to point to this file:  
`FFC=/srv/maverick/config/vision/seek_ffc.png`  
If FFC is set in the config file, vision_seek will automatically apply it.  
More information about this FFC procedure can be found in the github project of the main supporting library behind vision_seek:  
https://github.com/maartenvds/libseek-thermal
#### Output
Vision_seek has three methods of output, all controlled by setting the *OUTPUT* parameter in the *~/config/vision/vision_seek.conf* config file.
 - _window_: This outputs to a local window.  This will not work when running vision_seek as a service, as the service is disconnected from any terminal and does not know where to create the window.  Instead, run `vision_seek.sh` from the command line, either logged into the desktop or through ssh with X-forwarding enabled (*ssh -X* or *ssh -Y*).
 - _filename.avi_: This outputs a raw video file to specified filename/path.  Raw video files can be very large but because of the relatively low resolution of the Seek devices this should not be a problem.
 - _appsrc gstreamer pipeline_: It is also possible to specify a gstreamer pipeline - _Note: the pipeline must start with 'appsrc ! '_.  This can be very useful for compressing the video, transcoding or converting the video format, or streaming over the network.  Several examples are given in the config file.

### Flir One
Maverick supports the Flir One thermal imaging camera.  
![Flir One](../media/pizero-flirone.jpg)
Unlike the Seek Thermal camera which is supported entirely in userspace through OpenCV, Flir One support is achieved through v4l2 loopback devices.  Although a bit harder to set up, this method is easier and more flexible to use as the imager is accessed through standard v4l2 interfaces.  
Flir One support is disabled by default.  To enable support, set localconf parameter:  
`"maverick_hardware::flirone_install": true`  
To start the flir one service at boot, set localconf parameter:  
`"maverick_hardware::flirone::active": true`  
Once the flirone service is started, three v4l2 devices should be present and working:
 - /dev/video1: Greyscale stream of thermal data
 - /dev/video2: RGB camera
 - /dev/video3: Colourised stream of thermal data  

To stream the colourised thermal stream, visiond must have specific config set:  
```
camera_device = /dev/video3
format = yuv
pixelformat =
width = 160
height = 128
framerate = 8
output = rtsp
output_dest = 0.0.0.0
output_port = 5600
```
![](../media/flirone-radiator.jpg)

### Vision_landing
vision_landing combines the Aruco, Gstreamer, OpenCV and optionally RealSense components to create a system that analyses video in realtime for landing markers (Aruco/April fiducial markers, or tags) and uses these markers to estimate the position and distance of the landing marker compared to the UAV and passes this data to the flight controller to achieve Precision Landing.  The flight controller applies corrections according to the attitude of the UAV to work out what needs to be done to land directly on the marker.  A well tuned setup can achieve reliable accuracy to within a couple of centimeters.  

![](../media/precland1.png)

It is a work in progress (as is the support for vision based landing in ArduPilot) - the main project page is https://github.com/fnoop/vision_landing.

Like visiond, it has a dynamic config in ~/config/vision/vision_landing.conf, and to activate any config changes, restart the service:  
`maverick restart vision_landing`  
This service is not started by default, as it contends for camera usage with visiond.  To use it, first turn off visiond (`maverick stop visiond`).  It can be started a boot by setting a localconf parameter:  
`"maverick_vision::vision_landing::active": true`
### Camera-streaming-daemon
camera-streaming-daemon is an open-source project from Intel (https://github.com/01org/camera-streaming-daemon).  It is still early stages for the project, but it has great promise for an improvement in the method that realtime digital video is normally implemented on UAVs.  Instead of the normal method of providing a gstreamer pipeline and endpoint to send data to, camera-streaming-daemon (csd) provides an RTSP server with multiple endpoints to connect to if there are multiple cameras or streams available, and publishes these streams over the network using Zeroconf/Avahi.  
camera-streaming-daemon is not yet the default over visiond (although it is intended to be when more mature), so it can be started simply by calling the csd service (after stopping visiond, which would contend for the video resource):  
`maverick stop visiond`  
`maverick start csd`  
To start at boot, set a localconf parameter:  
`"maverick_vision::camera_streaming_daemon::active": true`  

### Collision-avoidance-library
Intel RealSense Collision Avoidance Library is a library/tool for investigating collision avoidance strategies.  It uses Intel RealSense cameras for depth perception and allows different detection methods and avoidance strategies.  It is not intended to be an end-user service but more a system for developers to investigate collision avoidance.  Further information can be found here:  
https://github.com/01org/collision-avoidance-library/wiki  
Maverick provides collision-avoidance-library as a pre-installed and pre-configured vision component in the OS images.  It is not installed by default when building Maverick from scratch, to install it set a localconf parameter:  
`"maverick_vision::collision_avoidance": true`  
The coav-tool is controlled by maverick service *coav*, so to start and stop the service:  
`maverick start coav`  
`maverick stop coav`  
To configure it, alter configuration file *~/config/vision/coav.conf* and restart to activate the changes: `maverick restart coav`.  

### Orb_slam2
Orb_slam2 is installed and configured as part of the OS images, but is not installed by default when building Maverick from scratch, as it takes a lot of resource and is really an experimental/academic project - of limited real-world use.  To enable it, set localconf parameter:  
`"maverick_vision::orb_slam2": true`  

### RTAB-Map
Like Orb_slam2, RTAB-Map is installed as part of the OS images, but is not installed by default when building Maverick from scratch as it takes a lot of resource to compile and install.  To enable it, set localconf parameter:  
`"maverick_vision::rtabmap": true`  

### CUAV
CUAV is an image processing module for MAVProxy.  It is installed by default.  For more information, please see the [official documentation](http://canberrauav.github.io/cuav/build/html/index.html).
