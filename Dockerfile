# Reproducible Linux build: compiles the app, runs every suite headless and
# renders the scripted evidence, so any machine with Docker can check that
# the project builds. Same commands as BUILDING.md.
#
#   docker build -t more-than-a-note .
#   docker build --target evidence --output type=local,dest=evidence .

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
RUN cmake --workflow --preset release \
    && cmake --build --preset release --target evidence \
    && cmake --workflow --preset asan \
    && CXX=clang++ cmake --workflow --preset core

FROM scratch AS evidence
COPY --from=build /src/build/release/evidence /
