PWD=$(pwd)
VIM_CONFIG=".vimrc"
BASH_CONFIG=".bashrc"
TMUX_CONFIG=".tmux.conf"
VIM_CONFIG_PATH="${PWD}/${VIM_CONFIG}"
TMUX_CONFIG_PATH="${PWD}/${TMUX_CONFIG}"

ALIASES=$(cat <<EOF

alias git_tree='git log --all --decorate --graph --oneline'
alias git_tree_full='git log --all --decorate --graph'

EOF
)

ln -s "$VIM_CONFIG_PATH" "$HOME/$VIM_CONFIG"
ln -s "$TMUX_CONFIG_PATH" "$HOME/$TMUX_CONFIG"
echo "$ALIASES" >> "$HOME/$BASH_CONFIG"

tmux source "$HOME/$TMUX_CONFIG"
. "$HOME/$BASH_CONFIG"

