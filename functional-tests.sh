#! /usr/bin/env bash
#
# Author:   Bert Van Vreckem <bert.vanvreckem@gmail.com>
#
# Run BATS test files in the current directory, and the ones in the subdirectory
# matching the host name.
#
# The script installs BATS if needed. It's best to put ${bats_install_dir} in
# your .gitignore.

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable

#{{{ Variables

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bats_archive="v0.4.0.tar.gz"
bats_url="https://github.com/sstephenson/bats/archive/${bats_archive}"
bats_install_dir="/opt"
bats_default_location="${bats_install_dir}/bats/libexec/bats"
test_file_pattern="*.bats"

# Color definitions
readonly reset='\e[0m'
readonly black='\e[0;30m'
readonly red='\e[0;31m'
readonly green='\e[0;32m'
readonly yellow='\e[0;33m'
readonly blue='\e[0;34m'
readonly purple='\e[0;35m'
readonly cyan='\e[0;36m'
readonly white='\e[0;37m'
#}}}

main() {

  bats=$(find_bats_executable)

  if [ -z "${bats}" ]; then
    install_bats
    bats="${bats_default_location}"
  fi

  debug "Using BATS executable at: ${bats}"

  # List all test cases (i.e. files in the test dir matching the test file
  # pattern)

  # Tests to be run on all hosts
  global_tests=$(find_tests "${test_dir}" 1)

  # Tests for individual hosts
  host_tests=$(find_tests "${test_dir}/${HOSTNAME}")

  # Loop over test files
  for test_case in ${global_tests} ${host_tests}; do
    info "Running test ${test_case}"
    ${bats} "${test_case}"
  done
}

#{{{ Functions

# Tries to find BATS executable in the PATH or the place where this script
# installs it.
find_bats_executable() {
  if which bats > /dev/null;  then
    which bats
  elif [ -x "${bats_default_location}" ]; then
    echo "${bats_default_location}"
  else
    echo ""
  fi
}

# Usage: install_bats
install_bats() {
  pushd "${bats_install_dir}" > /dev/null 2>&1
  curl --location --remote-name "${bats_url}"
  tar xzf "${bats_archive}"
  mv bats-* bats
  rm "${bats_archive}"
  popd > /dev/null 2>&1
}

# Usage: find_tests DIR [MAX_DEPTH]
#
# Finds BATS test suites in the specified directory
find_tests() {
  local max_depth=""
  if [ "$#" -eq "2" ]; then
    max_depth="-maxdepth $2"
  fi

  local tests
  tests=$(find "$1" ${max_depth} -type f -name "${test_file_pattern}" -printf '%p\n' 2> /dev/null)

  echo "${tests}"
}

# Usage: info [ARG]...
#
# Prints all arguments on the standard output stream
info() {
  printf "${yellow}### %s${reset}\n" "${*}"
}

# Usage: debug [ARG]...
#
# Prints all arguments on the standard output stream
debug() {
  printf "${cyan}### %s${reset}\n" "${*}"
}
#}}}

main
