#!/bin/bash

# Let's source the environment variables first
[ -f ".env" ] && . ".env"

clear

terraform destroy
