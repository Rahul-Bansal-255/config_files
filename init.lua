-- Neovim Configuration for C/C++ Development
-- Save this file as `~/.config/nvim/init.lua`

------------------------------------------------------------
-- Global Settings
------------------------------------------------------------
vim.g.mapleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.mouse = 'a'
vim.opt.list = false
vim.opt.wrap = true
vim.opt.listchars = {
    space = '⋅', tab = '→ ', trail = '•', eol = '↲',
}
vim.opt.scrolloff = 3
vim.opt.laststatus = 3                                     -- Set how the statusline behaves across splits and windows.

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  float = { show_header = false, source = 'always', border = 'single' },
  severity_sort = true,
})

vim.opt.foldmethod = "indent"
vim.opt.foldenable = false

vim.opt.cursorline = true
vim.opt.cursorcolumn = true

------------------------------------------------------------
-- Plugin Manager Bootstrap
------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

------------------------------------------------------------
-- Plugin Setup
------------------------------------------------------------
require("lazy").setup({
  -- LSP & Completion
  { 'neovim/nvim-lspconfig' },                             -- Quickstart configs for Nvim LSP
  { 'hrsh7th/nvim-cmp' },                                  -- A completion plugin for neovim coded in Lua
  { 'hrsh7th/cmp-nvim-lsp' },                              -- nvim-cmp source for neovim's built-in language server client
  { 'L3MON4D3/LuaSnip' },                                  -- Snippet Engine for Neovim written in Lua

  -- Syntax Highlighting
  { 'nvim-treesitter/nvim-treesitter' },                   -- Nvim Treesitter configurations and abstraction layer
  { 'nvim-treesitter/nvim-treesitter-context' },           -- Show code context
  { "MTDL9/vim-log-highlighting", ft = { "log" } },        -- Syntax highlighting for generic log files in VIM

  -- UI & UX
  { 'nvim-tree/nvim-tree.lua' },                           -- A file explorer tree for neovim written in lua
  { 'nvim-lualine/lualine.nvim' },                         -- Neovim statusline plugin written in lua
  {
      'akinsho/bufferline.nvim',
      dependencies = 'nvim-tree/nvim-web-devicons',
  },                                                       -- A snazzy bufferline for Neovim
  { 'folke/which-key.nvim' },                              -- Show available keybindings in a popup as you type
  { 'windwp/nvim-autopairs' },                             -- Autopairs for neovim written in lua

  -- Git
  { 'lewis6991/gitsigns.nvim' },                           -- Git integration for buffers
  { 'tpope/vim-fugitive' },                                -- fugitive.vim: A Git wrapper so awesome, it should be illegal
  {
      'sindrets/diffview.nvim',
      dependencies = 'nvim-lua/plenary.nvim',
  },                                                       -- Single tabpage interface for easily cycling through diffs

  -- Telescope
  {
      'nvim-telescope/telescope.nvim',
      dependencies = 'nvim-lua/plenary.nvim',
  },                                                       -- Fuzzy finder

  -- Theme
  { 'morhetz/gruvbox' , name = 'gruvbox' },                -- Retro groove color scheme for Vim
  { 'rose-pine/neovim', name = 'rose-pine' },              -- Soho vibes for Neovim

  -- Formatter & Debugger
  { 'mhartington/formatter.nvim' },                        -- Formatter

  -- Renderer
  { 'MeanderingProgrammer/render-markdown.nvim' },         -- Plugin to improve viewing Markdown files in Neovim
})

vim.cmd("colorscheme gruvbox")

------------------------------------------------------------
-- LSP Configuration
------------------------------------------------------------
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Shared `on_attach` logic
local on_attach = function(_, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', "<leader>d", vim.lsp.buf.hover, opts)
  vim.keymap.set('n', "<leader>j", vim.lsp.buf.definition, opts)
  vim.keymap.set('n', '<leader>J', function()
    vim.cmd('tab split')
    vim.lsp.buf.definition()
  end, opts)
end

-- C/C++ setup
lspconfig.clangd.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Python setup
lspconfig.pylsp.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

------------------------------------------------------------
-- Autocompletion
------------------------------------------------------------
local cmp = require('cmp')
require('luasnip.loaders.from_vscode').lazy_load()
require('nvim-autopairs').setup {}

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = { { name = 'nvim_lsp' } },
})

------------------------------------------------------------
-- Treesitter Setup
------------------------------------------------------------
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "c", "cpp", "lua", "python" },
  highlight = { enable = true },
}

