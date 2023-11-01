ARG namespace=swift
ARG swift_version=5.9
ARG ubuntu_version=jammy
ARG base_image=$namespace:$swift_version-$ubuntu_version

# Swift-Format builder ---------------------------------------------------------
FROM swift:5.9-jammy as swift-format-builder

RUN git clone https://github.com/apple/swift-format src --depth 1 --branch 509.0.0
RUN swift build --package-path /src --configuration release --product swift-format
RUN cp \
	$(swift build --package-path /src --configuration release --show-bin-path)/swift-format \
	/bin/swift-format

# Swift-MMIO Builder -----------------------------------------------------------
FROM $base_image as swift-mmio-builder
# needed to do again after FROM due to docker limitation
ARG swift_version
ARG ubuntu_version

# Install packages
RUN apt-get update && apt-get install -y locales locales-all make

# set as UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# copy swift-format into bin
COPY --from=swift-format-builder /bin/swift-format /bin/swift-format
