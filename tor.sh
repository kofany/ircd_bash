#!/bin/bash
##########################################################
## K-line generator for tor exit ips                    ##
## Jerzy (kofany) Dabrowski                             ##
##########################################################

#our conf file dir
conf_dir="/home/ircd/irc/etc"
#our target file for K-lines
target="ircd-k-tor.conf"

#chk if the target file is there :) (return 1 or nothing)
chk_timestamp()
{
touch ${conf_dir}/timestamp
timestamp=$(date '+%d/%m/%Y_%H')
chk_last=$(cat ${conf_dir}/timestamp |grep "${timestamp}")
[[ -n ${chk_last} ]] && { echo -e "I have done my work in last 60 minutes - exiting"; exit ; }
}

#get tor exits files (wget needed to installed on box)
get_tor()
{
#if tor dir del all files inside else make dir 
[[ -d "${conf_dir}/tor" ]] && rm -rf ${conf_dir}/tor/* || mkdir ${conf_dir}/tor/
links=("https://lists.fissionrelays.net/tor/exits.txt" "https://www.dan.me.uk/torlist/?exit")
for link in ${links[@]}; do
i=$((i+1))
	wget -q -O ${conf_dir}/tor/exits${i} ${link}
done
}
#gen new target file with uniqe k-lines for ips merged from 2 sources
gen_kline()
{
#del old merge file if exists
[[ -f "${conf_dir}/tor/merge" ]] && rm -rf ${conf_dir}/tor/merge
exfiles=$(ls ${conf_dir}/tor/)
for exfile in ${exfiles[@]}; do
cat ${conf_dir}/tor/${exfile} >> ${conf_dir}/tor/merge
done
#remove old target file
[[ -f "${conf_dir}/${target}" ]] && rm -rf ${conf_dir}/${target}
#eliminate duplicated ips with awk
k_lines=$(awk '!seen[$0]++' ${conf_dir}/tor/merge)
IFS=$'\n'       # make newlines the only separator
for k_line in ${k_lines[@]}; do
echo -e "K|${k_line}|Tor connections are NOT welcome|*|0|" >> ${conf_dir}/${target}
done
#timestamp remove old and make new
[[ -f "${conf_dir}/timestamp" ]] && rm -rf ${conf_dir}/timestamp
timestamp=$(date '+%d/%m/%Y_%H')
echo -e "${timestamp}" >> ${conf_dir}/timestamp
}
reload_ircd()
{
ircdpid=$(pgrep ircd)
#check if include line with target is in ircd.conf
chk_include=$(cat ${conf_dir}/ircd.conf |grep ${target})
[[ -z ${chk_include} ]] && { sed -i '1s/^/#include ircd-k-tor.conf\n/' ${conf_dir}/ircd.conf; }
#chk_conf
[[ -f "/home/ircd/chkoutput" ]] && rm -rf /home/ircd/chkoutput
/home/ircd/irc/sbin/chkconf &> /home/ircd/chkoutput
chk_error=$(cat /home/ircd/chkoutput |grep ERROR)
[[ -z ${chk_error} ]] && kill -HUP ${ircdpid} || echo -e "Exiting Problem with ircd.conf file run chkconf manualy"
}
chk_timestamp
get_tor
gen_kline
reload_ircd
