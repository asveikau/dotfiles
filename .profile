export PS1='\u@\h:\w\$ '
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

export GIT_EDITOR=vi
export SVN_EDITOR=$GIT_EDITOR

export GIT_AUTHOR_NAME="Andrew Sveikauskas"
export GIT_AUTHOR_EMAIL="a.l.sveikauskas@gmail.com"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"

# XXX - Ugly hack for amd(8) and /home.
# getwd(2) is showing the staging area instead of ~
#
case `pwd` in
/tmp_mnt/*)
   cd
   ;;
esac

lowercase() {
   env LANG=C LC_CTYPE=C tr '[:upper:]' '[:lower:]'
}

os=`uname | lowercase`
platform=`uname -sm | lowercase | sed -e s/' '/_/g -e s/x86_64/amd64/`

unset lowercase

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

[ -d /usr/games ] && PATH=$PATH:/usr/games
[ -d /opt/pkg ] && PATH=/opt/pkg/bin:$PATH
[ -d /opt/local ] && PATH=/opt/local/bin:/opt/local/sbin:$PATH

export PATH=$HOME/bin:$HOME/bin/$os:$HOME/bin/$platform:$PATH

case "$os" in
sunos)
   uid=`/usr/xpg4/bin/id -u`
   export PATH=$HOME/bin/`hostname | sed 's/\..*$//'`:$PATH
   ;;
*)
   uid=`id -u`
   export PATH=$HOME/bin/`hostname -s`:$PATH
   ;;
esac

if [ "$platform" = "darwin" ]; then
   rm -f /var/log/asl/*$uid.asl 2>/dev/null
fi

machine_tmp=/tmp/${USER-`whoami`}

mkdir -p $machine_tmp

if [ "`which gpg-agent 2>/dev/null | grep -v ^no' '`" != "" ]; then
   # If there's an agent running and $DISPLAY changes, we'll restart it.
   # This fixes an issue where ssh-ing sets a terminal-oriented pinentry
   # which then becomes less nice when you subsequently log in via X.
   #
   AGENT_PID="`pgrep -u $uid gpg-agent`"
   if [ "$AGENT_PID" != "" ]; then
      AGENT_DISPLAY="`gpg-connect-agent 'getinfo std_startup_env' /bye 2>/dev/null | grep -a '^D DISPLAY=' | cut -d = -f 2- | tr -d '\0'`"

      ## XXX - previously was experimenting with killing based on number of
      ## cached keys, which is useful, but slow.
      #CACHED_COUNT="`gpg-connect-agent 'keyinfo --list' /bye|grep -c '1 P'`"

      if [ "$AGENT_DISPLAY" != "$DISPLAY" ]; then
         gpgconf --kill gpg-agent
         unset AGENT_PID
         if [ "`pgrep -u $uid gpg-agent`" != "" ]; then
            sleep 0.3
            pkill -9 -u $uid gpg-agent
         fi
      fi
      unset AGENT_DISPLAY
   fi
   # ssh-agent has a nice GUI on Mac, so don't use gpg-agent for SSH there.
   if [ "$os" != darwin ]; then
      SSHFLAGS=--enable-ssh-support
   fi
   if [ "$AGENT_PID" = "" ]; then
      gpg-agent --daemon \
                $SSHFLAGS \
         > /dev/null
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
      pkill -u $uid ssh-agent 2> /dev/null
      ssh-agent -a $machine_tmp/ssh-agent-sock > $machine_tmp/ssh-agent-cmds
   fi
   eval `cat $machine_tmp/ssh-agent-cmds` > /dev/null
fi

unset machine_tmp
unset uid
