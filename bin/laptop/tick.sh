#!/bin/sh

get_field() {
   sysctl $1 | cut -d ' ' -f 2
}

format_time() {
   minutes=$1
   if [ "$minutes" -ge 60 ]; then
      hours=$(($minutes / 60))
      minutes=$(($minutes % 60))
      printf "%.2d:" $hours
   else
      echo -n "00:"
   fi
   printf "%.2d" $minutes
}

echo -n `date '+%H:%M'`

if [ `get_field hw.acpi.acline` = 0 ]; then
   total_minutes=`get_field hw.acpi.battery.time`
   pct=`get_field hw.acpi.battery.life`
   echo ' ' \
        `printf %.2d $pct`%, \
        `format_time $total_minutes`
else
   echo ' ' +
fi

