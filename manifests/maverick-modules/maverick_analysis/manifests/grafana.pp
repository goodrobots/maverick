# @summary
#   Maverick_analysis::Grafana class
#   This class installs/manages Grafana software (grafana.com), which is used to display system and flight metrics.
#   As Grafana deliberately does not support real customistaion or embedding, it is likely this will be deprecated in the future in favour of custom solution that is more flexible.
#
# @example Declaring the class
#   This class is included from maverick_analysis class and should not be included from elsewhere
#
# @param active
#   If true, set the maverick-grafana service to running and enabled (at boot).
# @param port
#   TCP port number to run the grafana service.  Note this is normally reverse-proxied to the end user so does not need to be open.
# @param host
#   Hostname/IP to run the grafana service under.  When reverse-proxied this can be set to localhost.
# @param rootpath
#   Web root path - normally set to something other than / so it can be reverse-proxied without rewrites.
# @param grafana_version
#   Can be set to a specific version but causes problems with system upgrades.  Easier set to installed.
# @param grafana_firewall_rules
#   If grafana service reverse-proxied, set to false as service port does not need to be open.
# @param mav_password
#   Hashed password for mav user (default is 'wingman')
# @param mav-salt
#   Salt for hashed password for mav user
# @param admin_user
#   Name of the admin user
# @param admin_hash
#   Hashed password of the admin user (default is 'theneedforspeed')
# @param admin_salt
#   Salt for hashed password for root user
# @param admin_rand
#   ? - TODO
# @param admin_password
#   ? - TODO
#
class maverick_analysis::grafana (
    Boolean $active = true,
    Integer $port = 6022,
    String $host = "127.0.0.1",
    String $rootpath = "/analysis/grafana/",
    String $grafana_version = "installed",
    Boolean $grafana_firewall_rules = false,
    String $mav_password = 'e35f84e5859dfe5dfe2a9f6ed2086884c3a5e41d206c6e704b48cf45a0dda574ad85b4e9362e8d89eee3eb82e7ef34528ea4',
    String $mav_salt = 'ry48G1ZHyi',
    String $admin_user = 'admin',
    # To reset the admin hash: grafana-cli -d admin reset-admin-password theneedforspeed --config=/srv/maverick/config/analysis/grafana.ini from /usr/share/grafana
    String $admin_hash = '6eade3d424af57a87cb455d6577a7d92746517db17deda6b73fd40f22850b4491e6513d22763d9891d2a9206e8c61c9da3d6',
    String $admin_salt = 'WwOYa3P4rc',
    String $admin_rand = 'slhNQwWHa7',
    String $admin_password = 'admin',
) {

    if $active == true {
        ensure_packages(["sqlite3"])

        # python attrs package needed for grafanalib
        install_python_module { "grafanalib-attrs":
            pkgname     => "attrs",
            ensure      => installed,
        }

        file { ["/srv/maverick/data/analysis/grafana", "/srv/maverick/data/analysis/grafana/dashboards", "/srv/maverick/data/analysis/grafana/logs", "/srv/maverick/data/analysis/grafana/provisioning", "/srv/maverick/data/analysis/grafana/provisioning/datasources", "/srv/maverick/data/analysis/grafana/provisioning/dashboards", "/srv/maverick/var/log/analysis/grafana"]:
            ensure      => directory,
            mode        => "755",
            owner       => "mav",
            group       => "mav",
        }
        file { "/srv/maverick/software/grafana":
            ensure      => absent,
            force       => true,
        }

        if $joule_present == "yes" {
            $_dashboard = "system-dashboard-joule.json"
        } elsif $raspberry_present == "yes" {
            $_dashboard = "system-dashboard-raspberry.json"
        } else {
            $_dashboard = "system-dashboard-generic.json"
        }

        /*
        if $raspberry_present == "yes" or $tegra_present == "yes" {
            # If we're on tegra, need to do a bit of hackery
            if $tegra_present == "yes" {
                exec { "tegra-armhf":
                    command     => "/usr/bin/dpkg --add-architecture armhf && apt update",
                    unless      => "/usr/bin/dpkg --print-foreign-architectures |grep armhf",
                    notify      => Exec["apt_update"],
                }
            }
            $manage_package_repo = false
            # Don't use autodetect above, because we want OS images to be compatible with Zero
            $package_source = "https://dl.bintray.com/fg2it/deb-rpi-1b/main/g/grafana_${grafana_version}_armhf.deb"
            $install_method = "package"
        } else {
        */

        # Use auto package management by default
        $manage_package_repo = true
        $package_source = undef
        $install_method = "repo"

        # Install grafana repo key
        exec { "grafana-key":
            command         => "/usr/bin/curl https://packages.grafana.com/gpg.key | sudo apt-key add -",
            unless          => "/usr/bin/apt-key list |/bin/egrep '4E40 DDF6 D76E 284A 4A67'",
        } ->
        file { "/etc/systemd/system/maverick-grafana.service":
            owner       => "root",
            group       => "root",
            mode        => "644",
            source      => "puppet:///modules/maverick_analysis/grafana.service",
            notify      => Exec["maverick-systemctl-daemon-reload"],
        } ->
        class { "::grafana":
            cfg_location        => "/srv/maverick/config/analysis/grafana.ini",
            cfg => {
                app_mode => 'production',
                paths   => {
                    data            => "/srv/maverick/data/analysis/grafana",
                    logs            => "/srv/maverick/data/analysis/grafana/logs",
                    plugins         => "/srv/maverick/data/analysis/grafana/plugins",
                    provisioning    => "/srv/maverick/data/analysis/grafana/provisioning",
                },
                server   => {
                  http_port     => $port,
                  root_url      => "%(protocol)s://%(domain)s:${rootpath}",
                },
                users    => {
                  allow_sign_up => false,
                },
            },
            data_dir              => "/srv/maverick/data/analysis/grafana",
            install_method        => $install_method,
            manage_package_repo   => $manage_package_repo,
            package_source        => $package_source,
            service_name          => "maverick-grafana",
            version               => $grafana_version,
            notify                => Service[grafana-server],
        } ->
        service { "grafana":
            ensure      => "stopped",
            enable      => false,
        } ->
        service { "grafana-server":
            ensure      => "stopped",
            enable      => false,
        } ->
        # Set admin password
        exec { "grafana-adminpass":
            unless          => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db 'select * from main.user where login=\"admin\"' |grep ${admin_hash}",
            command         => "/bin/sleep 10; /usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db \"update main.user set password='${admin_hash}', salt='${admin_salt}', rands='${admin_rand}' where login='admin'\"",
            user            => "mav",
        } ->
        # Create maverick org in grafana
        exec { "grafana-maverickorg":
            unless          => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db 'select * from main.org' |grep Maverick",
            command         => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db \"insert into main.org values(10,0,'Maverick','','','','','','','','2017-06-20 11:02:55','2017-06-20 11:15:51')\"", # sleep is to give grafana enough time to fire up and release the db
            user            => "mav",
        } ->
        # Delete old mav user
        exec { "grafana-deloldmavuser":
            onlyif          => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db 'select * from main.user where id=10' |grep mav",
            command         => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db \"delete from main.user where id=10\"",
            user            => "mav",
        } ->
        # Create mav user in grafana
        exec { "grafana-mavuser":
            unless          => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db 'select * from main.user' |grep mav",
            command         => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db \"insert into main.user values(100,0,'mav','mav','Maverick User','${mav_password}','${mav_salt}','yICOZzT82L','',10,0,0,'','2017-06-21 12:54:43','2017-06-21 12:54:43',1,'2017-06-21 12:54:43',0,0)\"",
            user            => "mav",
        } ->
        # Delete old mav user link
        exec { "grafana-deloldmavuserlink":
            onlyif          => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db 'select * from main.org_user where id=100 and org_id=1' |grep Viewer",
            command         => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db \"delete from main.org_user where id=100\"",
            user            => "mav",
        } ->
        # Link mav user to org
        exec { "grafana-linkmav":
            unless          => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db 'select * from main.org_user where org_id=\"10\" and user_id=\"100\"' |grep Viewer",
            command         => "/usr/bin/sqlite3 /srv/maverick/data/analysis/grafana/grafana.db \"insert into main.org_user values('100','10','100','Viewer','2017-06-21 13:43:38','2017-06-21 13:43:38')\"",
            user            => "mav",
        }

        # Deploy the provisioning config
        file { "/srv/maverick/data/analysis/grafana/provisioning/datasources/influx.yaml":
            source          => "puppet:///modules/maverick_analysis/grafana-influx.yaml",
            owner           => "mav",
            group           => "mav",
            notify          => Service["maverick-grafana"],
        } ->
        file { "/srv/maverick/data/analysis/grafana/provisioning/dashboards/dashboards.yaml":
            source          => "puppet:///modules/maverick_analysis/grafana-dashboards.yaml",
            owner           => "mav",
            group           => "mav",
            notify          => Service["maverick-grafana"],
        } ->

        # Deploy provisioning dashboards
        file { "/srv/maverick/data/analysis/grafana/dashboards/system_dashboard.json":
            content         => template("maverick_analysis/${_dashboard}"),
            owner           => "mav",
            group           => "mav",
        } ->
        file { "/srv/maverick/data/analysis/grafana/dashboards/flight-dashboard-ardupilot.json":
            content         => template("maverick_analysis/flight-dashboard-ardupilot.json"),
            owner           => "mav",
            group           => "mav",
        } ->
        file { "/srv/maverick/data/analysis/grafana/dashboards/flight-ekf2-ardupilot.json":
            content         => template("maverick_analysis/flight-ekf2-ardupilot.json"),
            owner           => "mav",
            group           => "mav",
        }->
        file { "/srv/maverick/data/analysis/grafana/dashboards/flight-ekf3-ardupilot.json":
            content         => template("maverick_analysis/flight-ekf3-ardupilot.json"),
            owner           => "mav",
            group           => "mav",
        } ->
        file { "/srv/maverick/data/analysis/grafana/dashboards/flight-ekf2ekf3-ardupilot.json":
            content         => template("maverick_analysis/flight-ekf2ekf3-ardupilot.json"),
            owner           => "mav",
            group           => "mav",
        } ->
        file { "/srv/maverick/data/analysis/grafana/dashboards/mavexplorer-mavgraphs.json":
            content         => template("maverick_analysis/mavexplorer-mavgraphs.json"),
            owner           => "mav",
            group           => "mav",
        }

        ### NEW - Not working yet
        /*
        exec { "grafana-reset-admin-password":
            command         => "/usr/sbin/grafana-cli admin reset-admin-password ${admin_password} --config=/srv/maverick/config/analysis/grafana.ini",
            #unless          => "",
            cwd             => "/usr/share/grafana",
        }
        */

        if defined(Class["::maverick_web"]) {
            nginx::resource::location { "web-analysis-graphs-http":
                location    => "/analysis/grafana/",
                proxy       => "http://localhost:${port}/",
                server      => getvar("maverick_web::server_fqdn"),
                require     => [ Class["nginx"] ],
                ssl         => true,
            }
        }

        if $grafana_firewall_rules == true {
            if defined(Class["::maverick_security"]) {
                maverick_security::firewall::firerule { "grafana":
                    ports       => $port,
                    ips         => lookup("firewall_ips"),
                    proto       => "tcp"
                }
            }
        }
    } else {
        service { 'maverick-grafana':
            ensure => stopped,
            enable => false,
        }
    }

    # status.d entry
    file { "/srv/maverick/software/maverick/bin/status.d/121.analysis/101.grafana.status":
        owner   => "mav",
        content => "grafana,Analysis Dashboard\n",
    }

}
