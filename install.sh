#!/bin/sh
# Install the IrukaDark CLI.
#   curl -fsSL https://raw.githubusercontent.com/co-r-e/irukadark-cli/main/install.sh | sh
# Options (environment variables):
#   IRUKADARK_INSTALL_DIR  Where to put irukadark (default: ~/.local/bin)
#   IRUKADARK_VERSION      A version to install, such as 0.1.0 (default: the latest)
set -eu

REPOSITORY="co-r-e/irukadark-cli"
INSTALL_DIR="${IRUKADARK_INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${IRUKADARK_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/irukadark}"

fail() {
  echo "irukadark: $*" >&2
  exit 1
}

case "$(uname -s)" in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  *) fail "This computer is not supported yet. irukadark runs on macOS and Linux (on Windows, use WSL)." ;;
esac
case "$(uname -m)" in
  arm64 | aarch64) arch=arm64 ;;
  x86_64 | amd64) arch=x64 ;;
  *) fail "This processor ($(uname -m)) is not supported." ;;
esac
# Apple silicon running this script under Rosetta reports x86_64
if [ "$os" = darwin ] && [ "$arch" = x64 ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = 1 ]; then
  arch=arm64
fi

name="irukadark-${os}-${arch}"
if [ -n "${IRUKADARK_VERSION:-}" ]; then
  base="https://github.com/${REPOSITORY}/releases/download/v${IRUKADARK_VERSION#v}"
else
  base="https://github.com/${REPOSITORY}/releases/latest/download"
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
else
  fail "sha256sum or shasum is needed to check the download."
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

echo "Downloading ${name}..."
curl -fsSL --retry 3 -o "$tmp/$name" "$base/$name" || fail "Could not download ${base}/${name}"
curl -fsSL --retry 3 -o "$tmp/SHA256SUMS" "$base/SHA256SUMS" || fail "Could not download the checksums."

expected="$(awk -v n="$name" '$2 == n || $2 == "*" n {print $1}' "$tmp/SHA256SUMS")"
actual="$(sha256 "$tmp/$name")"
if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
  fail "The download does not match its checksum. Nothing was installed."
fi

mkdir -p "$INSTALL_DIR"
chmod 755 "$tmp/$name"
mv "$tmp/$name" "$INSTALL_DIR/irukadark"

# irukadark update replaces only a copy it knows was installed by this script
mkdir -p "$CONFIG_DIR"
printf '{"method":"script","path":"%s"}\n' "$INSTALL_DIR/irukadark" > "$CONFIG_DIR/install.json"

version="$("$INSTALL_DIR/irukadark" version 2>/dev/null || true)"
echo "Installed ${version:-irukadark} to ${INSTALL_DIR}/irukadark"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo
    echo "Add ${INSTALL_DIR} to your PATH, for example:"
    echo "  echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ~/.zshrc"
    ;;
esac

echo
echo "Next:"
echo "  irukadark auth login       Sign in"
echo "  irukadark skills install   Let Claude Code and Codex use irukadark"
