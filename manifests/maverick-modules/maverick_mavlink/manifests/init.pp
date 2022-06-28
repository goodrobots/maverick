# @summary
#   Maverick_mavlink class
#   This class controls all other classes in maverick_mavlink module.
#
# @example Declaring the class
#   This class is included from the environment manifests and is not usually included elsewhere.
#   It could be included selectively from eg. minimal environment.
#
# @param cmavnode_install
#   If true, install cmavnode software.
# @param cmavnode_source
#   Github repo to use to install cmavnode.
# @param mavlink_router_install
#   If true, install mavlink-router software.
# @param mavlink_router_source
#   Git repo to use to install mavlink-router.
# @param mavproxy_install
#   If true, install mavproxy software.
# @param mavproxy_type
#   Whether to install mavproxy from source or through pip.
# @param mavcesium_install
#   If true, install mavcesium software.
# @param mavcesium_apikey
#   API key for Bing maps to be used in mavcesium.
# @param mavcesium_port
#   TCP port to run mavcesium service.
# @param mavcesium_mavlink_port
#   TCP port to connect mavcesium to for mavlink data.
# @param mavcesium_source
#   Git repo to use to install mavcesium.
# @param mavcesium_active
#   If true, activate the mavcesium service and enable at boot time.
# @param cuav_install
#   If true, install CUAV software.
# @param gooey_version
#   Gooey is a CUAV dependency, can be version sensitive.
# @param mavsdk
#   If true, install MavSDK software.
# @param dronekit
#   If true, install Dronekit software.
#
class maverick_mavlink (
    Boolean $cmavnode_install = true,
    String $cmavnode_source = "https://github.com/MonashUAS/cmavnode.git",
    Boolean $mavlink_router_install = true,
    String $mavlink_router_source = "https://github.com/mavlink-router/mavlink-router.git",
    Boolean $mavproxy_install = true,
    String $mavproxy_source = "https://github.com/ArduPilot/MAVProxy.git",
    Enum['pip', 'source'] $mavproxy_type = "pip",
    Boolean $mavcesium_install = true,
    String $mavcesium_apikey = "Auw42O7s-dxnXl0f0HdmOoIAD3bvbPjFOVKDN9nNKrf1uroCCBxetdPowaQF4XaG",
    String $mavcesium_port = "6791",
    String $mavcesium_mavlink_port = "5770",
    String $mavcesium_source = "https://github.com/SamuelDudley/MAVCesium.git",
    Boolean $mavcesium_active = false,
    Boolean $cuav_install = false,
    String $gooey_version = "1.0.2",
    Boolean $mavsdk = true,
    Boolean $dronekit = true,
) {
    
    $buildparallel = ceiling((1 + $::processorcount) / 2) # Restrict build parallelization to roughly processors/2 (to restrict memory usage during compilation)

    if $mavsdk == true {
        # Install dronecode
        class { "maverick_mavlink::mavsdk": }
    }


    if $dronekit == true {
        # Install dronekit
        class { "maverick_mavlink::dronekit": }
    }

    # Create config directory for all mavlink configs
    file { "/srv/maverick/config/mavlink":
        ensure      => directory,
        owner       => "mav",
        group       => "mav",
        mode        => "755",
    }
    # Create data directory for mavlink
    file { [ "/srv/maverick/data/mavlink", "/srv/maverick/data/mavlink/fc", "/srv/maverick/data/mavlink/fc/logs", "/srv/maverick/data/mavlink/sitl", "/srv/maverick/data/mavlink/sitl/logs"]:
        ensure      => directory,
        owner       => "mav",
        group       => "mav",
        mode        => "755",
    }
    # Create log directory for mavlink
    file { ["/srv/maverick/var/log/mavlink" ]:
        ensure      => directory,
        owner       => "mav",
        group       => "mav",
        mode        => "755",
    }
    
    # Remove old maverick-params@ service
    file { "/srv/maverick/software/maverick/bin/mavlink_params":
        ensure      => absent,
    } ->
    file { "/etc/systemd/system/maverick-params@.service":
        ensure      => absent,
        notify      => Exec["maverick-systemctl-daemon-reload"],
    }

    # Install maverick-mavlink service
    file { "/etc/systemd/system/maverick-mavlink@.service":
        source      => "puppet:///modules/maverick_mavlink/maverick-mavlink@.service",
        owner       => "root",
        group       => "root",
        mode        => "644",
        notify      => Exec["maverick-systemctl-daemon-reload"],
    }
    file { "/srv/maverick/software/maverick/bin/mavlink.sh":
        ensure      => link,
        target      => "/srv/maverick/software/maverick/manifests/maverick-modules/maverick_mavlink/files/mavlink.sh",
    }

    ### cmavnode
    # Install cmavnode from gitsource
    if $cmavnode_install {
        if ! ("install_flag_cmavnode" in $installflags) {
            ensure_packages(["libboost-all-dev", "cmake", "libconfig++-dev", "libreadline-dev"])
            oncevcsrepo { "git-cmavnode":
                gitsource   => $cmavnode_source,
                dest        => "/srv/maverick/var/build/cmavnode",
                submodules  => true,
            } ->
            # Create build directory
            file { "/srv/maverick/var/build/cmavnode/build":
                ensure      => directory,
                owner       => "mav",
                group       => "mav",
                mode        => "755",
            }
            exec { "cmavnode-prepbuild":
                user        => "mav",
                timeout     => 0,
                command     => "/usr/bin/cmake -DCMAKE_INSTALL_PREFIX=/srv/maverick/software/cmavnode ..",
                cwd         => "/srv/maverick/var/build/cmavnode/build",
                creates     => "/srv/maverick/var/build/cmavnode/build/Makefile",
                require     => [ File["/srv/maverick/var/build/cmavnode/build"], Package["libreadline-dev"] ], # ensure we have all the dependencies satisfied
            } ->
            exec { "cmavnode-build":
                user        => "mav",
                timeout     => 0,
                command     => "/usr/bin/make -j${buildparallel} >/srv/maverick/var/log/build/cmavnode.build.out 2>&1",
                cwd         => "/srv/maverick/var/build/cmavnode/build",
                creates     => "/srv/maverick/var/build/cmavnode/build/cmavnode",
                require     => Exec["cmavnode-prepbuild"],
            } ->
            exec { "cmavnode-install":
                user        => "mav",
                timeout     => 0,
                command     => "/usr/bin/make install >/srv/maverick/var/log/build/cmavnode.install.out 2>&1",
                cwd         => "/srv/maverick/var/build/cmavnode/build",
                creates     => "/srv/maverick/software/cmavnode/bin/cmavnode",
            }
            file { "/srv/maverick/var/build/.install_flag_cmavnode":
                ensure      => file,
                owner       => "mav",
            }
        }
        file { "/etc/systemd/system/maverick-cmavnode@.service":
            ensure      => absent,
            notify      => Exec["maverick-systemctl-daemon-reload"],
        }
        file { "/srv/maverick/software/maverick/bin/cmavnode.sh":
            ensure      => link,
            target      => "/srv/maverick/software/maverick/manifests/maverick-modules/maverick_mavlink/files/cmavnode.sh",
        }
    }

    ### mavlink-router
    # Install mavlink-router from gitsource
    if $mavlink_router_install {
        if ! ("install_flag_mavlink-router" in $installflags) {
            ensure_packages(["autoconf", "meson", "ninja-build", "pkg-config", "gcc", "g++"])
            oncevcsrepo { "git-mavlink-router":
                gitsource   => $mavlink_router_source,
                dest        => "/srv/maverick/var/build/mavlink-router",
                submodules  => true,
            } ->
            install_python_module { "pip-meson":
                pkgname => "meson",
                ensure  => present,
            } ->
            exec { "mavlink-router-meson":
                command     => "/srv/maverick/software/python/bin/meson --prefix=/srv/maverick/software/mavlink-router --libdir=/srv/maverick/software/mavlink-router -Dsystemdsystemunitdir=/etc/systemd/system build >/srv/maverick/var/log/build/mavlink-router.configure.log 2>&1",
                cwd         => "/srv/maverick/var/build/mavlink-router",
                timeout     => 0,
                user        => "mav",
                creates     => "/srv/maverick/var/build/mavlink-router/build/build.ninja",
                require     => Package["meson"],
            } ->
            exec { "mavlink-router-ninja":
                command     => "/usr/bin/ninja -C build >/srv/maverick/var/log/build/mavlink-router.ninja.out 2>&1",
                cwd         => "/srv/maverick/var/build/mavlink-router",
                timeout     => 0,
                user        => "mav",
                #creates     => "/srv/maverick/var/build/mavlink-router/build",
                require     => Package["ninja-build"],
            } ->
            file{ [ "/srv/maverick/software/mavlink-router",
                    "/srv/maverick/software/mavlink-router/bin", ]:
                ensure      => directory,
                owner       => "mav",
                group       => "mav",
            } ->
            exec { "mavlink-router-copy-install":
                command     => "/bin/cp /srv/maverick/var/build/mavlink-router/build/src/mavlink-routerd /srv/maverick/software/mavlink-router/bin/mavlink-routerd >/srv/maverick/var/log/build/mavlink-router.install.out 2>&1",
                cwd         => "/srv/maverick/var/build/mavlink-router",
                timeout     => 0,
                user        => "mav",
                creates     => "/srv/maverick/software/mavlink-router/bin/mavlink-routerd",
            } ->
            file { "/srv/maverick/var/build/.install_flag_mavlink-router":
                ensure      => file,
                owner       => "mav",
            }
        }
        file { "/etc/systemd/system/maverick-mavlink-router@.service":
            ensure      => absent,
            notify      => Exec["maverick-systemctl-daemon-reload"],
        }
    }
    
    ### Mavproxy
    # Install mavproxy globally (not in virtualenv) from pip
    if $mavproxy_install and $mavproxy_type == "pip" {
        ensure_packages(["python-lxml", "libxml2-dev", "libxslt1-dev"])
        install_python_module { 'pip-mavproxy-global':
            pkgname     => 'MAVProxy',
            ensure      => atleast,
            version     => "1.6.1",
            timeout     => 0,
            require     => Package["python-lxml", "libxml2-dev", "libxslt1-dev"],
        } ->
        file { "/etc/systemd/system/maverick-mavproxy@.service":
            ensure      => absent,
            notify      => Exec["maverick-systemctl-daemon-reload"],
        } ->
        file { "/srv/maverick/software/maverick/bin/mavproxy.sh":
            ensure      => link,
            target      => "/srv/maverick/software/maverick/manifests/maverick-modules/maverick_mavlink/files/mavproxy.sh",
        }
    }

    # Install mavproxy from source
    if $mavproxy_install and $mavproxy_type == "source" {
        ensure_packages(["python-lxml", "libxml2-dev", "libxslt1-dev"])
        # First uninstall pip mavproxy, to remove any conflicts
        install_python_module { 'pip-mavproxy-global':
            pkgname     => 'MAVProxy',
            ensure      => absent,
            timeout     => 0,
        }
        if ! ("install_flag_mavproxys" in $installflags) {
            oncevcsrepo { "git-mavproxy":
                gitsource   => $mavproxy_source,
                dest        => "/srv/maverick/var/build/mavproxy",
                submodules  => true,
                require     => Install_python_module["pip-mavproxy-global"],
            } ->
            exec { "mavproxy-build":
                command     => "/usr/bin/python setup.py build install --user",
                cwd         => "/srv/maverick/var/build/mavproxy",
                user        => "root",
                timeout     => 0,
                #creates     => "",
            } ->
            file { "/srv/maverick/var/build/.install_flag_mavproxy":
                ensure      => file,
                owner       => "mav",
                group       => "mav",
                mode        => "644",
            }
        }
        file { "/etc/systemd/system/maverick-mavproxy@.service":
            ensure      => absent,
            notify      => Exec["maverick-systemctl-daemon-reload"],
        } ->
        file { "/srv/maverick/software/maverick/bin/mavproxy.sh":
            ensure      => link,
            target      => "/srv/maverick/software/maverick/manifests/maverick-modules/maverick_mavlink/files/mavproxy.sh",
        }
    }

    ## Install mavcesium dependencies and services
    if $mavcesium_install == true {
        # Overlay mavcesium master ontop of mavproxy installed version
        ensure_packages(["libffi-dev"])
        oncevcsrepo { "git-mavcesium":
            gitsource   => $mavcesium_source,
            dest        => "/srv/maverick/software/mavcesium",
            submodules  => true,
            owner       => "mav",
            require     => Package["libffi-dev"],
        } ->
        install_python_module { "mav-configparser":
            pkgname     => "configparser",
            ensure      => atleast,
            version     => "3.5.0",
        } ->
        install_python_module { "mav-pyopenssl":
            pkgname     => "pyOpenSSL",
            ensure      => atleast,
            version     => "17.0.0",
        } ->
        install_python_module { "mav-service-identity":
            pkgname     => "service-identity",
            ensure      => atleast,
            version     => "16.0.0",
        } ->
        exec { "rm-configparser-dingleberry":
            command     => "/bin/rm -rf /usr/local/lib/python2.7/dist-packages/configparser",
            onlyif      => "/bin/ls /usr/local/lib/python2.7/dist-packages/configparser/__init__.py",
        } ->
        file { "/srv/maverick/config/mavlink/mavcesium.ini":
            owner       => "mav",
            mode        => "644",
            content     => template("maverick_mavlink/mavcesium_default.ini.erb"),
        } ->
        file { "/srv/maverick/config/mavlink/mavcesium.conf":
            ensure      => present,
            owner       => "mav",
            group       => "mav",
            mode        => "644",
            content     => template("maverick_mavlink/mavcesium.conf.erb"),
            replace     => false,
        } ->
        file { "/etc/systemd/system/maverick-mavcesium.service":
            ensure      => present,
            source      => "puppet:///modules/maverick_mavlink/maverick-mavcesium.service",
            notify      => Exec["maverick-systemctl-daemon-reload"],
        }
        
        if $mavcesium_active == true {
            service { "maverick-mavcesium":
                ensure      => running,
                enable      => true,
                require     => [ File["/etc/systemd/system/maverick-mavcesium.service"], Exec["maverick-systemctl-daemon-reload"] ],
            }
        } else {
            service { "maverick-mavcesium":
                ensure      => stopped,
                enable      => false,
                require     => [ File["/etc/systemd/system/maverick-mavcesium.service"], Exec["maverick-systemctl-daemon-reload"] ],
            }
        }

        if defined(Class["::maverick_web"]) {
            # Setup reverse proxy for websocket
            nginx::resource::location { "web-mavcesium-websocket":
                location                => "/mavlink/mavcesium/websocket/",
                proxy                   => "http://127.0.0.1:${mavcesium_port}/mavlink/mavcesium/websocket/",
            	proxy_connect_timeout   => "7d",
            	#proxy_send_timeout      => "7d", # not supported by nginx puppet module
            	proxy_read_timeout      => "7d",
                proxy_set_header        => ['Upgrade $http_upgrade', 'Connection "upgrade"'],
            	proxy_http_version      => "1.1",
            	server                  => getvar("maverick_web::server_fqdn"),
        	}
            # Setup reverse proxy for static content
            nginx::resource::location { "web-mavcesium":
                location    => "/mavlink/mavcesium/",
                proxy       => "http://127.0.0.1:${mavcesium_port}/mavlink/mavcesium/",
                server      => getvar("maverick_web::server_fqdn"),
                require     => [ Service["maverick-nginx"] ],
            }
        }

        # status.d entry
        file { "/srv/maverick/software/maverick/bin/status.d/123.vision/103.mavcesium.status":
            owner   => "mav",
            content => "mavcesium,MavCesium\n",
        }
    }

    # Install cuav
    if $cuav_install == true {
        if $::operatingsystem == "Debian" {
            exec { "libturbojpeg-install":
                command     => "/usr/bin/apt install -y libturbojpeg-dev",
                #unless      => "/usr/bin/dpkg -l libturbojpeg-dev",
                creates     => "/usr/include/turbojpeg.h",
            }
        } elsif $::operatingsystem == "Ubuntu" {
            ensure_packages(["libjpeg-turbo8-dev"])
        }

        # Install dependencies based on version of gooey
        if versioncmp($gooey_version, "0.9.3") > 0 {
            # Install dependencies for gooey/wxpython4/cuav
            ensure_packages(
                ["libdc1394-22-dev", "python-wxgtk3.0", "libgstreamer-plugins-base1.0-dev", "dpkg-dev", "python2.7-dev", "libjpeg-dev", "libtiff5-dev", "libsdl1.2-dev", "libnotify-dev", "libsm-dev", "libgtk2.0-dev", "libwebkitgtk-dev", "libwebkitgtk-3.0-dev"],
                {'before' => Install_python_module["pip-gooey"]}
            )
        } else {
            # Install dependencies for gooey/wxpython3/cuav
            ensure_packages(
                ["libdc1394-22-dev", "python-wxgtk3.0", ],
                {'before' => Install_python_module["pip-gooey"]}
            )
        }
        install_python_module { "pip-gooey":
            pkgname     => "Gooey",
            ensure      => exactly,
            version     => $gooey_version,
            timeout     => 0,
        }
        unless "cuav" in $::python_modules["global"] {
            oncevcsrepo { "git-cuav":
                gitsource   => "https://github.com/CanberraUAV/cuav.git",
                dest        => "/srv/maverick/var/build/cuav",
                # submodules  => true,
                require     => Install_python_module["pip-numpy"],
            } ->
            exec { "compile-cuav":
                command     => "/usr/bin/python setup.py install",
                cwd         => "/srv/maverick/var/build/cuav",
                before      => Class["maverick_vision::opencv"],
                require     => [ Package["libdc1394-22-dev"], Install_python_module["pytest"], ],
                unless      => "/bin/ls /usr/local/lib/python2.7/dist-packages/cuav*",
            }
        }      
        #install_python_module { "pip-cuav":
        #    pkgname     => "cuav",
         #   ensure      => present,
         #   timeout     => 0,
         #   require     => [ Class["maverick_vision::opencv"], Package["libdc1394-22-dev"] ],
        #}
    }
    
}

