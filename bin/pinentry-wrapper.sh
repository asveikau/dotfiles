#!/bin/sh
exec `(which pinentry-gtk-2; 
       ls /Applications/MacPorts/pinentry-mac.app;
       which pinentry) 2>/dev/null | head -n 1` "$@"
