#!/bin/bash
KSU_ROOT="$(dirname "$(readlink -f "$0")")/.."
cd "$KSU_ROOT"

fetch_url() {
    # Skip network fetch if running inside Android build system to avoid restricted PATH errors
    if [[ "$PATH" == *"/out/.path/"* ]] || [[ "$PATH" == *"/prebuilts/build-tools/"* ]]; then
        return 1
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -LSs "$1" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$1" 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import urllib.request, sys; sys.stdout.buffer.write(urllib.request.urlopen('$1').read())" 2>/dev/null
    else
        return 1
    fi
}

LOCAL_VERSION=0
if [ -f "drivers/kernelsu/Makefile" ]; then
    LOCAL_VERSION=$(awk -F= '/CFLAGS_ksu\.o \+= -DKSU_VERSION=/ {print $3}' drivers/kernelsu/Makefile || echo 0)
fi

FORCE_UPDATE=0
KSU_REF="master"
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
        FORCE_UPDATE=1
        shift
        ;;
        -c|--clean)
        echo "[+] Cleaning up KernelSU directory..." >&2
        rm -rf drivers/kernelsu
        exit 0
        ;;
        -r|--ref|--commit|--branch)
        KSU_REF="$2"
        shift 2
        ;;
        *)
        shift
        ;;
    esac
done

REMOTE_VERSION=$(fetch_url "https://raw.githubusercontent.com/backslashxx/KernelSU/${KSU_REF}/kernel/Makefile" | awk -F= '/CFLAGS_ksu\.o \+= -DKSU_VERSION=/ {print $3}' || echo 0)

if [ -z "$REMOTE_VERSION" ] || [ "$REMOTE_VERSION" = "0" ]; then
    echo "[-] Failed to fetch remote KernelSU version for ref '${KSU_REF}'. Using existing version!" >&2
elif [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ] || [ ! -d "drivers/kernelsu" ] || [ "$FORCE_UPDATE" = "1" ]; then
    echo "[+] Updating KernelSU from version $LOCAL_VERSION to $REMOTE_VERSION (ref: ${KSU_REF})..." >&2
    
    # Remove existing symlink or folder if present
    echo "[+] Cleanup exist version..." >&2
    rm -rf drivers/kernelsu

    # Download and extract the kernel directory from the archive
    fetch_url "https://github.com/backslashxx/KernelSU/archive/${KSU_REF}.tar.gz" | tar -xz -C drivers/ --wildcards '*/kernel' --transform 's|^[^/]*/kernel|kernelsu|' >&2
    
    if [ $? -eq 0 ]; then
        echo "[+] KernelSU downloaded successfully (version $REMOTE_VERSION)." >&2
    else
        echo "[-] Failed to download KernelSU. Using exist version!" >&2
    fi
else
    echo "[+] KernelSU is up to date (version $LOCAL_VERSION)." >&2
fi
