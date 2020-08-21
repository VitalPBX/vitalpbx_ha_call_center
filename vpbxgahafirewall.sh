#!/bin/bash
# This code is the property of VitalPBX LLC Company
# License: Proprietary
# Date: 19-Aug-2020
# VitalPBX Hight Availability Update Firewall Rules
#
set -e
function jumpto
{
    label=$start
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

echo -e "\n"
echo -e "************************************************************"
echo -e "*  Welcome to the VitalPBX high availability installation  *"
echo -e "*      You need three server for this implementation       *"
echo -e "*                All options are mandatory                 *"
echo -e "************************************************************"

filename="config.txt"
if [ -f $filename ]; then
	echo -e "config file"
	n=1
	while read line; do
		case $n in
			1)
				ip_master=$line
  			;;
			2)
				ip_standby=$line
  			;;
			3)
				ip_app=$line
  			;;
		esac
		n=$((n+1))
	done < $filename
	echo -e "IP Master................ > $ip_master"	
	echo -e "IP Standby............... > $ip_standby"
	echo -e "IP Application........... > $ip_app"
fi

while [[ $ip_master == '' ]]
do
    read -p "IP Master................ > " ip_master 
done 

while [[ $ip_standby == '' ]]
do
    read -p "IP Standby............... > " ip_standby 
done 

while [[ $ip_app == '' ]]
do
    read -p "IP Application........... > " ip_app 
done 

echo -e "************************************************************"
echo -e "*                   Check Information                      *"
echo -e "*       Make sure you have internet on three servers       *"
echo -e "************************************************************"
while [[ $veryfy_info != yes && $veryfy_info != no ]]
do
    read -p "Are you sure to continue with this settings? (yes,no) > " veryfy_info 
done

if [ "$veryfy_info" = yes ] ;then
	echo -e "************************************************************"
	echo -e "*      Starting to run the scripts - Update Firewall       *"
	echo -e "************************************************************"
else
    	exit;
fi

stepFile=stepfirewall.txt
if [ -f $stepFile ]; then
	step=`cat $stepFile`
else
	step=0
fi

echo -e "Start in step: " $step

start="configuring_firewall"
case $step in
	1)
		start="configuring_firewall"
	;;
	2)
		start="create_ami_user"
	;;
	3)
		start="vitalpbx_cluster_ok"		
  	;;
esac
jumpto $start
echo -e "*** Done Step 1 ***"
echo -e "1"	> stepfirewall.txt

configuring_firewall:
echo -e "************************************************************"
echo -e "*             Configuring Temporal Firewall                *"
echo -e "************************************************************"
#Create temporal Firewall Rules in Server 1 and 2
firewall-cmd --permanent --add-service=high-availability
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd --permanent --zone=public --add-port=4567/tcp
firewall-cmd --permanent --zone=public --add-port=4568/tcp
firewall-cmd --permanent --zone=public --add-port=4444/tcp
firewall-cmd --permanent --zone=public --add-port=4567/udp
firewall-cmd --permanent --zone=public --add-port=5038/udp
firewall-cmd --permanent --zone=public --add-rich-rule 'rule family='ipv4' source address='$ip_app' port port=5038 protocol=tcp accept'
firewall-cmd --reload
ssh root@$ip_standby "firewall-cmd --permanent --add-service=high-availability"
ssh root@$ip_standby "firewall-cmd --permanent --zone=public --add-port=3306/tcp"
ssh root@$ip_standby "firewall-cmd --permanent --zone=public --add-port=4567/tcp"
ssh root@$ip_standby "firewall-cmd --permanent --zone=public --add-port=4568/tcp"
ssh root@$ip_standby "firewall-cmd --permanent --zone=public --add-port=4444/tcp"
ssh root@$ip_standby "firewall-cmd --permanent --zone=public --add-port=4567/udp"
ssh root@$ip_standby "firewall-cmd --permanent --zone=public --add-port=5038/udp"
ssh root@$ip_standby 'firewall-cmd --permanent --zone=public --add-rich-rule "rule family='ipv4' source address='$ip_app' port port=5038 protocol=tcp accept"'
ssh root@$ip_standby "firewall-cmd --reload"
ssh root@$ip_app "firewall-cmd --permanent --zone=public --add-port=3306/tcp"
ssh root@$ip_app "firewall-cmd --permanent --zone=public --add-port=4567/tcp"
ssh root@$ip_app "firewall-cmd --permanent --zone=public --add-port=4568/tcp"
ssh root@$ip_app "firewall-cmd --permanent --zone=public --add-port=4444/tcp"
ssh root@$ip_app "firewall-cmd --permanent --zone=public --add-port=4567/udp"
ssh root@$ip_app "firewall-cmd --reload"
echo -e "************************************************************"
echo -e "*             Configuring Permanent Firewall               *"
echo -e "*   Creating Firewall Services in VitalPBX in Server 1     *"
echo -e "************************************************************"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('MariaDB Client', 'tcp', '3306')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('MariaDB Galera Traffic', 'tcp', '4567-4568')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('MariaDB Galera SST', 'tcp', '4444')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA2224', 'tcp', '2224')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA3121', 'tcp', '3121')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA5403', 'tcp', '5403')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA5404-5405', 'udp', '5404-5405')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA21064', 'tcp', '21064')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA9929', 'both', '9929')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('Asterisk AMI', 'both', '5038')"
echo -e "************************************************************"
echo -e "*             Configuring Permanent Firewall               *"
echo -e "*     Creating Firewall Rules in VitalPBX in Server 1      *"
echo -e "************************************************************"
last_index=$(mysql -uroot ombutel -e "SELECT MAX(\`index\`) AS Consecutive FROM ombu_firewall_rules"  | awk 'NR==2')
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'MariaDB Client'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_app', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'MariaDB Galera Traffic'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_app', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'MariaDB Galera SST'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_app', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA2224'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA3121'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA5403'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA5404-5405'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA21064'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA9929'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'Asterisk AMI'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_floating', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_app', 'accept', $last_index)"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_whitelist (host, description, \`default\`) VALUES ('$ip_master', 'Server 1 IP', 'no')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_whitelist (host, description, \`default\`) VALUES ('$ip_standby', 'Server 2 IP', 'no')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_whitelist (host, description, \`default\`) VALUES ('$ip_app', 'Server App IP', 'no')"
echo -e "*** Done Step 2 ***"
echo -e "2"	> stepfirewall.txt

create_ami_user:
echo -e "************************************************************"
echo -e "*                   Creating AMI User                      *"
echo -e "************************************************************"
cat > /etc/asterisk/vitalpbx/manager__50-astboard-user.conf << EOF
[astboard]
secret = astboard
deny = 0.0.0.0/0.0.0.0
permit= 0.0.0.0/0.0.0.0
read = all
write = all
writetimeout = 5000
eventfilter=!Event: RTCP*
eventfilter=!Event: VarSet
eventfilter=!Event: Cdr
eventfilter=!Event: DTMF
eventfilter=!Event: AGIExec
eventfilter=!Event: ExtensionStatus
eventfilter=!Event: ChannelUpdate
eventfilter=!Event: ChallengeSent
eventfilter=!Event: SuccessfulAuth
eventfilter=!Event: NewExten
EOF
chown apache:root /etc/asterisk/vitalpbx/manager__50-astboard-user.conf
echo -e "*** Done Step 3 ***"
echo -e "3"	> stepfirewall.txt

vitalpbx_cluster_ok:
echo -e "************************************************************"
echo -e "*              VitalPBX Update Firewall OK                 *"
echo -e "************************************************************"
role