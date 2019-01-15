## What is Maverick?
Maverick is a system for creating, maintaining and controlling UAV Companion Computers.  The name Maverick reflects the initial main goal of interfacing Companion Computers to Flight Controllers through the Mavlink protocol, specifically ArduPilot.

<img src="media/maverick-snapshots.jpg" width="100%">

### Why Maverick?
UAVs, as flight vehicles that share a busy airspace and are autonomous to varying degrees, are becoming more regulated and licensed globally and as such require better and more thorough engineering.  Companion Computers are often used in conjunction with dedicated Flight Controllers to influence partially or entirely the characteristics of flight, and should be subject to the same rigours of engineering and development as any complex system in a critical environment.

Maverick brings Automation and Configuration Management to the problem of building and maintaining Companion Computers, drawing on decades of engineering experience to bring increased reliability and reduced risk to this important technology.  Configuration Management is a tried and tested engineering process and is ubiquitous in aerospace and military engineering.

UAV Companion Computers also suffer from a lack of collaborative development, unlike flight controller development.  Software for Companion Computers is usually distributed in the form of modified vendor OS images or adhoc scripts.  These are simple to download and install, but are difficult or clumsy to create and collaborate on developing, and are not upgradable.  If new features are developed, a new image must be released and end-users must download the entire new image and reinstall from scratch.  Each type of hardware or OS typically requires a new effort to produce logic and images for that platform.

Instead of creating, distributing and maintaining separate logic and large complete OS images and package repositories for each different type of computer and OS, Maverick allows agile, collaborative development of companion computers through more familiar coding and github workflow, and is OS and hardware agnostic. The same environment is created on any supported computer, on any supported OS, so the underlying platform becomes largely irrelevant.

Maverick provides easy to install OS images for convenience, but can be entirely installed from a few K of github code.  When new features are developed using Maverick, existing installs can be updated quickly and safely with a single command without any disruption to data or running services.

It is hoped by largely automating and reducing complex system installation and configuration to a simple install, this will help reduce the barriers to entry for prospective UAV developers, who can quickly get started with a full development stack at their disposal.

### What does it do?
Lots!  And lots more planned!
- Configures the computer hardware and peripherals
- Configures network interfaces, addresses, services, wireless setup
- Hardens security, configures firewall, antivirus, intrusion detection, reactive brute-force defences
- Configures flight controller proxy (MAVProxy, mavlink-router, cmavnode), Dronekit and MAVROS environment
- Compiles/installs Gstreamer and OpenCV software, Aruco fiducial marker software, FPV intelligent vision daemon, ROS, Cloud9 IDE
- Dev environment installs and configures browser IDE (Cloud9), Ardupilot SITL, proxy, dronekit environment

<img src="media/maverick-architecture.svg" width="100%">

Even though Maverick enables a rich set of functionality out of the box, the main goal of the project is actually to provide a framework for automated system configuration, rather than the features themselves.  The actual functionality of the platform is just beginning, and is at a very early stage.

### How does it work?
At the heart of Maverick is the tried and tested Configuration Management system Puppet.  Puppet is a system that abstracts the configuration of a system into declarative code, and is widely used in complex computing environments to automate computer configuration in a secure, repeatable manner that reduces risk and increases reliability.  Maverick can be used to create and install companion systems, but can also be used to update an existing system.  Maverick can be re-run any number of times and will only make changes where necessary to bring the system into the configured state.

The declarative code files are called manifests and are arranged in modules.  They effectively form building blocks that can be put together to create system blueprints.  Each module and manifest can have parameters applied through configuration files that adapt the way the declarative code is applied.  This makes a very flexible and efficient method of describing and building systems.  The assembled 'blueprints' can be simply saved as a single configuration file and reapplied any number of times to produce perfect clones.

### Hardware support
Maverick is designed to be cross platform and hardware agnostic. Initially it is being developed and tested on the following platforms:
- Raspberry Pi (3, 2 Model B, A+, Raspbian and Ubuntu)
- ODROID (XU3/XU4, Ubuntu)
- Intel Joule
- Beaglebone Black (Debian and Ubuntu)

Support will hopefully be added for more hardware in the future, eg:
- Nvidia TX1/TX2
- Intel Edison
- Up Board/Squared

