class maverick-network (
    $ethernet = true,
    $wireless = true,
    $netman = false,
    $predictable = false,
    $dhcpcd = false,
    $dnsmasq = false,
    $dnsclient = false, 
    $ntpclient = false,
    ) {

    # Install software 
    ensure_packages(["ethtool", "libpcap-dev", "iw", "wpasupplicant", "rfkill", "dnsutils", "resolvconf"])
    
    python::pip { 'pip-python-wifi':
        pkgname     => 'python-wifi',
        ensure      => present,
    }
    # Ensure wpa_supplicant isn't running
    service { "wpa_supplicant":
        ensure      => stopped,
        enable      => false,
        require     => Package["wpasupplicant"]
    }

    # Base network setup
    class { "network": 
        hostname => "${hostname}",
        config_file_notify => '',
    }
    network::interface { 'lo':
        enable_dhcp     => false,
        auto            => true,
        method          => loopback,
        manage_order    => 0,
    }

    if $ntpclient == true {
        class { "maverick-network::ntpclient": }
    }
    
    if $dnsclient == true {
        class { "maverick-network::dnsclient": }
    }

    if $dnsmasq == true {
        class { "maverick-network::dnsmasq": }
    }

    if $dhcpcd == false {
        # Make sure dhcp client daemons are turned off, for now we depend on dhclient/wpa_supplicant
        service { "udhcpd":
            ensure      => stopped,
            enable      => false
        } ->
        package { "dhcpcd5":
            ensure      => absent,
        }
    }

    # Set high network buffers to better cope with our likely crappy usb ethernet and wifi links (12mb instead of default 128k)
    # Need to look closer at this to ensure it doesn't increase latency
    base::sysctl::conf { 
        "net.core.rmem_max": 							value => '12582912';
        "net.core.wmem_max": 							value => '12582912';
        "net.ipv4.tcp_rmem":							value => "10240 87380 12582912";
        "net.ipv4.tcp_wmem":							value => "10240 87380 12582912";
    }
    
    ### Interface naming configuration
    # Turn off biosdevname
    package { "biosdevname":
        ensure      => purged,
    }
    # Turn off desktop udev rules
    file { "/etc/udev/rules.d/75-persistent-net-generator.rules":
        ensure      => link,
        target      => "/dev/null",
    }
    if $predictable == false {
        file { "/etc/udev/rules.d/80-net-setup-link.rules":
            ensure      => link,
            target      => "/dev/null",
        }
        if $odroid_present == "yes" {
            lineval { "predictable-names-odroid-off":
                file => "/media/boot/boot.ini", 
                field => "net.ifnames", 
                oldvalue => "1", 
                newvalue => "0", 
                linesearch => "bootrootfs"
            }
        }
        if $raspberry_present == "yes" {
            lineval { "predictable-names-raspberry-off":
                file => "/boot/cmdline.txt", 
                field => "net.ifnames", 
                oldvalue => "1", 
                newvalue => "0", 
                linesearch => "root="
            }
        }
    } else {
        file { "/etc/udev/rules.d/80-net-setup-link.rules":
            ensure      => absent,
        }
        if $odroid_present == "yes" {
            lineval { "predictable-names-odroid-on":
                file => "/media/boot/boot.ini", 
                field => "net.ifnames", 
                oldvalue => "0", 
                newvalue => "1", 
                linesearch => "bootrootfs"
            }
        }
        if $raspberry_present == "yes" {
            lineval { "predictable-names-raspberry-on":
                file => "/boot/cmdline.txt", 
                field => "net.ifnames", 
                oldvalue => "0", 
                newvalue => "1", 
                linesearch => "root="
            }
        }
    }
    
    # Remove connman - ubuntu/intel connection manager.  Ugly and unwielding, we want a more controllable, consistent interface to networking.
    # Ensure This is done after the rest of wireless is setup otherwise we lose access to everything.
    if $netman == false and $netman_connmand == "yes" {
        warning("Disabling connman connection manager: Please reset hardware and log back in if the connection hangs.  Please reboot when maverick is completed to activate new network config.")
        file { "/etc/resolv.conf":
            ensure      => file,
            owner       => "root",
            group       => "root",
            mode        => 644,
        } ->
        service { "connman.service":
            ensure      => undef,
            enable      => false,
        }
    } 
    
    # Remove NetworkManager
    if $netman == false and $netman_networkmanager == "yes" {
        warning("Disabling NetworkManager connection manager: Please reset hardware and log back in if the connection hangs.  Please reboot when maverick is completed to activate new network config.")
        service { "NetworkManager.service":
            ensure      => stopped,
            enable      => false,
        } ->
        service { "NetworkManager-wait-online":
            ensure      => stopped,
            enable      => false
        } ->
        package { "network-manager":
            ensure      => absent, # remove but don't purge, so it can be restored later
        }
    }
    
    # Hack ifup-wait-all-auto.service to have a shorter timeout period as this hangs the boot process until all interfaces are up.  We don't want this.
    exec { "hack-ifup-wait":
        command     => '/bin/sed /lib/systemd/system/ifup-wait-all-auto.service -i -r -e "s/^TimeoutStartSec\\=.*/TimeoutStartSec=5/"',
        unless      => "/bin/grep 'TimeoutStartSec\\=5' /lib/systemd/system/ifup-wait-all-auto.service",
        onlyif      => "/bin/ls /lib/systemd/system/ifup-wait-all-auto.service",
    }
    
    # Reduce dhcp timeout
    # First, if we don't have an unhashed timeout line, unhash one
    exec { "dhcp-reduce-timeout-unhash":
        command     => '/bin/sed /etc/dhcp/dhclient.conf -i -r -e "s/^#timeout/timeout/"',
        unless      => "/bin/grep -e '^timeout' /etc/dhcp/dhclient.conf",
    } ->
    # Change the timeout value if necessary
    exec { "dhcp-reduce-timeout":
        command     => '/bin/sed /etc/dhcp/dhclient.conf -i -r -e "s/^timeout\s.*/timeout 5/"',
        unless      => "/bin/grep -e '^timeout 5' /etc/dhcp/dhclient.conf",
    }
    
    file { "/etc/systemd/system/rfkill-unblock.service":
        ensure      => present,
        source      => "puppet:///modules/maverick-network/rfkill-unblock.service",
        mode        => 644,
        owner       => "root",
        group       => "root",
        notify      => Exec["maverick-systemctl-daemon-reload"],
        require     => Package["rfkill"]
    } ->
    service { "rfkill-unblock.service":
        enable      => true,
    }
    
    # If wireless auth defaults are set in localconf.json, configure it 
    # Retrieve wireless auth data from hiera
    $wifi_ssid = hiera('wifi_ssid')
    $wifi_passphrase = hiera('wifi_passphrase')
    if $wifi_ssid and $wifi_passphrase {
        file { "/etc/wpa_supplicant/wpa_supplicant.conf":
            content => template("maverick-network/wpa_supplicant.conf.erb"),
            mode    => 600,
            owner   => "root",
            group   => "root",
        }
    }

    # Retrieve defined interfaces and process
    $interfaces = hiera_hash("maverick-network::interfaces")
    if $interfaces {
        concat { "/etc/udev/rules.d/10-network-customnames.rules":
            ensure      => present,
        }
	    ### Setup defaults that are added to each create_resources iteration
	    #$def_defaults = {
		#    'type'      => 'managed',
	    #}
	    ### Now convert the managed_interfaces hash into actual function calls
		#create_resources("process_interface", $interfaces, $def_defaults)
		create_resources("process_interface", $interfaces)
	}
    
    define process_interface (
        $mode = "managed",
        $type = "ethernet",
        $addressing = "dhcp",
	    $macaddress = undef,
	    $ipaddress = undef,
	    $gateway = undef,
	    $nameservers = undef,
	    $ssid = undef,
	    $psk = undef,
	) {
	    # Process managed interfaces
		if $mode == "managed" {
		    maverick-network::managed { $name:
		        type        => $type,
		        addressing  => $addressing,
		        macaddress  => $macaddress,
		        ipaddress   => $ipaddress,
		        gateway     => $gateway,
		        nameservers => $nameservers,
		        ssid        => $ssid,
		        psk         => $psk,
		    }
		}
	}
    
}