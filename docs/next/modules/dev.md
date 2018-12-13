# Development Module

The *development* module is mostly responsible for setting up the Maverick dev environment (unsurprisingly).  There are several components that make up the dev environment:

 - Cloud9 Browser based Integrated Development Environment (IDE)
 - ArduPilot source tree, compiled to chosen vehicle
 - SITL, automatically configured to run from compiled ArduPilot firmware
 - Mavlink proxy attached to SITL, to multiplex SITL mavlink across TCP and UDP connections
 - Separate Dev ROSmaster instance
 - Separate Dev MAVROS instance
 - Dedicated 'sitl' python environment

## Cloud9 IDE
Cloud9 is a fantastic browser based IDE that includes syntax highlighting, code completion, debugger, command-line terminal, and a modular plug-in architecture.  It was originally integrated to Maverick as part of the Dev module, but it turned out to be so good for general config editing and other purposes that it is now running by default for all environments.  It is implemented as part of it's [own module](/modules/cloud9).

## ArduPilot
There is a complete git clone of the ArduPilot source tree (master branch by default) in ~/code/ardupilot.  The default vehicle type is ArduCopter, and the firmware is compiled automatically for the SITL environment.  A common development workflow is to develop firmware code in SITL, then when tested and ready upload to the Flight Controller for real world testing.  Maverick makes a great development platform for this workflow.

### ArduPilot Firmware
The default source for ArduPilot can be changed by setting localconf parameter:  
`"maverick_dev::ardupilot::ardupilot_source": "https://github.com/myfork/ardupilot.git"`  
By default, if the source is different from the official source, the official source is set as the upstream.  To turn this off, set the localconf parameter:  
`"maverick_dev::ardupilot::ardupilot_setupstream": false"`  
To change the upstream source, set localconf parameter:  
`"maverick_dev::ardupilot::ardupilot_upstream": "https://github.com/anothersource/ardupilot.git"`  
To change the source branch, set localconf parameter:  
`"maverick_dev::ardupilot::ardupilot_branch": "Copter-3.5"`  
To change the vehicle type, set localconf parameter:  
`"maverick_dev::ardupilot::ardupilot_vehicle": "plane"`  
All the main vehicle types are supported: copter, plane, sub, rover, antennatracker.  Note that changing the vehicle type here also determines which vehicle type is loaded into SITL, and will involve re-compiling the firmware for the vehicle type (which is done automatically).
### Compile/Upload to Flight Controller
It is possible (and straight forward) to use Maverick on a companion computer to cross compile firmware for an actual Flight Controller hardware, and to upload the firmware.  
To do this for the px4/pixhawk and associated boards (eg. Pixracer, Cube/Pixhawk2, Pixhawk3 etc), Maverick needs to install the Arm EABI compiler toolchain.  To enable this toolchain which is disabled by default, set localconf parameter:  
`"maverick_dev::ardupilot::armeabi_packages": true`

In order to cross compile and upload the firmware for a Pixhawk, simply plug the Pixhawk into the USB port of the companion computer, and type:
```bash
cd ~/code/ardupilot
./waf --board=px4-v2 configure
./waf --upload copter
```

