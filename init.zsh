autoload -U +X compinit 
autoload -Uz ~/.zsh/fmk/zsh_defer/zsh-defer
ZSH="$HOME/.zsh/fmk"
export PATH="$HOME/.local/bin:$PATH"
fpath=("$ZSH/functions" "$ZSH/completions" $fpath)

#load plugins and scrips

source $ZSH/load_plugins.zsh
source $ZSH/load_scripts.zsh
