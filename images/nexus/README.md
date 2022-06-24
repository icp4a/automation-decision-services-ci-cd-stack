# Nexus docker image for simple devops stack

This image adds customization on top of the [travelaudience/docker-nexus image](https://github.com/travelaudience/docker-nexus).

## Features

When the image is started with its default entrypoint, a script is executed only
once to automatically configure some aspects of Nexus:
- register some default users

## Configuration:
The configuration script is controlled by environment variables and files:
- `$NEXUS_BASEURL`: base URL of the nexus for API calls
- `$NEXUS_CONFIG_DIR`: path of folder containing config files.  Defaults to `/etc/nexus-config`.
- `$NEXUS_CONFIG_TOUCHPOINT`: path of a marker file indicating if the configuration
  has already been done. Defaults to `/var/run/nexus-config-touchpoint`.

For each file matching `user.*` in the folder `NEXUS_CONFIG_DIR`, the script registers
a user in Nexus.  Each file is composed of 2 lines (all terminated by a newline char):
- first line gives the username to create
- second line gives the password of the user

For instance:
    # cat /etc/nexus-config/user.0
    sample
    samplepwd
    # cat /etc/gitea-init-config/user.1
    johndoe
    str0ngPa$$word!

### Implementation
This user config system is implemented as an runit service (/etc/service/nexusconfig) which waits
for complete start of the "nexus" service, then create users by uploading a Groovy script into Nexus
scripting service and calling this script for each user.
Then the runit service blocks for ever (to prevent runit to restart the service)
