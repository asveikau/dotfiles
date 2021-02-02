search_program() {
   [ "`which "$1" 2>/dev/null | grep -v ^no' '`" != "" ]
}

bgcolor='#333340'
if search_program picom; then
   picom -b --backend glx
   hsetroot -solid $bgcolor
else
   xsetroot -solid $bgcolor
fi

wrap_exec() {
   set -m
   ("$@") &
   tick_pid="$tick_pid -$!"
   set +m
}

xcolor() {
   xpath=`which xterm 2>/dev/null | sed -e 's|/bin/xterm$||'`
   printf '#%.2x%.2x%.2x\n' `grep "$1"$ $xpath/lib/X11/rgb.txt | sed s/$1$//`
}

lemon_wrapper() {
   (while true; do tick.sh; sleep 60; done) | sed -l -e s/%/%%/g | \
      while read line; do echo '%{r}'"$line"; done |
      lemonbar -F `xcolor wheat` -f 'xft:Consolas:size=8' "$@"
}

do_wmaker() {
   wmclock &
   exec wmaker --no-dock --no-clip
}

do_fvwm() {
   wrap_exec lemon_wrapper -n FvwmLemonBar
   fvwm
   code=$?
   kill -- $tick_pid
   exit $code
}

do_dwm() {
   (while true; do xsetroot -name "`tick.sh`"; sleep 60; done) &
   tick_pid="$tick_pid $!"
   dwm
   code=$?
   kill -- $tick_pid
   exit $code
}

case `hostname` in
pi|laptop)
  do_dwm
  ;;
*)
  do_fvwm
  ;;
esac
