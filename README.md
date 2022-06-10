VitalPBX High Availability for Call Center
=====
## This is a proof of concept. If you implement it, it is at your own risk.<br>
## VitalPBX Teams does not support this type of implementation.<br>
High availability is a characteristic of a system which aims to ensure an agreed level of operational performance, usually uptime, for a higher than normal period.<br>

Make a high-availability cluster out of any pair of VitalPBX servers. VitalPBX can detect a range of failures on one VitalPBX server and automatically transfer control to the other server, resulting in a telephony environment with minimal down time.<br>

<strong>Important note:</strong><br>
Since DRBD is no longer used in version 3, it is not possible to migrate a High Availability VitalPBX from Version 2 to 3.<br>
The VitalPBX team does not provide support for systems in an HA environment because it is not possible to determine the environment where it has been installed.

## Example:<br>
![VitalPBX HA](https://github.com/VitalPBX/vitalpbx_ha_call_center/blob/master/HACallCenter3Servers.png)

-----------------
## Prerequisites
In order to install VitalPBX in high availability you need the following:<br>
a.- 4 IP addresses.<br>
b.- Install VitalPBX Version 3.0 in the three servers with similar characteristics.<br>
c.- MariaDB Galera (include in VitalPBX 3).<br>
d.- Corosync, Pacemaker, PCS and lsyncd.

## Configurations
We will configure in each server the IP address and the host name. Go to the web interface to: <strong>Admin>System Settinngs>Network Settings</strong>.<br>
First change the Hostname, remember press the <strong>Check</strong> button.<br>
Disable the DHCP option and set these values<br>

| Name          | Master                 | Standby               | App                   |
| ------------- | ---------------------- | --------------------- | --------------------- |
| Hostname      | vitalpbx1.local        | vitalpbx2.local       | vitalpbx3.local       |
| IP Address    | 192.168.10.61          | 192.168.10.62         | 192.168.10.63         |
| Netmask       | 255.255.255.0          | 255.255.255.0         | 255.255.255.0         |
| Gateway       | 192.168.10.1           | 192.168.10.1          | 192.168.10.1          |
| Primary DNS   | 8.8.8.8                | 8.8.8.8               | 8.8.8.8               |
| Secondary DNS | 8.8.4.4                | 8.8.4.4               | 8.8.4.4               |

## Install Dependencies
Install the necessary dependencies in Server 1 and 2<br>
<pre>
[root@vitalpbx1 ~]# yum -y install corosync pacemaker pcs lsyncd vitalpbx-high-availability
[root@vitalpbx2 ~]# yum -y install corosync pacemaker pcs lsyncd vitalpbx-high-availability
</pre>

## Create authorization key
Create authorization key for the Access between the Server 1 and 2 without credentials. And create authorization key for access from Server 1 and 2 to Server 3.<br>
Create key in Server <strong>1</strong> to access Server <strong>2</strong> and <strong>3</strong>
<pre>
[root@vitalpbx<strong>1</strong> ~]# ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' >/dev/null
[root@vitalpbx<strong>1</strong> ~]# ssh-copy-id root@<strong>192.168.10.62</strong>
Are you sure you want to continue connecting (yes/no)? <strong>yes</strong>
root@192.168.10.62's password: <strong>(remote server root’s password)</strong>

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.10.62'"
and check to make sure that only the key(s) you wanted were added. 

[root@vitalpbx<strong>1</strong> ~]#
</pre>

<pre>
[root@vitalpbx<strong>1</strong> ~]# ssh-copy-id root@<strong>192.168.10.63</strong>
Are you sure you want to continue connecting (yes/no)? <strong>yes</strong>
root@192.168.10.63's password: <strong>(remote server root’s password)</strong>

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.10.63'"
and check to make sure that only the key(s) you wanted were added. 

[root@vitalpbx<strong>1</strong> ~]#
</pre>


Create key in Server <strong>2</strong> to access Server <strong></strong> and <strong>3</strong>
<pre>
[root@vitalpbx<strong>2</strong> ~]# ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' >/dev/null
[root@vitalpbx<strong>2</strong> ~]# ssh-copy-id root@<strong>192.168.10.61</strong>
Are you sure you want to continue connecting (yes/no)? <strong>yes</strong>
root@192.168.10.61's password: <strong>(remote server root’s password)</strong>

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.10.61'"
and check to make sure that only the key(s) you wanted were added. 

[root@vitalpbx<strong>2</strong> ~]#
</pre>

<pre>
[root@vitalpbx<strong>2</strong> ~]# ssh-copy-id root@<strong>192.168.10.63</strong>
Are you sure you want to continue connecting (yes/no)? <strong>yes</strong>
root@192.168.10.63's password: <strong>(remote server root’s password)</strong>

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.10.63'"
and check to make sure that only the key(s) you wanted were added. 

[root@vitalpbx<strong>2</strong> ~]#
</pre>

## Script
Now copy and run the following script<br>
<pre>
[root@ vitalpbx<strong>1</strong> ~]# mkdir /usr/share/vitalpbx/ha
[root@ vitalpbx<strong>1</strong> ~]# cd /usr/share/vitalpbx/ha
[root@ vitalpbx<strong>1</strong> ~]# wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha_call_center/master/vpbxgaha.sh
[root@ vitalpbx<strong>1</strong> ~]# chmod +x vpbxgaha.sh
[root@ vitalpbx<strong>1</strong> ~]# ./vpbxgaha.sh

************************************************************
*  Welcome to the VitalPBX high availability installation  *
*                All options are mandatory                 *
************************************************************
IP Master................ > <strong>192.168.10.61</strong>
IP Standby............... > <strong>192.168.10.62</strong>
IP Application........... > <strong>192.168.10.63</strong>
Floating IP.............. > <strong>192.168.10.60</strong>
Floating IP Mask (SIDR).. > <strong>24</strong>
hacluster password....... > <strong>MyPassword (any password)</strong>
************************************************************
*                   Check Information                      *
*        Make sure you have internet on both servers       *
************************************************************
Are you sure to continue with this settings? (yes,no) > <strong>yes</strong>
</pre>

At the end of the installation you have to see the following message

<pre>
************************************************************
*                VitalPBX Cluster OK                       *
*    Don't worry if you still see the status in Stop       *
*  sometimes you have to wait about 30 seconds for it to   *
*                 restart completely                       *
*         after 30 seconds run the command: role           *
************************************************************

 _    _ _           _ ______ ______ _    _
| |  | (_)_        | (_____ (____  \ \  / /
| |  | |_| |_  ____| |_____) )___)  ) \/ /
 \ \/ /| |  _)/ _  | |  ____/  __  ( )  (
  \  / | | |_( ( | | | |    | |__)  ) /\ \
   \/  |_|\___)_||_|_|_|    |______/_/  \_\


 Role           : Master
 Version        : 3.0.1-1
 Asterisk       : 17.6.0
 Linux Version  : CentOS Linux release 7.8.2003 (Core)
 Welcome to     : vitalpbx1.local
 Uptime         :  1:30
 Load           : Last Minute: 0.74, Last 5 Minutes: 0.30, Last 15 Minutes: 0.16
 Users          : 4 users
 IP Address     : 192.168.10.61 192.168.10.60
 Clock          : Wed 2020-08-05 09:04:19 EDT
 NTP Sync.      : no


