#  [MediaPipe](https://github.com/google/mediapipe) for Apple Silicon
[![PyPI](https://img.shields.io/pypi/v/mediapipe-silicon)](https://pypi.org/project/mediapipe-silicon/)

Prebuilt Google MediaPipe packages for Apple Silicon (`arm64`).

## Install
To install the prebuilt packages, use the following command to install from [PyPi](https://pypi.org/project/mediapipe-silicon/). The package is called **mediapipe-silicon** but is a drop-in-replacement for the mediapipe package.

```
pip install mediapipe-silicon
```

### Requirements.txt
To use this library version in a `requirements.txt` it is recommended to use the following structure.

```
mediapipe-silicon; platform_system == "Darwin" and platform.machine == 'arm64'
```

## Build
To build the libraries yourself, please first install the following dependencies and run the build script.

```
brew install wget cmake protobuf bazelisk opencv@3
brew uninstall --ignore-dependencies glog
```

```
./build-macos.sh
```

The pre-built wheel packages should be in the `dist` directory.

## About
MIT License - Copyright (c) 2022 Florian Bruggisser
