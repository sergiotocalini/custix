# Custix
Custom Zabbix Scripts

# Deploy
## Zabbix

    #~ git clone https://github.com/sergiotocalini/custix.git
    #~ ./custix/deploy_zabbix.sh
    #~

# Scripts
## os_updates
The script is checking if there are some updates to apply.
### Debian / Ubuntu
This script uses -s simulation option when invoking apt-get, no root access is needed.
However, root access is required for updating APT repositories and we can add the following options in apt.conf.d.

    #~ cat /etc/apt/apt.conf.d/02periodic
    APT::Periodic::Enable "1";
    APT::Periodic::Update-Package-Lists "1";
    #~
    