Maverick will detect the base hardware platform and attached peripherals and apply software and default settings as necessary. Further base and peripheral config is available by specifying config parameters and including new modules.

### OS support
Like hardware support, Maverick is designed to be software agnostic. Currently most of the support is Debian/Ubuntu based, but the underlying Configuration Management system (Puppet) that does most of the heavy lifting is completely cross platform and has providers for almost every OS.
Currently it supports:
- Raspbian (Raspberry Pi official debian based OS)
- Odroid Ubuntu (Official ubuntu OS for Odroid XU3/4) + Experimental 4.9 kernel
- Beaglebone Black Ubuntu
- Ubuntu for Joule

It has also been lightly tested with:
- Ubuntu for Raspberry

### Environments
Maverick can place the system in one of several modes, or environments.  
- *Bootstrap:* The initial environment which sets up core hardware and OS, including expanding the filesystem to fill the available space which is often necessary to complete configuration of other environments.
- *Flight:* is the safest and quickest environment to implement.  It has less unnecessary/development software installed and running that might interfere with critical flight services.
- *Development:* adds useful software and services for development, including a separate python/dronekit virtualenv, browser based IDE (Cloud9) with edit access to all Maverick code and software, complete Ardupilot SITL build, separate mavlink proxy and ROS instances.


| | Bootstrap | Flight | Development |
|--- | :---: | :---: | :---: |
|Hardware | x | x | x |
|OS | x | x | x |
|Network |  | x | x |
|Mavlink Proxy |  | x | x |
|Dronekit |  | x | x |
|Vision |  | x | x |
|ROS |  | x | x |
|MAVROS |  | x | x |
|SITL |  |  | x |
|SITL Mavlink Proxy |  |  | x |
|SITL ROS |  |  |  x |
|SITL MAVROS |  |  |  x |
|Web IDE |  | x |  x |

______



## Configuration

### How configuration is applied
The underlying Configuration Management system (Puppet) is a declarative system, so rather than normal imperative code which is executed or compiled line by line, it looks at all of the code in the codebase up front, draws a node dependency graph and decides what actions need to be applied in order to reach the end state described in the code (or manifests, in Puppet speak).  This is counter-intuitive to normal coders so takes a little while to get used to, but in a lot of ways is actually simpler and easier to work with than traditional code.

Each manifest (code file) can contain parameters (like function parameters), and these parameters can influence how the manifest is executed.  These parameters can provide default values within each manifest, and can also be supplied or overridden by a hierarchical configuration system called Hiera.

It should also be noted that the first action in a Puppet run is to collect information about the system through 'facts', which are supplied by a component called Facter.  These facts are passed through to Puppet and can be accessed within the manifests to further (or initially) influence the node graph.

So for example, a simple Puppet manifest to install some software and define a system service (to start a service at boot, for example):
```puppet
class test (
  $package_state = "installed",
  $service_state = "running",
  $service_atboot = true,
) {
  package { "test-package":
    ensure    => $package_state
  }
  service { "test-service":
    ensure      => $service_state,
    enable      => $service_atboot,
    require     => Package["test-package"]
  }
}
```

This tells Puppet that you want a software package called 'test-package' to be installed.  In the background it works out what platform, architecture and OS is running and how software should be found and installed.  On debian or ubuntu it will use apt or dpkg, on CentOS/Fedora it will use yum or rpm.

It then sets a system service called 'test-service' to be actively running, and to start at boot.  Most systems these days use systemd, but Puppet will work out in the background what the appropriate service method is used and apply it (eg. init, upstart, systemd).  The require parameter tells the node graph compiler that this Service should happen *after* the Package, for example if the package provides the service manifests which is a common scenario.

