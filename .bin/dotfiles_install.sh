git clone --bare git@github.com:weilin/.dotfiles.git $HOME/.dotfiles
function dotfiles_git() {
	   /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}
mkdir -p .config-backup
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
