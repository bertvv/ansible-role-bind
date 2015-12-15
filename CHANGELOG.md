# Change log

This file contains al notable changes to the bind Ansible role.

This file adheres to the guidelines of [http://keepachangelog.com/](http://keepachangelog.com/). Versioning follows [Semantic Versioning](http://semver.org/).  "GH-X" refers to the X'th issue on the Github project.

## 3.2.1 - 2015-12-15

### Added

* The domain name can now also point to an IP address, enabling e.g. "http://example.com/" (GH-11)

## 3.2.0 - 2015-12-07

### Added

* Add support for multiple IP addresses per host (GH-9)
* Allow setting `rrset-order` (for DNS round robin)
* Add support for (multiple) IPv6 (AAAA) records (GH-2). For now, only forward lookups are supported.

### Changed

* Test code is put into a separate branch. This means that test code is no longer included when installing the role from Ansible Galaxy.

## 3.1.0 - 2015-12-04

### Added

* Add support for zone transfers (GH-8)
* Check whether `bind_zone_master_server_ip` was set (GH-7)

### Removed

* Role variable `bind_recursion` was removed. This role is explicitly only suitable for an authoritative DNS server, and in this case, recursion should be off.

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

