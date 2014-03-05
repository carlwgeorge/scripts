#!/usr/bin/env python

import os
import re
import sys
import json
import requests

try:
    import configparser
except ImportError:
    import ConfigParser as configparser


def write(msg):
    sys.stdout.write(msg)
    sys.stdout.flush()


def parse_config():
    # parse the config file
    config = configparser.ConfigParser()
    try:
        import xdg.BaseDirectory as basedir
    except ImportError:
        config_file = [os.path.expanduser("~/.config/rax.cfg")]
    else:
        config_file = [basedir.xdg_config_home + "/rax.cfg"]
    config.read(config_file)

    info = {'username': '',
            'apikey': '',
            'ddi': '',
            'region': ''}
    try:
        # check if this section exists
        config.options('main')
    except configparser.NoSectionError:
        # the file is missing or there is no main section
        sys.exit('missing or malformed configuration file')
    else:
        # loop through each config option
        for each in config.options('main'):
            # test if the config option is a valid key
            if each in info.keys():
                value = config.get('main', each)
                info[each] = value
            else:
                # the option is bogus
                sys.exit('{0}: invalid option'.format(each))
    # return our info dictionary

    # TODO: what if there options are missing from the config file?
    return info


def get_token(info):
    payload = {
        'auth': {
            'RAX-KSKEY:apiKeyCredentials': {
                'username': info['username'],
                'apiKey': info['apikey']
            }
        }
    }
    header = {
        'Content-Type': 'application/json'
    }
    url = 'https://identity.api.rackspacecloud.com/v2.0/tokens'
    r = requests.post(url,
                      data=json.dumps(payload),
                      headers=header)
    token = r.json()['access']['token']['id']
    return token


def get_metadata(info, token, server_id):
    url = 'https://{DC}.{BASE}/{DDI}/servers/{ID}/metadata'.format(
        DC=info['region'],
        BASE='servers.api.rackspacecloud.com/v2',
        DDI=info['ddi'],
        ID=server_id)
    header = {
        'Content-Type': 'application/json',
        'X-Auth-Token': token
    }
    r = requests.get(url, headers=header)
    metadata = r.json()['metadata']
    return metadata


def get_rc_status(metadata):
    data = metadata.get('rackconnect_automation_status', 'N/A')
    if data == 'DEPLOYED':
        return 'COMPLETE'
    else:
        return data


def get_mc_status(metadata):
    data = metadata.get('rax_service_level_automation', 'N/A')
    if data == 'Complete':
        return 'COMPLETE'
    else:
        return data


def validate_uuid(uuid):
    p = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z'
    if re.match(p, uuid):
        return True
    else:
        return False


def main():
    if len(sys.argv) > 1:
        server_id = sys.argv[1]
    else:
        write('Server id? ')
        server_id = sys.stdin.readline().rstrip('\n')
    if not validate_uuid(server_id):
        sys.exit('Invalid server id.')

    # basic info dict
    info = parse_config()

    # get a token
    token = get_token(info)

    # get the status
    metadata = get_metadata(info, token, server_id)
    rc = get_rc_status(metadata)
    mc = get_mc_status(metadata)

    write('RackConnect:\t{RC}\nServermill:\t{MC}\n'.format(RC=rc, MC=mc))

if __name__ == '__main__':
    main()

# vim: set syntax=python sw=4 ts=4 expandtab :
