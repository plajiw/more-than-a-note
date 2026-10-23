# Reproducible Linux build: compiles the app, runs the tests headless and
# produces a self-contained install tree.
#
#   docker build -t more-than-a-note .                        # build + tests
#   docker build --target dist --output type=local,dest=out . # export the Linux build to ./out

FROM debian:trixie-slim AS toolchain
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build \
        qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools \
        libqt6sql6-sqlite libgl-dev \
        qml6-module-qtquick qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts qml6-module-qtquick-window \
        qml6-module-qtqml-workerscript qml6-module-qtquick-templates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src

FROM toolchain AS build
COPY . .
ENV QT_QPA_PLATFORM=offscreen
RUN cmake --preset release \
    && cmake --build --preset release \
    && ctest --preset release \
    && cmake --install build/release --prefix /out/more-than-a-note

FROM scratch AS dist
COPY --from=build /out /
