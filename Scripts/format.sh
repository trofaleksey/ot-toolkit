#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "${repository_root}"

xcrun swift-format format --in-place --recursive \
    OTToolkit \
    OTToolkitTests \
    OTToolkitUITests
