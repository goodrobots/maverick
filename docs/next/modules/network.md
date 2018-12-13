# Network Module

Networking is a complex subject and the setup and configuration of networking is particularly complex, not least because of the varieties of hardware and network types.  There are many ways of configuring networking, but for an embedded UAV Companion Computer that is inherently headless (without display or keyboard), reliability and connectivity is paramount.  Therefore Maverick uses a deliberately simple networking setup.  Modern Debian/Ubuntu OS use managers such as *Connection Manager* or *Network Manager*, however these tend to be complex in nature and really intended for human/desktop use where multiple transient connections (such as multiple wifi networks) are required to be configured.

Maverick, by default, disables these Managers and uses the very simple but reliable Debian/Ubuntu networking model of configuring a single file - */etc/network/interfaces*.  This has proved to be simpler and more reliable to manage, particularly from the automated manifests that Maverick uses.

### Quick Start Wifi
For very quick initial setup of Wifi, Maverick provides a utility to help: `wifi-setup`.  This utility is mostly useful when Maverick is first installed or image first booted as it only provides a very simple network configuration.  However, it's a fast and easy way to setup wifi especially on those boards without ethernet (eg. Joule, Pi Zero W).  Simply type: `wifi-setup`, enter your router SSID and passphrase:  
```
[dev] [mav@maverick-raspberry ~/var/build]$ wifi-setup
Enter Wifi SSID: MySSID
Enter Wifi Passphrase:

Updated config, restarting networking.. (If you do not see 'Done' below shortly, reset the power)

Done
```

### Raspberry Quick Start Wifi
Maverick Raspberry OS images are based on the standard Raspbian.  Raspbian has a small /boot FAT partition which can be easily accessed from any Windows, Mac or Linux computer.  A file '*wpa_supplicant.conf*' can be placed on this partition which will be used at boot time to configure wifi.  The contents should be like this:
```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={ 
    ssid="MySSID" 
    psk="MyPassword" 
}
```

This is particularly useful for the Pi Zero which has no ethernet port and is more difficult to attach keyboard and screen to.

### PSKs - Pre Shared Keys
In the documentation below about how to setup network interfaces, wifi passphrases are represented by 'psk'.  A PSK (Pre Shared Key) is an encrypted form of the wifi passphrase, and the unencrypted passphrase form is not used anywhere for better security.  A PSK is generated from a combination of the SSID and the passphrase and can be easily generated from Maverick:  
`wpa_passphrase <SSID> <passphrase>`  
 eg.  
 `wpa_passphrase Maverick ifeeltheneed`  
 From the output of this, extract the value of the 'psk' field and use this as the psk value as the localconf parameter:  
 ```json
 network={
	ssid="Maverick"
	#psk="ifeeltheneed"
	psk=8097a204e44b0a740d5daad37d0e34ac16e4df353bc827dcd57d49b36d49740d
}
```
So from the above, the localconf parameter to set the AP psk would be:
`"psk": "8097a204e44b0a740d5daad37d0e34ac16e4df353bc827dcd57d49b36d49740d"`

### wpa_supplicant
For cases where multiple wifi networks need to be configured, or other wpa-supplicant customisations, each managed wifi interface is automatically configured to use /etc/wpa_supplicant/wpa_supplicant.conf.  A simple template is placed by Maverick if one doesn't already exist, but any changes thereafter are not touched or over-ridden by Maverick, so this file is safe to customise as you wish.

## Network Interfaces
Any number of network interfaces can be defined in localconf, with a variety of parameters that change how each interface is configured.  The chosen model is to specify the MAC address and an interface name for each interface, so they are easy to identify.  For example, a simple wifi interface for normal connectivity might be defined:  
```
"maverick_network::interfaces": {
        "wman0": {
            "type":	"wireless",
            "macaddress": "00:c2:c6:e2:45:xx", // put your wifi mac address here, can be obtained from 'maverick netinfo'
            "ssid":    "MySSID",
            "psk":    "66ab1efd34a940390e024872739778958c3350cbexxxxx"
        }
}
```
This uses the MAC address specified to fix the interface name 'wman0', and set the wifi SSID and PSK to authenticate to the AP/router.  There are different interface 'modes', by default the 'managed' mode is used, however wireless type interfaces can also use 'ap' (access point) and 'monitor' mode (used for wifibroadcast).

