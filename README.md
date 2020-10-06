# Ansible role BIND

[![Actions Status](https://github.com/bertvv/ansible-role-bind/workflows/CI/badge.svg)](https://github.com/bertvv/ansible-role-bind/actions)

An Ansible role for setting up ISC BIND as an **authoritative-only** DNS server for multiple domains. Specifically, the responsibilities of this role are to:

- install BIND
- set up the main configuration file (primary/secondary server)
- set up forward and reverse lookup zone files

This role supports multiple forward and reverse zones, including for IPv6. Although enabling recursion is supported (albeit *strongly* discouraged), consider using another role if you want to set up a caching or forwarding name server.

If you like/use this role, please consider giving it a star and rating it on the role's [Ansible Galaxy page](https://galaxy.ansible.com/bertvv/bind). Thanks!

See the [change log](CHANGELOG.md) for notable changes between versions.

**WARNING:** If you've been using this role since **before v5.0.0**, please check the change log for important information on breaking changes. Old playbooks will fail if you upgrade to v5.0.0.

## Supported platforms

This role can be used on several platforms, see [meta/main.yml](meta/main.yml) for an updated list. We strive to set up automated tests for each supported platform (see [.ci.yml](.github/workflows/ci.yml)), but this is not always possible.

A few remarks on supported roles that are not included in automated tests

- **Arch Linux** and **FreeBSD** should work, but at this time, it's not possible to test the role on these distros, since no suitable Docker images are available.
- **CentOS 6** should work, but idempotence tests fail even if BIND is installed succesfully and acceptance tests succeed.

## Requirements

The packages `python-netaddr` (required for the [`ipaddr`](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters_ipaddr.html) filter) and `dnspython` should be installed on the management node

## Role Variables

| Variable                    | Default              | Comments (type)                                                                                                                      |
|:----------------------------|:---------------------|:-------------------------------------------------------------------------------------------------------------------------------------|
| `bind_acls`                 | `[]`                 | A list of ACL definitions, which are mappings with keys `name:` and `match_list:`. See below for an example.                         |
| `bind_allow_query`          | `['localhost']`      | A list of hosts that are allowed to query this DNS server. Set to ['any'] to allow all hosts                                         |
| `bind_allow_recursion`      | `['any']`            | Similar to `bind_allow_query`, this option applies to recursive queries.                                                             |
| `bind_check_names`          | `[]`                 | Check host names for compliance with RFC 952 and RFC 1123 and take the defined action (e.g. `warn`, `ignore`, `fail`).               |
| `bind_dns_keys`             | `[]`                 | A list of binding keys, which are mappings with keys `name:` `algorithm:` and `secret:`. See below for an example.                   |
| `bind_dns64`                | `false`              | If `true`, support for [DNS64](https://www.oreilly.com/library/view/dns-and-bind/9781449308025/ch04.html) is enabled                 |
| `bind_dns64_clients`        | `['any']`            | A list of clients which the DNS64 function applies to (can be any ACL)                                                               |
| `bind_dnssec_enable`        | `true`               | If `true`, DNSSEC is enabled                                                                                                         |
| `bind_dnssec_validation`    | `true`               | If `true`, DNSSEC validation is enabled                                                                                              |
| `bind_extra_include_files`  | `[]`                 | A list of custom config files to be included from the main config file                                                               |
| `bind_forward_only`         | `false`              | If `true`, BIND is set up as a caching name server                                                                                   |
| `bind_forwarders`           | `[]`                 | A list of name servers to forward DNS requests to.                                                                                   |
| `bind_listen_ipv4`          | `['127.0.0.1']`      | A list of the IPv4 address of the network interface(s) to listen on. Set to ['any'] to listen on all interfaces.                     |
| `bind_listen_ipv6`          | `['::1']`            | A list of the IPv6 address of the network interface(s) to listen on                                                                  |
| `bind_log`                  | `data/named.run`     | Path to the log file                                                                                                                 |
| `bind_other_logs`           | -                    | A list of logging channels to configure, with a separate mapping for each zone, with relevant details                                |
| `bind_query_log`            | -                    | A mapping with keyss `file:` (e.g. `data/query.log`), `versions:`, `size:`. When defined, this will enable the query log             |
| `bind_recursion`            | `false`              | Determines whether requests for which the DNS server is not authoritative should be forwarded†.                                      |
| `bind_rrset_order`          | `random`             | Defines order for DNS round robin (either `random` or `cyclic`)                                                                      |
| `bind_statistics_channels`  | `false`              | If `true`, BIND is configured with a `statistics-channels` clause (currently only supports listening on a single interface)          |
| `bind_statistics_allow`     | `['127.0.0.1']`      | A list of hosts that can access the server statistics                                                                                |
| `bind_statistics_host`      | `127.0.0.1`          | IP address of the network interface that the statistics service should listen on                                                     |
| `bind_statistics_port`      | 8053                 | Network port that the statistics service should listen on                                                                            |
| `bind_transfer_key_name`    | -                    | The name of a TSIG key that should be used to sign XFR requests from the client                                                      |
| `bind_zone_dir`             | -                    | When defined, sets a custom absolute path to the server directory (for zone files, etc.) instead of the default.                     |
| `bind_zones`                | n/a                  | A list of mappings with zone definitions. See below this table for examples                                                          |
| `- allow_update`            | `['none']`           | A list of hosts that are allowed to dynamically update this DNS zone.                                                                |
| `- also_notify`             | -                    | A list of servers that will receive a notification when the primary zone file is reloaded.                                           |
| `- create_forward_zones`    | -                    | When initialized and set to `false`, creation of forward zones will be skipped (resulting in a reverse only zone)                    |
| `- create_reverse_zones`    | -                    | When initialized and set to `false`, creation of reverse zones will be skipped (resulting in a forward only zone)                    |
| `- delegate`                | `[]`                 | Zone delegation.                                                                                                                     |
| `- hostmaster_email`        | `hostmaster`         | The e-mail address of the system administrator for the zone                                                                          |
| `- hosts`                   | `[]`                 | Host definitions. Empty => secondary zone, nonempty => primary zone.                                                                 |
| `- ipv6_networks`           | `[]`                 | A list of the IPv6 networks that are part of the domain, in CIDR notation (e.g. 2001:db8::/48)                                       |
| `- mail_servers`            | `[]`                 | A list of mappings (with keys `name:` and `preference:`) specifying the mail servers for this domain.                                |
| `- name_servers`            | `[ansible_hostname]` | A list of the DNS servers for this domain.                                                                                           |
| `- name`                    | `example.com`        | The domain name                                                                                                                      |
| `- naptr`                   | `[]`                 | A list of mappings with keys `name:`, `order:`, `pref:`, `flags:`, `service:`, `regex:` and `replacement:` specifying NAPTR records. |
| `- networks`                | `['10.0.2']`         | A list of the networks that are part of the domain                                                                                   |
| `- other_name_servers`      | `[]`                 | A list of the DNS servers outside of this domain.                                                                                    |
| `- primaries`               | -                    | A list of primary DNS servers for this zone.                                                                                         |
| `- services`                | `[]`                 | A list of services to be advertised by SRV records                                                                                   |
| `- text`                    | `[]`                 | A list of mappings with keys `name:` and `text:`, specifying TXT records. `text:` can be a list or string.                           |
| `bind_zone_file_mode`       | 0640                 | The file permissions for the main config file (named.conf)                                                                           |
| `bind_zone_minimum_ttl`     | `1D`                 | Minimum TTL field in the SOA record.                                                                                                 |
| `bind_zone_time_to_expire`  | `1W`                 | Time to expire field in the SOA record.                                                                                              |
| `bind_zone_time_to_refresh` | `1D`                 | Time to refresh field in the SOA record.                                                                                             |
| `bind_zone_time_to_retry`   | `1H`                 | Time to retry field in the SOA record.                                                                                               |
| `bind_zone_ttl`             | `1W`                 | Time to Live field in the SOA record.                                                                                                |

† Best practice for an authoritative name server is to leave recursion turned off. However, [for some cases](http://www.zytrax.com/books/dns/ch7/queries.html#allow-query-cache) it may be necessary to have recursion turned on.

### Minimal variables for a working zone

In order to set up an authoritative name server that is available to clients, you should at least define the following variables:

| Variable           | Primary | Secondary |
|:-------------------|:-------:|:---------:|
| `bind_allow_query` |    V    |     V     |
| `bind_listen_ipv4` |    V    |     V     |
| `bind_zones`       |    V    |     V     |
| `- hosts`          |    V    |    --     |
| `- name_servers`   |    V    |    --     |
| `- name`           |    V    |     V     |
| `- networks`       |    V    |     V     |
| `- primaries`      |    V    |     V     |

### Domain definitions

```Yaml
bind_zones:
  # Example of a primary zone (hosts: and name_servers: ares defined)
  - name: mydomain.com           # Domain name
    create_reverse_zones: false  # Skip creation of reverse zones
    primaries:
      - 192.0.2.1                # Primary server(s) for this zone
    name_servers:
      - pub01.mydomain.com.
      - pub02.mydomain.com.
    hosts:
      - name: pub01
        ip: 192.0.2.1
        ipv6: 2001:db8::1
        aliases:
          - ns1
      - name: pub02
        ip: 192.0.2.2
        ipv6: 2001:db8::2
        aliases:
          - ns2
      - name: '@'                # Enables "http://mydomain.com/"
        ip:
          - 192.0.2.3            # Multiple IP addresses for a single host
          - 192.0.2.4            #   results in DNS round robin
        sshfp:                   # Secure shell fingerprint
          - "3 1 1262006f9a45bb36b1aa14f45f354b694b77d7c3"
          - "3 2 e5921564252fe10d2dbafeb243733ed8b1d165b8fa6d5a0e29198e5793f0623b"
        ipv6:
          - 2001:db8::2
          - 2001:db8::3
        aliases:
          - www
      - name: priv01             # This IP is in another subnet, will result in
        ip: 10.0.0.1             #   multiple reverse zones
      - name: mydomain.net.
        aliases:
          - name: sub01
            type: DNAME          # Example of a DNAME alias record
    networks:
      - '192.0.2'
      - '10'
      - '172.16'
    delegate:
      - zone: foo
        dns: 192.0.2.1
    services:
      - name: _ldap._tcp
        weight: 100
        port: 88
        target: dc001
    naptr:                       # Name Authority Pointer record, used for IP
      - name: "sip"              #   telephony
        order: 100
        pref: 10
        flags: "S"
        service: "SIP+D2T"
        regex: "!^.*$!sip:customer-service@example.com!"
        replacement: "_sip._tcp.example.com."
  # Minimal example of a secondary zone (hosts: is not defined)
  - name: acme.com
    primaries:
      - 172.17.0.2
    networks:
      - "172.17"
```

### Hosts

Host names that this DNS server should resolve can be specified in `bind_zones.hosts` as a list of mappings with keys `name:`, `ip:`,  `aliases:` and `sshfp:`. Aliases can be CNAME (default) or DNAME records.

To allow to surf to `http://example.com/`, set the host name of your web server to `'@'` (must be quoted!). In BIND syntax, `@` indicates the domain name itself.

If you want to specify multiple IP addresses for a host, add entries to `bind_zones.hosts` with the same name (e.g. `priv01` in the code snippet). This results in multiple A/AAAA records for that host and allows [DNS round robin](http://www.zytrax.com/books/dns/ch9/rr.html), a simple load balancing technique. The order in which the IP addresses are returned can be configured with role variable `bind_rrset_order`.

### Networks

As you can see, not all hosts are in the same subnet. This role will generate suitable reverse lookup zones for each subnet. All subnets should be specified in `bind_zones.networks`, though, or the host will not get a PTR record for reverse lookup.

Remark that only the network part should be specified here! When specifying a class B IP address (e.g. "172.16") in a variable file, it must be quoted. Otherwise, the Yaml parser will interpret it as a float.

Based on the idea and examples detailed at <https://linuxmonk.ch/wordpress/index.php/2016/managing-dns-zones-with-ansible/> for the gdnsd package, the zone files are fully idempotent, and thus only get updated if "real" content changes.

### Zone delegation

To delegate a zone to a DNS server, it is sufficient to create a `NS` record (under delegate) which is the equivalent of:

```text
foo IN NS 192.0.2.1
```

### Service records

Service (SRV) records can be added with the services. This should be a list of mappings with mandatory keys `name:` (service name), `target:` (host providing the service), `port:` (TCP/UDP port of the service) and optional keys `priority:` (default = 0) and `weight:` (default = 0).

### ACLs

ACLs can be defined like this:

```Yaml
bind_acls:
  - name: acl1
    match_list:
      - 192.0.2.0/24
      - 10.0.0.0/8
```

The names of the ACLs will be added to the `allow-transfer` clause in global options.

### Binding Keys

Binding keys can be defined like this:

```Yaml
bind_dns_keys:
  - name: primary_key
    algorithm: hmac-sha256
    secret: "azertyAZERTY123456"
bind_extra_include_files:
  - "{{ bind_auth_file }}"
```

**tip**: Extra include file must be set as an ansible variable because file is OS dependant

This will be set in a file *"{{ bind_auth_file }}* (e.g. /etc/bind/auth_transfer.conf for Debian) which have to be added in the list variable **bind_extra_include_files**

### Using TSIG for zone transfer (XFR) authorization

**Warning:** this functionality is **broken** in v5.0.0

To authorize the transfer of zone between primary & secondary servers based on a TSIG key, set the name in the variable `bind_transfer_key_name`:

```Yaml
bind_transfer_key_name: primary_key
```

A check will be performed to ensure the key is actually present in the `bind_dns_keys` mapping. This will add a server statement for the `a` in `bind_auth_file` on a secondary server containing the specified key.

## Dependencies

No dependencies.

## Example Playbook

See the test playbook [converge.yml](molecule/default/converge.yml) and the accompanying `group_vars` file [all.yml](molecule/default/group_vars/all.yml) for an elaborate example that showcases most features.

## Testing

This role is tested using [Ansible Molecule](https://molecule.readthedocs.io/). Tests are launched automatically on [Github Actions](https://github.com/bertvv/ansible-role-bind/actions) after each commit and PR.

This Molecule configuration will:

- Run Yamllint and Ansible Lint
- Create two Docker containers, one primary (`ns1`) and one secondary (`ns2`) DNS server
- Run a syntax check
- Apply the role with a [test playbook](molecule/default/converge.yml) and check idempotence
- Run acceptance tests with [verify playbook](molecule/default/verify.yml)

This process is repeated for all the supported Linux distributions.

### Local test environment

In order to run the acceptance tests on this role locally, you can install the necessary tools on your machine, or use this reproducible setup in a VirtualBox VM (set up with Vagrant): <https://github.com/bertvv/ansible-testenv>.

Steps to install the tools manually:

1. Docker should be installed on your machine (assumed to run Linux). No Docker containers should be running when you start the test.
2. As recommended by Molecule, create a python virtual environment
3. Install the software tools `python3 -m pip install molecule docker netaddr dnspython yamllint ansible-lint`
4. Navigate to the root of the role directory and run `molecule test`

Molecule automatically deletes the containers after a test. If you would like to check out the containers yourself, run `molecule converge` followed by `molecule login --host HOSTNAME`.

The Docker containers are based on images created by [Jeff Geerling](https://hub.docker.com/u/geerlingguy), specifically for Ansible testing (look for images named `geerlingguy/docker-DISTRO-ansible`). You can use any of his images, but only the distributions mentioned in [meta/main.yml](meta/main.yml) are supported.

The default config will start two Centos 7 containers (the primary supported platform at this time). Choose another distro by setting the `MOLECULE_DISTRO` variable with the command, e.g.:

``` bash
MOLECULE_DISTRO=debian9 molecule test
```

or

``` bash
MOLECULE_DISTRO=debian9 molecule converge
```

You can run the acceptance tests on both servers with `molecule verify`.

## License

BSD

## Contributors

This role could only have been realized thanks to the contributions of many. If you have an idea to improve it even further, don't hesitate to pitch in!

Issues, feature requests, ideas, suggestions, etc. can be posted in the Issues section.

Pull requests are also very welcome. Please create a topic branch for your proposed changes. If you don't, this will create conflicts in your fork after the merge. Don't hesitate to add yourself to the contributor list below in your PR!

Maintainers:

- [Bert Van Vreckem](https://github.com/bertvv/)
- [Stuart Knight](https://github.com/blofeldthefish)

Contributors:

- [Aido](https://github.com/aido)
- [Angel Barrera](https://github.com/angelbarrera92)
- [B. Verschueren](https://github.com/bverschueren)
- [Boris Momčilović](https://github.com/kornrunner)
- [Brad Durrow](https://github.com/bdurrow)
- [Christopher Hicks](http://www.chicks.net/)
- [David J. Haines](https://github.com/dhaines)
- [Fabio Rocha](https://github.com/frock81)
- [Fazle Arefin](https://github.com/fazlearefin)
- [Greg Cockburn](https://github.com/gergnz)
- [Gregory Shulov](https://github.com/GR360RY)
- [Guillaume Darmont](https://github.com/gdarmont)
- [jadjay](https://github.com/jadjay)
- [Jascha Sticher](https://github.com/itbane)
- [Joanna Delaporte](https://github.com/jdelaporte)
- [Jörg Eichhorn](https://github.com/jeichhorn)
- [Jose Taas](https://github.com/josetaas)
- [Lennart Weller](https://github.com/lhw)
- [Loic Dachary](http://dachary.org)
- [Mario Ciccarelli](https://github.com/kartone)
- [Otto Sabart](https://github.com/seberm)
- [Paulius Mazeika](https://github.com/pauliusm)
- [Paulo E. Castro](https://github.com/pecastro)
- [Peter Janes](https://github.com/peterjanes)
- [psa](https://github.com/psa)
- [Rafael Bodill](https://github.com/rafi)
- [Rayford Johnson](https://github.com/rayfordj)
- [Robin Ophalvens](https://github.com/RobinOphalvens)
- [Romuald](https://github.com/rds13)
- [Tom Meinlschmidt](https://github.com/tmeinlschmidt)
- [Jascha Sticher](https://github.com/itbane)
