#!/bin/bash

set -euo pipefail
set -m

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <timeout-seconds> <log-path> <command> [arguments...]" >&2
  exit 64
fi

timeout_seconds=$1
log_path=$2
shift 2

if ! [[ "${timeout_seconds}" =~ ^[1-9][0-9]*$ ]]; then
  echo "timeout must be a positive integer" >&2
  exit 64
fi

mkdir -p "$(dirname "${log_path}")"
timeout_marker="${log_path}.timeout"
rm -f "${timeout_marker}"

command_pid=
watchdog_pid=

stop_watchdog() {
  if [[ -n "${watchdog_pid}" ]] && kill -0 "${watchdog_pid}" 2>/dev/null; then
    kill -TERM -- "-${watchdog_pid}" 2>/dev/null \
      || kill -TERM "${watchdog_pid}" 2>/dev/null \
      || true
    wait "${watchdog_pid}" 2>/dev/null || true
  fi
  watchdog_pid=
}

terminate_command() {
  if [[ -n "${command_pid}" ]] && kill -0 "${command_pid}" 2>/dev/null; then
    kill -TERM -- "-${command_pid}" 2>/dev/null \
      || kill -TERM "${command_pid}" 2>/dev/null \
      || true
    for _ in 1 2 3 4 5; do
      if ! kill -0 "${command_pid}" 2>/dev/null; then
        break
      fi
      sleep 1
    done
    kill -KILL -- "-${command_pid}" 2>/dev/null \
      || kill -KILL "${command_pid}" 2>/dev/null \
      || true
    wait "${command_pid}" 2>/dev/null || true
    xcrun simctl shutdown all >/dev/null 2>&1 || true
  fi
  command_pid=
}

cleanup() {
  status=$?
  trap - EXIT INT TERM
  stop_watchdog
  terminate_command
  exit "${status}"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

"$@" > >(tee "${log_path}") 2>&1 &
command_pid=$!

(
  sleep "${timeout_seconds}"
  if kill -0 "${command_pid}" 2>/dev/null; then
    message="Test command exceeded ${timeout_seconds} seconds."
    printf '::error::%s\n' "${message}"
    printf '%s\n' "${message}" >> "${log_path}"
    touch "${timeout_marker}"
    kill -TERM -- "-${command_pid}" 2>/dev/null \
      || kill -TERM "${command_pid}" 2>/dev/null \
      || true
    sleep 5
    kill -KILL -- "-${command_pid}" 2>/dev/null \
      || kill -KILL "${command_pid}" 2>/dev/null \
      || true
  fi
) &
watchdog_pid=$!

set +e
wait "${command_pid}"
status=$?
set -e
command_pid=
stop_watchdog

if [[ -f "${timeout_marker}" ]]; then
  rm -f "${timeout_marker}"
  xcrun simctl shutdown all >/dev/null 2>&1 || true
  exit 124
fi

exit "${status}"
