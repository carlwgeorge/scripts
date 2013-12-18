# supersandbox

Bootstrap a complete supernova environment using virtualenv.

## Installation

```
curl -s https://raw.github.com/cgtx/scripts/master/supersandbox/supersandbox > /usr/local/bin/supersandbox
chmod +x /usr/local/bin/supersandbox
```

## Usage

    $ supersandbox 
    usage:		supersandbox subcommand
    
    description:	Bootstrap a complete supernova environment using virtualenv.
    
    subcommands:	install 	install the environment and wrapper scripts
        		upgrade  	upgrade the pip pacakges in the environment
        		remove   	remove the environment and wrapper scripts
        		template 	create configuration template file
        		status   	check the status of your installation
