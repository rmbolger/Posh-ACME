title: SSHProxy

# How to use the SSHProxy plugin

This plugin works by delegating the update via SSH to another server which is already able to do dynamic updates against your chosen DNS provider(s). It is designed to use SSH keypairs rather than relying on negiotiating username/password authentication so as to allow the SSH server administrator greater control over what can be run on behalf of Posh-ACME.

## Setup

### Plugin dependencies

You will need (Open)SSH client software installed on your Posh-ACME client. On Linux and MacOS, this comes pre-installed. For Windows, the OpenSSH client can be downloaded from Microsoft (https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=gui) or the upstream version from https://github.com/PowerShell/Win32-OpenSSH. Note that PuTTY isn't sufficient, though plink.exe (from the PuTTY suite) would work.

You will also need an SSH server where you can install your Posh-ACME public key and run your update script from.

### Posh-ACME Client SSH setup

To allow the Posh-ACME client to connect to your chosen SSH server, you will need to generate an SSH keypair and ensure this on both the Posh-ACME client and the server. The current best-practice recommends *ed_25519* keys. To generate these, run the following on your Posh-ACME client device.

```bash
ssh-keygen -q -N '' -t ed25519 -f $HOME/poshacme
```

This will create two files in your home directory

* poshacme - your private key
* poshacme.pub - your public key

You will need to reference the first in your Posh-ACME SSHProxy configuration and use the contents of second on the SSH server.

(thoughout this document, i'll be using $HOME/poshacme - you can replace this with a filename of your choosing).

### SSH (proxy) server setup

On the SSH server, for the account chosen to proxy your Posh-ACME DNS updates, edit the users' *$HOME/.ssh/authorized_keys* file and add (all one line) 

```
from="1.2.3.4",restrict,command="/usr/local/bin/dnsupdate" <contents of generated poshacme.pub file>
```

replacing *1.2.3.4* with the IP address of the Posh-ACME device and */usr/local/bin/dnsupdate* with the name of the script that will run your DDNS update and append the contents of the *poshacme.pub* file generated earlier by *ssh-keygen*.

Whilst it is beyond the scope of this guide to explain how to configure the actual DDNS update that will be undertaken on your behalf by the SSH server, The following example using *nsupdate* should suffice.

Example /usr/local/bin/dnsupdate command

```bash
#!/bin/bash

# grab args given to when connecting
set -- $SSH_ORIGINAL_COMMAND

# belt and braces validatation
if [ "$#" -ne 3 ]; then
	echo "usage: $0 [add|delete] _acme-challenge.some.name token"
	exit 1
fi

if [ "$1" = "add" ]; then
	:
elif [ "$1" = "delete" ]; then
	:
else
	echo "usage: $0 [add|delete] _acme-challenge.some.name token"
fi

# in particular, we want $2 to start _acme-challenge - we could do more
# fancy validation if wanted.

if ! [[ "$2" =~ ^_acme-challenge.* ]]; then
	echo "usage: $0 [add|delete] _acme-challenge.some.name token"
	exit 1
fi

# do the update
printf "update $1 $2. 60 TXT $3\nsend\n" | nsupdate -y all:myupdatekey
```

It should also be noted that this isn't restricted to SSH connections to a Linux server. This will work against any OpenSSH server running on Linux, Windows or Mac.

## Using the Plugin

For most, using the following should suffice:

```powershell
$pArgs=@{
    SSHServer = "ssh.example.com"
    SSHUser = "nsupdate" 
    SSHIdentityFile = "$HOME/poshacme"
}
Publish-Challenge example.com -Plugin SSHProxy -PluginArgs $pArgs
```

Additionally, you can specify `SSHConfigFile` if you need specify an alternative to the default ssh configuration file. You'll know if you need to do this as you will be doing other fancy SSH things from your Posh-ACME client! Similarly, you can specify `SSHRemoteCommand` if your SSH server config isn't using a forced command - this is considerably less secure...