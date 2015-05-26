#! /usr/bin/bash
outfile="$1"
[[ "${outfile}" ]] || outfile="conkyrc" 

#Functions
not_up() {
  local interf=$1 
  local fname=$2
  echo -e "$hr \n $cgy Interface $interf is Down" >> $fname 
}

inter_up () {
  local interf=$1
  local fname=$2
  echo '$hr' >> $fname
  echo "$cgy Down:$cgy \${downspeed $interf} k/s$cgy \${offset 80}Up:$cgy \${Upspeed $interf} k/s " >> $fname
  echo "$cbl\${downspeedgraph $1 32, 150 000000 7f8ed3} $cbl\${upspeedgraph $1 32, 150 000000 7f8ed3} " >> $fname
}

status_check () {
  [[ -n `ip addr show | grep "$1" | grep 'DOWN'` ]]  && not_up $1 $2 || inter_up $1 $2
}

one_print () {
  echo "$cgy CPU $1: $cgy\${execi 5 $2 | head -n $1}C " >> $outfile
}

double_print () {
  echo "$cgy CPU $1: $cgy\${execi 5 $2 | head -n $1}C \${offset 60} CPU $3: \${execi 5 $4 | head -n $3}C " >> $outfile 
}

use_sens () {
  no_of_cores=(`sensors | grep 'Core' | wc -l`)
  cpureg='sensors | perl -lane '"'"'my @F = split(/[C,+]+/,$_); /Core/ && print $F[2]'"'"
  for i in $(seq 1 2 $no_of_cores) 
  do
    let j="$i+1"
    [[ "$j" > "$no_of_cores" ]] && single_print $i "$cpureg" || double_print $i "$cpureg" $j "$cpureg" 
  done
}

use_sniff() {
  no_of_cores=(`find /sys/ -name "*_input" 2>/dev/null | wc -l`)
  flist=(`find /sys/ -name "*_input" 2>/dev/null | sort | uniq`)
  for i in $(seq 1 2 $no_of_cores)
  do 
    let j="$i+1"
    [[ "$j" > "$no_of_cores" ]] && single_print $i ${flist[$i]} || double_print $i ${flist[$i]} $j ${flist[$j]} 
    #echo "$cgy CPU $i: $cgy\${execi 5 echo \$((\$(cat ${flist[$i]}) /1000 )) }C \${offset 60} CPU $j: \${execi 5 echo \$((\$(cat ${flist[$j]}) /1000)) }C " >> $outfile
  done
}

cpustat () {
  sensors -v foo > /dev/null 2>&1 && use_sens || use_sniffing 
}

check_reddit_script () {
  [[ -d "/home/$USER/.scripts" ]] || mkdir ~/.scripts
  [[ -f "/home/$USER/.scripts/reddittracker.sh" ]] || echo "copy reddittracker script to ~/.scripts directory"
  [[ -f "/home/$USER/.scripts/threads.txt" ]] || (cd /home/$USER/.scripts && touch threads.txt && echo "reddits threads here" >> threads.txt)
}

#Define Colors
cgy='${color grey}'
cbl='${color black}'
clg='${color lightgrey}'
cw='${color white}'

cat << EOF > $outfile
alignment top_right
background yes
border_margin 2
border_width 1
maximum_width 512
cpu_avg_samples 2
default_color white
default_outline_color black
default_shade_color black
draw_borders no
draw_graph_borders yes
draw_outline no
draw_shades no

use_xft no
xftfont DejaVu Sans Mono:size=18

gap_x 5
gap_y 60
minimum_size 5 5
net_avg_samples 2
double_buffer yes
no_buffers yes
out_to_console no
out_to_stderr no
extra_newline no
own_window no
own_window_transparent yes
#own_window_class Conky
own_window_type override
stippled_borders 4
update_interval 1.0
uppercase no
use_space no
show_graph_scale no

TEXT
EOF

echo '${scroll 16 $nodename - $sysname $kernel on $machine | }${alignr}${time %T}' >> $outfile
echo '$hr' >> $outfile
echo -e "$cgy"'Uptime:$color $uptime' >> $outfile
echo "$cgy"'RAM Usage:$color $mem/$memmax - $memperc% ${membar 4}' >> $outfile
echo "$cgy"'Swap Usage:$color $swap/$swapmax - $swapperc% ${swapper 4}' >> $outfile
echo "$cgy"'CPU Usage:$color $cpu% ${cpubar 4}' >> $outfile
echo "$cbl\${cpugraph 000000 7f8ed3}" >> $outfile
#do cat /proc/cpuinfo functions here.
cpustat

echo '$hr' >> $outfile
echo "$cgy"'Processess:$color $processes '"$cgy"' Running:$color $running_processes' >> $outfile
echo "$cgy"'File Systems:' >> $outfile
echo '  / $color${fs_used /home/}/${fs_size /home/} ${fs_bar 6 /home/}' >> $outfile

echo "$cgy"'Networking:' >> $outfile
#do eth and wlano function here.
ifaces=(`ip addr show | perl -F: -lane ' if(/BROADCAST/){$F[1] =~ s/(^\s+|\s+$F[1])//g && print $F[1]} '`)
wifaces=(`ip addr show | perl -F: -lane 'if(/BROADCAST/ and !/DOWN/) {$F[1] =~ s/(^\s+$F[1])//g && print $F[1]} '`)
for i in "${ifaces[@]}" ; do status_check $i $outfile ; done  #remember to export if subshell + xargs.
echo "$cgy TCP Connections: $cgy\${tcp_portmon 1 65535 count}" >> $outfile
echo "$hr" >> $outfile
echo -e "$cgy""Name \t \t PID\tCPU%\tMEM%" >> $outfile
seq 1 4 | xargs -n 1 -I _ echo "$clg \${top name _} \${top cpu _} \${top mem _}" >> $outfile 
echo '$hr' >> $outfile

echo '$hr' >> $outfile
echo "$cw\$mpd_status" >> $outfile
echo '${scroll 16 $mpd_title - $mpd_artist}' >> $outfile
#reddit score tracker starts
echo '$hr' >> $outfile
check_reddit_Sscript &&  echo "scripts are in place" # or, (comment this line && edit conkyrc file.) 
for i in `seq 1 3` ; do
echo "\${scroll 16 \` cat ~/.scripts/threads.txt | tail -n $i \` | }\${alignr}{execi 30 ~/.scripts/reddittracker.sh \` cat ~/.scripts/threads.txt | tail -n $i \` } "  >> $outfile  
done
