#!/bin/bash

# Configuration
VER="2025.12.2"
SOF_URL="https://github.com/thesofproject/sof-bin/releases/download/v${VER}/sof-bin-${VER}.tar.gz"

# Paths relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
TEMP_DIR="${SCRIPT_DIR}/.temp"

# Calculate Android root (Assuming script is in device/generic/common)
ANDROID_ROOT="$(cd "${SCRIPT_DIR}/../../.." &> /dev/null && pwd)"
DEST_LOCATION="${ANDROID_ROOT}/vendor/intel/proprietary/sof-bin"

echo "Checking SOF firmware..."

# 1. Check if the exact version is already installed
if [ -d "$DEST_LOCATION" ] && [ -f "$DEST_LOCATION/version.txt" ]; then
    CURRENT_VER=$(cat "$DEST_LOCATION/version.txt")
    if [ "$CURRENT_VER" = "$VER" ]; then
        echo "SOF firmware v${VER} is already up to date. Skipping download."
        exit 0
    fi
fi

# 2. Setup download command (aria2c fallback to wget)
if command -v aria2c >/dev/null 2>&1; then
    # -x4 for 4 connections, -d specifies dir, -o specifies output name
    DOWNLOAD_CMD="aria2c -x4 -d ${TEMP_DIR} -o sof-bin.tar.gz"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget -O ${TEMP_DIR}/sof-bin.tar.gz"
else
    echo "Error: Neither aria2c nor wget is installed. Please install one of them to download firmware."
    exit 1
fi

# 3. Clean and prepare .temp directory
rm -rf "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}"

# 4. Download Firmware
echo "Downloading SOF firmware v${VER}..."
if ! $DOWNLOAD_CMD "$SOF_URL"; then
    echo "Error: Download failed!"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# 5. Extract Firmware
echo "Extracting firmware to ${DEST_LOCATION}..."
# Wipe the old firmware to prevent ghost files from older versions
rm -rf "${DEST_LOCATION}"
mkdir -p "${DEST_LOCATION}"

# --strip-components=1 removes the root folder (e.g., sof-bin-2025.12.2) from the tarball
tar -xzf "${TEMP_DIR}/sof-bin.tar.gz" -C "${DEST_LOCATION}" --strip-components=1

# 6. Generate the modified install.sh dynamically
echo "Applying Android-specific modifications to install.sh..."

# Using 'EOF' in quotes prevents bash from evaluating variables, treating it as a literal string block.
cat << 'EOF' > "${DEST_LOCATION}/install.sh"
#!/bin/sh
# shellcheck disable=SC3043
set -e

: "${FW_DEST:=/lib/firmware/intel}"
: "${FW_LOCATION:=vendor/intel/proprietary/sof-bin}"

usage()
{
    cat <<UEOF
Usage example:
        sudo $0 [[v1.8.x/]v1.8]
UEOF
    exit 1
}

main()
{
    test "$#" -le 1 || usage
    local path; path=$(dirname "$1")
    local ver; #ver=$(basename "$1")
    local sdir optversuffix

    [ -z "$ver" ] || optversuffix="-$ver"

    if [ -n "$optversuffix" ]; then
        for sdir in sof sof-ipc4 sof-ipc4-tplg sof-ace-tplg sof-tplg; do
            if test -e "$FW_LOCATION/$path/$sdir${optversuffix}" ; then
                case "$(uname)" in
                    Darwin) safer_ln=;;
                    *) safer_ln='--no-target-directory';;
                esac
                ( set -x; ln -s $safer_ln "$sdir-$ver" "${FW_DEST}/$sdir" ) || true
            fi
        done
    fi

    # Trailing slash in srcdir/ ~= srcdir/*
    rsync -a "${FW_LOCATION}/${path}"/sof*"$optversuffix" "${FW_DEST}"/
}

die()
{
    >&2 printf '%s ERROR: ' "$0"
    >&2 printf "$@"
    exit 1
}

main "$@"
EOF

chmod +x "${DEST_LOCATION}/install.sh"

# 7. Write version file and clean up
echo "$VER" > "${DEST_LOCATION}/version.txt"
rm -rf "${TEMP_DIR}"

echo "SOF firmware successfully updated to v${VER}."
