# Reproducible Linux build: compiles the app and runs the tests headless,
# so any machine with Docker can check that the project builds.
#
#   docker build -t more-than-a-note .

FROM debian:trixie-slim AS toolchain
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential clang cmake ninja-build \
        qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools \
        libqt6sql6-sqlite qt6-svg-dev libgl-dev \
        qml6-module-qtquick qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts qml6-module-qtquick-window \
        qml6-module-qtqml-workerscript qml6-module-qtquick-templates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src

FROM toolchain AS build
COPY . .
ENV QT_QPA_PLATFORM=offscreen
RUN cmake --preset release \
    && cmake --build --preset release --parallel 2 \
    && ctest --preset release --output-on-failure \
    && cmake --preset core -DCMAKE_CXX_COMPILER=clang++ \
    && cmake --build --preset core --parallel 2 \
    && ctest --preset core --output-on-failure
