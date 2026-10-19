ARG ROS_DISTRO=lyrical
ARG TARGETARCH
# for dev host on amd64
FROM osrf/ros:${ROS_DISTRO}-desktop-full AS base-amd64

# for arm64
FROM --platform=linux/arm64 ros:${ROS_DISTRO}-ros-base AS base-arm64

FROM base-${TARGETARCH}

RUN apt-get update && apt-get install -y nano \
    && rm -rf /var/lib/apt/lists/*

    #
RUN apt-get update && apt-get install -y \
    locales \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y \
    #dev tools
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-argcomplete \
    build-essential \
    cmake \
    git \
    # I2C and GPIO tools
    i2c-tools \
    libi2c-dev \
    python3-gpiozero \
    v4l-utils \
    libv4l-dev \
    libcamera-dev \
    libopencv-dev \
    python3-opencv \
    # Foxglove Bridge (instead of RQt)
    ros-${ROS_DISTRO}-foxglove-bridge \
    # system tools for building libgpiod from source
    autoconf \
    autoconf-archive \
    libtool \
    pkg-config \
    m4 \
    python3-dev \
    python3-setuptools \
    && rm -rf /var/lib/apt/lists/*

# build libgpiod v2.1 from sources
WORKDIR /tmp
RUN git clone --depth 1 --branch v2.1 https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/ && \
    cd libgpiod && \
    ./autogen.sh --enable-bindings-cxx --enable-bindings-python --enable-tools --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && rm -rf libgpiod


RUN apt-get update && apt-get install -y \
    ros-lyrical-xacro \
    ros-lyrical-joint-state-publisher-gui \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user or rename default existing
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN if id -u ${USER_GID} >/dev/null 2>&1; then \
        EXISTING_USER=$(id -nu ${USER_GID}); \
        usermod -l ${USERNAME} ${EXISTING_USER}; \
        groupmod -n ${USERNAME} ${EXISTING_USER}; \
        usermod -d /home/${USERNAME} -m ${USERNAME}; \
    else \
        groupadd --gid ${USER_GID} ${USERNAME} && \
        useradd -s /bin/bash --uid ${USER_GID} --gid ${USER_GID} -m ${USERNAME}; \
    fi \
    && mkdir -p /home/${USERNAME}/.config \
    && chown -R ${USER_GID}:${USER_GID} /home/${USERNAME}/.config

# Set up sudo
RUN apt-get update \
    && apt-get install -y sudo \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}

# setup autocompletes
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/${USERNAME}/.bashrc
RUN echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> /home/${USERNAME}/.bashrc


# rosdep update
RUN rosdep update

WORKDIR /my_bot_dev_ws
ENV ROS_DISTRO=${ROS_DISTRO}
ENV SHELL=/bin/bash

COPY --chown=ros:ros entrypoint.sh /home/ros/entrypoint.sh
RUN chmod +x /home/ros/entrypoint.sh

ENTRYPOINT ["/home/ros/entrypoint.sh"]
CMD ["bash"]
