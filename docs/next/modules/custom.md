# Custom Modules

Maverick provides locations in the Maverick system that are excluded from upstream commits to place custom modules.


## Custom Module Locations

Custom modules can be placed in the Maverick System at ~/software/maverick/manifests/custom-modules. This directory is excluded from commits in .gitignore.

For an external location for other github projects directories or modules outside the Maverick hierarchy, modules can be placed in ~/code/maverick/custom-modules.

## Adding Custom Modules to Maverick
To add modules to Maverick System simply add classes to ~/config/maverick/localconf.json
```
"classes": [ “custom_module_class_name"
]
```
## Example Custom Modules
### Second SITL Module
Below is a custom module sample for creating a swarm of SITL instances.
```
class sample_sitl_swarm (
) {

    # Create a custom APSITL instance (copter by default)
    maverick_dev::apsitl { "custom_sitl":
        instance_name       => "custom",
        instance_number     => 1,
    }

    # Create a swarm of SITL instances through simple iteration
    $instances = {
        2 => { "instance_name" => "copter2", "vehicle_type" => "copter", "ros_instance" => true, "api_instance" => true, "mavlink_proxy" => "mavlink-router" },
        3 => { "instance_name" => "copter3", "vehicle_type" => "copter", "ros_instance" => true, "api_instance" => true, "mavlink_proxy" => "mavlink-router" },
        4 => { "instance_name" => "copter4", "vehicle_type" => "copter", "ros_instance" => false, "api_instance" => false, "mavlink_proxy" => "mavlink-router" },
        5 => { "instance_name" => "copter5", "vehicle_type" => "copter", "ros_instance" => false, "api_instance" => false, "mavlink_proxy" => "mavlink-router" },
        6 => { "instance_name" => "plane1", "vehicle_type" => "plane", "ros_instance" => true, "api_instance" => true, "mavlink_proxy" => "mavlink-router" },
        7 => { "instance_name" => "plane2", "vehicle_type" => "plane", "ros_instance" => false, "api_instance" => false, "mavlink_proxy" => "mavlink-router" },
        8 => { "instance_name" => "rover1", "vehicle_type" => "rover", "ros_instance" => true, "api_instance" => true, "mavlink_proxy" => "mavlink-router" },
        9 => { "instance_name" => "sub1", "vehicle_type" => "sub", "ros_instance" => true, "api_instance" => true, "mavlink_proxy" => "mavlink-router" }
    }
    $instances.each |Integer $instance_number, Hash $instance_vars| {
        maverick_dev::apsitl { $instance_vars['instance_name']:
            instance_number => $instance_number,
            *               => $instance_vars,
        }
    }

}
```
To add the Sample SITL Swarm Module, add sample_sitl_swarm class to ~/config/maverick/localconf.json in the format described in Adding Custom Modules to Maverick Section.
```
"classes": [ “sample_sitl_swarm"
]
```
