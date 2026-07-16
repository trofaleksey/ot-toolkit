#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "${repository_root}"

xcrun swift-format lint --recursive --strict \
    OTToolkit \
    OTToolkitTests \
    OTToolkitUITests
