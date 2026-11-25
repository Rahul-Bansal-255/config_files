#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VIM_CONFIG=".vimrc"
TMUX_CONFIG=".tmux.conf"
WEZTERM_CONFIG=".wezterm.lua"
NVIM_CONFIG="init.lua"
NVIM_SUB_CONFIG="lua"
NVIM_LOCK="lazy-lock.json"
STARSHIP_CONFIG="starship.toml"

VIM_CONFIG_FILE_SRC="${SCRIPT_DIR}/${VIM_CONFIG}"
TMUX_CONFIG_FILE_SRC="${SCRIPT_DIR}/${TMUX_CONFIG}"
WEZTERM_CONFIG_FILE_SRC="${SCRIPT_DIR}/${WEZTERM_CONFIG}"
NVIM_CONFIG_FILE_SRC="${SCRIPT_DIR}/${NVIM_CONFIG}"
NVIM_SUB_CONFIG_SRC="${SCRIPT_DIR}/${NVIM_SUB_CONFIG}"
NVIM_LOCK_FILE_SRC="${SCRIPT_DIR}/${NVIM_LOCK}"
STARSHIP_CONFIG_FILE_SRC="${SCRIPT_DIR}/${STARSHIP_CONFIG}"

VIM_CONFIG_FILE_DEST="$HOME/$VIM_CONFIG"
TMUX_CONFIG_FILE_DEST="$HOME/$TMUX_CONFIG"
WEZTERM_CONFIG_FILE_DEST="$HOME/$WEZTERM_CONFIG"
NVIM_CONFIG_PATH_DEST="$HOME/.config/nvim"
NVIM_CONFIG_FILE_DEST="$NVIM_CONFIG_PATH_DEST/$NVIM_CONFIG"
NVIM_SUB_CONFIG_DEST="$NVIM_CONFIG_PATH_DEST/$NVIM_SUB_CONFIG"
NVIM_LOCK_FILE_DEST="$NVIM_CONFIG_PATH_DEST/$NVIM_LOCK"
STARSHIP_CONFIG_PATH_DEST="$HOME/.config"
STARSHIP_CONFIG_FILE_DEST="$STARSHIP_CONFIG_PATH_DEST/$STARSHIP_CONFIG"

case "$(uname -m)" in
    aarch64 | arm64)
        NVIM_ARCH="arm64"
        GO_ARCH="arm64"
        ;;
    *)
        NVIM_ARCH="x86_64"
        GO_ARCH="amd64"
        ;;
esac
NVIM_INSTALL_DIR="/opt/nvim-linux-${NVIM_ARCH}"
NVIM_ARCHIVE="nvim-linux-${NVIM_ARCH}.tar.gz"
NVIM_RELEASE_API="https://api.github.com/repos/neovim/neovim/releases/latest"
GO_INSTALL_DIR="/usr/local/go"
BEAR_VERSION="4.2.2"
BEAR_PREFIX="/usr/local"
BASHRC="$HOME/.bashrc"
SHELL_RELOAD_NEEDED=0

# Temporary directories are removed on exit, including when a step fails.
CLEANUP_DIRS=()
trap 'rm -rf ${CLEANUP_DIRS[@]+"${CLEANUP_DIRS[@]}"}' EXIT

