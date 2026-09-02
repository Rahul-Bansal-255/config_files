#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VIM_CONFIG=".vimrc"
TMUX_CONFIG=".tmux.conf"
WEZTERM_CONFIG=".wezterm.lua"
NVIM_CONFIG="init.lua"
NVIM_SUB_CONFIG="lua"
STARSHIP_CONFIG="starship.toml"

VIM_CONFIG_FILE_SRC="${SCRIPT_DIR}/${VIM_CONFIG}"
TMUX_CONFIG_FILE_SRC="${SCRIPT_DIR}/${TMUX_CONFIG}"
WEZTERM_CONFIG_FILE_SRC="${SCRIPT_DIR}/${WEZTERM_CONFIG}"
NVIM_CONFIG_FILE_SRC="${SCRIPT_DIR}/${NVIM_CONFIG}"
NVIM_SUB_CONFIG_SRC="${SCRIPT_DIR}/${NVIM_SUB_CONFIG}"
STARSHIP_CONFIG_FILE_SRC="${SCRIPT_DIR}/${STARSHIP_CONFIG}"

VIM_CONFIG_FILE_DEST="$HOME/$VIM_CONFIG"
TMUX_CONFIG_FILE_DEST="$HOME/$TMUX_CONFIG"
WEZTERM_CONFIG_FILE_DEST="$HOME/$WEZTERM_CONFIG"
NVIM_CONFIG_PATH_DEST="$HOME/.config/nvim"
NVIM_CONFIG_FILE_DEST="$NVIM_CONFIG_PATH_DEST/$NVIM_CONFIG"
NVIM_SUB_CONFIG_DEST="$NVIM_CONFIG_PATH_DEST/$NVIM_SUB_CONFIG"
STARSHIP_CONFIG_PATH_DEST="$HOME/.config"
STARSHIP_CONFIG_FILE_DEST="$STARSHIP_CONFIG_PATH_DEST/$STARSHIP_CONFIG"

NVIM_INSTALL_DIR="/opt/nvim-linux-x86_64"
NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz"
NVIM_DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/${NVIM_ARCHIVE}"
BASHRC="$HOME/.bashrc"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install options (uses dnf for tmux/vim/git, upstream installers for neovim/starship):
  --install-tmux        Install tmux via dnf
  --install-vim         Install vim via dnf
  --install-git         Install git via dnf
  --install-neovim      Install neovim from the pre-built release archive
  --install-starship    Install starship via the official install script
  --install-all         Install tmux, vim, git, neovim and starship (not wezterm)

Configure options (symlinks dotfiles from this repo into \$HOME):
  --configure-tmux      Symlink tmux config and reload the running tmux server
  --configure-vim       Symlink vim config
  --configure-wezterm   Symlink wezterm config
  --configure-neovim    Symlink neovim config
  --configure-starship  Symlink starship config
  --configure-git       Apply git global config/aliases
  --configure-all       Run all of the configure steps above

  -a, --all             Shorthand for --install-all --configure-all
  -h, --help            Show this help message

Note: wezterm is never installed by this script, only configured.
EOF
}

safe_link() {
  local src="$1" dest="$2" dest_dir
  dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf "$dest"
  fi
  ln -s "$src" "$dest"
}

append_once() {
  local line="$1" file="$2"
  touch "$file"
  if ! grep -qF -- "$line" "$file"; then
    printf '\n%s\n' "$line" >>"$file"
  fi
}

install_tmux() {
  echo "Installing tmux via dnf..."
  sudo dnf install -y tmux
}

install_vim() {
  echo "Installing vim via dnf..."
  sudo dnf install -y vim
}

install_neovim() {
  echo "Installing neovim from pre-built archive..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  curl -fL -o "${tmp_dir}/${NVIM_ARCHIVE}" "$NVIM_DOWNLOAD_URL"
  sudo rm -rf "$NVIM_INSTALL_DIR"
  sudo tar -C /opt -xzf "${tmp_dir}/${NVIM_ARCHIVE}"
  rm -rf "$tmp_dir"
  append_once 'export PATH="$PATH:'"$NVIM_INSTALL_DIR"'/bin"' "$BASHRC"
}

install_starship() {
  echo "Installing starship..."
  curl -fsS https://starship.rs/install.sh | sh -s -- -y
  append_once 'eval "$(starship init bash)"' "$BASHRC"
}

install_git() {
  echo "Installing git via dnf..."
  sudo dnf install -y git
}

install_all() {
  install_tmux
  install_vim
  install_git
  install_neovim
  install_starship
}

configure_vim() {
  safe_link "$VIM_CONFIG_FILE_SRC" "$VIM_CONFIG_FILE_DEST"
}

configure_tmux() {
  safe_link "$TMUX_CONFIG_FILE_SRC" "$TMUX_CONFIG_FILE_DEST"
  if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
    tmux source "$TMUX_CONFIG_FILE_DEST"
  fi
}

configure_wezterm() {
  safe_link "$WEZTERM_CONFIG_FILE_SRC" "$WEZTERM_CONFIG_FILE_DEST"
}

configure_neovim() {
  safe_link "$NVIM_CONFIG_FILE_SRC" "$NVIM_CONFIG_FILE_DEST"
  safe_link "$NVIM_SUB_CONFIG_SRC" "$NVIM_SUB_CONFIG_DEST"
}

configure_starship() {
  safe_link "$STARSHIP_CONFIG_FILE_SRC" "$STARSHIP_CONFIG_FILE_DEST"
}

configure_git() {
  git config --global core.editor vim
  git config --global alias.tree 'log --all --decorate --graph --oneline'
  git config --global alias.tree-full 'log --all --decorate --graph'
  git config --global alias.show-files 'show --name-status --oneline'
}

configure_all() {
  configure_vim
  configure_tmux
  configure_wezterm
  configure_neovim
  configure_starship
  configure_git
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-tmux) install_tmux ;;
    --install-vim) install_vim ;;
    --install-neovim) install_neovim ;;
    --install-starship) install_starship ;;
    --install-git) install_git ;;
    --install-all) install_all ;;
    --configure-tmux) configure_tmux ;;
    --configure-vim) configure_vim ;;
    --configure-wezterm) configure_wezterm ;;
    --configure-neovim) configure_neovim ;;
    --configure-starship) configure_starship ;;
    --configure-git) configure_git ;;
    --configure-all) configure_all ;;
    -a|--all)
      install_all
      configure_all
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done
