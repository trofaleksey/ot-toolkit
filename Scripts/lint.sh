#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "${repository_root}"

xcrun swift-format lint --recursive --strict \
    OTToolkit \
    OTToolkitTests \
    OTToolkitUITests

visual_timer_domain="OTToolkit/Features/VisualTimer/Domain"
forbidden_clock_pattern='(^|[^[:alnum:]_])(Date|TimeInterval|Timer|DispatchTime|SuspendingClock)([^[:alnum:]_]|$)|^[[:space:]]*import[[:space:]]+(Foundation|Darwin|Glibc)([[:space:]]|$)'

if find "${visual_timer_domain}" -type f -name '*.swift' -print0 \
    | xargs -0 grep -nHE "${forbidden_clock_pattern}"; then
    printf '%s\n' \
        'Visual Timer domain must use only its injected monotonic clock.' >&2
    exit 1
fi
