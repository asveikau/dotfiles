export PS1='\u@\h:\w\$ '
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

export GIT_EDITOR=vi
export SVN_EDITOR=$GIT_EDITOR

export GIT_AUTHOR_NAME="Andrew Sveikauskas"
export GIT_AUTHOR_EMAIL="a.l.sveikauskas@gmail.com"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"

os=`uname -s|tr '[:upper:]' '[:lower:]'`
platform=`uname -sm|tr '[:upper:]' '[:lower:]' | sed -e s/' '/_/g -e s/x86_64/amd64/`

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

[ -d /usr/games ] && PATH=$PATH:/usr/games
[ -d /opt/pkg ] && PATH=/opt/pkg/bin:$PATH
[ -d /opt/local ] && PATH=/opt/local/bin:/opt/local/sbin:$PATH

export PATH=$HOME/bin/`hostname -s`:$HOME/bin:$HOME/bin/$os:$HOME/bin/$platform:$PATH

if [ "$os" = "openbsd" ]; then
   export PKG_PATH=http://mirrors.sonic.net/pub/OpenBSD/`uname -r`/packages/`machine -a`/
fi

if [ "$platform" = "darwin" ]; then
   rm -f /var/log/asl/*`id -u`.asl 2>/dev/null
fi

machine_tmp=/tmp/`whoami`

mkdir -p $machine_tmp

if [ "`which gpg-agent`" != "" ]; then
   # If there's an agent running and $DISPLAY changes, we'll restart it.
   # This fixes an issue where ssh-ing sets a terminal-oriented pinentry
   # which then becomes less nice when you subsequently log in via X.
   #
   AGENT_PID="`pgrep -u $(id -u) gpg-agent`"
   if [ "$AGENT_PID" != "" ]; then
      AGENT_DISPLAY="`gpg-connect-agent 'getinfo std_session_env' /bye 2>/dev/null | grep -a '^D DISPLAY=' | cut -d = -f 2- | tr -d '\0'`"
      if [ "$AGENT_DISPLAY" != "$DISPLAY" ]; then
         gpgconf --kill gpg-agent
         unset AGENT_PID
         if [ "`grep -u $(id -u) gpg-agent`" != "" ]; then
            sleep 0.3
            pkill -9 -u `id -u` gpg-agent
         fi
      fi
      unset AGENT_DISPLAY
   fi
   # ssh-agent has a nice GUI on Mac, so don't use gpg-agent for SSH there.
   if [ "`uname -s`" != Darwin ]; then
      SSHFLAGS=--enable-ssh-support
   fi
   if [ "$AGENT_PID" = "" ]; then
      PINENTRY=`(which pinentry-gtk-2; ls /Applications/MacPorts/pinentry-mac.app/Contents/MacOS/pinentry-mac; which pinentry) 2>/dev/null | head -n 1`

      if [ -x $PINENTRY ]; then
         PINENTRY="--pinentry-program $PINENTRY"
      else
         unset PINENTRY
      fi

      gpg-agent --daemon \
                $SSHFLAGS \
                $PINENTRY \
         > /dev/null

      unset PINENTRY
   fi
   unset AGENT_PID
   if [ "$SSHFLAGS" != "" ]; then
      unset SSH_AGENT_PID
      export SSH_AUTH_SOCK=`gpgconf --list-dirs agent-ssh-socket`
      SSHFLAGS=""
   fi
fi

if [ "" = "$SSH_AUTH_SOCK" ]; then
   if [ ! -S $machine_tmp/ssh-agent-sock ] || [ ! -f $machine_tmp/ssh-agent-cmds ]; then
      pkill -u `id -u` ssh-agent 2> /dev/null
      ssh-agent -a $machine_tmp/ssh-agent-sock > $machine_tmp/ssh-agent-cmds
   fi
   eval `cat $machine_tmp/ssh-agent-cmds` > /dev/null
fi

unset machine_tmp
