#!/bin/bash

#######################################
# START SERVICES
#######################################
#
set -ex

systemctl enable ${service}
systemctl start ${service}
