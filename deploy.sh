PWD=$(pwd)
VIM_CONFIG=".vimrc"
TMUX_CONFIG=".tmux.conf"
VIM_CONFIG_PATH="${PWD}/${VIM_CONFIG}"
TMUX_CONFIG_PATH="${PWD}/${TMUX_CONFIG}"

ln -s "$VIM_CONFIG_PATH" "$HOME/$VIM_CONFIG"
ln -s "$TMUX_CONFIG_PATH" "$HOME/$TMUX_CONFIG"

git config --global alias.tree 'log --all --decorate --graph --oneline'
git config --global alias.tree-full 'log --all --decorate --graph'
git config --global alias.show-files 'show --name-status --oneline'

tmux source "$HOME/$TMUX_CONFIG"
