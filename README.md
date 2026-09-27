# onnxruntime-musle

GitHub Actions builds ONNX Runtime 1.29.0 for Alpine Linux/musl on native GitHub-hosted x86-64 and ARM64 runners. It bootstraps Alpine Linux 3.24.1 as a chroot, compiles with Alpine's native toolchain using all runner CPUs, then publishes each library archive as an OCI artifact to GitHub Packages at `ghcr.io/korolevsoftware/onnxruntime-musle`. No Docker or QEMU is used.

A published archive contains `lib/libonnxruntime.so*`, optional provider support, upstream license files, target architecture, version, build package inventory, and `SHA256SUMS`.

## Pull an architecture package

Install [ORAS](https://oras.land/docs/installation/) and pull the desired artifact from GHCR:

```sh
oras pull ghcr.io/korolevsoftware/onnxruntime-musle:latest-linux-amd64
# or
oras pull ghcr.io/korolevsoftware/onnxruntime-musle:latest-linux-arm64
```

For a commit-specific build, use `sha-<commit>-amd64` or `sha-<commit>-arm64`. Version tags are `1.29.0-linux-amd64` and `1.29.0-linux-arm64`.

The workflow runs on each push and can also be started manually. The repository's GitHub Actions token publishes the package; after the first run, change its visibility in GitHub Packages settings if consumers need anonymous access.
