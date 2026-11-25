# config_files
 Configuration files for different tools like vim and tmux

## Files

| File | Linked to | Purpose |
|---|---|---|
| `init.lua`, `lua/` | `~/.config/nvim/` | Neovim config (plugins via lazy.nvim) |
| `lazy-lock.json` | `~/.config/nvim/lazy-lock.json` | Pinned Neovim plugin versions |
| `.vimrc` | `~/.vimrc` | Plain Vim config, no plugins |
| `.tmux.conf` | `~/.tmux.conf` | tmux config |
| `.wezterm.lua` | `~/.wezterm.lua` | WezTerm config |
| `starship.toml` | `~/.config/starship.toml` | Starship prompt |
| `deploy.sh` | | Installs tools and links the files above |

## Usage

```bash
./deploy.sh help                       # list all components
./deploy.sh all                        # install and configure everything
./deploy.sh install tmux git           # install selected tools
./deploy.sh configure neovim tmux      # link selected configs
```

- `install` needs dnf (Fedora, RHEL and its rebuilds). `configure` works on any system, including macOS.
- `configure` backs up an existing file to `<name>.bak.<timestamp>` before linking.
- After running, open a new shell (or `source ~/.bashrc`) to pick up PATH changes.
- Set `GAMES=1` before starting Neovim to load the game plugins.

