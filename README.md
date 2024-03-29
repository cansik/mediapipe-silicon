#  [MediaPipe](https://github.com/google/mediapipe) for Apple Silicon
[![PyPI](https://img.shields.io/pypi/v/mediapipe-silicon)](https://pypi.org/project/mediapipe-silicon/)

Prebuilt Google MediaPipe packages for Apple Silicon (`arm64`).

🥳 The official [MediaPipe 0.9.3.0](https://pypi.org/project/mediapipe/0.9.3.0/) now builds universal2 pip wheels for OSX. This means, `arm64` is now officially supported!

## Install
To install the prebuilt packages, use the following command to install from [PyPi](https://pypi.org/project/mediapipe-silicon/). The package is called **mediapipe-silicon** but is a drop-in-replacement for the mediapipe package.

```
pip install mediapipe-silicon
```

As mentioned in https://github.com/cansik/mediapipe-silicon/issues/1 maybe it is necessary to limit the `protobuf` version, because the most recent one is not compatible:

```bash
pip install "protobuf>=3.11,<4"
```

### Requirements.txt
To use mediapipe in a `requirements.txt` it is recommended to use the following structure. This will install either `mediapipe` or `mediapipe-silicon`.

```
mediapipe; platform_system != "Darwin" or platform.machine != "arm64"
mediapipe-silicon; platform_system == "Darwin" and platform.machine == "arm64"
protobuf>=3.11,<4
```

## Build
To build the libraries yourself, please first install the following dependencies and run the build script.

```
brew install wget cmake protobuf bazelisk opencv@3 powershell
brew uninstall --ignore-dependencies glog
```

The build script is written in powershell:

```
pwsh tools/build.ps1
```

The pre-built wheel packages should be in the `dist` directory.

## About
MIT License - Copyright (c) 2023 Florian Bruggisser
