#! /usr/bin/bash
#
# Author:   Bert Van Vreckem <bert.vanvreckem@gmail.com>
#
# The script installs BATS if needed. It's best to put ${bats_install_dir} in
# your .gitignore.

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable

#{{{ Variables

test_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bats_repo_url="https://github.com/sstephenson/bats.git"
bats_install_dir="${test_dir}/bats"
bats="${bats_install_dir}/libexec/bats"

ns_ips="192.168.56.53 192.168.56.54"

# color definitions
Blue='\e[0;34m'
Yellow='\e[0;33m'
Reset='\e[0m'

#}}}
# Script proper

# Install BATS if needed
if [ ! -d "${bats_install_dir}" ]; then
  git clone "${bats_repo_url}" "${bats_install_dir}"
  rm -rf "${bats_install_dir}/.git*"
fi


# Run the test script on both master and slave server
for sut in ${ns_ips}; do
  echo -e "${Blue}Testing ${Yellow}${sut}${Reset}"
  ns_ip=${sut} ${bats} ${test_dir}/dns.bats
done
