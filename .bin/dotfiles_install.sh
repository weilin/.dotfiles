BASHRC_FILE=$HOME/.bashrc
BARE_GIT_DIR=$HOME/.dotfiles

function dotfiles_git() {
	   /usr/bin/git --git-dir=$BARE_GIT_DIR --work-tree=$HOME $@
}

mkdir -p $HOME/.config-backup
if ! [ -e $HOME/.config-backup/.bashrc.bak ]
then
	cp -al $BASHRC_FILE $HOME/.config-backup/.bashrc.bak
fi

if ! [ -e $BARE_GIT_DIR ]
then
	git clone --bare git@github.com:weilin/.dotfiles.git $BARE_GIT_DIR
	dotfiles_git checkout
	if [ $? = 0 ]; then
	   echo "Checked out config.";
	else
	    echo "Backing up pre-existing dot files.";
	    dotfiles_git checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
	fi;

	dotfiles_git checkout
	dotfiles_git config status.showUntrackedFiles no
	dotfiles_git config user.email "weilin.su@gmail.com"
	dotfiles_git config user.name "William Su"
fi

grep "^BASHRC_DIR=" $BASHRC_FILE 2>&1 > /dev/null
RET=$?
#echo "RET of grep .bashrc.d = $RET"
if [ "$RET" != "0" ]
then
	cat << EOF >> $BASHRC_FILE

BASHRC_DIR=$HOME/.bashrc.d
if [[ -d $BASHRC_DIR && -r $BASHRC_DIR && -x $BASHRC_DIR ]]; then
    for sh in "$BASHRC_DIR"/*.bash ; do
        [[ ${sh##*/} != @($_backup_glob|Makefile*|$_blacklist_glob) && -f \
        $shi && -r $sh ]] && . "$sh"
    done
fi
EOF
fi
