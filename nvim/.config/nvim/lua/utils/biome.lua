local M = {}

function M.has_biome_config()
  local files = { ".biome.json", "biome.json" }
  for _, file in ipairs(files) do
    if vim.fn.filereadable(vim.fn.getcwd() .. "/" .. file) == 1 then
      return true
    end
  end
  return false
end

return M
