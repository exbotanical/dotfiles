local M = {}

local opts = {
  mode = "n",
  prefix = "<leader>",
  buffer = nil,
  silent = true,
  noremap = true,
  nowait = true,
}

local vopts = {
  mode = "v",
  prefix = "<leader>",
  buffer = nil,
  silent = false,
  noremap = true,
  nowait = true,
}

local xopts = {
  mode = "x",
  prefix = "<leader>",
  buffer = nil,
  silent = true,
  noremap = true,
  nowait = true,
}

local mappings = {
  ["w"] = { "<Cmd>w!<Cr>", "Save" },
  ["q"] = { "<Cmd>q!<Cr>", "Quit" },

  -- System
  ["z"] = {
    name = "System",
    b = {
      "<Cmd>hi Normal ctermbg=none guibg=none<CR>",
      "Transparent background",
    },
    s = { ":<C-u>SaveSession<Cr>", "Save session" },
    l = { ":<C-u>SearchSession<Cr>", "Load session" },
    c = { "<Cmd>Telescope colorscheme<Cr>", "Color scheme" },
    h = { "<Cmd>ToggleTerm<CR>", "New horizontal terminal" },
    t = { "<Cmd>terminal<CR>", "New terminal" },
    e = { "!!$SHELL<CR>", "Execute line" },
    z = {
      "<Cmd>lua require('config.telescope').search_dotfiles()<CR>",
      "Configuration",
    },
    r = { "<Cmd>luafile %<Cr>", "Reload lua file" },
    m = { "<Cmd>messages<Cr>", "Messages" },
    p = { "<Cmd>messages clear<Cr>", "Clear messages" },
    f = { "<Cmd>FloatermNew<Cr>", "Floating terminal" },
    i = { "<Cmd>PackerUpdate<Cr>", "Packer update" },
    y = { "<Cmd>Telescope neoclip<Cr>", "Clipboard manager" },
    x = { "<Cmd>Telescope bookmarks<Cr>", "Browser bookmarks" },
  },

  -- Buffer
  b = {
    name = "Buffer",
    a = { "<Cmd>BWipeout other<Cr>", "Delete all buffers" },
    d = { "<Cmd>bd<Cr>", "Delete current buffer" },
    l = { "<Cmd>ls<Cr>", "List buffers" },
    n = { "<Cmd>bn<Cr>", "Next buffer" },
    p = { "<Cmd>bp<Cr>", "Previous buffer" },
    f = { "<Cmd>bd!<Cr>", "Force delete current buffer" },
  },

  -- Jump
  j = {
    name = "Jump",
    a = { "<Cmd>lua require('harpoon.mark').add_file()<Cr>", "Add" },
    m = { "<Cmd>lua require('harpoon.ui').toggle_quick_menu()<Cr>", "Menu" },
    c = { "<Cmd>lua require('harpoon.cmd-ui').toggle_quick_menu()<Cr>", "Menu" },
  },
  ["1"] = { "<Cmd>lua require('harpoon.ui').nav_file(1) <Cr>", "Jump 1" },
  ["2"] = { "<Cmd>lua require('harpoon.ui').nav_file(2) <Cr>", "Jump 2" },
  ["3"] = { "<Cmd>lua require('harpoon.ui').nav_file(3) <Cr>", "Jump 3" },
  ["4"] = { "<Cmd>lua require('harpoon.term').gotoTerminal(1)<Cr>", "Terminal" },
  ["5"] = { "<Cmd>lua require('harpoon.term').sendCommand(1,1)<Cr>", "Command 1" },
  ["6"] = { "<Cmd>lua require('harpoon.term').sendCommand(1,2)<Cr>", "Command 2" },

  -- Quick fix
  c = {
    name = "Quickfix",
    o = { "<Cmd>copen<Cr>", "Open quickfix" },
    c = { "<Cmd>cclose<Cr>", "Close quickfix" },
    n = { "<Cmd>cnext<Cr>", "Next quickfix" },
    p = { "<Cmd>cprev<Cr>", "Previous quickfix" },
    x = { "<Cmd>cex []<Cr>", "Clear quickfix" },
    t = { "<Cmd>BqfAutoToggle<Cr>", "Toggle preview" },
  },

  -- File
  f = {
    name = "File",
    b = { "<Cmd>Telescope buffers<Cr>", "Search buffers" },
    c = { "<Cmd>Telescope current_buffer_fuzzy_find<Cr>", "Search current buffer" },
    f = { "<Cmd>Telescope git_files<Cr>", "Git files" },
    g = { "<Cmd>Telescope live_grep<Cr>", "Live grep" },
    h = { "<Cmd>Telescope help_tags<Cr>", "Help" },
    p = { "<Cmd>Telescope file_browser<Cr>", "Pop-up file browser" },
    o = { "<Cmd>Telescope oldfiles<Cr>", "Old files" },
    m = { "<Cmd>Telescope marks<Cr>", "Mark" },
    n = { "<Cmd>ene <BAR> startinsert <Cr>", "New file" },
    r = { "<Cmd>Telescope frecency<Cr>", "Recent file" },
    s = { "<Cmd>Telescope symbols<Cr>", "Symbols" },
    a = { "<Cmd>xa<Cr>", "Save all & quit" },
    e = { "<Cmd>NvimTreeToggle<CR>", "Explorer" },
    z = { "<Cmd>lefta 20vsp ~/repositories<CR>", "Netrw" },
    v = { "<Cmd>Telescope media_files<CR>", "View media files" },
    t = { "<Cmd>Telescope<CR>", "Telescope" },
    l = { "<Cmd>e!<CR>", "Reload file" },
    j = { "<Cmd>Telescope zoxide list<CR>", "Jump to folder" },
  },

  -- Git
  g = {
    name = "Source code",
    a = { "<Cmd>Telescope repo list<Cr>", "All repositories" },
    s = { "<Cmd>Git<Cr>", "Git status" },
    p = { "<Cmd>Git push<Cr>", "Git push" },
    b = { "<Cmd>Git branch<Cr>", "Git branch" },
    d = { "<Cmd>Gvdiffsplit<Cr>", "Git diff" },
    f = { "<Cmd>Git fetch --all<Cr>", "Git fetch" },
    m = { "<Cmd>GitMessenger<Cr>", "Git messenger" },
    n = { "<Cmd>Neogit<Cr>", "NeoGit" },
    v = { "<Cmd>DiffviewOpen<Cr>", "Diffview open" },
    c = { "<Cmd>DiffviewClose<Cr>", "Diffview close" },
    h = { "<Cmd>DiffviewFileHistory<Cr>", "File history" },
    ["r"] = {
      name = "Rebase",
      u = {
        "<Cmd>Git rebase upstream/master<Cr>",
        "Git rebase upstream/master",
      },
      o = {
        "<Cmd>Git rebase origin/master<Cr>",
        "Git rebase origin/master",
      },
    },
    x = {
      name = "Diff",
      ["2"] = { "<Cmd>diffget //2", "Diffget 2" },
      ["3"] = { "<Cmd>diffget //3", "Diffget 3" },
    },
    g = {
      "<Cmd>DogeGenerate<Cr>",
      "Generate doc",
    },
    y = { name = "Git URL" },
  },

  -- Project
  p = {
    name = "Project",
    s = {
      "<Cmd>lua require('config.telescope').switch_projects()<CR>",
      "Search files",
    },
    p = {
      "<Cmd>lua require('telescope').extensions.project.project({})<Cr>",
      "List projects",
    },
    r = {
      "<Cmd>Telescope projects<Cr>",
      "Recent projects",
    },
  },

  -- Easymotion
  ["<Space>"] = { name = "Easymotion" },

  -- Search
  ["s"] = {
    name = "Search",
    w = {
      "<Cmd>lua require('telescope').extensions.arecibo.websearch()<CR>",
      "Web search",
    },
    s = { "<Cmd>lua require('spectre').open()<CR>", "Search file" },
    z = { "<Plug>SearchNormal", "Browser search" },
    v = {
      "<Cmd>lua require('spectre').open_visual({select_word=true})<CR>",
      "Visual search",
    },
    f = {
      "viw:lua require('spectre').open_file_search()<Cr>",
      "Open file search",
    },
    c = { "q:", "Command history" },
    g = { "q/", "Grep history" },
    l = { "<Cmd>lua require('utils.cheatsheet').cheatsheet()<CR>", "Search code" },
    o = { "<Cmd>SymbolsOutline<CR>", "Symbols Outline" },
    b = { "<Cmd>Telescope current_buffer_fuzzy_find<CR>", "Fuzzy find buffer" },
  },

  -- Run
  r = {
    name = "Run",
    x = "Swap next parameter",
    X = "Swap previous parameter",
    s = { "<Cmd>SnipRun<CR>", "Run snippets" },
  },

  -- Git signs
  h = {
    name = "Git signs",
    b = "Blame line",
    p = "Preview hunk",
    R = "Reset buffer",
    r = "Reset buffer",
    s = "Stage hunk",
    S = "Stage buffer",
    u = "Undo stage hunk",
    U = "Reset buffer index",
  },

  -- Notes
  n = {
    name = "Notes",
    n = {
      "<Cmd>FloatermNew nvim ~/Documents/notes/<Cr>",
      "New note",
    },
    o = { "<Cmd>GkeepOpen<Cr>", "GKeep Open" },
    c = { "<Cmd>GkeepClose<Cr>", "GKeep Close" },
    r = { "<Cmd>GkeepRefresh<Cr>", "GKeep Refresh" },
    s = { "<Cmd>GkeepSync<Cr>", "GKeep Sync" },
    p = { "<Cmd>MarkdownPreview<Cr>", "Preview markdown" },
    z = { "<Cmd>ZenMode<Cr>", "Zen Mode" },
    h = { "<Cmd>Twilight<Cr>", "Twilight" },
    g = { "<Cmd>GrammarousCheck<Cr>", "Grammar check" },
  },

  -- Database
  x = {
    name = "Database",
    u = { "<Cmd>DBUIToggle<Cr>", "Toggle UI" },
    f = { "<Cmd>DBUIFindBuffer<Cr>", "Find buffer" },
    r = { "<Cmd>DBUIRenameBuffer<Cr>", "Rename buffer" },
    q = { "<Cmd>DBUILastQueryInfo<Cr>", "Last query info" },
  },

  -- Viewer
  v = {
    name = "View",
    v = { "<Cmd>vsplit term://vd <cfile><CR>", "VisiData" },
  },
}

