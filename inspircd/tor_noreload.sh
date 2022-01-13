#!/bin/bash
##########################################################
## K-line generator for tor exit ips [InspIRCd version] ##
## Jerzy (kofany) Dabrowski                             ##
## this script need wget to run proply                  ##
##########################################################
#
# Please create a epmty file /etc/inspircd/tor.sh
# and do correct chmod 
# Best install this file in /usr/share/inspircd/ :)
# 
#wget check
command -v wget >/dev/null 2>&1 || { echo >&2 "I require wget but it's not installed.  Aborting."; exit 1; }
#our conf file dir
conf_dir="/etc/inspircd"
#our target file for K-lines
target="tor.conf"

#chk if the target file is there :) (return 1 or nothing)
#chk_timestamp()
#{
#touch ${conf_dir}/timestamp
#timestamp=$(date '+%d/%m/%Y_%H')
#chk_last=$(cat ${conf_dir}/timestamp |grep "${timestamp}")
#[[ -n ${chk_last} ]] && { echo -e "I have done my work in last 60 minutes - exiting"; exit ; }
#}

#get tor exits files (wget needed to installed on box)
get_tor()
{
#if tor dir del all files inside else make dir 
[[ -d "${conf_dir}/tor" ]] && { mv ${conf_dir}/tor ${conf_dir}/tor_backup; mkdir ${conf_dir}/tor/;} || mkdir ${conf_dir}/tor/
links=("https://lists.fissionrelays.net/tor/exits.txt" "https://www.dan.me.uk/torlist/?exit")
for link in ${links[@]}; do
i=$((i+1))
	wget -q -O ${conf_dir}/tor/exits${i} ${link}
done
}
#gen new target file with uniqe k-lines for ips merged from 2 sources
gen_kline()
{
[[ -f "${conf_dir}/tor/merge" ]] && mv ${conf_dir}/tor/merge ${conf_dir}/tor/merge.backup
exfiles=$(ls ${conf_dir}/tor/)
for exfile in ${exfiles[@]}; do
cat ${conf_dir}/tor/${exfile} >> ${conf_dir}/tor/merge
done
#back up old target file
[[ -f "${conf_dir}/${target}" ]] && mv ${conf_dir}/${target} ${conf_dir}/${target}.backup
#eliminate duplicated ips with awk
k_lines=$(awk '!seen[$0]++' ${conf_dir}/tor/merge)
IFS=$'\n'       # make newlines the only separator
for k_line in ${k_lines[@]}; do
if [[ ${k_line} =~ ^([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
echo -e "<badip ipmask=\"${k_line}\" reason=\"Tor connections are NOT welcome\">" >> ${conf_dir}/${target}
fi
if [[ ${k_line} =~ ^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$ ]]; then
	echo -e "<badip ipmask=\"${k_line}\" reason=\"Tor connections are NOT welcome\">" >> ${conf_dir}/${target}
fi
done
#timestamp remove old and make new
[[ -f "${conf_dir}/timestamp" ]] && rm -rf ${conf_dir}/timestamp
timestamp=$(date '+%d/%m/%Y_%H')
echo -e "${timestamp}" >> ${conf_dir}/timestamp
}
#reload_ircd()
#{
#	#last fail-safe if target is empty use backup file
#chk_target=$(wc -l < ${conf_dir}/${target})
#if [[ ${chk_target} -lt 10 ]]; then
#	mv ${conf_dir}/${target}.backup ${conf_dir}/${target}
#fi
#timestamp=$(date '+%d/%m/%Y_%H')
#chk_include=$(cat ${conf_dir}/inspircd.conf |grep ${target})
#[[ -z ${chk_include} ]] && { sed -i '1s/^/<include file="tor.conf">\n/' ${conf_dir}/inspircd.conf; }
#/usr/share/inspircd/inspircd rehash && echo -e "${timestamp} ircd rehash-ed" >> log_hup;
#}
#chk_timestamp
get_tor
gen_kline
#reload_ircd