usage() {
    cat <<EOF
Usage: $(basename "$0") COMMAND [COMPONENT ...] [COMMAND [COMPONENT ...] ...]

Commands (can be chained in a single invocation):
  install COMPONENT ...    Install one or more components
  configure COMPONENT ...  Configure (symlink) one or more components
  all                      Shorthand for: install all && configure all
  help                     Show this help message

Install components (uses dnf for epel/tmux/vim/git/python/ripgrep/clangd/devtools, pipx for pylsp/black/beautysh, npm for bashls/typescript, nvm for nodejs, cargo for treesitter, upstream installers for neovim/starship/rust/golang, build-from-source for bear):
  epel                  Install the EPEL repository via dnf (skipped on Fedora)
  devtools              Install the "Development Tools" package group via dnf
  tmux                  Install tmux via dnf
  vim                   Install vim via dnf
  git                   Install git via dnf
  python                Install python3 via dnf
  black                 Install black (Python formatter) via pipx
  pylsp                 Install pylsp (python-lsp-server) via pipx
  beautysh              Install beautysh (Bash formatter) via pipx
  ripgrep               Install ripgrep via dnf
  clangd                Install clangd + clang-format via dnf (clang-tools-extra)
  rust                  Install build deps via dnf, then rust via rustup, plus rustfmt/rust-analyzer components
  treesitter            Install tree-sitter CLI via cargo (needed by nvim-treesitter to build parsers; requires rust)
  bear                  Install bear ${BEAR_VERSION} from source into ${BEAR_PREFIX} (requires rust, git and a C compiler)
  neovim                Install neovim from the pre-built release archive (checksum-verified)
  starship              Install starship via the official install script
  nodejs                Install Node.js (v24) and npm via nvm
  bashls                Install bash-language-server via npm (requires nodejs) and shellcheck via dnf
  typescript            Install typescript, typescript-language-server, and prettier via npm (requires nodejs)
  golang                Install Go from the official release archive (checksum-verified) and gopls via go install
  all                   Install all of the components above (not wezterm, which is configure-only)

Configure components (symlinks dotfiles from this repo into \$HOME):
  tmux                  Symlink tmux config and reload the running tmux server
  vim                   Symlink vim config
  wezterm               Symlink wezterm config
  neovim                Symlink neovim config and plugin lock file
  starship              Symlink starship config
  git                   Apply git global config/aliases
  all                   Run all of the configure steps above

Examples:
  $(basename "$0") install tmux vim git
  $(basename "$0") configure all
  $(basename "$0") all
  $(basename "$0") install tmux git configure vim git

Notes:
  install requires dnf (Fedora, RHEL and its rebuilds); configure works on any system.
  Re-running install skips rustup, nvm, bear, neovim and Go when already at the target version.
  wezterm is never installed by this script, only configured.
EOF
}

