#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Author: Pavel Zinchuk


from inspect import getmembers
from pprint import pprint
from ansible.module_utils.basic import AnsibleModule
DOCUMENTATION = '''
---
module: bind_cat_zones
short_description: Bind Zone Catalogs update
description:
   - Create add new zone to the Zone Catalog
   - Delete add new zone to the Zone Catalog
version_added: "0.1"
author:
    - "Pavel Zinchuk"
    - "With some code examples from ISC - https://kb.isc.org/docs/aa-01401"
requirements:
    - "python >= 3.5"
    - "bind >= 9.10.1"
options:
    state:
        description:
            - Create or delete zone from Bind Catalog Zones
        required: false
        default: "present"
        choices: [ "present", "absent" ]
    zone_name:
        description:
            - name of zone to create or delete.
        required: true
    catzone_name:
        description:
            - name of the catalog zone in which the new zone will be created.
        required: true
    zone_path:
        description:
            - path to the directory with zone file.
        required: true
    bind_dns_keys:
        description:
            - list of Bind keys, which configured for Bind service. Keys by default stored in the varisble bind_dns_keys.
        required: true
    bind_controls_list:
        description:
            - list of Bind controls, configured for Bind service. Controls list by default stored in the varisble bind_controls.
        required: true
    bind_controls_name:
        description:
            - name of Bind controls endpoint, that will be used to manage Bind zones via rndc commans. Controls list by default stored in the varisble bind_controls.
        required: true
'''

EXAMPLES = '''
# Add zone
- name: Add zone to the Catalog Zones
  bind_cat_zones:
    bind_controls_list: "{{ bind_controls }}"
    bind_controls_name: "{{ item.bind_controls_name }}"
    bind_dns_keys: "{{ bind_dns_keys }}"
    zone_name: "{{ item.name }}"
    catzone_name:  "{{ item.catalog_zone }}"
    zone_path: "{{ bind_zone_dir }}/"
  with_items:
    - "{{ bind_zone_domains | selectattr('catalog_zone', 'defined')|list }}"

# Delete zone
- name: Delete zone to the Catalog Zones
  bind_cat_zones:
    bind_controls_list: "{{ bind_controls }}"
    bind_controls_name: "{{ item.bind_controls_name }}"
    bind_dns_keys: "{{ bind_dns_keys }}"
    zone_name: "{{ item.name }}"
    catzone_name:  "{{ item.catalog_zone }}"
    zone_path: "{{ bind_zone_dir }}/"
    state: absent
  with_items:
    - "{{ bind_zone_domains | selectattr('catalog_zone', 'defined')|list }}"
'''

try:
    import sys
    import os
    import isc
    import dns.query
    import dns.update
    import dns.name
    import dns.zone
    import hashlib

    HAS_DNS_LIBS = True
except ImportError:
    HAS_DNS_LIBS = False


class bindCatZones(object):
    def __init__(self, module, rndc, dnsupdate, hash):
        self._module = module
        self._rndc = rndc
        self._nsupdate = dnsupdate
        self._dns_zone_hash = hash

    def is_catalogzone_exists(self, **params):
        try:
            zone = dns.zone.from_xfr(dns.query.xfr(
                params['nameserver'], params['catzone_name'], lifetime=params['timeout']))
            for (_, _, _) in zone.iterate_rdatas("SOA"):
                return None
                # if rdata.to_text() == ('%s%s' % (params['zone_name'], '.')):
                #     return params['zone_name']
        except:
            self._module.exit_json(
                changed=False, result='Catalog zone - Add skipped. Catalog Zones %s is not yet configured.' % params['catzone_name'])

    def domain_exists_in_bind_cache(self, **params):
        try:
            zone = dns.zone.from_xfr(dns.query.xfr(
                params['nameserver'], params['zone_name'], lifetime=params['timeout']))
            for (name, _, _) in zone.iterate_rdatas("SOA"):
                if name.to_text() == ('%s%s' % (params['zone_name'], '.')) or name.to_text() == '@':
                    return params['zone_name']
        except:
            return None

    def domain_exists_in_catalogzone(self, **params):
        try:
            zone = dns.zone.from_xfr(dns.query.xfr(
                params['nameserver'], params['catzone_name'], lifetime=params['timeout']))
            for (_, _, rdata) in zone.iterate_rdatas("PTR"):
                if rdata.to_text() == ('%s%s' % (params['zone_name'], '.')):
                    return params['zone_name']
        except:
            return None

    def create(self, **params):
        changed = False
        self.is_catalogzone_exists(**params)

        # Add zone dynamically with 'rndc addzone'
        domain_in_cache = self.domain_exists_in_bind_cache(**params)
        if domain_in_cache is None:
            # Add zone to master using RNDC
            response = self._rndc.call(
                'addzone %s {type master; file "%s%s";};' % (params['zone_name'], params['zone_path'], '%s%s' % (params['zone_name'], params['zone_extention'])))
            if response['result'].decode('utf-8') != '0':
                self._module.fail_json(msg="Error adding zone %s to add zone to Bind: %s" %
                                       (params['zone_path'], response['err']))
            changed = True

        # Update Catalog Zone to add PTR with new zone
        domain_in_catalog = self.domain_exists_in_catalogzone(**params)
        if domain_in_catalog is None:
            
            # Update catalog zone
            self._nsupdate.add('%s.zones' % self._dns_zone_hash, 3600,
                               'ptr', '%s.' % params['zone_name'])
            response = dns.query.tcp(
                self._nsupdate, params['nameserver'], port=params['dns_port'])
            if response.rcode() != 0:
                self._module.fail_json(msg="Error updating catalog zone: %d" %
                                       response.rcode())
            changed = True

        if changed == False:
            self._module.exit_json(
                changed=False, result='Catalog zone - Add skipped. Domain zone %s already exists in the catalog zone: %s.' % (params['zone_name'], params['catzone_name']))
        else:
            self._module.exit_json(
                changed=True, result='Domain zone %s added to the catalog zones %s successfully' % (params['zone_name'], params['catzone_name']))

    def delete(self, **params):
        changed = False

        # Delete from Catalog Zone
        domain_in_catalog = self.domain_exists_in_catalogzone(**params)
        if domain_in_catalog is not None:
            self._nsupdate.delete('%s.zones' % self._dns_zone_hash)
            response = dns.query.tcp(
                self._nsupdate, params['nameserver'], port=params['dns_port'])
            if response.rcode() != 0:
                self._module.fail_json(
                    msg="Error updating catalog zone: %d" % response.rcode())

            changed = True

        # Delete zone from master using RNDC
        domain_in_cache = self.domain_exists_in_bind_cache(**params)
        if domain_in_cache is not None:
            response = self._rndc.call('delzone %s' % params['zone_name'])
            if response['result'].decode('utf-8') != '0':
                self._module.fail_json(
                    msg="Error deleting zone from master: %s" % response['err'])

            changed = True

        if changed == False:
            self._module.exit_json(
                changed=False, result='Catalog zone - Add skipped. Domain zone %s already exists in the catalog zone: %s.' % (params['zone_name'], params['catzone_name']))
        else:
            self._module.exit_json(
                changed=True, result='Domain zone %s added to the catalog zones %s successfully' % (params['zone_name'], params['catzone_name']))


