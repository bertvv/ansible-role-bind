# Change log

This file contains al notable changes to the bind Ansible role.

This file adheres to the guidelines of [http://keepachangelog.com/](http://keepachangelog.com/). Versioning follows [Semantic Versioning](http://semver.org/).  "GH-X" refers to the X'th issue/pull request on the Github project.

## 4.1.0 - 2018-10-05

## Added

- (GH-53) Add variable `bind_zone_dir` and `bind_zone_file_mode` for setting the master zone file path and mode, and `bind_extra_include_files` for including arbitrary configuration files into named.conf. (credit: [Brad Durrow](https://github.com/bdurrow))
- (GH-64) Add variable `bind_query_log` to enable query logging (credit: [Angel Barrera](https://github.com/angelbarrera92))

## Changed

- (GH-55) Fix issue with non-existing file when grepping domain (credit: [Tom Meinlschmidt](https://github.com/tmeinlschmidt))
- (GH-57) Fix issue with forwarding in subdomain delegations (credit: [Stuart Knight](https://github.com/blofeldthefish))
- (GH-66) Fix issue that causes playbook to fail when running in `--check` mode (credit: [Jörg Eichhorn](https://github.com/jeichhorn))
- (GH-67) Improved documentation with minimal slave configuration (credit: [Christopher Hicks](https://github.com/chicks-net))
- Add Ubuntu 18.04, Debian 8-9 and Arch Linux to list of supported distros.

## 4.0.1 - 2018-05-21

### Changed

- (GH-52) Move all zone specific configuration options to `bind_zones`  (credit: [Stuart Knight](https://github.com/blofeldthefish))

## 4.0.0 - 2018-05-19

### Added

- (GH-50) Add support for multiple zones (credit: [Stuart Knight](https://github.com/blofeldthefish)). **This is a breaking change,** as it changes the syntax for specifying zones.
- Allow out-of-zone name server records

## 3.9.1 - 2018-04-22

## Changed

- Allow multi-line `ansible_managed` comment (credit: [Fazle Arefin](https://github.com/fazlearefin))
- Fix the atrocious implementation of (GH-35)
- Updated documentation for specifying hosts with multiple IP addresses
- Create serial as UTC UNIX time (credit: [David J. Haines](https://github.com/dhaines))
- Fix bugs, linter and deprecation warnings

## 3.9.0 - 2017-11-21

### Added

- (GH-35) Role variable `bind_check_names`, which adds support for check-names (e.g. `check-names master ignore;`)
- (GH-36) Role variable `bind_allow_recursion`, which adds support for allow-recursion (credit: [Loic Dachary](https://github.com/dachary))
- (GH-39) Role variable `bind_zone_delegate`, which adds support for zone delegation / NS records (credit: [Loic Dachary](https://github.com/dachary))
- (GH-40) Role variables `bind_dnssec_enable` and `bind_dnssec_validation`, which makes DNSSEC validation configurable (credit: [Guillaume Darmont](https://github.com/gdarmont)).

### Changed

- (GH-38) Only append domain to MX if it does not end with a dot (credit: [Loic Dachary](https://github.com/dachary))

## 3.8.0 - 2017-07-12

This release adds support for multiple TXT entries and fixes some bugs.

### Added

- (GH-31) Support for multiple TXT entries for the same name (credit: [Rafael Bodill](https://github.com/rafi))

### Changed

- (GH-31) Fixed ipv6 reverse zone hash calculation for complete idempotency (credit: [Stuart Knight](https://github.com/blofeldthefish))
- (GH-32, GH-33) Fix for bug where CNAMEs and Multi-IP entries weren't working (credit: [Greg Cockburn](https://github.com/gergnz))

## 3.7.1 - 2017-07-03

### Changed

- (GH-29) Zone files are fully idempotent, so are only changed when actual content changes (credit: [@Stuart Knight](https://github.com/blofeldthefish))

## 3.7.0 - 2017-06-01

### Added

- (GH-10) Implement reverse IPv6 lookups
- (GH-28) Add option `bind_forwarders` and `bind_forward_only`, which allows BIND to be set up as a caching name server.

## 3.6.1 - 2017-06-01

### Changed

- Fixed a bug with generating the reverse zone names.

## 3.6.0 - 2017-06-01

### Changed

- (GH-25) Allow slave log file to be set with variable `bind_log` instead of a hard coded value (credit @kartone).
- The alignment of columns in the reverse zone file are improved

### Added

- (GH-22, 23) Documentation improvements
- (GH-27) Allow dynamic updates (credit: @bverschueren)

### Removed

- The custom filter plugins were removed. The functionality has since been added to Ansible's built-in filter plugins. This does require `python-netaddr` to be installed on the management node.

## 3.5.2 - 2016-09-29

### Changed

* The call to `named-checkconf` was fixed. It had the full path to the binary, which is not the same on all distributions. (GH-20, credit @peterjanes)

## 3.5.1 - 2016-09-22

### Changed

* The check for master/slave server is improved (GH-19, credit @josetaas)

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

