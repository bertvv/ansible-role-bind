# Custom filters for handling IP addresses


def reverse_dotted_decimals(ipaddress):
    """Reverse the order of the decimals in the specified IP-address.
    E.g. "192.168.10" would become "10.168.192"

    Keyword arguments:
        ipaddress -- An IP address in dotted decimal notation
    """
    return '.'.join(ipaddress.split('.')[::-1])


def reverse_lookup_zone(ipaddress):
    """Return the notation for the reverse lookup zone for the specified
    network address.

    E.g. "192.0.2" would become "2.0.192.in-addr.arpa"

    Keyword arguments:
        ipaddress -- The network part of an IP address in dotted decimal
        notation
    """
    return reverse_dotted_decimals(ipaddress) + '.in-addr.arpa'


class FilterModule(object):
    ''' Ansible core jinja2 filters '''

    def filters(self):
        return {
            'reverse_dotted_decimals': reverse_dotted_decimals,
            'reverse_lookup_zone': reverse_lookup_zone,
        }
