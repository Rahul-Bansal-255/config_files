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
vim.opt.list = true
vim.opt.wrap = true
vim.opt.listchars = { space = '⋅', tab = '→ ', trail = '•', eol = '↲' }
vim.opt.scrolloff = 3

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  float = { show_header = false, source = 'always', border = 'single' },
  severity_sort = true,
})

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
  {
      'nvim-treesitter/nvim-treesitter',
      build = ":TSUpdate",
  },                                                       -- Nvim Treesitter configurations and abstraction layer
  { 'nvim-treesitter/nvim-treesitter-context' },           -- Show code context

  -- UI & UX
  { 'nvim-tree/nvim-tree.lua' },                           -- A file explorer tree for neovim written in lua
  { 'nvim-lualine/lualine.nvim' },                         -- Neovim statusline plugin written in lua
  {
      'akinsho/bufferline.nvim',
      version = "*",
      dependencies = 'nvim-tree/nvim-web-devicons',
  },                                                       -- A snazzy bufferline for Neovim
  { 'folke/which-key.nvim' },                              -- Show available keybindings in a popup as you type
  { 'windwp/nvim-autopairs' },                             -- Autopairs for neovim written in lua

  -- Git
  { 'lewis6991/gitsigns.nvim' },                           -- Git integration for buffers
  { 'tpope/vim-fugitive' },                                -- fugitive.vim: A Git wrapper so awesome, it should be illegal
  {
      'NeogitOrg/neogit',
      dependencies = 'nvim-lua/plenary.nvim',
  },                                                       -- Git interface for Neovim inspired by Magit
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
  { 'morhetz/gruvbox' },                                   -- Retro groove color scheme for Vim

  -- Formatter & Debugger
  { 'mhartington/formatter.nvim' },                        -- Formatter
  { 'mfussenegger/nvim-dap' },                             -- Debug Adapter Protocol client implementation for Neovim
  { 'rcarriga/nvim-dap-ui' },                              -- A UI for nvim-dap

  -- Renderer
  { 'MeanderingProgrammer/render-markdown.nvim' },         -- Plugin to improve viewing Markdown files in Neovim
})

vim.cmd("colorscheme gruvbox")

------------------------------------------------------------
-- LSP Configuration
------------------------------------------------------------
local lspconfig = require('lspconfig')
lspconfig.clangd.setup({
  on_attach = function(_, bufnr)
    local opts = { noremap=true, silent=true, buffer=bufnr }
    vim.keymap.set('n', "<leader>j", vim.lsp.buf.definition, opts)
    vim.keymap.set('n', "<leader>d", vim.lsp.buf.hover, opts)
  end,
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
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
  ensure_installed = { "c", "cpp", "lua" },
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
end, { desc = "Toggle Treesitter Context" })

------------------------------------------------------------
-- Formatting Setup
------------------------------------------------------------
require('formatter').setup({
  filetype = {
    c = { function() return { exe = "clang-format", args = {}, stdin = true } end },
    cpp = { function() return { exe = "clang-format", args = {}, stdin = true } end }
  }
})
vim.keymap.set("n", "<leader>F", ":Format<CR>", { noremap = true })

------------------------------------------------------------
-- Debugging Setup
------------------------------------------------------------
local dap = require('dap')
dap.adapters.cppdbg = {
  id = 'cppdbg',
  type = 'executable',
  command = '/absolute/path/to/OpenDebugAD7',
}
dap.configurations.c = {
  {
    name = "Launch C Program",
    type = "cppdbg",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopAtEntry = true,
  }
}
dap.configurations.cpp = dap.configurations.c

vim.keymap.set('n', '<F5>', ":lua require'dap'.continue()<CR>")
vim.keymap.set('n', '<F10>', ":lua require'dap'.step_over()<CR>")
vim.keymap.set('n', '<F11>', ":lua require'dap'.step_into()<CR>")
vim.keymap.set('n', '<F12>', ":lua require'dap'.step_out()<CR>")
vim.keymap.set('n', '<leader>b', ":lua require'dap'.toggle_breakpoint()<CR>")

------------------------------------------------------------
-- UI Enhancements
------------------------------------------------------------
require('lualine').setup()
require('nvim-tree').setup()
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
require('gitsigns').setup()

------------------------------------------------------------
-- Key Mappings
------------------------------------------------------------
-- Tab Management
for i = 1, 9 do
  vim.keymap.set('n', '<leader>t' .. i, function()
    vim.cmd('tabnext ' .. i)
  end, { noremap = true, silent = true })
end
vim.keymap.set('n', '<leader>tn', ':tabnew<CR>', { noremap = true })
vim.keymap.set('n', '<leader>tc', ':tabclose<CR>', { noremap = true })
vim.keymap.set('n', '<leader>tl', ':tabnext<CR>', { noremap = true })
vim.keymap.set('n', '<leader>th', ':tabprev<CR>', { noremap = true })

-- File Explorer
vim.keymap.set('n', '<leader>nn', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>nj', function()
  require("nvim-tree.api").tree.find_file({ open = true, focus = true })
end, { desc = "Reveal current file in NvimTree" })

-- Telescope
require('telescope').setup()
vim.keymap.set('n', '<leader>ff', ":Telescope find_files<CR>")
vim.keymap.set('n', '<leader>fg', ":Telescope live_grep<CR>")
vim.keymap.set('n', '<leader>fh', ":Telescope command_history<CR>")
vim.keymap.set('n', '<leader>fd', ":Telescope diagnostics<CR>")

-- Diagnostics
vim.keymap.set('n', '<leader>e', function()
  vim.diagnostic.open_float(nil, { focus = false })
end)

-- Git Integration
require('neogit').setup()
vim.keymap.set('n', '<leader>gs', ':Neogit<CR>', { desc = "Neogit Status" })
vim.keymap.set('n', '<leader>gl', '<cmd>tab Git log --oneline --graph --decorate --all<cr>', { desc = "Git Log Tree" })
vim.keymap.set('n', '<leader>gd', ':DiffviewOpen<CR>', { desc = "Diff View" })
vim.keymap.set('n', '<leader>gf', ':DiffviewFileHistory<CR>', { desc = "File History Tree" })
vim.keymap.set('n', '<leader>gb', ":Gitsigns blame_line<CR>", { noremap = true, silent = true, desc = "Git Blame Line" })

-- Renderer
vim.keymap.set("n", "<leader>rmd", function()
  require("render-markdown").toggle()
end, { desc = "Toggle Markdown Render" })