A second interface/wifi adapter could be used as an access point (AP), by simply defining:  
```
"maverick_network::interfaces": {
        "wman0": {
            "type":	"wireless",
            "macaddress": "00:c2:c6:e2:45:xx",
            "ssid":    "MySSID",
            "psk":    "66ab1efd34a940390e024872739778958c3350cbexxxxx"
        },
        "wap0": {
            "type": "wireless",
            "mode": "ap",
            "macaddress": "00:c2:c2:ff:32:xx"
        }
}
```
This would automatically setup the second wifi card/adapter as an AP, with the default SSID 'Maverick' and the default passphrase 'ifeeltheneed'.  It sets up the necessary software and configuration to handle authentication and IP address allocation, so any computer can immediately connect to it.

A third interface could be configured for wifibroadcast:
```
"maverick_network::interfaces": {
        "wman0": {
            "type":	"wireless",
            "macaddress": "00:c2:c6:e2:45:xx",
            "ssid":    "MySSID",
            "psk":    "66ab1efd34a940390e024872739778958c3350cbexxxxx"
        },
        "wap0": {
            "type": "wireless",
            "mode": "ap",
            "macaddress": "00:c2:c2:ff:32:xx"
        },
        "wbcast0": {
            "type": "wireless",
            "mode": "monitor",
            "macaddress": "00:b3:a9:ee:10:xx"
        }
}
```

### Managed Interface
There are additional parameters to the 'managed' mode interface.  Here is an interface definition that uses all of them:  
```
"wman0": {
    "type":	"wireless",
    "macaddress": "00:c2:c6:e2:45:xx",
    "addressing": "static",
    "ipaddress": "192.168.1.10",
    "netmask": "255.255.255.0",
    "gateway": "192.168.1.254",
    "dns_nameservers": "192.168.1.254 192.168.1.1",
    "ssid":    "MySSID",
    "psk":    "66ab1efd34a940390e024872739778958c3350cbexxxxx"
}
```
For ethernet interfaces, just change 'type' to 'ethernet' and ommit ssid/psk.

A config file is placed in */srv/maverick/config/network* for each managed interface that controls the setting of the data rate and frequency for the interface at boot.  The file is named by interface, so for the *wman0* interface, the file would be */srv/maverick/config/network/interface-wman0.conf*.

### AP Interface
The example above to setup an AP interface is quite simple.  There are additional parameters that can be set however:
```
"wap0": {
    "type": "wireless",
    "mode": "ap",
    "macaddress": "00:c2:c2:ff:32:xx",
    "ssid": "Maverick",
    "psk": "8097a204e44b0a740d5daad37d0e34ac16e4df353bc827dcd57d49b36d49740d",
    "driver": "nl80211",
    "channel": 1,
    "hw_mode": "g",
    "disable_broadcast_ssid": false,
    "apaddress": "192.168.10.1",
    "dhcp_range": "192.168.10.10,192.168.10.50",
    "dhcp_leasetime": "24h",
    "forward": "wman0"
}
```
Note that the parameter to set the IP address for AP mode is 'apaddress' instead of 'ipaddress'.  

#### Connection Sharing
'Connection Sharing', aka Masquerading or NAT, is a method of sharing a network connection.  Instead of bridging interfaces, it creates an internal network for clients, forwards the data between interfaces and translates the network addresses to the external network (and back again for the return trip).  This allows a large number of clients to share the single external connection, as well as providing a separate internal network for the clients and better isolation and security.  
`"forward": "<external interface>"`  
To setup connection sharing, simply set the 'forward' parameter in the AP interface definition to the external interface.  So for example, if there is a *wman0* interface that is connected to the internet through wifi or 3g/4g connection, and the AP interface is *wap0*, within the *wap0* definition set the 'forward' parameter to *wman0*, as shown in the example in the previous 'AP Interface' section.
![Network Connection Sharing](../media/network-connection-sharing.svg)

