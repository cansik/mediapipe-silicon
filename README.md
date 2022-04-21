# MediaPipe - ARM
Prebuilt Google MediaPipe packages for arm64.

## Install
To install the prebuilt packages, use the following command. The package is called mediapipe-arm but is a drop-in-replacement for the mediapipe package.

```
pip install mediapipe-arm --find-links ?
```

## Build
To build the libraries yourself, please first install the following dependencies and run the build script.

```
brew install wget git git-lfs cmake protobuf bazelisk opencv
brew uninstall --ignore-dependencies glog
```

```
./build-macos.sh
```

The pre-built wheel packages should be in the `dist` directory.

## About
MIT License - Copyright (c) 2022 Florian Bruggisser