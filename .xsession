cd

. ~/.profile

xrdb merge ~/.Xdefaults

xmodmap ~/.xmodmap

xscreensaver -no-splash &

# Run the WM in a loop in case I want to restart it.
#
while true; do
   window-manager.sh
done
