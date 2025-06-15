local M = {}

---@class term-manager.TermState
---@field bufnr number: Buffer identifier of the terminal.
---@field win number: Window identifier of the terminal.

---@class term-manager._State
---@field focused_terminal term-manager.TermState: Buffer of the currently focused terminal.

---@type term-manager._State
local state = {
  focused_terminal = { bufnr = -1, win = -1 },
}

---@class term-manager.termConfig
---@field bufnr ?number: (default: -1) Buffer to set for the window.
---@field floating ?boolean: (default: false) Whether to create a floating window.
---@field enter ?boolean: (default: true) Whether to focus the new floating window.
---@field height ?number: Height of the created window.
---@field width ?number: Width of the created window.
---@field style ?string: (default: "minimal") Style of the created floating window.
---@field border ?string|string[]: (default: "single") Border style of the floating window.

--- Creates a new window
---@param opts ?term-manager.termConfig: Terminal configuration
---@return term-manager.TermState
local create_window = function(opts)
  opts = opts or {}
  opts.floating = opts.floating or false
  opts.enter = opts.enter or true

  -- Check if buffer is valid; If not create a new one
  local bufnr = opts.bufnr or -1
  if not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
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

    win = vim.api.nvim_open_win(bufnr, opts.enter, {
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
    vim.api.nvim_win_set_buf(win, bufnr)
  end

  return { bufnr = bufnr, win = win }
end

--- Starts a new terminal.
--- @param insert ?boolean: Whether to start in insert mode.
--- @param opts ?term-manager.termConfig: Window configuration for the new terminal
M.start_terminal = function(insert, opts)
  opts = opts or {}
  insert = insert or true
  local term = create_window(opts)
  local restore_buf = nil

  -- Ensure we're in the correct buffer.
  if vim.api.nvim_get_current_buf() ~= term.bufnr then
    restore_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_current_buf(term.bufnr)
  end

  if vim.bo[term.bufnr].buftype ~= "terminal" then
    vim.cmd.term()
  end

  if restore_buf ~= nil then
    vim.api.nvim_set_current_buf(restore_buf)
  elseif insert then
    vim.cmd "startinsert"
  end

  state.focused_terminal = term
end

--- Toggle currently active terminal session.
--- @param focus ?boolean: Focus toggled terminal window.
--- @param win_opts ?term-manager.termConfig: Window configuration for the terminal.
M.toggle_terminal = function(focus, win_opts)
  win_opts = win_opts or {}
  focus = focus or true

  if vim.api.nvim_buf_is_valid(state.focused_terminal.bufnr) then
    local term = state.focused_terminal

    if not vim.api.nvim_win_is_valid(term.win) then
      win_opts.bufnr = term.bufnr
      M.start_terminal(focus, win_opts)
    else
      vim.api.nvim_win_hide(term.win)
    end
  else
    M.start_terminal(focus, win_opts)
  end
end


vim.api.nvim_create_user_command("TermCreate", M.start_terminal, {})
vim.api.nvim_create_user_command("TermToggle", M.toggle_terminal, {})

return M
