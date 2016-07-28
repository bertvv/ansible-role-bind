# Change log

This file contains al notable changes to the bind Ansible role.

This file adheres to the guidelines of [http://keepachangelog.com/](http://keepachangelog.com/). Versioning follows [Semantic Versioning](http://semver.org/).  "GH-X" refers to the X'th issue/pull request on the Github project.

## 3.5.0 - 2016-07-28

### Added

* Introduced role variable `bind_log`, the path to the log file.
* Introduced role variable `bind_zone_also_notify`, a list of servers that will receive a notification when the master zone file is reloaded (GH-18, credit: Joanna Delaporte)
* Reverse zone files now handle the case with only a single host (GH-18, credit: Joanna Delaporte)

## 3.4.0 - 2016-05-26

### Added

* (GH-16) Support for service record (SRV) lookups
* Support for text record (TXT) lookups

### Changed

* Fixed Ansible 2.0 deprecation warnings
* Generating a serial is no longer considered a change
* Ensured that all role variables have a default value, e.g. empty list instead of undefined. This simplifies template logic (no `if defined` tests), and is considered [deprecated in playbooks within a *with_* loop](https://docs.ansible.com/ansible/porting_guide_2.0.html#deprecated).

## 3.3.1 - 2016-04-08

### Removed

* The `version:` field in `meta/main.yml`. This an unofficial field that is used by a third-party tool for managing role dependencies (librarian-ansible). Custom meta fields are no longer accepted in Ansible 2.0. See [ansible/ansible#13496](https://github.com/ansible/ansible/issues/13496) for more info. Unfortunately, this will break support for librarian-ansible. As a workaround, until this issue is resolved upstream, use version 3.3.0 of this role.

## 3.3.0 - 2016-04-08

### Added

* Added role variable `bind_other_name_servers` for adding NS records for DNS servers outside of the domain. (GH-12)
* Re-added `bind_recursion`, as it is needed in some cases. (GH-14)

### Removed

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

