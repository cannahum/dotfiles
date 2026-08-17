-- mapleader is already " " via LazyVim's own defaults (lazyvim/config/options.lua)

local keymap = vim.keymap -- for conciseness

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- Increment/decrement: dropped <leader>+/<leader>- (they just called vim's
-- own native <C-a>/<C-x>, adding nothing) -- also frees <leader>- for
-- LazyVim's "Split Window Below", which our override was silently
-- clobbering. Use <C-a>/<C-x> directly.

-- Window management: dropped <leader>sv/sh/se/sx -- they lived under
-- <leader>s, which LazyVim claims for its search menu (<leader>sh even
-- collided outright with "Help Pages"). LazyVim already covers this: <leader>w
-- proxies to <C-w> for anything (wv, w=, wc...), plus dedicated <leader>-
-- (split below), <leader>| (split right), <leader>wd (close window).

-- -- ThePrimeagen remaps -- --
-- Block move vertically
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- When appending lower line, cursor remains in its position
keymap.set("n", "J", "mzJ`z")

-- Set cursor to middle of buffer when moving with C-d and C-u
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")

-- Set cursor to middle of buffer when searching and finding next
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

-- Pasting over selection will not lose what your were pasting
keymap.set("x", "<leader>p", '"_dP')
