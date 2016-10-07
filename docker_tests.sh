#! /usr/bin/bash
#
# Author: Bert Van Vreckem <bert.vanvreckem@gmail.com>
#
# PURPOSE
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
readonly SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

#}}}

main() {
  check_args "${@}"

}

#{{{ Helper functions

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
Usage: ${SCRIPT_NAME} [OPTIONS]... [ARGS]...

  description

OPTIONS:

EXAMPLES:
_EOF_
}

#}}}

main "${@}"

