# Maverick Modules

Maverick is designed to be as modular as possible, consisting of modules, parameters and resources that can be interlinked like building blocks to create blueprints.  Each environment (bootstrap, flight, development) is comprised of a different combination of modules, resources and parameters.  All parameters can be set in any of the Maverick config (localconf.json, local-nodes, sample-nodes etc) and influence how the system is configured.  Each module below is linked to docs that explain the module, how the components within it work and the parameters that can be set.

All environments start with the base module:
- [Base](/modules/base)

Depending on the environment and what other classes are included by configuration, these other modules are available:
  - [Analysis](/modules/analysis)
  - [Cloud9](/modules/cloud9)
  - [Desktop](/modules/desktop)
  - [Development](/modules/dev)
  - [Flight Controller](/modules/fc)
  - [Hardware](/modules/hardware)
  - [Intelligence](/modules/intelligence)
  - [Mavlink](/modules/mavlink)
  - [Network](/modules/network)
  - [ROS](/modules/ros)
  - [Security](/modules/security)
  - [Vision](/modules/vision)
  - [Web](/modules/web)

  In Addition, locations for custom modules have been included.  More information and examples can be found in the [Custom Module](/modules/custom) entry.

!> Note:  Throughout the module documentation, it refers to 'localconf parameters'.  This generally refers to the file ~/config/maverick/localconf.json, although there are other ways to set localconf such as local-nodes and sample-nodes.  More information can be [obtained here](/about#local-configuration).
