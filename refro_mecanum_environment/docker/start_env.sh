#!/bin/bash

cd `dirname $0`
THIS_DIR="$(cd $(dirname "${BASH_SOURCE}") && pwd)"

: ${IMAGE:=kjm/ros/humble:latest}
: ${WORKSPACE_DIR:=${THIS_DIR}/kjm_ws}

USER_ID=$(id -u ${USER})
GROUP_ID=$(id -g ${USER})
COMMAND="${USER} ${USER_ID} ${GROUP_ID}"

NAME=""
RUNTIME=""
while getopts :n:t:w:gh OPT
do
    case ${OPT} in
        n) NAME="--name=${OPTARG}"
           echo "[Docker Container Name] ${OPTARG}"
           ;;
        t) IMAGE="kjm/ros/humble:${OPTARG}" ;;
        w) WORKSPACE_DIR="${HOME}/${OPTARG}" ;;
        g) RUNTIME="--runtime=nvidia" ;;
        h) echo "Usage: $(basename $0) [OPTIONS]"
           echo "Options:"
           echo " -n NAME docker container name"
           echo " -t TAG  docker image tag"
           echo " -w WORKSPACE_DIR  workspace directory"
           echo " -g                nvidia runtime"
           exit 1
           ;;
    esac
done

echo "[Docker Image] ${IMAGE}"
echo "[workspace] ${WORKSPACE_DIR}"
echo "[RUNTIME] ${RUNTIME}"

NETWORK_MODE="--network bridge" # "--network host" # for networkingMode: mirrored use only
WORKING_DIR="-w=${HOME}"
ENVIRONMENT="-e DISPLAY=${DISPLAY} \
             -e NVIDIA_VISIBLE_DEVICES=all \
             -e NVIDIA_DRIVER_CAPABILITIES=compute,graphics,utility \
             -e QT_X11_NO_MITSHM=1 \
             -e TZ=Asia/Tokyo \
             -e WORKSPACE_DIR=${WORKSPACE_DIR}"
VOLUMES="--mount type=bind,src=${HOME}/.ssh,dst=${HOME}/.ssh \
         --mount type=bind,src=${HOME}/.ros,dst=${HOME}/.ros \
         --mount type=bind,src=${HOME}/.gitconfig,dst=${HOME}/.gitconfig \
         --mount type=bind,src=${WORKSPACE_DIR},dst=${HOME} \
         --mount type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix "
        #  --mount type=bind,src=/dev/snd,dst=/dev/snd,readonly "

if [ -e ${HOME}/.ccache ]; then
    VOLUMES+="--mount type=bind,src=${HOME}/.ccache,dst=${HOME}/.ccache "
fi
# 日本語入力対応
if [ -e /run/user/${USER_ID}/bus ]; then
    ENVIRONMENT+=" -e DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_ID}/bus "
    VOLUMES+="--mount type=bind,src=/run/user/${USER_ID}/bus,dst=/run/user/${USER_ID}/bus "
fi

xhost + local:${USER}
docker run -it ${RUNTIME} ${NETWORK_MODE} ${WORKING_DIR} ${ENVIRONMENT} ${VOLUMES} ${NAME} --privileged --rm ${IMAGE} ${COMMAND}
