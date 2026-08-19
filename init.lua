-- Neovim Configuration for C/C++ Development
-- Save this file as `~/.config/nvim/init.lua`

------------------------------------------------------------
-- Global Settings
------------------------------------------------------------
vim.g.mapleader = ' '

vim.opt.number = false
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

vim.o.foldcolumn = '0'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

local games = vim.env.GAMES ~= nil

------------------------------------------------------------
-- Plugin Manager Bootstrap
------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

------------------------------------------------------------
-- Plugin Setup
------------------------------------------------------------
local plugins = {
  -- LSP & Completion
  { 'neovim/nvim-lspconfig' },                             -- Quickstart configs for Nvim LSP
  { 'hrsh7th/nvim-cmp' },                                  -- A completion plugin for neovim coded in Lua
  { 'hrsh7th/cmp-nvim-lsp' },                              -- nvim-cmp source for neovim's built-in language server client
  { 'L3MON4D3/LuaSnip' },                                  -- Snippet Engine for Neovim written in Lua
  { 'mrcjkb/rustaceanvim' },                               -- 🦀 Supercharge your Rust experience in Neovim!

  -- Syntax Highlighting
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
  {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate'
  },                                                       -- Nvim Treesitter configurations and abstraction layer
  { 'nvim-treesitter/nvim-treesitter-context' },           -- Show code context
  { 'andersevenrud/nvim_context_vt' },                     -- Virtual text context for neovim treesitter

  -- Git
  { 'lewis6991/gitsigns.nvim' },                           -- Git integration for buffers
  { 'tpope/vim-fugitive' },                                -- fugitive.vim: A Git wrapper so awesome, it should be illegal
  {
      'sindrets/diffview.nvim',
      dependencies = 'nvim-lua/plenary.nvim',
  },                                                       -- Single tabpage interface for easily cycling through diffs

  -- Search
  {
      'nvim-telescope/telescope.nvim',
      dependencies = 'nvim-lua/plenary.nvim',
  },                                                       -- Fuzzy finder
  { "chrisgrieser/nvim-rip-substitute" },                  -- Search & replace
  {
      'kevinhwang91/nvim-ufo',
      dependencies = 'kevinhwang91/promise-async'
  },                                                       -- Not UFO in the sky, but an ultra fold in Neovim.

  -- Theme
  { 'morhetz/gruvbox' , name = 'gruvbox' },                -- Retro groove color scheme for Vim
  { 'rose-pine/neovim', name = 'rose-pine' },              -- Soho vibes for Neovim

  -- Formatter & Debugger
  { "stevearc/conform.nvim" },                             -- Lightweight yet powerful formatter plugin for Neovim

  -- Renderer
  { 'MeanderingProgrammer/render-markdown.nvim' },         -- Plugin to improve viewing Markdown files in Neovim
}

if games then
  table.insert(plugins, { 'seandewar/killersheep.nvim' })            -- Neovim port of killersheep (with blood!)
  table.insert(plugins, { 'seandewar/nvimesweeper' })                -- Play Minesweeper in your favourite text editor
end

require("lazy").setup(plugins)

vim.cmd("colorscheme gruvbox")

------------------------------------------------------------
-- LSP Configuration
------------------------------------------------------------
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Shared `on_attach` logic
local on_attach = function(_, bufnr)
  vim.keymap.set('n', "<leader>d", vim.lsp.buf.hover,       { noremap = true, silent = true, buffer = bufnr, desc = "Show documentation float" })
  vim.keymap.set('n', "<leader>j", vim.lsp.buf.definition,  { noremap = true, silent = true, buffer = bufnr, desc = "Go to definition" })
  vim.keymap.set('n', '<leader>J', function()
    vim.cmd('tab split')
    vim.lsp.buf.definition()
  end,                                                      { noremap = true, silent = true, buffer = bufnr, desc = "Go to definition in new tab" })
  vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename,        { noremap = true, silent = true, buffer = bufnr, desc = "Rename symbol" })
  vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action,   { noremap = true, silent = true, buffer = bufnr, desc = "Code action" })
  vim.keymap.set('n', '<leader>lR', vim.lsp.buf.references,    { noremap = true, silent = true, buffer = bufnr, desc = "Show references" })
