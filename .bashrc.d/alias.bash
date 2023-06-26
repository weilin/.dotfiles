alias dotfiles_git='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias dotfiles_git_push='dotfiles_git push --set-upstream origin main'
alias push_dotfiles='dotfiles_git push --set-upstream origin main'

alias du1='du --max-depth 1 -h'
#alias fd='fdfind'
command -v nautilus && alias openfile_gui='nautilus'
alias findcpp='fd -t f -e c -e h -e cpp'
#alias curl='curl --netrc-file my-password-file'
alias curlu='curl -L -O --netrc'
#alias fdcpp='fd --exclude os/3rdParty/qt/ --exclude os/dist/ --exclude "port/*/*/dist/"  -t f -e cpp -e h -e c'
alias rgcpp='rg -t cpp -t c'
alias rgmake='rg -t make'
command -v nvim && alias vi='nvim'
alias git_remote_prune='git remote prune origin && if [ -f .gitmodules ]; then git submodule foreach  git remote prune origin; fi'
alias git_gc_all='git gc && if [ -f .gitmodules ]; then git submodule foreach  git gc; fi'
