#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
requested="${1:-latest}"

if [ "$requested" = latest ]; then
  release_json=$(curl --fail --location --retry 3 --silent --show-error \
    https://api.github.com/repos/microsoft/onnxruntime/releases/latest)
else
  version="${requested#v}"
  release_json=$(curl --fail --location --retry 3 --silent --show-error \
    "https://api.github.com/repos/microsoft/onnxruntime/releases/tags/v${version}")
fi

read -r version prerelease draft < <(python3 -c '
import json, sys
r = json.load(sys.stdin)
print(r["tag_name"].removeprefix("v"), str(r["prerelease"]).lower(), str(r["draft"]).lower())
' <<<"$release_json")
if [ "$prerelease" != false ] || [ "$draft" != false ]; then
  echo "Refusing non-stable ONNX Runtime release: $version" >&2
  exit 1
fi

archive_url="https://github.com/microsoft/onnxruntime/archive/refs/tags/v${version}.tar.gz"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
curl --fail --location --retry 3 --silent --show-error --max-time 900 \
  "$archive_url" -o "$tmp_dir/onnxruntime.tar.gz"
sha512=$(sha512sum "$tmp_dir/onnxruntime.tar.gz" | awk '{print $1}')

cat > "$tmp_dir/onnxruntime.env" <<EOF_ENV
ORT_VERSION=$version
ORT_SHA512=$sha512
EOF_ENV
mv "$tmp_dir/onnxruntime.env" onnxruntime.env
printf 'Pinned ONNX Runtime %s\nUpdated %s/onnxruntime.env\n' "$version" "$repo_root"
