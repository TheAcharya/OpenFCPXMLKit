#!/usr/bin/env bash
#
# Regenerate EmbeddedDTDs.swift from Sources/OpenFCPXMLKit/FCPXML DTDs.
# Invokes the GenerateEmbeddedDTDs executable; output is written to
# Sources/OpenFCPXMLKitCLI/Generated/EmbeddedDTDs.swift.
#
# Run from anywhere; the script finds the package root (directory containing Package.swift).
# Usage: ./Scripts/generate_embedded_dtds.sh
#    or: bash Scripts/generate_embedded_dtds.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f "$PACKAGE_ROOT/Package.swift" ]]; then
    echo "Error: Package.swift not found at $PACKAGE_ROOT" >&2
    exit 1
fi

DTD_DIR="$PACKAGE_ROOT/Sources/OpenFCPXMLKit/FCPXML DTDs"
if [[ ! -d "$DTD_DIR" ]]; then
    echo "Error: DTD directory not found: $DTD_DIR" >&2
    exit 1
fi

cd "$PACKAGE_ROOT"
swift run GenerateEmbeddedDTDs
