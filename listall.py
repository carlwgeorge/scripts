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


def create_table(username, apikey):
    pyrax.set_credentials(username, apikey)
    serverlist = pyrax.cloudservers.list()
    output = prettytable.PrettyTable(['UUID',
                                      'NAME',
                                      'PUBLIC IP',
                                      'PRIVATE IP',
                                      'RACKCONNECT STATUS'])
    for server in serverlist:
        output.add_row([server.id,
                        server.name,
                        server.accessIPv4,
                        server.addresses.get('private')[0].get('addr'),
                        server.metadata.get('rackconnect_automation_status')])
    output.align = 'l'
    output.sortby = 'NAME'
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
