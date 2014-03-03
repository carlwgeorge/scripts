#!/usr/bin/env python2

'''
This script will list all IPs for cloud servers on multiple accounts.

References:
https://github.com/rackspace/pyrax/blob/master/docs/getting_started.md
https://github.com/rackspace/pyrax/blob/master/docs/cloud_servers.md
http://code.google.com/p/prettytable/wiki/Tutorial
'''

import pyrax
import prettytable


def get_ipv4(ips):
    for ip in ips:
        if ip.get('version') == 4:
            return ip.get('addr')


def server_data(server):
    data = {}
    addresses = server.addresses
    private = get_ipv4(addresses.pop('private'))
    public = get_ipv4(addresses.pop('public'))
    if addresses:
        x, others = addresses.popitem()
        other = get_ipv4(others)
    else:
        other = None

    data['uuid'] = server.id
    data['name'] = server.name
    data['access'] = server.accessIPv4
    data['public'] = public
    data['private'] = private
    data['other'] = other
    data['rc'] = server.metadata.get('rackconnect_automation_status')
    return data


def create_table(username, apikey):
    pyrax.set_credentials(username, apikey)
    serverlist = pyrax.cloudservers.list()
    output = prettytable.PrettyTable(['UUID',
                                      'name',
                                      'accessIPv4',
                                      'public',
                                      'servicenet',
                                      'other',
                                      'RackConnect status'])
    for server in serverlist:
        data = server_data(server)
        output.add_row([data['uuid'],
                        data['name'],
                        data['access'],
                        data['public'],
                        data['private'],
                        data['other'],
                        data['rc']])
    output.align = 'l'
    output.sortby = 'name'
    return output


def main():
    pyrax.set_setting('identity_type', 'rackspace')
    # flavors = {
    # }

    # keys are ddis
    credentials = {
        111111: {'username': 'account1',
                 'apikey': 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'},
        222222: {'username': 'account2',
                 'apikey': 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'}
    }
    print('')
    for ddi in credentials:
        username = credentials.get(ddi).get('username')
        apikey = credentials.get(ddi).get('apikey')
        print('{}\t{}'.format(ddi, username))
        print(create_table(username, apikey))
        print('')


if __name__ == '__main__':
    main()

# vim: set syntax=python sw=4 ts=4 expandtab :
