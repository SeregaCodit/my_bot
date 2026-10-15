#!/bin/bash

set -e

source /opt/ros/lyrical/setup.bash
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash

echo "Provided arguments: $@"

exec $@
