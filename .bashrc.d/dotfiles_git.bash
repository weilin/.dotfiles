GIT_COMP_FILE=/usr/share/bash-completion/completions/git

alias git-dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias dotfiles_git='git-dotfiles'

alias git-dotfiles-push='git-dotfiles push --set-upstream origin main'


if ! [[ $(type -t ___git_complete) == function ]]
then
	if [ -e $GIT_COMP_FILE ]
	then
		source $GIT_COMP_FILE
	fi
fi


if [[ $(type -t ___git_complete) == function ]]
then
	___git_complete git-dotfiles __git_main
	___git_complete dotfiles_git __git_main
fi