def main():
    module = AnsibleModule(
        argument_spec=dict(
            bind_controls_list=dict(type='list', required=True),
            bind_controls_name=dict(type='str', required=True),
            # rndc_port=dict(type='int', default=953),
            # rndc_connect_key=dict(type='str', required=True),
            bind_dns_keys=dict(type='list', required=True),
            zone_name=dict(type='str', required=True),
            catzone_name=dict(type='str', required=True),
            dns_port=dict(type='int', required=False, default=53),
            zone_path=dict(type="str", required=True),
            zone_extention=dict(type='str', required=False, default=''),
            timeout=dict(type='int', required=False, default=15),
            state=dict(default="present", choices=['present', 'absent']),
        ),
        supports_check_mode=False
    )

    if not HAS_DNS_LIBS:
        module.fail_json(
            msg="Missing required bind module (check docs or install with: pip install python3-netaddr)")
    bind_controls_list = module.params['bind_controls_list']
    bind_controls_name = module.params['bind_controls_name']
    rndc_ip = list(filter(lambda x: x['name'] ==
                          bind_controls_name, bind_controls_list))[0]['inet']
    rndc_port = list(filter(lambda x: x['name'] ==
                            bind_controls_name, bind_controls_list))[0]['port']
    rndc_connect_key = list(filter(lambda x: x['name'] ==
                                   bind_controls_name, bind_controls_list))[0]['rndc_keys'][0]
    bind_dns_keys = module.params['bind_dns_keys']
    rndc_algo = list(filter(lambda x: x['name'] ==
                            rndc_connect_key, bind_dns_keys))[0]['algorithm']
    rndc_key = list(filter(lambda x: x['name'] ==
                           rndc_connect_key, bind_dns_keys))[0]['secret']
    zone_name = module.params['zone_name']
    catzone_name = module.params['catzone_name']
    state = module.params['state']

    catz_params = {}
    catz_params['nameserver'] = rndc_ip
    catz_params['zone_name'] = module.params['zone_name']
    catz_params['catzone_name'] = module.params['catzone_name']
    catz_params['dns_port'] = module.params['dns_port']
    catz_params['zone_path'] = module.params['zone_path']
    catz_params['zone_extention'] = module.params['zone_extention']
    catz_params['timeout'] = module.params['timeout']

    try:
        rndc = isc.rndc((rndc_ip, rndc_port), rndc_algo, rndc_key)
        dnsupdate = dns.update.Update(catzone_name)
        dns_zone_hash = hashlib.sha1(
            dns.name.from_text(zone_name).to_wire()).hexdigest()
        catzone = bindCatZones(module, rndc, dnsupdate, dns_zone_hash)
    except Exception as e:
        module.fail_json(
            msg="Failed to create catzone object with {exception}. Check that rndc port {rndc_port} available and check rndc connection parameters.".format(exception=e, rndc_port=rndc_port))

    if state == "absent":
        catzone.delete(**catz_params)
    else:
        catzone.create(**catz_params)

    # rather a WIP/debug-fallthrough:
    module.exit_json(
        changed=True, result="This module should not exit this way!")


if __name__ == '__main__':
    main()
