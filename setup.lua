local async = require("plenary.async")

async.run(function()
  local plugin_spec = require("plugins.lsp.mason-nvim")
  local ensure_installed = plugin_spec[1].opts.ensure_installed or {}
  local registry = require("mason-registry")

  -- Block for all Mason packages to be installed
  for _, pkg_name in ipairs(ensure_installed) do
    local ok, pkg = pcall(registry.get_package, pkg_name)
    if ok and pkg:is_installing() then
      -- Timeout after 2 minutes, 5 seconds interval
      local timeout, interval, waited = 120000, 5000, 0
      while not pkg:is_installed() do
        vim.notify("Still waiting for package: " .. pkg_name .. "\n", vim.log.levels.INFO)
        async.util.sleep(interval)
        waited = waited + interval
        if waited >= timeout then
          vim.notify("Timeout installing package: " .. pkg_name .. "\n", vim.log.levels.WARN)
          return
        end
      end
      vim.notify("Installed package: " .. pkg_name .. "\n", vim.log.levels.INFO)
    end
  end

  -- Update Treesitter parsers synchronously
  require("nvim-treesitter.install").update({ with_sync = true })
end, function()
  -- Quit when done
  vim.cmd("qa")
end)