local vmappings = {
  s = {
    name = "Search",
    v = { "<Cmd>lua require('spectre').open_visual()<CR>", "Visual search" },
    b = { "<Plug>SearchVisual", "Browser search" },
  },
  h = { name = "Git signs" },
  r = {
    name = "Run",
    s = { "<Cmd>lua require'sniprun'.run('v')<CR>", "Run snippets" },
    r = { "<Esc><Cmd>lua require('telescope').extensions.refactoring.refactors()<CR>", "Refactor" },
  },
  g = {
    name = "Source code",
    y = { name = "Git URL" },
  },
  b = {
    name = "Buffer",
    h = { ":fold<CR>", "Hide/fold code" },
  },
}

local xmappings = {
}

local lsp_mappings = {

  l = {
    name = "LSP",
    r = { "<Cmd>Lspsaga rename<CR>", "Rename" },
    u = { "<Cmd>Telescope lsp_references<CR>", "References" },
    o = { "<Cmd>Telescope lsp_document_symbols<CR>", "Document symbols" },
    d = { "<Cmd>Telescope lsp_definitions<CR>", "Definition" },
    a = { "<Cmd>Telescope lsp_code_actions<CR>", "Code actions" },
    e = { "<Cmd>lua vim.diagnostic.enable()<CR>", "Enable diagnostics" },
    x = { "<Cmd>lua vim.diagnostic.disable()<CR>", "Disable diagnostics" },
    n = { "<Cmd>update<CR>:Neoformat<CR>", "Neoformat" },
    t = { "<Cmd>TroubleToggle<CR>", "Trouble" },
  },
}

local lsp_mappings_opts = {
  {
    "document_formatting",
    { ["lf"] = { "<Cmd>lua vim.lsp.buf.formatting()<CR>", "Format" } },
  },
  {
    "code_lens",
    {
      ["ll"] = {
        "<Cmd>lua vim.lsp.codelens.refresh()<CR>",
        "Codelens refresh",
      },
    },
  },
  {
    "code_lens",
    { ["ls"] = { "<Cmd>lua vim.lsp.codelens.run()<CR>", "Codelens run" } },
  },
}

function M.register_lsp(client)
  local wk = require "which-key"
 
  wk.register(lsp_mappings, opts)

  for _, m in pairs(lsp_mappings_opts) do
    local capability, key = unpack(m)
    
    if client.server_capabilities[capability] then
      wk.register(key, opts)
    end
  end
end


function M.setup()
  local wk = require "which-key"
 
  wk.setup {}
  wk.register(mappings, opts)
  wk.register(vmappings, vopts)
  wk.register(xmappings, xopts)
end

return M
