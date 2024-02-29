ARG namespace=swift
ARG swift_version=5.9
ARG ubuntu_version=jammy
ARG base_image=$namespace:$swift_version-$ubuntu_version

# Swift-MMIO Builder -----------------------------------------------------------
FROM $base_image as swift-mmio-builder

# Install packages
RUN apt-get update && apt-get install -y locales locales-all make

# set as UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
