-- Get the list of Mason packages to install
local plugin_spec = require("plugins.lsp.mason-nvim")
local ensure_installed = plugin_spec[1].opts.ensure_installed or {}

-- Install Mason packages synchronously
vim.cmd("MasonInstall " .. table.concat(ensure_installed, " "))
