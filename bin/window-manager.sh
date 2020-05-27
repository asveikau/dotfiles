bgcolor='#333340'
if [ "`which picom 2>/dev/null | grep -v ^no' '`" != "" ]; then
   picom -b --backend glx
   hsetroot -solid $bgcolor
else
   xsetroot -solid $bgcolor
fi

do_wmaker() {
   wmclock &
   exec wmaker --no-dock --no-clip
}

do_fvwm() {
   exec fvwm
}

do_dwm() {
   (while true; do xsetroot -name "`tick.sh`"; sleep 60; done) &

   exec dwm
}

case `hostname` in
pi|laptop)
  do_dwm
  ;;
*)
  do_fvwm
  ;;
esac
