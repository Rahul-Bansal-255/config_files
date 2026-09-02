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
Usage: $(basename "$0") COMMAND [COMPONENT ...] [COMMAND [COMPONENT ...] ...]

Commands (can be chained in a single invocation):
  install COMPONENT ...    Install one or more components
  configure COMPONENT ...  Configure (symlink) one or more components
  all                      Shorthand for: install all && configure all
  help                     Show this help message

Install components (uses dnf for tmux/vim/git/python/ripgrep, upstream installers for neovim/starship/rust):
  tmux                  Install tmux via dnf
  vim                   Install vim via dnf
  git                   Install git via dnf
  python                Install python3 via dnf
  ripgrep               Install ripgrep via dnf
  neovim                Install neovim from the pre-built release archive
  starship              Install starship via the official install script
  rust                  Install build deps via dnf, then rust via rustup
  all                   Install all of the components above (not wezterm, which is configure-only)

Configure components (symlinks dotfiles from this repo into \$HOME):
  tmux                  Symlink tmux config and reload the running tmux server
  vim                   Symlink vim config
  wezterm               Symlink wezterm config
  neovim                Symlink neovim config
  starship              Symlink starship config
  git                   Apply git global config/aliases
  all                   Run all of the configure steps above

Examples:
  $(basename "$0") install tmux vim git
  $(basename "$0") configure all
  $(basename "$0") all
  $(basename "$0") install tmux git configure vim git

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

install() {
  local component="$1"
  case "$component" in
    tmux)
      echo "Installing tmux via dnf..."
      sudo dnf install -y tmux
      ;;
    vim)
      echo "Installing vim via dnf..."
      sudo dnf install -y vim
      ;;
    git)
      echo "Installing git via dnf..."
      sudo dnf install -y git
      ;;
    python)
      echo "Installing python3 via dnf..."
      sudo dnf install -y python3
      ;;
    ripgrep)
      echo "Installing ripgrep via dnf..."
      sudo dnf install -y ripgrep
      ;;
    rust)
      echo "Installing rust build dependencies via dnf..."
      sudo dnf install -y cmake gcc make curl clang
      echo "Installing rust via rustup..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      append_once 'source "$HOME/.cargo/env"' "$BASHRC"
      ;;
    neovim)
      echo "Installing neovim from pre-built archive..."
      local tmp_dir
      tmp_dir=$(mktemp -d)
      curl -fL -o "${tmp_dir}/${NVIM_ARCHIVE}" "$NVIM_DOWNLOAD_URL"
      sudo rm -rf "$NVIM_INSTALL_DIR"
      sudo tar -C /opt -xzf "${tmp_dir}/${NVIM_ARCHIVE}"
      rm -rf "$tmp_dir"
      append_once 'export PATH="$PATH:'"$NVIM_INSTALL_DIR"'/bin"' "$BASHRC"
      ;;
    starship)
      echo "Installing starship..."
      curl -fsS https://starship.rs/install.sh | sh -s -- -y
      append_once 'eval "$(starship init bash)"' "$BASHRC"
      ;;
    all)
      install tmux
      install vim
      install git
      install python
      install ripgrep
      install rust
      install neovim
      install starship
      ;;
    *)
      echo "Unknown install component: $component" >&2
      usage
      exit 1
      ;;
  esac
}

configure() {
  local component="$1"
  case "$component" in
    vim)
      safe_link "$VIM_CONFIG_FILE_SRC" "$VIM_CONFIG_FILE_DEST"
      ;;
    tmux)
      safe_link "$TMUX_CONFIG_FILE_SRC" "$TMUX_CONFIG_FILE_DEST"
      if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
        tmux source "$TMUX_CONFIG_FILE_DEST"
      fi
      ;;
    wezterm)
      safe_link "$WEZTERM_CONFIG_FILE_SRC" "$WEZTERM_CONFIG_FILE_DEST"
      ;;
    neovim)
      safe_link "$NVIM_CONFIG_FILE_SRC" "$NVIM_CONFIG_FILE_DEST"
      safe_link "$NVIM_SUB_CONFIG_SRC" "$NVIM_SUB_CONFIG_DEST"
      ;;
    starship)
      safe_link "$STARSHIP_CONFIG_FILE_SRC" "$STARSHIP_CONFIG_FILE_DEST"
      ;;
    git)
      git config --global core.editor vim
      git config --global alias.tree 'log --all --decorate --graph --oneline'
      git config --global alias.tree-full 'log --all --decorate --graph'
      git config --global alias.show-files 'show --name-status --oneline'
      ;;
    all)
      configure vim
      configure tmux
      configure wezterm
      configure neovim
      configure starship
      configure git
      ;;
    *)
      echo "Unknown configure component: $component" >&2
      usage
      exit 1
      ;;
  esac
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

is_command() {
  # "all" is intentionally excluded: it is also a valid component name for
  # both install and configure, so it must not act as a list boundary here.
  case "$1" in
    install | configure | help) return 0 ;;
    *) return 1 ;;
  esac
}

while [ "$#" -gt 0 ]; do
  cmd="$1"
  shift

  case "$cmd" in
    install)
      components=()
      while [ "$#" -gt 0 ] && ! is_command "$1"; do
        components+=("$1")
        shift
      done
      if [ "${#components[@]}" -eq 0 ]; then
        echo "Missing component(s) for install" >&2
        usage
        exit 1
      fi
      for component in "${components[@]}"; do
        install "$component"
      done
      ;;
    configure)
      components=()
      while [ "$#" -gt 0 ] && ! is_command "$1"; do
        components+=("$1")
        shift
      done
      if [ "${#components[@]}" -eq 0 ]; then
        echo "Missing component(s) for configure" >&2
        usage
        exit 1
      fi
      for component in "${components[@]}"; do
        configure "$component"
      done
      ;;
    all)
      install all
      configure all
      ;;
    help)
      usage
      ;;
    *)
      echo "Unknown command: $cmd" >&2
      usage
      exit 1
      ;;
  esac
done