### Monitor / Broadcast Interface
Support for monitor/injection wifi mode and wifibroadcast software is installed by default in Maverick.  A monitor interface can be defined like:  
```
"wcast0": {
    "type": "wireless",
    "mode": "monitor",
    "macaddress": "00:af:af:ff:ff:xx"
}
```
This will add a config file named by the interface, so for the above definition the config would be */srv/maverick/config/network/monitor-interface-wcast0.conf*.  This config controls the frequency and rate of the monitor interface.  It also installs a service to control the interface at boot, and after configuring a new monitor interface a reboot is necessary to activate the config.  

After a reboot, `maverick netinfo` should show a configured *Monitor* interface:  
```
Interface:          wcast0
Type:               Wireless
MAC Address:        24:05:0f:34:53:xx
Vendor:             Ralink : Ralink Technology, Corp. : MTN Electronic Co. Ltd
Model:              RT5572 Wireless Adapter : 5572
Driver:             rt2800usb
IP Address:         None
Predictable Name:   wlx24050f34539e
Wireless Chipset:   Ralink RT2870/3070
Wireless Standards: a,b,g,n
Wireless Modes:     ibss,managed,AP,AP VLAN,wds,monitor,mesh
Wireless Bands:     Dual Band - 2.4Ghz & 5Ghz
Wireless Mode:      Monitor
Wireless SSID:      None
Wireless Frequency: 5.745 Ghz
Wireless Chanwidth: None
Wireless RSS:       None
```
Now this interface is ready to be used for monitor/injection purposes, most commonly in this environment for wifibroadcast.  wifibroadcast software is installed into */srv/maverick/software/wifibroadcast* and can be setup and run as normal.  Alternatively, it can also easily be configured through [Maverick visiond](/modules/vision#visiond)

## Network components
### Avahi
Avahi is automatically installed and configured, in order to provide 'zeroconf' multicast DNS.  Under normal networking circumstances, the Maverick system should respond to any requests for <hostname>.local, eg. maverick-raspberry.local.  Avahi 'publish-addresses' is disabled by default but can be enabled by setting localconf parameter:  
`"maverick_network::avahi::explicit_naming"`

### IPv6
By default, Maverick leaves ipv6 configuration as is.  However, ipv6 can sometimes cause problems and so support can be deliberately disabled by setting localconf parameter:  
`"maverick_network::ipv6": false`  

### Predictable Naming
'Predictable Naming' is a feature of newer Linux kernels that enumerates network devices into names that are 'predictable' based on the type of hardware and bus/address location.  These names can be useful in certain circumstances, but for embedded systems where the most common network interfaces are USB wireless interfaces, these names are useless and awkward.  So this feature is disabled by default, and traditional simple naming like 'eth0' and 'wlan0' is used instead.  To restore predictable naming, set localconf parameter:  
`"maverick_network::predictable": true`  

### ZeroTier
ZeroTier is a really interesting networking system that is very useful to connect devices to the internet and makes them contactable where they don't have a public IP, such as a lot of 4G/mobile/cell modems in widespread use in UAVs.  ZeroTier is a commercial company that runs a proprietary network, however the protocol and source code is open.  It can add considerable latency to the connection and CPU usage on the source, but does make a system reachable where it is not normally reachable.  
Maverick installs ZeroTier software by default but does not start it.  To start the client and enable at boot, set localconf parameter:  
`"maverick_network::zerotier::active": true`  
By default, Zerotier is set to join the public 'Earth' network.  To join a different network, set localconf parameter:  
`"maverick_network::zerotier::network_id": "ztnetworkhash"`  
To not join a network automatically, set localconf parameter:  
`"maverick_network::zerotier::join_network": false`  
ZeroTier can be added and activated without any of the other Maverick networking setup (which can be quite intrusive and complex).  Just add the class in localconf:  
```
"classes":
	[
		"maverick_network::zerotier"
	]
```
The libzt library is not compiled by default, but can be enabled by setting localconf parameter:  
`maverick_network::zerotier::libzt": true`  
This installs into ~/software/libzt.
