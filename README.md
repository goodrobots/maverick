# Maverick

[![Join the chat at https://gitter.im/companioncomputers/Lobby](https://badges.gitter.im/companioncomputers/Lobby.svg)](https://gitter.im/companioncomputers/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
UAV Companion Computer System

Maverick is a system for creating, maintaining and controlling UAV Companion Computers.  The name Maverick reflects the initial main goal of interfacing Companion Computers to Flight Controllers through the Mavlink protocol, specifically ArduPilot (PX4 support planned).

Please see <a href='https://fnoop.github.io/maverick/' target="maverick_docs">the documentation</a> for more info and how to install it.

What does Maverick do?

 - Downloadable, ready to flash, ready to fly images for Raspberry Pi (all models), Odroid XU4, Intel Joule
 - Downloadable VM image for developers in OVA (Open Virtual Appliance) format, should run in VirtualBox, VMware etc
 - Ability to bootstrap from any donor/vendor OS (only Debian/Ubuntu supported so far, but possible to support any base OS) and create custom images
 - Single 'maverick' command provides system/network info, self updating, system configuration, service control
 - Self-contained, consistent software environments and versions across different platforms
 - Automatic detection and configuration of platform hardware and peripherals
 - Easy modular network configuration including managed wireless, monitor/injection, Host Access Point, Avahi, Dnsmasq, DHCP client/server, wifibroadcast
 - Built-in security, firewall, antivirus, scanners
 - Selective, modular Mavlink proxy, Dronekit and MAVROS configuration, supports MAVProxy, mavlink-router, cmavnode
 - Rich web-based IDE (Integrated Development Environment) - Cloud9
 - Full SITL environment with separate mavlink proxy, dronekit and MAVROS instances
 - Extensive consistent software components installed on all platforms - ROS Kinetic, Tensorflow 1.2, OpenCV 3.2, Gstreamer 1.10.4, FPV video (visiond, camera-streaming-daemon), Orb_slam2, RTABMAP, Aruco
 - ArduPllot development environment, compiled ArduPilot for SITL, everything necessary setup to compile and upload to Flight Controllers direct from companion computer
 - Vision functions - automatic detection and configuration of attached digital cameras for FPV (visiond), Precision Landing with vision_landing, experimental collision avoidance with RealSense depth cameras, Thermal Image streaming with Seek Thermal devices (support for Flir One coming soon), experimental SLAM components ORB_SLAM2 and RTABMAP

<img src="https://fnoop.github.io/maverick/media/maverick-snapshots.jpg" width="100%">
<img src="https://fnoop.github.io/maverick/media/maverick-architecture.svg" width="100%">
