# @summary
#   Maverick_hardware::Tegra class
#   This class installs/manages the Nvidia Tegra hardware environment, including support for TX1/TX2 and Jetson Nano.
#   NB: This manifest is specifically configured for JetPack 4.4.  The setup and versions of Nvidia software is quite specific to the version of JetPack.
#
# @example Declaring the class
#   This class is included from maverick_hardware class and should not be included from elsewhere
#
# @param expand_root
#   If true, expand the root filesystem to the full size of the SD card
# @param jtx1inst
#   If true, install software that can be used to monitor the TX1 power use.
# @param remove_large_packages
#   If true, remove large tegra packages that are probably not needed
#
class maverick_hardware::tegra (
    Boolean $expand_root = true,
    Boolean $jtx1inst = false,
    Boolean $remove_large_packages = true,
) {

    ### Online Jetpack install
    ### As per https://docs.nvidia.com/jetson/jetpack/install-jetpack/index.html#upgrade-jetpack
    # First uninstall the local/old stuff
    exec { "tegra-remove-localrepos":
        command     => "/usr/bin/apt purge -y libvisionworks* cuda-*local*",
        onlyif      => "/bin/ls -ld /var/lib/cuda*local* || /bin/ls -ld /var/cuda*local*",
    } ->
    # Then install everything using online packages, using the uber meta package
    # Note we do this inside an exec so it only happens once, because we then selectively remove large packages to reduce disk space consumed.
    exec { "tegra-install-jetpack":
        command     => "/usr/bin/apt -y install nvidia-jetpack",
        onlyif      => "/bin/ls -ld /var/lib/cuda*local* || /bin/ls -ld /var/cuda*local*",
    } ->
    # Ensure important packages are always installed
    package {["cuda-libraries-10-2"]:
        ensure      => installed,
    } ->
    file { "/etc/profile.d/20-tegra-cudadir.sh":
        mode        => "644",
        owner       => "root",
        group       => "root",
        content     => 'NEWPATH="/usr/local/cuda-10.2"; export CUDA_TOOLKIT_ROOT_DIR=${CUDA_TOOLKIT_ROOT_DIR:-${NEWPATH}}; if [ -n "${CUDA_TOOLKIT_ROOT_DIR##*${NEWPATH}}" -a -n "${CUDA_TOOLKIT_ROOT_DIR##*${NEWPATH}:*}" ]; then export CUDA_TOOLKIT_ROOT_DIR=$NEWPATH:$CUDA_TOOLKIT_ROOT_DIR; fi',
    }

    if $remove_large_packages == true {
        # Remove some of the very large 'extra' packages to save space
        package { ["libcudnn8-doc", "cuda-documentation-10-2", "cuda-samples-10-2", "cuda-nvgraph-dev-10-2", "cuda-cusparse-dev-10-2", "cuda-cusolver-dev-10-2", "libnvinfer-samples", "libnvinfer-dev"]:
            ensure  => purged,
            require => Exec["tegra-install-jetpack"],
        }
    }

    install_python_module { "jetson-stats":
        owner   => "root",
        pkgname => "jetson-stats",
        ensure  => present,
    }

    ### Disable nvidia report_ip_to_host
    exec { "tegra-disable-report":
        command         => "/bin/mv -f /etc/rc.local /etc/rc.local.report",
        onlyif          => "/bin/grep report_ip_to_host /etc/rc.local",
    }

    # Put tegra firstboot script in place
    file { "/srv/maverick/software/maverick/bin/maverick-firstboot.sh":
        ensure      => link,
        target      => "/srv/maverick/software/maverick/manifests/maverick-modules/maverick_hardware/files/tegra-firstboot.sh",
        force       => true,
    }

    if ($expand_root) {
        # $rootpart_expanded and $rootfs_expanded are facts provided by facts.d/filesystems.py
        if str2bool($::rootpart_expanded) == false or str2bool($::rootfs_expanded) == false {
            file { "/etc/tegra-expandroot":
                ensure      => absent,
            }
            warning("Root filesystem/partition needs expanding, *please reboot* when configure is finished.")
        }
    }

    if ! ("install_flag_jtx1inst" in $installflags) and $jtx1inst == true {
        # Pull jtx1inst fix from git mirror
        oncevcsrepo { "git-jtx1inst":
            gitsource   => "https://github.com/fnoop/jtx1inst.git",
            dest        => "/srv/maverick/var/build/jtx1inst",
            depth       => undef,
        } ->
        # Create build directory
        file { "/srv/maverick/var/build/jtx1inst/build":
            ensure      => directory,
            owner       => "mav",
            group       => "mav",
            mode        => "755",
        } ->
        exec { "jtx1inst-prepbuild":
            user        => "mav",
            timeout     => 0,
            environment => ["CMAKE_INSTALL_RPATH=/srv/maverick/software/jtx1inst/lib"],
            command     => "/usr/bin/cmake -DCMAKE_INSTALL_PREFIX=/srv/maverick/software/jtx1inst -DCMAKE_INSTALL_RPATH=/srv/maverick/software/jtx1inst/lib .. >/srv/maverick/var/log/build/jtx1inst.build.out 2>&1",
            cwd         => "/srv/maverick/var/build/jtx1inst/build",
            creates     => "/srv/maverick/var/build/jtx1inst/build/Makefile",
        } ->
        exec { "jtx1inst-build":
            user        => "mav",
            timeout     => 0,
            command     => "/usr/bin/make >>/srv/maverick/var/log/build/jtx1inst.build.out 2>&1",
            cwd         => "/srv/maverick/var/build/jtx1inst/build",
            creates     => "/srv/maverick/var/build/jtx1inst/build/libjtx1inst.so",
            require     => Exec["jtx1inst-prepbuild"],
        } ->
        exec { "jtx1inst-install":
            user        => "mav",
            timeout     => 0,
            command     => "/usr/bin/make install >>/srv/maverick/var/log/build/jtx1inst.build.out 2>&1",
            cwd         => "/srv/maverick/var/build/jtx1inst/build",
            creates     => "/srv/maverick/software/jtx1inst/lib/libjtx1inst.so",
        } ->
        file { "/srv/maverick/software/jtx1inst/bin":
            ensure      => directory,
            mode        => "755",
            owner       => "mav",
            group       => "mav",
        } ->
        exec { "cp-jtx1inst-bin":
            command     => "/bin/cp /srv/maverick/var/build/jtx1inst/build/jtx1inst_demo /srv/maverick/software/jtx1inst/bin/jtx1inst",
            creates     => "/srv/maverick/software/jtx1inst/bin/jtx1inst",
            user        => "mav",
        } ->
        file { "/srv/maverick/var/build/.install_flag_jtx1inst":
            ensure      => present,
            owner       => "mav",
        }
    }

    if $tegra_model == "Jetson Xavier NX" {
        # Disables the nvgetty service which occupies the UART of the J12 header for the flight controller
        exec { "tegra-disable-nvgetty":
            command     => "/bin/systemctl stop nvgetty; sleep 10; /bin/systemctl disable nvgetty;",
            onlyif      => "/bin/systemctl is-enabled nvgetty",
        }
    }

}
