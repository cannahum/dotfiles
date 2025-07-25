-- Detect the correct Chrome binary path
local chrome_candidates = {
  "google-chrome-stable",
  "google-chrome",
  "chrome",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", -- macOS
}

local function find_chrome()
  for _, name in ipairs(chrome_candidates) do
    local handle = io.popen("command -v " .. name .. " 2>/dev/null")
    if handle then
      local result = handle:read("*a"):gsub("%s+", "")
      handle:close()
      if result and #result > 0 then
        return result
      end
    end
  end
  return nil
end

local chrome_path = find_chrome()
if chrome_path then
  vim.g.mkdp_browser = chrome_path
else
  vim.g.mkdp_browser = "firefox" -- fallback browser
end