## Ardupilot SITL
Maverick provides a complete ArduPilot SITL environment, complete with a Mavlink proxy so multiple connection types can be made, and optionally a separate ROS environment and MAVRos connected to SITL.  
In *dev* mode, SITL is automatically compiled and installed, and a system service is enabled and running by default.  In *flight* mode, all the SITL and associated services are disabled to ensure they do not conflict or take resources during flight.  
The SITL service can be turned off by setting the localconf parameter:  
`"maverick_dev::sitl:sitl_active": false`  
SITL can be turned off in it's entirety during bootstrap by setting localconf parameter (but not recommended during normal usage):  
`"maverick_dev::sitl": false`  
There are no actual parameters or config to set within Maverick for SITL - all of this is set automatically by the ArduPilot vehicle type in the section above.  There is however a dynamic config file for SITL, in ~/config/mavlink/sitl.conf.  SITL is started using 'sim_vehicle.py', which is the [recommended way of starting SITL](http://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html).  The *~/config/mavlink/sitl.conf* provides a simple way of setting the sim_vehicle.py startup parameters.  If this config is updated, the changes are activated by restarting SITL:  
`maverick restart sitl`

### SITL Mavlink Proxy
As explained more fully in the [mavlink module](/modules/mavlink), a Mavlink proxy is used to provide multiple connection points to a Mavlink source, in this case SITL.  If a proxy is not wanted, it can be disabled by setting a localconf parameter:  
`"maverick_dev::sitl::mavlink_active": false`  
The proxy type can be changed by setting a localconf parameter:  
`"maverick_dev::sitl::mavlink_proxy": "mavproxy"`  
Current supported proxies are: *mavlink-router* (the default), *mavproxy* and *cmavnode*.  The configuration, system services and firewall rules for each proxy are automatically generated and controlled by Maverick.  
Certain values of the proxy configuration can be set (although it is recommended to keep them as default).  
The default starting tcp port that can be used for client connections is set by localconf parameter:  
`"maverick_dev::sitl::mavlink_startingtcp": 5780`  
Some proxies can only provide a single tcp endpoint (cmavnode, mavlink-router).  Mavproxy however can provide multiple tcp endpoints and Maverick provides 3 by default, starting at $mavlink_startingtcp, so 5780, 5781 and 5782.  
There are two types of udp endpoints that mavlink proxies can provide - *udp* (udpout) and *udpin*.  Maverick provides three of each udp endpoint type, starting at $mavlink_startingudp value (14580 by default for SITL).  This can be set with a localconf parameter:  
`"maverick_dev::sitl::mavlink_startingudp": 14580`  
Three ports are provided for *udp* (udpout) endpoints: 14580, 14581 and 14582.  Three ports are provided for *udpin* endpoints: 14583, 14584, and 14585.  

## ROS
A complete (separate) ROS environment is provided for development use, connected to SITL.  This separate ROS environment can be disabled during build by setting localconf parameter:  
`"maverick_dev::sitl::ros_instance": false`  
By default, a full desktop ROS build is provided and if [the desktop](/modules/desktop) is enabled then standard ROS desktop environments like *rviz* can be used.  

### ROS master
A distinct ROS master is started on a non-standard port: 11313 by default.  This can be changed by setting localconf parameter:  
`"maverick_dev::sitl::rosmaster_port": "11313"`  
The SITL ROS master can be turned off by setting localconf parameter:  
`"maverick_dev::sitl::rosmaster_active": false`  
Note this is different from disabling the ROS build altogether (the $ros_instance referred to above) - the $rosmaster_active parameter just stops and deactivates the ROS Master so it does not start at boot.  
Note that when using *roslaunch* to start ROS nodes that should communicate with this ROS master, the environment must be altered to find the SITL ROS master on the non-standard port.  A config file is automatically generated and updated that contains the necessary environment variables and can be used as a convenience:  
`source ~/config/ros/rosmaster-sitl.conf`  (or `. ~/config/ros/rosmaster-sitl.conf`)  

### MAVROS
MAVROS is provided to interface ROS with SITL through Mavlink.  By default it uses the first tcp endpoint (5780).  This can be set with localconf parameter:  
`"maverick_dev::sitl::mavlink_port": 5780`  
The SITL MAVROS instance can be disabled by setting localconf parameter:  
`"maverick_dev::sitl::mavros_active": false`  
One problem with starting the ROS master and MAVROS node at launch is that roslaunch (used to start ROS nodes including MAVROS) will start it's own master if it does not detect one running.  However, the ROS master takes a while to fully start, especially on slow platforms, so MAVROS will try and launch a conflicting master.  In order to mitigate this issue, there is a configurable startup delay applied to the MAVROS service.  By default it is 10 seconds, but on particularly slow platforms like the Raspberry it is increased by default to 20 seconds.  The higher the delay, the less likely this issue is to occur and the more reliable the platform, but it delays when the MAVROS node can be connected to and used.  This can be altered with a localconf parameter:  
`"maverick_dev::sitl::mavros_startup_delay": 60`  

## Python and Dronekit
A Python 'virtual environment' is pre-configured for SITL.  A separate copy of dronekit python is installed into ~/code/sitl, and the system portion of the virtualenv is in ~/.virtualenvs/sitl.  To activate the environment, simply type:  
```bash
workon sitl
(sitl) [dev] [mav@maverick-joule ~/code/sitl]$
```
The (sitl) denotes the python sitl virtualenv is currently active.  To use the environment in scripts:  
```bash
source /srv/maverick/.virtualenvs/sitl/bin/activate
```
The dronekit-python installed into ~/code/sitl is sourced from the official dronekit github repo, but can be changed by setting localconf parameter:  
`"maverick_dev::sitl::sitl_dronekit_source": "http://github.com/myfork/dronekit-python.git"`
