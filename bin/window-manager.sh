bgcolor='#333340'
if [ "`which picom 2>/dev/null | grep -v ^no' '`" != "" ]; then
   picom -b --backend glx
   hsetroot -solid $bgcolor
else
   xsetroot -solid $bgcolor
fi

lemon_wrapper() {
   (while true; do tick.sh; sleep 60; done) | sed -l -e s/%/%%/g | \
      while read line; do echo '%{r}'"$line"; done |
      lemonbar -B ff000000 -F wheat -f 'xft:Consolas:size=8' "$@"
}

do_wmaker() {
   wmclock &
   exec wmaker --no-dock --no-clip
}

do_fvwm() {
   lemon_wrapper -n FvwmLemonBar &
   tick_pid="$!"
   fvwm
   code=$?
   kill "$tick_pid"
   exit $code
}

do_dwm() {
   (while true; do xsetroot -name "`tick.sh`"; sleep 60; done) &
   tick_pid=$!
   dwm
   code=$?
   kill "$tick_pid"
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
