# Custix
Custom Zabbix Scripts

# Deploy
## Zabbix

    #~ git clone https://github.com/sergiotocalini/custix.git
    #~ ./custix/deploy_zabbix.sh
    #~

# Scripts
## os_updates
### Debian / Ubuntu
To make it works correctly you must to add these options on apt.conf.d

    #~ cat /etc/apt/apt.conf.d/02periodic
    APT::Periodic::Enable "1";
    APT::Periodic::Update-Package-Lists "1";
    #~
    
