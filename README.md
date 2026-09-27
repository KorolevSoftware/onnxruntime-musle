# onnxruntime-musle

GitHub Actions builds the pinned ONNX Runtime release for Alpine Linux/musl on native GitHub-hosted x86-64 and ARM64 runners. It bootstraps Alpine Linux 3.24.1 as a chroot, compiles with Alpine's native toolchain using all runner CPUs, then publishes each library archive as an OCI artifact to GitHub Packages at `ghcr.io/korolevsoftware/onnxruntime-musle`. No Docker or QEMU is used.

The source of truth for the ONNX Runtime version and source archive SHA-512 is [`onnxruntime.env`](onnxruntime.env). The generated archive contains `lib/libonnxruntime.so*`, optional provider support, upstream license files, target architecture, version, build package inventory, and `SHA256SUMS`.

## Update ONNX Runtime

A scheduled GitHub Actions workflow checks the official stable release once a day. When a new version appears, it updates `onnxruntime.env`, commits the pin, and triggers the native builds. If you want to update immediately, run:

```sh
./scripts/update-ort-version.sh latest
```

To pin a particular stable release, pass its version, for example `./scripts/update-ort-version.sh 1.30.0`. The script checks the official GitHub release, downloads the source archive, calculates its SHA-512, and updates `onnxruntime.env`. Commit and push the change to start the build.

## Pull an architecture package

Install [ORAS](https://oras.land/docs/installation/) and pull the desired artifact from GHCR:

```sh
oras pull ghcr.io/korolevsoftware/onnxruntime-musle:latest-linux-amd64
# or
oras pull ghcr.io/korolevsoftware/onnxruntime-musle:latest-linux-arm64
```

For a commit-specific build, use `sha-<commit>-amd64` or `sha-<commit>-arm64`. The version tags are `<ORT_VERSION>-linux-amd64` and `<ORT_VERSION>-linux-arm64`, where `<ORT_VERSION>` is set in `onnxruntime.env`.

The workflow runs on each push and can also be started manually. The repository's GitHub Actions token publishes the package; after the first run, change its visibility in GitHub Packages settings if consumers need anonymous access.
