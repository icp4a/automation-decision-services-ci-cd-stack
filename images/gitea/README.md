# GITEA docker image for the DevOps Stack

Adds customisation on top of the [gitea/gitea](https://hub.docker.com/r/gitea/gitea) from Docker Hub.

## Features


When the image is started with its default entrypoint, a script is executed only
once to automatically configure some aspects of Gitea:
- register some default users

## Configuration:
The configuration script is controlled by environment variables and files:
- `$GITEA_INIT_CONFIG_DIR`: path of folder containing config files.  Defaults to `/etc/gitea-init-config`.
- `$GITEA_INIT_TOUCHPOINT`: path of a marker file indicating if the configuration
  has already been done. Defaults to `/var/run/gitea-init-touchpoint`.

For each file matching `user.*` in the folder `GITEA_INIT_CONFIG_DIR`, the script registers
a user in Gitea.  Each file is composed of 3 lines (all terminated by a newline char):
- first line gives the username to create
- second line gives the password of the user
- third line is either `admin` to create a Gitea admin user, or any other token to
create a non-admin user.

For instance:
    # cat /etc/gitea-init-config/user.0
    gitadmin
    gitadmin
    admin
    # cat /etc/gitea-init-config/user.1
    demo
    Pa$$word!
    lambda


### Implementation
This user config system is implemented as an s6 service (/etc/s6/gitea-init) which waits
for complete start of the "gitea" S6 service, then create users with the gitea command line,
and then blocks for ever (to prevent s6 to restart the service)

Constraints:
    - gitea admin command requires the DB to have been fully initialized (tables created)
    - which is performed by the git web service
