local async = require("plenary.async")

async.run(function()
  local mason_spec = require("plugins.core.mason-nvim")
  local mason_ensure = mason_spec[1].opts.ensure_installed or {}
  local mason_registry = require("mason-registry")

  -- Block for all Mason packages to be installed
  for _, pkg_name in ipairs(mason_ensure) do
    local ok, pkg = pcall(mason_registry.get_package, pkg_name)
    if ok and not pkg:is_installed() then
      if not pkg:is_installing() and pkg:is_installable() then
        pkg:install()
      end
      -- Timeout after 10 minutes, 2 seconds interval
      local timeout, interval, waited = 1000000, 2000, 0
      while pkg:is_installing() and not pkg:is_installed() do
        vim.notify("Still waiting for package: " .. pkg_name .. "\n", vim.log.levels.INFO)
        async.util.sleep(interval)
        waited = waited + interval
        if waited >= timeout then
          vim.notify("Timeout installing package: " .. pkg_name .. "\n", vim.log.levels.WARN)
          break
        end
      end

      if pkg:is_installed() then
        vim.notify("Installed package: " .. pkg_name .. "\n", vim.log.levels.INFO)
      else
        vim.notify("Could not install package: " .. pkg_name .. "\n", vim.log.levels.ERROR)
      end
    end
  end

  local ts_spec = require("plugins.treesitter.nvim-treesitter")
  local ts_ensure = ts_spec[1].opts.ensure_installed or {}
  local ts_parsers = require("nvim-treesitter.parsers")

  -- Block for all Treesitter parsers to be installed
  for _, lang in ipairs(ts_ensure) do
    if not ts_parsers.has_parser(lang) then
      local ok, error = pcall(function()
        vim.cmd("TSInstall " .. lang)
      end)

      if not ok then
        vim.notify("Failed to queue install: " .. error .. "\n", vim.log.levels.ERROR)
      end

      -- Timeout after 10 minutes, 2 seconds interval
      local timeout, interval, waited = 1000000, 2000, 0
      while not ts_parsers.has_parser(lang) do
        vim.notify("Still waiting for parser: " .. lang .. "\n", vim.log.levels.INFO)
        async.util.sleep(interval)
        waited = waited + interval
        if waited >= timeout then
          vim.notify("Timeout installing parser: " .. lang .. "\n", vim.log.levels.WARN)
          break
        end
        -- Reload cached parsers
        package.loaded["nvim-treesitter.parsers"] = nil
        ts_parsers = require("nvim-treesitter.parsers")
      end

      if ts_parsers.has_parser(lang) then
        vim.notify("Installed parser: " .. lang .. "\n", vim.log.levels.INFO)
      else
        vim.notify("Could not install parser: " .. lang .. "\n", vim.log.levels.ERROR)
      end
    end
  end
end, function()
  -- Quit when done
  vim.cmd("qa")
end)
