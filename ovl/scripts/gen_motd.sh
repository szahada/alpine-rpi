#!/bin/sh
{
printf "%s\n" "$(printf %60s |tr " " "=")"
printf "%s\n%s\n%s\n" "$(uname -mnrs)" "$(uptime | sed 's/^ //' | cut -d' ' -f2-)" "$(printf %60s |tr " " "=")"
printf "%s\n%s\n" "$(ip -o addr show | grep '\sinet\s' | awk '{print "\t"$2"\t"$4}')" "$(printf %60s |tr " " "=")"
printf "%s\n%s\n" "$(free -m | awk '{ if(NR==1) printf("%5s%10s%10s%10s%10s\n", " ",$1,$2,$3,$6); else printf("%5s%10s%10s%10s%10s\n", $1,$2,$3,$4,$7);}')" "$(printf %60s |tr " " "=")" 
printf "%s\n%s\n" "$(df -h / /srv)" "$(printf %60s |tr " " "=")"
} > /etc/motd 

