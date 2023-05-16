export IGNOREEOF=10
export LC_ALL=C
export EDITOR=vim

case "$TERM" in
xterm*|rxvt*|screen)
	PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
	;;
*)
	;;
esac

for script in $HOME/.bashrc.d/*.bash; do
        [[ -r ${script} ]] && source "${script}"
done

for sh in $HOME/.bash_completetion.d/* ; do
        [[ -r ${sh} ]] && source "${sh}"
done
