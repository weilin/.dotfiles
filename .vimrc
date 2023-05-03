
" If using a dark background within the editing area and syntax highlighting
" turn on this option as well
"set background=dark

" Uncomment the following to have Vim jump to the last position when
" reopening a file
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

if ! &diff
	au BufRead,BufNewFile *.ts set filetype=xml syntax=xml
	au BufRead,BufNewFile projects set filetype=json syntax=json nofoldenable
	au BufRead,BufNewFile */shared/model/* set filetype=json syntax=json nofoldenable
	au BufRead,BufNewFile */shared/panel/* set filetype=json syntax=json nofoldenable
	au BufRead,BufNewFile */os/*/*.cpp set expandtab ts=4 sw=4 ai
	"set foldmethod=manual
	"set nofoldenable
endif

set nofoldenable

" au BufNewFile,BufRead *.xml,*.htm,*.html so ~/.vimlhXMLFolding


" Uncomment the following to have Vim load indentation rules and plugins
" according to the detected filetype.
filetype plugin indent on

" The following are commented out as they cause vim to behave a lot
" differently from regular Vi. They are highly recommended though.
set showcmd		" Show (partial) command in status line.
set showmatch		" Show matching brackets.
set ignorecase		" Do case insensitive matching
set smartcase		" Do smart case matching
set incsearch		" Incremental search
set hlsearch
"set autowrite		" Automatically save before commands like :next and :make
"set hidden		" Hide buffers when they are abandoned
"set mouse=a		" Enable mouse usage (all modes)

" settings of cscope.
" I use GNU global instead cscope because global is faster.
set cscopetag
set cscopeprg=gtags-cscope
set cscopequickfix=c-,d-,e-,f-,g0,i-,s-,t-
nmap <silent> <leader>j <ESC>:cstag <c-r><c-w><CR>
nmap <silent> <leader>g <ESC>:lcs f c <c-r><c-w><cr>:lw<cr>
nmap <silent> <leader>s <ESC>:lcs f s <c-r><c-w><cr>:lw<cr>
command! -nargs=+ -complete=dir FindFiles :call FindFiles(<f-args>)
au VimEnter * call VimEnterCallback()
au BufAdd *.[ch] call FindGtags(expand('<afile>'))
au BufWritePost *.[ch] call UpdateGtags(expand('<afile>'))
  
let g:rg_highlight='true'
nnoremap <silent> <F8> :TlistToggle<CR>

function! FindFiles(pat, ...)
     let path = ''
     for str in a:000
         let path .= str . ','
     endfor
  
     if path == ''
         let path = &path
     endif
  
     echo 'finding...'
     redraw
     call append(line('$'), split(globpath(path, a:pat), '\n'))
     echo 'finding...done!'
     redraw
endfunc
  
function! VimEnterCallback()
     for f in argv()
         if fnamemodify(f, ':e') != 'c' && fnamemodify(f, ':e') != 'h' && fnamemodify(f, ':e') != 'cpp'
             continue
         endif
  
         call FindGtags(f)
     endfor
endfunc
  
function! FindGtags(f)
     let dir = fnamemodify(a:f, ':p:h')
     while 1
         let tmp = dir . '/GTAGS'
         if filereadable(tmp)
             exe 'cs add ' . tmp . ' ' . dir
             break
         elseif dir == '/'
             break
         endif
  
         let dir = fnamemodify(dir, ":h")
     endwhile
endfunc
  
function! UpdateGtags(f)
     let dir = fnamemodify(a:f, ':p:h')
     exe 'silent !cd ' . dir . ' && global -u &> /dev/null &'
endfunction


" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" Any valid git URL is allowed
" Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Multiple Plug commands can be written in a single line using | separators
" Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

" On-demand loading
" Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
" Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Using a non-default branch
" Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
" Plug 'fatih/vim-go', { 'tag': '*' }

" Plugin options
" Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Unmanaged plugin (manually installed and updated)
" Plug '~/my-prototype-plugin'

Plug 'yegappan/taglist'
Plug 'othree/xml.vim'
Plug 'sukima/xmledit'
Plug 'aceofall/gtags.vim'
Plug 'vim-scripts/XML-Folding'
Plug 'rust-lang/rust.vim'
Plug 'jremmen/vim-ripgrep'

" Initialize plugin system
call plug#end()
