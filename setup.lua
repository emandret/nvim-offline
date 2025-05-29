local async = require("plenary.async")

async.run(function()
  local mason_spec = require("plugins.lsp.mason-nvim")
  local mason_ensure = mason_spec[1].opts.ensure_installed or {}
  local mason_registry = require("mason-registry")

  -- Block for all Mason packages to be installed
  for _, pkg_name in ipairs(mason_ensure) do
    local ok, pkg = pcall(mason_registry.get_package, pkg_name)
    if ok and not pkg:is_installed() then
      if not pkg:is_installing() and pkg:is_installable() then
        pkg:install()
      end
      -- Timeout after 10 minutes, 10 seconds interval
      local timeout, interval, waited = 1000000, 100000, 0
      while pkg:is_installing() and not pkg:is_installed() do
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

  local ts_spec = require("plugins.syntax.nvim-treesitter")
  local ts_ensure = ts_spec[1].opts.ensure_installed or {}
  local ts_install = require("nvim-treesitter.install")

  -- Block for all Treesitter parsers to be installed
  for _, lang in ipairs(ts_ensure) do
    if vim.treesitter.language.inspect(lang) == nil then
      local ok = pcall(function()
        ts_install.install(lang)
      end)

      if not ok then
        vim.notify("Failed to queue installation for: " .. lang .. "\n", vim.log.levels.ERROR)
      end

      -- Timeout after 10 minutes, 10 seconds interval
      local timeout, interval, waited = 1000000, 100000, 0
      while vim.treesitter.language.inspect(lang) == nil do
        vim.notify("Still waiting for parser: " .. lang .. "\n", vim.log.levels.INFO)
        async.util.sleep(interval)
        waited = waited + interval
        if waited >= timeout then
          vim.notify("Timeout installing parser: " .. lang .. "\n", vim.log.levels.WARN)
          return
        end
      end
      vim.notify("Installed parser: " .. lang .. "\n", vim.log.levels.INFO)
    end
  end
end, function()
  -- Quit when done
  vim.cmd("qa")
end)
