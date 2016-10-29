#! /usr/bin/env bash
#
# Author: Bert Van Vreckem <bert.vanvreckem@gmail.com>
#
# Runs tests for this Ansible role on a Docker container
# Environment variables DISTRIBUTION and VERSION must be set
# See usage() for details.

#{{{ Bash settings
# abort on nonzero exitstatus
set -o errexit
# abort on unbound variable
set -o nounset
# don't hide errors within pipes
set -o pipefail
#}}}
#{{{ Variables
readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

readonly container_id="$(mktemp)"
readonly role_dir='/etc/ansible/roles/role_under_test'
readonly test_playbook="${role_dir}/tests/test.yml"

readonly docker_image="bertvv/ansible-testing"

# Distribution specific settings
init="/sbin/init"
run_opts=("--privileged")
#}}}

main() {
  configure_env

  start_container

  run_syntax_check
  run_playbook
  run_idempotence_test

}

#{{{ Helper functions

configure_env() {

  case "${DISTRIBUTION}_${VERSION}" in
    'centos_7')
      init=/usr/lib/systemd/systemd
      run_opts+=('--volume=/sys/fs/cgroup:/sys/fs/cgroup:ro')
      ;;
    'ubuntu_14.04')
      # Workaround for issue when the host operating system has SELinux
      if [ -x '/usr/sbin/getenforce' ]; then
        run_opts+=('--volume=/sys/fs/selinux:/sys/fs/selinux:ro')
      fi
      ;;
    'ubuntu_16.04')
      run_opts=('--volume=/run' '--volume=/run/lock' '--volume=/tmp' '--volume=/sys/fs/cgroup:/sys/fs/cgroup:ro' '--cap-add=SYS_ADMIN' '--cap-add=SYS_RESOURCE')

      if [ -x '/usr/sbin/getenforce' ]; then
        run_opts+=('--volume=/sys/fs/selinux:/sys/fs/selinux:ro')
      fi
      ;;
  esac
}

# Usage: build_container
build_container() {
  docker build --tag="${docker_image}:${DISTRIBUTION}_${VERSION}" .
}

start_container() {
  log "Starting container"
  set -x
  docker run --detach \
    --volume="${PWD}:${role_dir}:ro" \
    "${run_opts[@]}" \
    "${docker_image}:${DISTRIBUTION}_${VERSION}" \
    "${init}" \
    > "${container_id}"
  set +x
}

get_container_id() {
  cat "${container_id}"
}

# Usage: get_container_ip CONTAINER_ID
get_container_ip() {
  local container_id="${1}"

  docker inspect \
    --format '{{ .NetworkSettings.IPAddress }}' \
    "${container_id}"
}

exec_container() {
  id="$(get_container_id)"

  set -x
  docker exec --tty \
    "${id}" \
    env TERM=xterm \
    "${@}"
  set +x
}

run_syntax_check() {
  log "Running syntax check on playbook"
  exec_container ansible-playbook "${test_playbook}" --syntax-check
}

run_playbook() {
  log "Running playbook"
  exec_container ansible-playbook "${test_playbook}"
  log "Run finished"
}

run_idempotence_test() {
  log "Running idempotence test"
  local output
  output="$(mktemp)"

  exec_container ansible-playbook "${test_playbook}" 2>&1 | tee "${output}"

  if grep -q 'changed=0.*failed=0' "${output}"; then
    result='pass'
    return_status=0
  else
    result='fail'
    return_status=1
  fi
  rm "${output}"

  log "Result: ${result}"
  return "${return_status}"
}

cleanup() {
  log "Cleaning up"
  id="$(get_container_id)"

  docker stop "${id}"
  docker rm "${id}"
  rm "${container_id}"
}

# Check if command line arguments are valid
check_args() {
  if [ "${#}" -ne "1" ]; then
    echo "Expected 1 argument, got ${#}" >&2
    usage
    exit 2
  fi
}

# Print usage message on stdout
usage() {
cat << _EOF_
Usage: ${script_name} [OPTIONS]... [ARGS]...

  Creates a Docker container, installs this role, and runs tests.

OPTIONS:

EXAMPLES:
_EOF_
}

log() {
  local yellow='\e[0;33m'
  local reset='\e[0m'

  printf "${yellow}>>> %s${reset}\n" "${*}"
}

#}}}

main "${@}"

#trap cleanup EXIT INT ERR HUP TERM