************************************************************
*                  Servers Status                          *
************************************************************
Master
 virtual_ip     (ocf::heartbeat:IPaddr2):       Started vitalpbx1.local
 asterisk       (service:asterisk):     Started vitalpbx1.local
 lsyncd (service:lsyncd.service):       Started vitalpbx1.local

Servers Status
  vitalpbx1.local: Online
  vitalpbx2.local: Online
</pre>

## Installing Sonata Switchboard in Server 3
Now we are going to connect to Server 3 to install Sonata Switchboard, for which we are going to Admin/Add-Ons/Add-Ons.

In Server 1 we are going to create an Api Key through which Sonata Switchboard will be connected, for which we are going to Admin/Admin/Application Keys. We create the API Key that works in all Tenants and then we edit it to copy the value.

In the Server 3 console we are going to execute the following command to update the connection values of Sonata Switchboard.:

<pre>
[root@ vitalpbx<strong>3</strong> ~]# mysql -uroot astboard -e "UPDATE pbx SET host='192.168.10.60', remote_host='yes', api_key='babf43dbf6b8298f46e3e7381345afbf'"
[root@ vitalpbx<strong>3</strong> ~]# sed -i -r 's/localhost/192.168.10.60/' /usr/share/sonata/switchboard/monitor/config.ini
[root@ vitalpbx<strong>3</strong> ~]# systemctl restart switchboard
</pre>
Remember to change the Api Key for the value copied in the previous step.

