#!/bin/bash

set -e

source /opt/ros/${ROS_DISTRO}/setup.bash
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash

echo "Provided arguments: $@"

exec $@
