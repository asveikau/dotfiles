#!/bin/sh

ext() {
   for i in "$@"; do
   	echo "$@" | sed -e 's/[^.]*\.//g'
   done
}

i=0
for arg in "$@"; do
   if [ $i == $(($# - 1)) ]; then
      last="$arg"
   fi
   i=$((i+1))
done
last_dir="`dirname \"$last\"`"
case "$last_dir" in
   .)
      last_dir=`pwd`
   ;;
   /*)
   ;;
   *)
      last_dir="`pwd`/$last_dir"
   ;;
esac
export TMPDIR="$last_dir"

tmpdir="`mktemp -d -t concat-video`"
i=0
last=''

for arg in "$@"; do
   if [ $i == $(($# - 1)) ]; then
      last="$arg"
   else
      if [ "`echo $arg | grep -c ^/`" = 0 ]; then
         prefix=`pwd`/
      else
         prefix=''
      fi
      ln -s "$prefix""$arg" "$tmpdir"/`printf '%.4d' $i`.`ext "$arg"` 
   fi
   
   i=$((i+1))
done

cd "$tmpdir"

vcodecs="`for i in *.*; do ffprobe $i; done 2>&1 < /dev/null | grep Video: | sed -e 's/^.*Video: //' -e 's/[0-9]* kb.s, //'|uniq|wc -l`"
acodecs="`for i in *.*; do ffprobe $i; done 2>&1 < /dev/null | grep Audio: | sed -e 's/^.*Audio: //' -e 's/[0-9]* kb.s //'|uniq|wc -l`"

outfile=out."`ext \"$last\"`"

gen_filter_args() {
   audio=false
   video=false

   if [ "$vcodecs" -gt 0 ]; then
        video=true
   fi
   if [ "$acodecs" -gt 0 ]; then
        audio=true
   fi

   echo -n "-filter_complex "

   for i in `seq 0 $(($1-1))`; do
      $video && echo -n "[$i:v:0]"
      $audio && echo -n "[$i:a:0]"
   done
   echo -n concat=n=$1:
   $video && echo -n v=1
   $audio && $video && echo -n :
   $audio && echo -n a=1
   $video && echo -n "[outv]"
   $audio && echo -n "[outa]"
   $video && echo -n ' -map [outv]'
   $audio && echo -n ' -map [outa]'
}

if [ "$vcodecs" -lt 2 ] && [ "$acodecs" -lt 2 ]; then
   for i in `ls *.*`; do
      echo file \'"$i"\' >> concat
   done
   cat concat
   vcodec="-vcodec copy"
   acodec="-acodec copy"
   ffmpeg -f concat -i concat $vcodec $acodec $outfile
else
   nfiles="`ls *.* | wc -l|while read i; do echo $i; done`"

   ffmpeg `for i in *.*; do echo -i $i; done` \
          `gen_filter_args $nfiles` \
          $outfile
fi

cd -

mv -i "$tmpdir"/out.* "$last"

rm -rf "$tmpdir"
