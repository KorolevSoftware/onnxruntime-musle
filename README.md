# onnxruntime-musle

GitHub Actions builds the pinned ONNX Runtime release for Alpine Linux/musl on native GitHub-hosted x86-64 and ARM64 runners. It bootstraps Alpine Linux 3.24.1 as a chroot and compiles with Alpine's native toolchain using all runner CPUs. The two architecture archives are attached to a GitHub Release; no Docker or QEMU is used.

The source of truth for the ONNX Runtime version and source archive SHA-512 is [`onnxruntime.env`](onnxruntime.env). Each release contains `onnxruntime-<version>-linux-amd64-musl.tar.gz` and `onnxruntime-<version>-linux-arm64-musl.tar.gz`. The archives include `lib/libonnxruntime.so*`, optional provider support, upstream license files, target architecture, version, build package inventory, and `SHA256SUMS`.

## Download the libraries

Open the [latest release](https://github.com/KorolevSoftware/onnxruntime-musle/releases/latest) and download the archive for your architecture. Release assets can also be downloaded directly:

```sh
VERSION=1.30.0
curl -L -o "onnxruntime-${VERSION}-linux-amd64-musl.tar.gz" \
  "https://github.com/KorolevSoftware/onnxruntime-musle/releases/download/onnxruntime-v${VERSION}/onnxruntime-${VERSION}-linux-amd64-musl.tar.gz"
```

For ARM64, replace `amd64` with `arm64`.

## Update ONNX Runtime

A scheduled GitHub Actions workflow checks the official stable release once a day. When a new version appears, it updates `onnxruntime.env`, commits the pin, and triggers the native builds and release. To update immediately, run:

```sh
./scripts/update-ort-version.sh latest
```

To pin a particular stable release, pass its version, for example `./scripts/update-ort-version.sh 1.30.0`. The script checks the official GitHub release, downloads the source archive, calculates its SHA-512, and updates `onnxruntime.env`. Commit and push the change to start the build.