end

-- C/C++ setup
vim.lsp.config['clangd'] = {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp' },
  on_attach = on_attach,
  capabilities = capabilities,
}
vim.lsp.enable('clangd')

-- Python setup
vim.lsp.config['pylsp'] = {
  cmd = { 'pylsp' },
  filetypes = { 'python' },
  on_attach = on_attach,
  capabilities = capabilities,
}
vim.lsp.enable('pylsp')

-- Rust setup
vim.g.rustaceanvim = {
  server = {
    on_attach = on_attach,
    capabilities = capabilities,
--     settings = {
--       ["rust-analyzer"] = {
--         cargo = {
--           allFeatures = false,       -- reduce feature explosion
--           runBuildScripts = false,   -- skip build.rs
--         },
--         procMacro = {
--           enable = false,            -- disable macros (huge speed gain)
--         },
--         checkOnSave = {
--           command = "check",         -- fastest option
--         },
--       },
--     },
  },
}
-- vim.lsp.config['rust_analyzer'] = {
--   cmd = { 'rust-analyzer' },
--   filetypes = { 'rust' },
--   root_markers = { 'Cargo.toml', '.git' },
--   on_attach = on_attach,
--   capabilities = capabilities,
-- }
-- vim.lsp.enable('rust_analyzer')

------------------------------------------------------------
-- Autocompletion
------------------------------------------------------------
local cmp = require('cmp')
require('luasnip.loaders.from_vscode').lazy_load()
require('nvim-autopairs').setup {}
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

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
    ['<C-e>'] = cmp.mapping.abort(),
  }),
  sources = { { name = 'nvim_lsp' } },
})

------------------------------------------------------------
-- Formatting Setup
------------------------------------------------------------
require("conform").setup({
  formatters_by_ft = {
    c = { "clang_format" },
    cpp = { "clang_format" },
    rust = { "rustfmt" },
  },
})
vim.keymap.set({ "n", "v" }, "<leader>F", function()
  require("conform").format({
    lsp_format = "fallback",
    async = false,
    timeout_ms = 3000,
  })
end, { desc = "Format file" })

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
require("nvim-treesitter.config").setup({
  ensure_installed = { "c", "cpp", "python", "rust" },
  highlight = { enable = true },
  indent = { enable = true },
})
require("treesitter-context").setup({
  enable = false,
  max_lines = 0,
  min_window_height = 0,
  line_numbers = true,
  multiline_threshold = 15,
  trim_scope = 'outer',
  mode = 'cursor',
  separator = nil,
})
require('nvim_context_vt').setup({
  enabled = false,
  disable_ft = { 'markdown' },
})
require('render-markdown').setup({})

------------------------------------------------------------
-- Key Mappings
------------------------------------------------------------
-- Tab Management
for i = 0, 9 do
  vim.keymap.set('n', '<leader>t' .. i, function()
    vim.cmd('tabnext ' .. i+1)
  end, { noremap = true, silent = true, desc = "Go to tab " .. (i) })
end
vim.keymap.set('n', '<leader>tc', ':tabnew<CR>',     { noremap = true, silent = true, desc = "Create new tab" })
vim.keymap.set('n', '<leader>tx', ':tabclose<CR>',   { noremap = true, silent = true, desc = "Close current tab" })
vim.keymap.set('n', '<leader>tl', ':tabnext<CR>',    { noremap = true, silent = true, desc = "Go to next tab" })
vim.keymap.set('n', '<leader>th', ':tabprev<CR>',    { noremap = true, silent = true, desc = "Go to previous tab" })
vim.keymap.set('n', '<leader>tH', ':tabmove -1<CR>', { noremap = true, silent = true, desc = "Move tab left" })
vim.keymap.set('n', '<leader>tL', ':tabmove +1<CR>', { noremap = true, silent = true, desc = "Move tab right" })

