-- local-plugins/minischeme.nvim/main.lua
local M = {}

local function load_yaml(path)
  local lines = vim.fn.readfile(path)
  return vim.fn.yaml_decode(table.concat(lines, "\n"))
end

local function ensure_yaml(path)
  if vim.fn.filereadable(path) == 1 then
    return true
  end

  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")

  local ok, err = pcall(vim.fn.writefile, {
    "highlights: {}",
    "captures: {}",
    "links: {}",
  }, path)

  if not ok then
    vim.notify("minischeme: failed to create " .. path .. ": " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  return true
end

local function apply(spec)
  if spec.inherits then
    vim.cmd.colorscheme(spec.inherits)
  end

  for group, opts in pairs(spec.highlights or {}) do
    vim.api.nvim_set_hl(0, group, opts)
  end

  for capture, opts in pairs(spec.captures or {}) do
    vim.api.nvim_set_hl(0, capture, opts)
  end

  for from, to in pairs(spec.links or {}) do
    vim.api.nvim_set_hl(0, from, { link = to })
  end
end

function M.setup(opts)
  opts = opts or {}
  local path = opts.file or (vim.fn.stdpath("config") .. "/minimal-colors.yaml")

  if not ensure_yaml(path) then
    return
  end

  local function reload()
    local ok, spec = pcall(load_yaml, path)
    if not ok then
      vim.notify("minischeme: failed to parse " .. path, vim.log.levels.ERROR)
      return
    end
    apply(spec)
  end

  reload()

  vim.api.nvim_create_user_command("MiniSchemeReload", reload, {})

  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      reload()
    end,
  })
end

return M
