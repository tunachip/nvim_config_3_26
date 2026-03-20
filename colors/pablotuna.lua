vim.o.background = "dark"

local ok_lush, lush = pcall(require, "lush")
if not ok_lush then
  vim.notify("pablotuna: lush.nvim is required", vim.log.levels.ERROR)
  return
end

local function apply()
  package.loaded["lush_theme.pablotuna"] = nil
  local theme = require("lush_theme.pablotuna")
  lush(theme)
  vim.g.colors_name = "pablotuna"
end

apply()

pcall(vim.api.nvim_del_user_command, "PablotunaReload")
vim.api.nvim_create_user_command("PablotunaReload", function()
  apply()
  vim.notify("pablotuna reloaded", vim.log.levels.INFO)
end, { desc = "Reload the pablotuna colorscheme" })
