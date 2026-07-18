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
bounded_log_path="${log_path}.bounded"
rm -f "${timeout_marker}" "${bounded_log_path}"

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
  fi
  command_pid=
}

compact_log() {
  if [[ -f "${log_path}" ]]; then
    if tail -c 10485760 "${log_path}" > "${bounded_log_path}"; then
      mv "${bounded_log_path}" "${log_path}"
    else
      rm -f "${bounded_log_path}"
    fi
  fi
}

cleanup() {
  status=$?
  trap - EXIT INT TERM
  stop_watchdog
  terminate_command
  compact_log
  exit "${status}"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

"$@" > "${log_path}" 2>&1 &
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
compact_log
tail -n 500 "${log_path}" || true
trap - EXIT INT TERM

if [[ -f "${timeout_marker}" ]]; then
  rm -f "${timeout_marker}"
  exit 124
fi

exit "${status}"