require'treesitter-context'.setup{
  enable = false,           -- Enable this plugin (Can be disabled for large files)
  max_lines = 3,            -- How many lines the context window can span
  trim_scope = 'inner',     -- 'inner' or 'outer'
  mode = 'topline',         -- 'cursor', 'topline'
  separator = nil,          -- e.g. nil or '─' to separate context and content
  zindex = 3,               -- The Z-index of the context window
}

vim.keymap.set("n", "<leader>c", function()
  require("treesitter-context").toggle()
end, { noremap = true, silent = true })

------------------------------------------------------------
-- Formatting Setup
------------------------------------------------------------
require('formatter').setup({
  filetype = {
    c = { function() return { exe = "clang-format", args = {}, stdin = true } end },
    cpp = { function() return { exe = "clang-format", args = {}, stdin = true } end }
  }
})
vim.keymap.set("n", "<leader>F", ":Format<CR>", { noremap = true, silent = true })

------------------------------------------------------------
-- UI Enhancements
------------------------------------------------------------
require('lualine').setup {
  sections = {
    lualine_c = {
      function()
        return vim.fn.expand('%:p')  -- absolute path
      end
    },
    lualine_x = {},
    lualine_y = {
      function()
        return string.format("%d/%d", vim.fn.line("."), vim.fn.line("$"))
      end,
    },
    lualine_z = {
      function()
        return string.format("%d/%d", vim.fn.col("."), #vim.fn.getline("."))
      end,
    }
  }
}
require('nvim-tree').setup{
  view = {
    width = 50,
  }
}
require('bufferline').setup {
  options = {
    mode = "tabs",
    separator_style = "slant",
    show_buffer_close_icons = false,
    show_close_icon = false,
    diagnostics = "nvim_lsp",
  }
}
require('which-key').setup()
require('gitsigns').setup({
    current_line_blame = true
})

------------------------------------------------------------
-- Key Mappings
------------------------------------------------------------
-- Tab Management
for i = 0, 9 do
  vim.keymap.set('n', '<leader>t' .. i, function()
    vim.cmd('tabnext ' .. i+1)
  end, { noremap = true, silent = true })
end
vim.keymap.set('n', '<leader>tc', ':tabnew<CR>',     { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tx', ':tabclose<CR>',   { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tl', ':tabnext<CR>',    { noremap = true, silent = true })
vim.keymap.set('n', '<leader>th', ':tabprev<CR>',    { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tH', ':tabmove -1<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tL', ':tabmove +1<CR>', { noremap = true, silent = true })

-- Directional window navigation
vim.keymap.set('n', '<leader>wh', '<C-w>h', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>wj', '<C-w>j', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>wk', '<C-w>k', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>wl', '<C-w>l', { noremap = true, silent = true })

-- File Explorer
vim.keymap.set('n', '<leader>nn', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>nj', function()
  require("nvim-tree.api").tree.find_file({ open = true, focus = true })
end,                                                     { noremap = true, silent = true })

-- Telescope
require('telescope').setup({
  defaults = {
    layout_strategy = "vertical",
    layout_config = {
      vertical = {
        width = 0.9,           -- Width of the window (float or int)
        height = 0.9,          -- Height of the window
        preview_height = 0.4,  -- Height of preview pane (relative to window height)
      },
    },
  },
  pickers = {
    find_files = {
      hidden = true,        -- Show hidden files
      no_ignore = false,    -- Include files ignored by .gitignore
    },
  },
})
vim.keymap.set('n', '<leader>ff', ":Telescope find_files<CR>",  { noremap = true, silent = true })
vim.keymap.set('n', '<leader>fg', ":Telescope live_grep<CR>",   { noremap = true, silent = true })

-- Diagnostics
vim.keymap.set('n', '<leader>e', function()
  vim.diagnostic.open_float(nil, { focus = false })
end,                                                            { noremap = true, silent = true })

-- Git Integration
vim.keymap.set('n', '<leader>gb', ":Gitsigns blame_line<CR>",   { noremap = true, silent = true })
vim.keymap.set('n', '<leader>gd', ':DiffviewOpen<CR>',          { noremap = true, silent = true })
vim.keymap.set('n', '<leader>gh', ':DiffviewFileHistory %<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>gH', ':DiffviewFileHistory<CR>',   { noremap = true, silent = true })

-- Renderer
vim.keymap.set("n", "<leader>rmd", function()
  require("render-markdown").toggle()
end,                                                            { noremap = true, silent = true })

