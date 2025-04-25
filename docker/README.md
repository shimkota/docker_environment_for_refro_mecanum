# ROS2 Docker

Docker environment for ROS humble

## Prerequisite

- docker

## Usage

create directories and files if not exist (for bind mount)

```bash
mkdir -p ${HOME}/.ros ${HOME}/.ssh
touch ${HOME}/.gitconfig
```

build docker image

```bash
cd /path/to/docker
bash build.sh
# docker pull osrf/ros:humble-desktop-full # where applicable
```

run docker container

```bash
bash start_env.sh
```

display running container

```bash
docker ps -a
```

attach to running container

```bash
docker exec -it {container name} gosu ${USER}:${USER} /bin/bash
```
