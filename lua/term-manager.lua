local M = {}

---@class term-manager.termConfig
---@field floating boolean: (default: false)
---Whether to create a floating window.
---@field enter boolean: (default: true) Whether to focus the new floating window.
---@field height number: Height of the created window.
---@field width number: Width of the created window.
---@field style string: (default: "minimal") Style of the created floating window.
---@field border string|string[]: (default: "single") Border style of the floating window.

--- Creates a new window
---@param opts ?term-manager.termConfig: Terminal configuration
local create_window = function(opts)
  opts = opts or {}
  opts.floating = opts.floating or false
  opts.enter = opts.enter or true

  -- Check if buffer is valid; If not create a new one
  local buf = opts.buf or -1
  if not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
  end

  local win
  if opts.floating then
    local max_width = vim.o.columns
    local max_height = vim.o.lines

    local width = opts.width or math.floor(max_width * 0.8)
    local height = opts.height or math.floor(max_height * 0.8)

    -- Place the window at the center
    local row = math.floor((max_height - height) / 2 - 1)
    local col = math.floor((max_width - width) / 2)

    win = vim.api.nvim_open_win(buf, opts.enter, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = opts.style or "minimal",
      border = opts.border or "single",
    })
  else
    vim.cmd("split")
    vim.cmd("wincmd J")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(win, opts.height or 10)
    vim.api.nvim_win_set_buf(win, buf)
  end

  return { buf = buf, win = win }
end

--- Starts a new terminal.
--- @param insert ?boolean: Whether to start in insert mode.
--- @param opts ?term-manager.termConfig: Window configuration for the new terminal
M.start_terminal = function(insert, opts)
  opts = opts or {}
  insert = insert or true
  local term = create_window(opts)
  local restore_buf = nil

  if vim.api.nvim_get_current_buf() ~= term.buf then
    restore_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_current_buf(term.buf)
  end

  if vim.bo[term.buf].buftype ~= "terminal" then
    -- Ensure we're in the correct buffer.
    vim.cmd.term()
  end

  if restore_buf ~= nil then
    vim.api.nvim_set_current_buf(restore_buf)
  elseif insert then
    vim.cmd "startinsert"
  end
end


vim.api.nvim_create_user_command("TermCreate", M.start_terminal, {})

return M