safe_link() {
    local src="$1" dest="$2" dest_dir backup
    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"
    if [ -L "$dest" ]; then
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        # dest may already be the repo file itself, e.g. via a symlinked parent directory.
        if [ "$(realpath "$dest")" = "$(realpath "$src")" ]; then
            echo "$dest already points to $src, leaving it unchanged."
            return
        fi
        backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        echo "Backing up existing $dest to $backup"
        mv "$dest" "$backup"
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

require_dnf() {
    if ! command -v dnf >/dev/null 2>&1; then
        echo "Error: install requires dnf (Fedora, RHEL and its rebuilds); configure works on any system." >&2
        exit 1
    fi
}

verify_sha256() {
    local file="$1" expected="$2"
    if [ -z "$expected" ]; then
        echo "Error: no published checksum found for $(basename "$file")." >&2
        exit 1
    fi
    if ! echo "${expected}  ${file}" | sha256sum -c --quiet -; then
        echo "Error: checksum mismatch for $(basename "$file")." >&2
        exit 1
    fi
}

pipx_install() {
    local package="$1"
    # pipx gives each tool its own virtualenv under $HOME, leaving the system Python untouched.
    sudo dnf install -y pipx
    pipx install "$package"
    pipx ensurepath
}

npm_install() {
    # In a fresh invocation nvm is not loaded, so npm may not be on PATH yet.
    if ! command -v npm >/dev/null 2>&1 && [ -s "$HOME/.nvm/nvm.sh" ]; then
        # nvm.sh references unbound variables, so relax nounset while sourcing it.
        set +u
        # shellcheck disable=SC1091
        \. "$HOME/.nvm/nvm.sh"
        set -u
    fi
    if ! command -v npm >/dev/null 2>&1; then
        echo "Error: npm not found; install the 'nodejs' component first." >&2
        exit 1
    fi
    # nvm installs npm under \$HOME, so global installs need no sudo.
    npm install -g "$@"
}

remind_shell_reload() {
    # A script cannot change its parent shell, so PATH updates need a new shell.
    echo "Open a new shell or run 'source $BASHRC' to apply PATH changes to your current shell."
}

install() {
    local component="$1"
    case "$component" in
        epel)
            # EPEL only exists for RHEL and its rebuilds; Fedora ships these packages already.
            if (. /etc/os-release 2>/dev/null && [ "${ID:-}" = "fedora" ]); then
                echo "Skipping EPEL: not needed on Fedora."
            else
                echo "Installing EPEL via dnf..."
                sudo dnf install -y epel-release
            fi
            ;;
        devtools)
            echo "Installing Development Tools group via dnf..."
            sudo dnf groupinstall -y "Development Tools"
            ;;
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
        black)
            echo "Installing black via pipx..."
            pipx_install black
            ;;
        pylsp)
            echo "Installing pylsp (python-lsp-server) via pipx..."
            pipx_install python-lsp-server
            ;;
        beautysh)
            echo "Installing beautysh via pipx..."
            pipx_install beautysh
            ;;
        ripgrep)
            echo "Installing ripgrep via dnf..."
            sudo dnf install -y ripgrep
            ;;
        clangd)
            echo "Installing clangd + clang-format via dnf..."
            sudo dnf install -y clang-tools-extra
            ;;
        rust)
            echo "Installing rust build dependencies via dnf..."
            sudo dnf install -y cmake gcc make curl clang
            if command -v rustup >/dev/null 2>&1 || [ -x "$HOME/.cargo/bin/rustup" ]; then
                echo "rustup already installed, skipping installer."
            else
                echo "Installing rust via rustup..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            fi
            if [ -f "$HOME/.cargo/env" ]; then
                # shellcheck disable=SC1091
                source "$HOME/.cargo/env"
            fi
            echo "Installing rustfmt and rust-analyzer components via rustup..."
            rustup component add rustfmt rust-analyzer
            ;;
        treesitter)
            echo "Installing tree-sitter CLI via cargo..."
            if ! command -v cargo >/dev/null 2>&1; then
                echo "Error: cargo not found; install the 'rust' component first." >&2
                exit 1
            fi
            cargo install --locked tree-sitter-cli
            ;;
        bear)
            if command -v bear >/dev/null 2>&1 && [[ "$(bear --version 2>/dev/null)" == *"$BEAR_VERSION"* ]]; then
                echo "bear $BEAR_VERSION already installed, skipping."
                return
            fi
            echo "Installing bear from source..."
            if ! command -v cargo >/dev/null 2>&1; then
                echo "Error: cargo not found; install the 'rust' component first." >&2
                exit 1
            fi
            if ! command -v git >/dev/null 2>&1; then
                echo "Error: git not found; install the 'git' component first." >&2
                exit 1
            fi
            local bear_tmp
            bear_tmp=$(mktemp -d)
            CLEANUP_DIRS+=("$bear_tmp")
            # Build in a subshell.
            (
                cd "$bear_tmp"
                git clone --depth 1 --branch "$BEAR_VERSION" https://github.com/rizsotto/Bear.git
                cd Bear
                cargo build --release
                target/release/generate-completions target/release/completions
                sudo PREFIX="$BEAR_PREFIX" ./scripts/install.sh
            )
            rm -rf "$bear_tmp"
            ;;
        neovim)
            local release nvim_tag nvim_sha installed_nvim="" tmp_dir
            release="$(curl -fsSL "$NVIM_RELEASE_API")"
            nvim_tag="$(awk -F'"' '$2 == "tag_name" { print $4; exit }' <<<"$release")"
            # Each release asset lists its "name" followed later by its "digest" (sha256:<hex>).
            nvim_sha="$(awk -F'"' -v name="$NVIM_ARCHIVE" '$2 == "name" && $4 == name { found = 1 } found && $2 == "digest" { sub(/^sha256:/, "", $4); print $4; exit }' <<<"$release")"
            if [ -z "$nvim_tag" ]; then
                echo "Error: failed to determine latest neovim release." >&2
                exit 1
            fi
            if [ -x "$NVIM_INSTALL_DIR/bin/nvim" ]; then
                installed_nvim="$("$NVIM_INSTALL_DIR/bin/nvim" --version)"
                installed_nvim="${installed_nvim%%$'\n'*}"
            fi
            if [ "$installed_nvim" = "NVIM $nvim_tag" ]; then
                echo "neovim $nvim_tag already installed, skipping."
            else
                echo "Installing neovim $nvim_tag from pre-built archive..."
                tmp_dir=$(mktemp -d)
                CLEANUP_DIRS+=("$tmp_dir")
                curl -fL -o "${tmp_dir}/${NVIM_ARCHIVE}" "https://github.com/neovim/neovim/releases/download/${nvim_tag}/${NVIM_ARCHIVE}"
                verify_sha256 "${tmp_dir}/${NVIM_ARCHIVE}" "$nvim_sha"
                sudo rm -rf "$NVIM_INSTALL_DIR"
                sudo tar -C /opt -xzf "${tmp_dir}/${NVIM_ARCHIVE}"
                rm -rf "$tmp_dir"
            fi
            append_once 'export PATH="$PATH:'"$NVIM_INSTALL_DIR"'/bin"' "$BASHRC"
            ;;
        starship)
            echo "Installing starship..."
            curl -fsS https://starship.rs/install.sh | sh -s -- -y
            append_once 'eval "$(starship init bash)"' "$BASHRC"
            ;;
        nodejs)
            if [ -s "$HOME/.nvm/nvm.sh" ]; then
                echo "nvm already installed, skipping installer."
            else
                echo "Installing nvm..."
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash
            fi
            echo "Installing Node.js via nvm..."
            # Load nvm into the current shell (in lieu of restarting it) so the
            # npm-based steps below can run within this same invocation. nvm.sh
            # references unbound variables, so relax nounset while sourcing it.
            set +u
            # shellcheck disable=SC1091
            \. "$HOME/.nvm/nvm.sh"
            nvm install 24
            set -u
            ;;
        bashls)
            echo "Installing bash-language-server via npm..."
            npm_install bash-language-server
            echo "Installing shellcheck via dnf..."
            sudo dnf install -y ShellCheck
            ;;
        typescript)
            echo "Installing typescript tools via npm..."
            npm_install typescript typescript-language-server prettier
            ;;
        golang)
            local go_version_info go_version go_archive go_sha installed_go="" tmp_dir
            go_version_info="$(curl -fsSL "https://go.dev/VERSION?m=text")"
            go_version="${go_version_info%%$'\n'*}"
            if [ -z "$go_version" ]; then
                echo "Error: failed to determine latest Go version." >&2
                exit 1
            fi
            if [ -x "$GO_INSTALL_DIR/bin/go" ]; then
                installed_go="$("$GO_INSTALL_DIR/bin/go" env GOVERSION)"
            fi
            if [ "$installed_go" = "$go_version" ]; then
                echo "Go $go_version already installed, skipping."
            else
                echo "Installing Go $go_version from official release archive..."
                go_archive="${go_version}.linux-${GO_ARCH}.tar.gz"
                go_sha="$(curl -fsSL "https://dl.google.com/go/${go_archive}.sha256")"
                tmp_dir=$(mktemp -d)
                CLEANUP_DIRS+=("$tmp_dir")
                curl -fL -o "${tmp_dir}/${go_archive}" "https://go.dev/dl/${go_archive}"
                verify_sha256 "${tmp_dir}/${go_archive}" "$go_sha"
                sudo rm -rf "$GO_INSTALL_DIR"
                sudo tar -C /usr/local -xzf "${tmp_dir}/${go_archive}"
                rm -rf "$tmp_dir"
            fi
            append_once 'export PATH="'"$GO_INSTALL_DIR"'/bin:$HOME/go/bin:$PATH"' "$BASHRC"
            export PATH="${GO_INSTALL_DIR}/bin:$HOME/go/bin:$PATH"
            echo "Installing gopls via go install..."
            go install golang.org/x/tools/gopls@latest
            ;;
        all)
            install epel
            install devtools
            install tmux
            install vim
            install git
            install python
            install black
            install pylsp
            install beautysh
            install ripgrep
            install clangd
            install rust
            install treesitter
            install bear
            install neovim
            install starship
            install nodejs
            install bashls
            install typescript
            install golang
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
            # Reload the config against the running tmux server, whether or not
            # we are currently inside a tmux session. tmux has-session succeeds
            # only when a server is up, avoiding spawning one just to reload.
            if command -v tmux >/dev/null 2>&1 && tmux has-session 2>/dev/null; then
                tmux source-file "$TMUX_CONFIG_FILE_DEST"
            fi
            ;;
        wezterm)
            safe_link "$WEZTERM_CONFIG_FILE_SRC" "$WEZTERM_CONFIG_FILE_DEST"
            append_once 'export CLICOLOR=1' "$BASHRC"
            ;;
        neovim)
            safe_link "$NVIM_CONFIG_FILE_SRC" "$NVIM_CONFIG_FILE_DEST"
            safe_link "$NVIM_SUB_CONFIG_SRC" "$NVIM_SUB_CONFIG_DEST"
            safe_link "$NVIM_LOCK_FILE_SRC" "$NVIM_LOCK_FILE_DEST"
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
            require_dnf
            for component in "${components[@]}"; do
                install "$component"
            done
            SHELL_RELOAD_NEEDED=1
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
            SHELL_RELOAD_NEEDED=1
            ;;
        all)
            require_dnf
            install all
            configure all
            SHELL_RELOAD_NEEDED=1
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

if [ "$SHELL_RELOAD_NEEDED" -eq 1 ]; then
    remind_shell_reload
fi
