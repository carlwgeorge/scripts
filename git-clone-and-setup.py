#!/usr/bin/env python

import re
import sys
import subprocess


class MyGithubSetup(object):
    ''' class to perform github setup '''
    def __init__(self, server, repo):
        self.server = server
        self.repo = repo
        if self.server == 'github.com':
            print('detected public github')
            print('setting up user cgtx')
            self.__git_config('user.name', 'cgtx')
            self.__git_config('user.email', 'carl@carlgeorge.us')
        elif self.server == 'github.rackspace.com':
            print('detected Rackspace internal github')
            print('setting up user carl.george')
            self.__git_config('user.name', 'carl.george')
            self.__git_config('user.email', 'carl.george@rackspace.com')
        else:
            sys.exit('invalid github server specified')
        self.__git_config('push.default', 'simple')

    def __git_config(self, setting, value):
        cmd = ['git', 'config', setting, value]
        # subprocess.call(cmd, cwd=)
        print('changing directory to {}'.format(self.repo))
        print(cmd)


def main():
    if len(sys.argv) == 2:
        clone = sys.argv[1]
        # git@${SERVER}:${AUTHOR}/${REPO}.git
        pattern = r'^git@([^:]+):.+/([^.]+).git'
        match = re.match(pattern, clone)
        try:
            server = match.group(1)
            repo = match.group(2)
        except AttributeError:
            sys.exit('unable to parse git clone string')
        else:
            MyGithubSetup(server, repo)
    else:
        sys.exit('please provide me a valid git clone string')


if __name__ == '__main__':
    main()

# vim: set syntax=python sw=4 ts=4 expandtab :
