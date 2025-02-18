PWD=$(pwd)
VIM_CONFIG=".vimrc"
TMUX_CONFIG=".tmux.conf"
VIM_CONFIG_PATH="${PWD}/${VIM_CONFIG}"
TMUX_CONFIG_PATH="${PWD}/${TMUX_CONFIG}"

ln -s "$VIM_CONFIG_PATH" "$HOME/$VIM_CONFIG"
ln -s "$TMUX_CONFIG_PATH" "$HOME/$TMUX_CONFIG"

git config --global alias.tree 'git log --all --decorate --graph --oneline'
git config --global alias.tree-full 'git log --all --decorate --graph'

tmux source "$HOME/$TMUX_CONFIG"