-- Directional window navigation
vim.keymap.set('n', '<leader>wh', '<C-w>h',      { noremap = true, silent = true, desc = "Move to left window" })
vim.keymap.set('n', '<leader>wj', '<C-w>j',      { noremap = true, silent = true, desc = "Move to window below" })
vim.keymap.set('n', '<leader>wk', '<C-w>k',      { noremap = true, silent = true, desc = "Move to window above" })
vim.keymap.set('n', '<leader>wl', '<C-w>l',      { noremap = true, silent = true, desc = "Move to right window" })
vim.keymap.set('n', '<leader>w|', ':vsplit<CR>', { noremap = true, silent = true, desc = "Create vertical window split" })
vim.keymap.set('n', '<leader>w-', ':split<CR>',  { noremap = true, silent = true, desc = "Create horizontal window split" })
vim.keymap.set('n', '<leader>wx', ':close<CR>',  { noremap = true, silent = true, desc = "Close current window" })

-- File Explorer
vim.keymap.set('n', '<leader>nn', ':NvimTreeToggle<CR>', { noremap = true, silent = true, desc = "Toggle file explorer" })
vim.keymap.set('n', '<leader>nj', function()
  require("nvim-tree.api").tree.find_file({ open = true, focus = true })
end,                                                     { noremap = true, silent = true, desc = "Reveal current file in explorer" })

-- Search
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
vim.keymap.set('n', '<leader>ff', ":Telescope find_files<CR>",  { noremap = true, silent = true, desc = "Find files" })
vim.keymap.set('n', '<leader>fg', ":Telescope live_grep<CR>",   { noremap = true, silent = true, desc = "Live grep" })
vim.keymap.set('n', '<leader>fd', ":Telescope diagnostics<CR>", { noremap = true, silent = true, desc = "Show diagnostics" })
require("rip-substitute").setup({})
vim.keymap.set( { "n", "x" }, "<leader>fs",
  function()
    require("rip-substitute").sub()
  end,                                                          { noremap = true, silent = true, desc = "Search and replace" })
require('ufo').setup({
    provider_selector = function(bufnr, filetype, buftype)
        return {'treesitter', 'indent'}
    end
})
vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
vim.keymap.set('n', 'zp', require('ufo').peekFoldedLinesUnderCursor, { desc = 'Peek fold' })

-- Diagnostics
vim.keymap.set('n', '<leader>e', function()
  vim.diagnostic.open_float(nil, { focus = false })
end,                                                            { noremap = true, silent = true, desc = "Show diagnostics float" })

-- Git Integration
vim.keymap.set('n', '<leader>gb', ":Gitsigns blame_line<CR>",   { noremap = true, silent = true, desc = "Git blame current line" })
vim.keymap.set('n', '<leader>gd', ':DiffviewOpen<CR>',          { noremap = true, silent = true, desc = "Open diff view" })
vim.keymap.set('n', '<leader>gh', ':DiffviewFileHistory %<CR>', { noremap = true, silent = true, desc = "Show current file git history" })
vim.keymap.set('n', '<leader>gH', ':DiffviewFileHistory<CR>',   { noremap = true, silent = true, desc = "Show repo git history" })

-- Renderer
vim.keymap.set("n", "<leader>rmd", function()
  require("render-markdown").toggle()
end,                                                            { noremap = true, silent = true, desc = "Toggle markdown rendering" })

-- Treesitter Context
vim.keymap.set("n", "<leader>c", function()
    require("treesitter-context").toggle()
end,                                                            { noremap = true, silent = true, desc = "Toggle context" })

-- Treesitter Virtual Text
vim.keymap.set('n', '<leader>v', ':NvimContextVtToggle<CR>',    { noremap = true, silent = true, desc = "Toggle virtual text" })

------------------------------------------------------------
-- Games Configuration
------------------------------------------------------------
if games then
  require("games")
end

