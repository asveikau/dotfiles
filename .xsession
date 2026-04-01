cd

. ~/.profile

xrdb merge ~/.Xdefaults

xmodmap ~/.xmodmap

export LIBGL_DRI3_ENABLE=1
export MOZ_X11_EGL=1

xscreensaver -no-splash &

# Run the WM in a loop in case I want to restart it.
#
while true; do
   window-manager.sh
done
