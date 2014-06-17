#!/usr/bin/env python2

'''
This script will list all IPs for cloud servers on multiple accounts.

References:
https://github.com/rackspace/pyrax/blob/master/docs/getting_started.md
https://github.com/rackspace/pyrax/blob/master/docs/cloud_servers.md
https://github.com/rackspace/pyrax/blob/master/docs/cloud_networks.md
http://code.google.com/p/prettytable/wiki/Tutorial
'''

import pyrax
import prettytable


def get_ipv4(ips):
    for ip in ips:
        if ip.get('version') == 4:
            return ip.get('addr')


def server_data(server, network_list, flavor_dict):
    # start building our row data
    row = []
    row.append(server.id)
    row.append(server.name)
    row.append(server.metadata.get('rackconnect_automation_status'))
    row.append(flavor_dict.get(server.flavor.get('id')))
    row.append(server.accessIPv4)

    # get network data
    addresses = server.addresses
    for network in network_list:
        ips = addresses.get(network)
        if ips:
            ip = get_ipv4(ips)
        else:
            ip = None
        row.append(ip)
    return row


def create_table(username, apikey):
    pyrax.set_credentials(username, apikey)
    raw_server_list = pyrax.cloudservers.list()
    raw_network_list = pyrax.cloud_networks.list()
    raw_flavor_list = pyrax.cloudservers.flavors.list()
    flavor_dict = {}
    for flavor in raw_flavor_list:
        flavor_dict[flavor.id] = flavor.name

    headers = ['UUID',
               'name',
               'RackConnect status',
               'flavor',
               'accessIPv4']
    network_list = []
    for each in raw_network_list:
        network_list.append(each.label)
    headers += network_list
    output = prettytable.PrettyTable(headers)
    for server in raw_server_list:
        row = server_data(server, network_list, flavor_dict)
        output.add_row(row)
    output.align = 'l'
    output.sortby = 'name'
    return output


def main():
    pyrax.set_setting('identity_type', 'rackspace')

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
