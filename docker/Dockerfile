#########################################################################################
# ROS2環境(humble)
#########################################################################################
FROM osrf/ros:humble-desktop

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt install -y --no-install-recommends \
        ca-certificates \
        apt-transport-https \
        gosu \
        iproute2 \
        openssh-server \
        vim \
        git \
        curl \
        gnupg \
        net-tools \
        nano \
        gedit \
        lsb-release \
        wget \
        cmake \
        acpid \
        alsa-utils \
        pulseaudio \
    && rm -rf /var/lib/apt/lists/*

# RUN useradd -m refro
# RUN usermod -aG dialout refro
RUN rm -f /usr/share/keyrings/ros2-latest-archive-keyring.gpg || true
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN rm -f /etc/apt/sources.list.d/ros2-latest.list
RUN rm -f /usr/share/keyrings/ros2-latest-archive-keyring.gpg
RUN apt-get update && apt-get install -y \
        libbullet-dev \
        python3-flake8 \
        python3-pip \
        python3-pytest-cov \
        python3-rosdep \
        python3-vcstool \
        python3-setuptools \
        python3-colcon-common-extensions \
        python3-rosinstall-generator \
        python3-bloom python3-rosdep \
        python3-pydantic \
        python3-fastapi \
        python3-websockets \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install transforms3d && \
    pip3 install numpy==1.24.4 && \
    pip3 install open3d && \
    pip3 install pyyaml && \
    pip3 install playsound


RUN rm -f /etc/ros/rosdep/sources.list.d/20-default.list && \
    rosdep init && \
    rosdep update

    # ワークスペースのビルド
RUN . /opt/ros/humble/setup.sh

# 日本語設定
RUN apt-get update && apt-get install -y --no-install-recommends \
        language-pack-ja-base \
        language-pack-ja \
        fonts-ipafont-gothic \
        iputils-ping net-tools \
    && rm -rf /var/lib/apt/lists/*

# Python3をpythonにリンク
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 2

##############################################
# OpenGL対応
# (参照)https://gitlab.com/nvidia/container-images/opengl/blob/ubuntu16.04/glvnd/runtime/Dockerfile
##############################################
ENV LIBGLVND_VERSION="v1.6.0"
ENV nproc=4

RUN apt-get update && apt install -y --no-install-recommends \
        automake \
        autoconf \
        libtool \
        libxext-dev \
        libx11-dev \
        x11proto-gl-dev \
        libxcb-cursor0 \
        libxcb-xinerama0 \
        libxcb-randr0 \
        libxcb-shape0 \
        libxcb-util1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/libglvnd
RUN git clone --branch="${LIBGLVND_VERSION}" https://github.com/NVIDIA/libglvnd.git . && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/x86_64-linux-gnu && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/x86_64-linux-gnu -type f -name 'lib*.la' -delete

RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig

#########################################################################################
# 追加パッケージのインストール
#########################################################################################

COPY ./scripts/install.sh .
RUN sed -i "s/sudo //" install.sh
RUN chmod +x install.sh
RUN /bin/bash -c "apt update && \
                 ./install.sh && \
                 rm -rf /var/lib/apt/lists/* && \
                 rm install.sh"

RUN apt-get update && apt install -y --no-install-recommends \
        ccache \
    && rm -rf /var/lib/apt/lists/*

COPY ./requirements/unitree.txt unitree.txt
RUN pip install --no-cache-dir -r unitree.txt; \
    rm -f unitree.txt

# COPY ./kjm_ws/ros2_ws/src /kjm_ws/ros2_ws/src
# WORKDIR /kjm_ws/ros2_ws/src
# RUN rosdep install --from-paths gz_rosa_control -y --ignore-src

#########################################################################################
# 日本語入力モジュールのインストール
# 参考: https://zenn.dev/ysuito/articles/c196ae84c95e31
#########################################################################################
RUN apt update && apt install -y --no-install-recommends \
        dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

#########################################################################################
# ワークスペース初期化用エントリーポイントの生成
#########################################################################################
COPY ./resources/_bashrc /tmp/_bashrc
RUN echo '#!/bin/bash' >> /start.sh \
    # ホストと同じユーザーの作成
    && echo "groupadd -g \${3} \${1}" >> /start.sh \
    && echo "useradd -u \${2} -g \${3} \${1} -p \$(perl -se 'print crypt(\${var}, \"\\\$6\\\$saltsalt\")' -- -var=\${1})" >> /start.sh \
    && echo "usermod -G sudo \${1}" >> /start.sh \
    # ユーザーのホームディレクトリに.bash_profileを作成 
    && echo "chown -R \${1}:\${1} /home/\${1}" >> /start.sh \
    && echo "gosu \${1}:\${1} cp /tmp/_bashrc /home/\${1}/.bashrc" >> /start.sh \
    && echo "gosu \${1}:\${1} cp /tmp/_bash_profile /home/\${1}/.bash_profile" >> /start.sh \
    && echo "service dbus start " >> /start.sh \
    && echo "gosu \${1}:\${1} \"/bin/bash\"" >> /start.sh \
    && chmod 755 /start.sh

ENTRYPOINT ["/start.sh"]
