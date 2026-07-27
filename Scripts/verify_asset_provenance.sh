#!/bin/sh

# Fails when a shipped SF Symbol is missing from the asset provenance ledger.
#
# The ledger went stale between OTK-003 and OTK-040 because nothing checked it.
# This recognizes the syntactic forms the app actually uses to name a symbol:
# `systemName:`/`systemImage:`/`symbolName:`/`stateSymbol:` arguments, and the
# bodies of `var systemName/statusSymbol/stateSymbol: String` computed
# properties. A symbol introduced through some other form would not be seen, so
# adding a new naming pattern requires extending this extractor.

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "${repository_root}"

ledger="Documentation/ASSET_PROVENANCE.md"
test -s "${ledger}"

symbols=$(
    find OTToolkit -type f -name '*.swift' -print0 \
        | xargs -0 awk '
            function collect(text,   literal) {
                while (match(text, /"[^"]*"/)) {
                    literal = substr(text, RSTART + 1, RLENGTH - 2)
                    # SF Symbol names are lowercase/digit segments. Localized
                    # string keys in this project are camelCase, so they are
                    # excluded by the same shape test.
                    if (literal ~ /^[a-z0-9][a-z0-9.]*$/) {
                        print literal
                    }
                    text = substr(text, RSTART + RLENGTH)
                }
            }

            # Track the body of a symbol-producing computed property so bare
            # switch-case literals are collected too.
            /var (systemName|symbolName|statusSymbol|stateSymbol): String \{/ {
                in_symbol_property = 1
                depth = 0
            }
            in_symbol_property {
                collect($0)
                depth += gsub(/\{/, "{")
                depth -= gsub(/\}/, "}")
                if (depth <= 0) {
                    in_symbol_property = 0
                }
                next
            }
            # Only literals after the argument label are symbols: a preceding
            # literal is the localized title in Label("key", systemImage: ...).
            match($0, /(systemName|systemImage|symbolName|stateSymbol|statusSymbol):/) {
                collect(substr($0, RSTART + RLENGTH))
            }
        ' \
        | sort -u
)

missing=""
for symbol in ${symbols}; do
    if ! grep -qF "\`${symbol}\`" "${ledger}"; then
        missing="${missing}${symbol}
"
    fi
done

if [ -n "${missing}" ]; then
    printf '%s\n' 'Shipped SF Symbols are missing from the asset provenance ledger:' >&2
    printf '%s' "${missing}" >&2
    printf '%s\n' "Add each symbol to ${ledger} before shipping it." >&2
    exit 1
fi

printf '%s\n' "Asset provenance ledger covers every extracted SF Symbol."
