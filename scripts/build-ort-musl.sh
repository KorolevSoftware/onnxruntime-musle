#!/usr/bin/env bash
set -euo pipefail

arch=${1:?usage: build-ort-musl.sh amd64|arm64 x86_64|aarch64}
alpine_arch=${2:?usage: build-ort-musl.sh amd64|arm64 x86_64|aarch64}
case "$arch:$alpine_arch" in
  amd64:x86_64|arm64:aarch64) ;;
  *) echo "Unsupported architecture pair: $arch:$alpine_arch" >&2; exit 1 ;;
esac

alpine_version=3.24.1
ort_version=1.30.0
work_root="${RUNNER_TEMP:-/tmp}/ort-musl-${arch}"
rootfs="$work_root/rootfs"
output="$PWD/artifacts"
mkdir -p "$rootfs" "$output"

cleanup() {
  sudo umount "$rootfs/proc" 2>/dev/null || true
  sudo umount "$rootfs/dev" 2>/dev/null || true
}
trap cleanup EXIT

rootfs_archive="alpine-minirootfs-${alpine_version}-${alpine_arch}.tar.gz"
rootfs_url="https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/${alpine_arch}/${rootfs_archive}"
curl --fail --location --retry 3 "$rootfs_url" -o "$work_root/$rootfs_archive"
curl --fail --location --retry 3 "${rootfs_url}.sha256" -o "$work_root/$rootfs_archive.sha256"
(cd "$work_root" && sha256sum --check "$rootfs_archive.sha256")
sudo tar --numeric-owner -xzf "$work_root/$rootfs_archive" -C "$rootfs"

ort_url="https://github.com/microsoft/onnxruntime/archive/refs/tags/v${ort_version}.tar.gz"
curl --fail --location --retry 3 --max-time 600 "$ort_url" -o "$work_root/onnxruntime.tar.gz"
echo '10045518738889ec63e3a490d248f8cfc342775ce54b134f2996c7e47f744d1bf7332a5d57b3b3072aed5ef4dfeffd0de2593954735c5ce898048f1380b2c91c  onnxruntime.tar.gz' \
  | (cd "$work_root" && sha512sum --check -)
sudo mkdir -p "$rootfs/src/onnxruntime" "$rootfs/out"
sudo tar -xzf "$work_root/onnxruntime.tar.gz" --strip-components=1 -C "$rootfs/src/onnxruntime"
sudo cp /etc/resolv.conf "$rootfs/etc/resolv.conf"

cat > "$work_root/build-inside-alpine.sh" <<'CHROOT'
#!/bin/sh
set -eu
arch="$1"
ort_version="$2"
cd /src/onnxruntime
apk add --no-cache build-base linux-headers cmake ninja python3 bash git curl ca-certificates coreutils
printf '%s\n' \
  'if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 15 AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 16)' \
  '  set_source_files_properties("${ONNXRUNTIME_ROOT}/core/common/logging/logging.cc" PROPERTIES COMPILE_OPTIONS "-Wno-error=maybe-uninitialized")' \
  'endif()' >> cmake/onnxruntime_common.cmake
cmake -S cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -Donnxruntime_BUILD_SHARED_LIB=ON \
  -Donnxruntime_BUILD_UNIT_TESTS=OFF \
  -Donnxruntime_ENABLE_PYTHON=OFF \
  -DFLATBUFFERS_LOCALE_INDEPENDENT=OFF
cmake --build build --parallel "$(nproc)"
mkdir -p /out/lib
cp -P build/libonnxruntime.so* /out/lib/
if [ -f build/libonnxruntime_providers_shared.so ]; then cp build/libonnxruntime_providers_shared.so /out/lib/; fi
strip /out/lib/libonnxruntime.so.*
cp LICENSE ThirdPartyNotices.txt /out/
printf '%s\n' "$arch" > /out/architecture
printf '%s\n' "$ort_version" > /out/version
apk info -vv | sort > /out/build-packages.txt
cd /out
sha256sum lib/* LICENSE ThirdPartyNotices.txt architecture version build-packages.txt > SHA256SUMS
CHROOT
sudo cp "$work_root/build-inside-alpine.sh" "$rootfs/tmp/build-inside-alpine.sh"
sudo mount --bind /dev "$rootfs/dev"
sudo mount --bind /proc "$rootfs/proc"
sudo chroot "$rootfs" /bin/sh /tmp/build-inside-alpine.sh "$arch" "$ort_version"

sudo cp -a "$rootfs/out/." "$output/"
sudo chown -R "$(id -u):$(id -g)" "$output"
tar -C "$output" -czf "$output/onnxruntime-${ort_version}-linux-${arch}-musl.tar.gz" \
  lib LICENSE ThirdPartyNotices.txt architecture version build-packages.txt SHA256SUMS
echo "Built $output/onnxruntime-${ort_version}-linux-${arch}-musl.tar.gz"
