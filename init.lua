-- Neovim Configuration for Systems Programming
-- Save this file as `~/.config/nvim/init.lua`

------------------------------------------------------------
-- Global Settings
------------------------------------------------------------
vim.g.mapleader = ' '

-- nvim-tree replaces netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local function map(mode, lhs, rhs, desc, bufnr)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc, buffer = bufnr })
end

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
  float = { show_header = false, source = true, border = 'single' },
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

  -- Formatter & Debugger
  { "stevearc/conform.nvim" },                             -- Lightweight yet powerful formatter plugin for Neovim

  -- Renderer
  { 'MeanderingProgrammer/render-markdown.nvim' },         -- Plugin to improve viewing Markdown files in Neovim
}

if games then
  table.insert(plugins, { 'seandewar/killersheep.nvim' })            -- Neovim port of killersheep (with blood!)
  table.insert(plugins, { 'Rahul-Bansal-255/nvimesweeper' })         -- Play Minesweeper in your favourite text editor
end

require("lazy").setup(plugins)

vim.cmd("colorscheme gruvbox")

------------------------------------------------------------
-- LSP Configuration
------------------------------------------------------------
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Server commands, filetypes and root markers come from nvim-lspconfig
vim.lsp.config('*', { capabilities = capabilities })
vim.lsp.config('clangd', { filetypes = { 'c', 'cpp' } })
vim.lsp.config('ts_ls', { filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' } })
vim.lsp.enable({ 'clangd', 'pylsp', 'ts_ls', 'bashls', 'gopls' })

-- Rust setup
vim.g.rustaceanvim = {
  server = {
    capabilities = capabilities,
  },
}

-- Keymaps for every LSP client, including rust-analyzer
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    map('n', '<leader>d', vim.lsp.buf.hover, "Show documentation float", bufnr)
    map('n', '<leader>j', vim.lsp.buf.definition, "Go to definition", bufnr)
    map('n', '<leader>J', function()
      vim.cmd('tab split')
      vim.lsp.buf.definition()
    end, "Go to definition in new tab", bufnr)
    map('n', '<leader>lr', vim.lsp.buf.rename, "Rename symbol", bufnr)
    map('n', '<leader>la', vim.lsp.buf.code_action, "Code action", bufnr)
    map('n', '<leader>lR', vim.lsp.buf.references, "Show references", bufnr)
  end,
})

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
    go = { "gofmt" },
    python = { "black" },
    rust = { "rustfmt" },
    sh = { "beautysh" },
    bash = { "beautysh" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
  },
})
map({ "n", "v" }, "<leader>F", function()
  require("conform").format({
    lsp_format = "fallback",
    async = false,
    timeout_ms = 3000,
  })
end, "Format file")

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
-- Building parsers needs the tree-sitter CLI (`deploy.sh install treesitter`)
if vim.fn.executable("tree-sitter") == 1 then
  require("nvim-treesitter").install({ "c", "cpp", "go", "gomod", "gosum", "gowork", "python", "rust", "bash", "javascript", "typescript", "tsx", "json" })
end
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
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
  map('n', '<leader>t' .. i, function()
    vim.cmd('tabnext ' .. i+1)
  end, "Go to tab " .. (i))
end
map('n', '<leader>tc', ':tabnew<CR>',     "Create new tab")
map('n', '<leader>tx', ':tabclose<CR>',   "Close current tab")
map('n', '<leader>tl', ':tabnext<CR>',    "Go to next tab")
map('n', '<leader>th', ':tabprev<CR>',    "Go to previous tab")
map('n', '<leader>tH', ':tabmove -1<CR>', "Move tab left")
map('n', '<leader>tL', ':tabmove +1<CR>', "Move tab right")

-- Directional window navigation
map('n', '<leader>wh', '<C-w>h',      "Move to left window")
map('n', '<leader>wj', '<C-w>j',      "Move to window below")
map('n', '<leader>wk', '<C-w>k',      "Move to window above")
map('n', '<leader>wl', '<C-w>l',      "Move to right window")
map('n', '<leader>w|', ':vsplit<CR>', "Create vertical window split")
map('n', '<leader>w-', ':split<CR>',  "Create horizontal window split")
map('n', '<leader>wx', ':close<CR>',  "Close current window")

-- File Explorer
map('n', '<leader>nn', ':NvimTreeToggle<CR>', "Toggle file explorer")
map('n', '<leader>nj', function()
  require("nvim-tree.api").tree.find_file({ open = true, focus = true })
end, "Reveal current file in explorer")

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
      no_ignore = false,    -- Exclude files ignored by .gitignore
    },
  },
})
map('n', '<leader>ff', ":Telescope find_files<CR>",  "Find files")
map('n', '<leader>fg', ":Telescope live_grep<CR>",   "Live grep")
map('n', '<leader>fd', ":Telescope diagnostics<CR>", "Show diagnostics")

require("rip-substitute").setup({})
map({ "n", "x" }, "<leader>fs", function()
  require("rip-substitute").sub()
end, "Search and replace")

map('n', '<leader>fl', function()
  require('line_history').show()
end, "Telescope current line git history")

require('ufo').setup({
    provider_selector = function(bufnr, filetype, buftype)
        return {'treesitter', 'indent'}
    end
})
map('n', 'zR', require('ufo').openAllFolds, 'Open all folds')
map('n', 'zM', require('ufo').closeAllFolds, 'Close all folds')
map('n', 'zp', require('ufo').peekFoldedLinesUnderCursor, 'Peek fold')

-- Diagnostics
map('n', '<leader>e', function()
  vim.diagnostic.open_float(nil, { focus = false })
end, "Show diagnostics float")

-- Git Integration
map('n', '<leader>gb', ":Gitsigns blame_line<CR>",    "Git blame current line")
map('n', '<leader>gd', ':DiffviewOpen<CR>',           "Open diff view")
map('n', '<leader>gl', ':.,.DiffviewFileHistory<CR>', "Show current line git history")
map('n', '<leader>gf', ':DiffviewFileHistory %<CR>',  "Show current file git history")
map('n', '<leader>gh', ':DiffviewFileHistory<CR>',    "Show repo git history")

-- Renderer
map("n", "<leader>rmd", function()
  require("render-markdown").toggle()
end, "Toggle markdown rendering")

-- Treesitter Context
map("n", "<leader>c", function()
  require("treesitter-context").toggle()
end, "Toggle context")

-- Treesitter Virtual Text
map('n', '<leader>v', ':NvimContextVtToggle<CR>', "Toggle virtual text")

------------------------------------------------------------
-- Games Configuration
------------------------------------------------------------
if games then
  require("games")
end