However, anywhere in the Hiera configuration (described below in [Local Configuration](#local-configuration)) these parameters can be overridden.  So if we wanted to ensure this software is fully disabled, we simply set configuration entries to:
```json
{
  "test::package_state": "absent",
  "test::service_state": "stopped",
  "test::service_atboot": false
}
```
These entries are in the format: `"<class>::<parameter>": <value>`

There are multiple levels of configuration, defined in /srv/maverick/software/maverick/conf/hiera.yaml.  The entries in the :hierarchy section are in order of specificity, so the top entries override lower entries, and these entries represent json files within the /srv/maverick/software/maverick/conf or /srv/maverick/config/maverick directories.  So, some basic defaults are set in puppet-defaults.json and maverick-defaults.json - in particular it includes *base*, *maverick_desktop* and *maverick_security* modules by default.

!> Important Note: The hierarchical configuration *merges* rather than strictly overrides conflicting entries, where that resource can have multiple values.  So for example _classes_ can be defined in multiple levels of the hierarchy and all classes defined in all levels will be called, rather than just the classes defined in the top level.

### Local configuration
The simplest way to configure Maverick is to use the local config file: /srv/maverick/config/maverick/localconf.json.  This JSON file feeds into to the hiera config and is a convenient place to keep config.  A sample file is provided that does not do anything but gives some examples of what can be changed.  This is a good place to set (encrypted) passwords, wifi keys, git settings etc. as this file is in .gitignore and will never be committed back to git.

!> Important: All hiera json files must be strictly valid json, make sure no trailing commas are left lying around.

For example, this is a simple config :
```json
{
  "maverick_desktop::enable": true,
  "maverick_network::interfaces": {
    "wman0": {
      "type": "wireless",
      "macaddress": "24:05:0f:34:xx:xx",
      "mode": "managed",
      "ssid": "myrouter",
      "psk": "66ab1efd34a940390e024872739778958c3350cbe82c873dce9xxxxxx"
    },
      "wap1": {
      "type": "wireless",
      "macaddress": "00:c0:ca:88:xx:xx",
      "mode": "ap",
    }
  },
  "maverick_dev::ardupilot::ardupilot_source": "https://github.com/fnoop/ardupilot",
  "maverick_baremetal::odroid::kernel4x": true,
  "maverick_ros::installtype": "source",
  "maverick_security::firewall": true,
  "maverick_security::fail2ban": true,
  "classes":		[
	   "maverick_network"
   ]
}
```
This turns on desktop environment (disabled by default), sets up one managed network interface (wman0) to connect to a router, sets up a second network interface as an Access Point (default SSID is 'Maverick', default password is 'ifeeltheneed'), clones and compiles a fork of ardupilot (it automatically sets the upstream), compiles and installs experimental 4.9 odroid xu4 kernel (which also automatically compiles a modified version of gstreamer for the odroid MFC), compiles latest version of ROS from source, configures and enables a firewall and brute-force protection.

!> Note the last entry is to include the maverick_network class.  Networking is *not configured by default* as this would break existing connectivity.

### Local node config
Another way to configure Maverick is to place a pre-configured json file into /srv/maverick/config/maverick/local-nodes directory named after the hostname.  This is a great way of quickly rebuilding computers to a known configuration, or cloning computers to identical configurations (eg. for a swarm).  So for example:
```
cp /var/tmp/swarm-raspberry.json /srv/maverick/config/maverick/local-nodes
hostname swarm-raspberry
maverick configure
```
Maverick looks for a file in the local-nodes directory with the same name as the hostname, and if present adds it with a lower specificity than the localconf.json descibed in the previous section ([Local Configuration(/#/#local-configuration)]), so the localconf.json entries will always take priority.

All these json config files have the same syntax and scope, so a good workflow is to make changes in localconf.json and when happy with the changes to save these to a local-node file.  A library of local-node files can be easily built up and activated by just changing the hostname to whatever config is required.

### Sample node configs
A library of pre-set configs are included in /srv/maverick/software/maverick/conf/sample-nodes.  For example, there is a raspberrylcd.json that configures a Raspberry Pi with an LCD screen.  So the installation steps from scratch into flight mode would be:
```
sudo apt-get update && sudo apt-get -y upgrade
sudo apt-get install -y git && git clone https://github.com/goodrobots/maverick.git
hostname raspberrylcd
cd maverick && sudo ./bin/maverick --env=bootstrap configure
sudo reboot
maverick --env=flight configure
```
The sample-nodes files that start with 'maverick-' (eg. maverick-joule.json, maverick-raspberry.json, maverick-droidxu4.json) are the actual configs used to produce the downloadable OS images.
