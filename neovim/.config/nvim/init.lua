require("bootstrap"):init(base_dir)

require("config"):load()

local plugins = require "plugins"

require("plugin-loader").load { plugins, plugins }

require("core.theme").setup()

local Log = require "core.log"
Log:debug "Starting LunarVim"

local commands = require "core.commands"
commands.load(commands.defaults)

require("lsp").setup()
