-- Load your plugin spec
local plugin_spec = require("plugins.lsp.mason-nvim")
local ensure_installed = plugin_spec[1].opts.ensure_installed or {}

-- Install missing packages and wait for them to complete
local registry = require("mason-registry")
local async = require("plenary.async")

async.run(function()
  for _, pkg_name in ipairs(ensure_installed) do
    local ok, pkg = pcall(registry.get_package, pkg_name)
    if ok and not pkg:is_installed() then
      pkg:install()
      -- Wait for installation to complete
      while not pkg:is_installed() do
        async.util.sleep(100) -- wait 100ms
      end
    end
  end
end, function()
  -- Exit Neovim after all installs are complete
  vim.cmd("qa")
end)
