#!/usr/bin/env bash
# Blaze CLI (staging, 社内向け) installer for macOS / Linux
# 使い方: curl -fsSL https://cli.igness.ai/install-stg.sh | bash
set -euo pipefail

REPO="igness-ai/blaze-cli-dist"
INSTALL_DIR="${HOME}/.blaze-stg/bin"
BINARY_NAME="blaze-stg"

detect_platform() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"
    case "$os" in
        Darwin) os_triple="apple-darwin" ;;
        *) echo "error: unsupported OS: $os" >&2; exit 1 ;;
    esac
    case "$arch" in
        x86_64|amd64)
            if [ "$os_triple" = "apple-darwin" ]; then
                echo "error: Intel Mac はサポート対象外です。Apple Silicon Mac をご使用ください。" >&2
                exit 1
            fi
            arch_triple="x86_64"
            ;;
        arm64|aarch64) arch_triple="aarch64" ;;
        *) echo "error: unsupported architecture: $arch" >&2; exit 1 ;;
    esac
    echo "${arch_triple}-${os_triple}"
}

# 最新 staging tag (stg-*) を取得 (releases 一覧から先頭の prerelease)
get_latest_staging_tag() {
    curl -fsSL --proto '=https' --tlsv1.2 \
        "https://api.github.com/repos/${REPO}/releases?per_page=10" \
        | grep '"tag_name"' \
        | sed -E 's/.*"(stg-[^"]+)".*/\1/' \
        | grep '^stg-' \
        | sort -r \
        | head -n1
}

# trap EXIT は main() の local スコープ外で発火するため、tmpdir はグローバルに持つ
tmpdir=""

main() {
    local platform tag archive url checksum_url
    platform="$(detect_platform)"
    tag="$(get_latest_staging_tag)"
    [ -n "$tag" ] || { echo "error: staging tag 取得失敗" >&2; exit 1; }

    archive="blaze-stg-${platform}.tar.gz"
    url="https://github.com/${REPO}/releases/download/${tag}/${archive}"
    checksum_url="${url}.sha256"

    echo "Installing Blaze CLI staging (${tag}, ${platform})..."

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    # CI 生成の本来のファイル名のまま保存する (sha256 ファイル内の記載と一致させるため)
    curl -fsSL --proto '=https' --tlsv1.2 "$url" -o "${tmpdir}/${archive}"
    curl -fsSL --proto '=https' --tlsv1.2 "$checksum_url" -o "${tmpdir}/${archive}.sha256"

    cd "$tmpdir"
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 -c "${archive}.sha256"
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum -c "${archive}.sha256"
    else
        echo "error: shasum/sha256sum が利用不可。整合性検証ができません" >&2
        exit 1
    fi

    if tar tzf "$archive" | grep -E '^/|(^|/)\.\.(/|$)' >/dev/null; then
        echo "error: archive contains unsafe paths" >&2
        exit 1
    fi
    # macOS の bsdtar は GNU tar 専用の --no-same-owner / --no-overwrite-dir を受けない。
    # zip-slip は tar tzf の事前検査、改竄は SHA-256 で防御済みなので追加オプション不要。
    tar xzf "$archive"
    mkdir -p "$INSTALL_DIR"

    if [ -f "${INSTALL_DIR}/${BINARY_NAME}" ]; then
        mv "${INSTALL_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}.bak"
    fi
    # tar 内のバイナリは "blaze" 名 (CI で固定) なのでリネームして配置
    mv "blaze" "${INSTALL_DIR}/${BINARY_NAME}"
    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    rm -f "${INSTALL_DIR}/${BINARY_NAME}.bak"

    echo "Installed to ${INSTALL_DIR}/${BINARY_NAME}"

    if ! echo "$PATH" | grep -q "${INSTALL_DIR}"; then
        local rc=""
        if [ -f "${HOME}/.zshrc" ]; then rc="${HOME}/.zshrc"
        elif [ -f "${HOME}/.bashrc" ]; then rc="${HOME}/.bashrc"
        elif [ -f "${HOME}/.profile" ]; then rc="${HOME}/.profile"
        fi
        if [ -n "$rc" ]; then
            echo "export PATH=\"${INSTALL_DIR}:\$PATH\"" >> "$rc"
            echo "Added ${INSTALL_DIR} to PATH in ${rc}"
            echo "次のいずれかで反映: source ${rc}  または新しいターミナルを開く"
        fi
    fi

    echo
    echo "Run '${BINARY_NAME}' to get started."
}

main "$@"
