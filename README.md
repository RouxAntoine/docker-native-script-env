## docker environment to develop with nativescript

to start this environment key in `make up` to stop container use `make down`

after `make up`

use `docker exec -it adb-tns /bin/bash` to chroot to container


## in container command

into container all nativescript standard command are available like `tns build android` etc ...


> this repository is inspired by https://hub.docker.com/r/kristophjunge/nativescript/dockerfile