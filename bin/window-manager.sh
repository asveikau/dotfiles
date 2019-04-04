do_wmaker() {
   wmclock &
   exec wmaker --no-dock --no-clip
}

do_dwm() {
   xsetroot -solid black

   (while true; do xsetroot -name "`tick.sh`"; sleep 60; done) &

   exec dwm
}

case `hostname` in
pi|laptop)
  do_dwm
  ;;
*)
  do_wmaker
  ;;
esac
