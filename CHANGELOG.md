# Change log

This file contains al notable changes to the bind Ansible role.

This file adheres to the guidelines of [http://keepachangelog.com/](http://keepachangelog.com/). Versioning follows [Semantic Versioning](http://semver.org/).

## 3.0.0 - 2015-06-14

### Added

* You can now set up a master and slave DNS server.
* The variable `bind_zone_master_server_ip` was added. This is a **required** variable, which makes this release not backwards compatible.
* Automated acceptance tests for the test playbook

## 2.0.0 - 2015-06-10

### Added

* Added EL6 to supported platforms. Thanks to @rilindo for verifying this.

### Changed

* Recursion is turned off by default, which fits an authoritative name server. This change is not backwards compatible, as the behaviour of BIND is different from before when you do not set the variable `bind_recursion` explicitly.

### Removed

* Firewall settings. This should not be a concern of this role. Configuring the firewall is functionality offered by other roles (e.g. [bertvv.bind](https://github.com/bertvv/ansible-role-el7))

## 1.0.0 - 2015-04-22

First release!

### Added

- Functionality for master DNS server
- Multiple reverse lookup zones