Notes:
•	The Sonata Switchboard license must be installed on the Master Server. This is because Sonata Switchboard connects directly to the Master Server via API and it needs to display the information in real time.
•	You can install Sonata Recording, Sonata Billing, and Sonata Stats on the application server. In this case the license must be on the application server. No additional configuration is necessary.

## Change Servers Role

To execute the process of changing the role, we recommend using the following command:<br>

<pre>
[root@vitalpbx-master /]# bascul
************************************************************
*     Change the roles of servers in high availability     *
* <strong>WARNING-WARNING-WARNING-WARNING-WARNING-WARNING-WARNING</strong>  *
*All calls in progress will be lost and the system will be *
*     be in an unavailable state for a few seconds.        *
************************************************************
Are you sure to switch from vitalpbx<strong>1</strong>.local to vitalpbx<strong>2</strong>.local? (yes,no) >
</pre>

This action convert the vitalpbx<strong>1</strong>.local to Standby and vitalpbx<strong>2</strong>.local to Master. If you want to return to default do the same again.<br>

Next we will show a short video how high availability works in VitalPBX<br>
<div align="center">
  <a href="https://www.youtube.com/watch?v=3yoa3KXKMy0"><img src="https://img.youtube.com/vi/3yoa3KXKMy0/0.jpg" alt="High Availability demo video on VitalPBX"></a>
</div>

## Recommendations
If you have to turn off both servers at the same time, we recommend that you start by turning off the one in Standby and then the Master<br>
If the two servers stopped abruptly, always start first that you think you have the most up-to-date information and a few minutes later the other server<br>
If you want to update the version of VitalPBX we recommend you do it first on Server 1, then do a bascul and do it again on Server 2<br>

## Dahdi with Xorcom HA Hardware
If you are going to install Dhadi with Xorcom HA Hardware we recommend you to execute the following commands in the Server <strong>1</strong>

<pre>
[root@vitalpbx1 ~]# systemctl stop dahdi
[root@vitalpbx1 ~]# systemctl disable dahdi
[root@vitalpbx1 ~]# pcs resource create dahdi service:dahdi op monitor interval=30s
[root@vitalpbx1 ~]# pcs cluster cib fs_cfg
[root@vitalpbx1 ~]# pcs cluster cib-push fs_cfg --config
[root@vitalpbx1 ~]# pcs -f fs_cfg constraint colocation add dahdi with virtual_ip INFINITY
[root@vitalpbx1 ~]# pcs -f fs_cfg constraint order lsyncd then dahdi
[root@vitalpbx1 ~]# pcs cluster cib-push fs_cfg --config
</pre>

and in the Server <strong>2</strong>

<pre>
[root@vitalpbx2 ~]# systemctl stop dahdi
[root@vitalpbx2 ~]# systemctl disable dahdi
</pre>

## Update VitalPBX version

To update VitalPBX to the latest version just follow the following steps:<br>
1.- From your browser, go to ip 192.168.10.60<br>
2.- Update VitalPBX from the interface<br>
3.- Execute the following command in Master console<br>
<pre>
[root@vitalpbx1 /]# bascul
</pre>
4.- From your browser, go to ip 192.168.10.60 again<br>
5.- Update VitalPBX from the interface<br>
6.- Execute the following command in Master console<br>
<pre>
[root@vitalpbx1 /]# bascul
</pre>

## Some useful commands
• <strong>bascul</strong>, is used to change roles between high availability servers. If all is well, a confirmation question should appear if we wish to execute the action.<br>
• <strong>role</strong>, shows the status of the current server. If all is well you should return Masters or Slaves.<br>
• <strong>pcs resource refresh --full</strong>, to poll all resources even if the status is unknown, enter the following command.<br>
• <strong>pcs cluster unstandby host</strong>, in some cases the bascul command does not finish tilting, which causes one of the servers to be in standby (stop), with this command the state is restored to normal.<br>

## More Information
If you want more information that will help you solve problems about High Availability in VitalPBX we invite you to see the following manual<br>
[High Availability Manual, step by step](https://github.com/VitalPBX/vitalpbx_ha_call_center/raw/master/VitalPBX3.0HighAvailabilityCallCentersSetup.pdf)

<strong>CONGRATULATIONS</strong>, you have installed and tested the high availability in <strong>VitalPBX 3</strong><br>
:+1:
