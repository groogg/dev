-- =======================================================================
-- Neovim Config — kickstart-inspired, Python-focused
-- =======================================================================

-- Leader key (must be set before lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- -----------------------------------------------------------------------
-- Options
-- -----------------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.diagnostic.config({ virtual_text = false })
vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  callback = function()
    vim.diagnostic.config({ virtual_text = vim.bo.filetype == "python" })
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    vim.cmd("wincmd =")
  end,
})

-- -----------------------------------------------------------------------
-- Keymaps
-- -----------------------------------------------------------------------
-- General
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>=", "gg=G<C-o>", { desc = "Reindent entire file" })
vim.keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format file (conform)" })

-- Move lines in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Focus left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Focus right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Focus lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Focus upper window" })

-- Terminal
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Diagnostics
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

-- Python
vim.keymap.set("n", "<leader>pr", function()
  vim.cmd("w")
  vim.cmd("vsplit | term uv run " .. vim.fn.expand("%"))
end, { desc = "Run Python file (uv)" })
vim.keymap.set("n", "<leader>pt", function()
  vim.cmd("w")
  vim.cmd("vsplit | term uv run pytest " .. vim.fn.expand("%") .. " -v")
end, { desc = "Pytest current file" })
vim.keymap.set("n", "<leader>pf", function()
  vim.cmd("w")
  local func = vim.fn.search("^\\s*def \\zs\\w\\+", "bnW")
  local name = vim.fn.matchstr(vim.fn.getline(func), "def \\zs\\w\\+")
  vim.cmd("vsplit | term uv run pytest " .. vim.fn.expand("%") .. " -v -k " .. name)
end, { desc = "Pytest current function" })
vim.keymap.set("n", "<leader>pb", function()
  local line = vim.fn.line(".")
  local cur = vim.fn.getline(line)
  if cur:match("breakpoint()") then
    vim.api.nvim_del_current_line()
  else
    local indent = cur:match("^(%s*)")
    vim.fn.append(line - 1, indent .. "breakpoint()")
  end
end, { desc = "Toggle breakpoint()" })

-- -----------------------------------------------------------------------
-- Autocommands
-- -----------------------------------------------------------------------
-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank() end,
})

-- -----------------------------------------------------------------------
-- Auto-load .env from project root
-- -----------------------------------------------------------------------
local env_file = vim.fn.getcwd() .. "/.env"
if vim.fn.filereadable(env_file) == 1 then
  for line in io.lines(env_file) do
    local key, value = line:match("^([%w_]+)%s*=%s*(.+)$")
    if key and not line:match("^%s*#") then
      value = value:gsub("^['\"](.-)['\"]$", "%1")
      vim.env[key] = value
    end
  end
end

-- -----------------------------------------------------------------------
-- Bootstrap lazy.nvim
-- -----------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- -----------------------------------------------------------------------
-- Plugins
-- -----------------------------------------------------------------------
require("lazy").setup({

  -- Colorscheme --------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("tokyonight").setup({ style = "night" })
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Telescope ----------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",

    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "%.git/", "node_modules/", "%.venv/", "__pycache__/", "%.DS_Store" },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
      })
      pcall(require("telescope").load_extension, "fzf")

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Search files" })
      vim.keymap.set("n", "<leader>sF", function()
        builtin.find_files({ hidden = true, no_ignore = true })
      end, { desc = "Search ALL files (incl. ignored)" })
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Search grep" })
      vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
      vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "Search resume" })
      vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Buffers" })
    end,
  },

  -- LSP ----------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          map("gd", require("telescope.builtin").lsp_definitions, "Goto definition")
          map("gr", require("telescope.builtin").lsp_references, "Goto references")
          map("gI", require("telescope.builtin").lsp_implementations, "Goto implementation")
          map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "Document symbols")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("gD", vim.lsp.buf.declaration, "Goto declaration")
        end,
      })

      local capabilities = require("blink.cmp").get_lsp_capabilities()

      require("mason-lspconfig").setup({
        ensure_installed = { "pyright", "ruff" },
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({ capabilities = capabilities })
          end,
          ["pyright"] = function()
            require("lspconfig").pyright.setup({
              capabilities = capabilities,
              settings = {
                python = {
                  pythonPath = vim.fn.getcwd() .. "/.venv/bin/python",
                  analysis = {
                    autoImportCompletions = true,
                    autoSearchPaths = true,
                    useLibraryCodeForTypes = true,
                  },
                },
              },
            })
          end,
        },
      })
    end,
  },

  -- Completion ---------------------------------------------------------
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*",
    opts = {
      keymap = {
        preset = "default",
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      signature = { enabled = true },
    },
  },

  -- Treesitter ---------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = { "python", "lua", "vim", "vimdoc", "markdown", "bash", "json", "yaml", "toml", "sql" },
      highlight = { enable = true },
    },
  },

  -- Formatting ---------------------------------------------------------
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    },
  },

  -- Git signs ----------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
  },

  -- Which-key ---------------------------------------------------------
  {
    "folke/which-key.nvim",
    event = "VimEnter",
    opts = {
      spec = {
        { "<leader>s", group = "Search" },
        { "<leader>d", group = "Document" },
        { "<leader>r", group = "Rename" },
        { "<leader>c", group = "Code" },
        { "<leader>p", group = "Python" },
        { "<leader>9", group = "99 AI", mode = "v" },
        { "<leader>sf", desc = "Search files" },
        { "<leader>sF", desc = "Search ALL files (incl. ignored)" },
        { "<leader>sg", desc = "Search grep" },
        { "<leader>sd", desc = "Search diagnostics" },
        { "<leader>sr", desc = "Search resume" },
        { "<leader><leader>", desc = "Buffers" },
        { "<leader>ds", desc = "Document symbols" },
        { "<leader>rn", desc = "Rename symbol" },
        { "<leader>ca", desc = "Code action" },
      },
    },
  },

  -- Oil — file explorer as a buffer ----------------------------------
  {
    "stevearc/oil.nvim",
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {
      view_options = { show_hidden = true },
    },
  },

  -- Undotree — visual undo history -----------------------------------
  {
    "mbbill/undotree",
    keys = {
      { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle undotree" },
    },
  },

  -- Surround — add/change/delete surrounding chars --------------------
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },

  -- Autopairs — auto-close brackets/quotes ----------------------------
  { "echasnovski/mini.pairs", version = false, event = "VeryLazy", opts = {} },

  -- Statusline ---------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = { theme = "tokyonight" },
      sections = {
        lualine_x = { "encoding", "filetype" },
      },
    },
  },

  -- Flash — jump anywhere on screen -----------------------------------
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
    },
    opts = {},
  },

  -- Multi-cursor -------------------------------------------------------
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      vim.g.VM_maps = {
        ["Add Cursor Down"] = "<M-Down>",
        ["Add Cursor Up"] = "<M-Up>",
      }
    end,
  },

  -- Harpoon — quick file switching -----------------------------------
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon add" })
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon menu" })

      vim.keymap.set("n", "<C-1>", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<C-2>", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<C-3>", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<C-4>", function() harpoon:list():select(4) end)
    end,
  },

  -- 99 — AI assist (ThePrimeagen) -------------------------------------
  {
    "ThePrimeagen/99",
    config = function()
      local _99 = require("99")
      _99.setup({
        provider = _99.Providers.ClaudeCodeProvider,
      })

      vim.keymap.set("v", "<leader>9v", function()
        _99.visual()
      end, { desc = "99: Send to Claude Code" })

      vim.keymap.set("v", "<leader>9s", function()
        _99.stop_all_requests()
      end, { desc = "99: Stop all requests" })
    end,
  },

}, {
  ui = {
    icons = {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
})
