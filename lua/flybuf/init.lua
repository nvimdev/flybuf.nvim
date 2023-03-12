local api, fn = vim.api, vim.fn
local nvim_buf_set_keymap = api.nvim_buf_set_keymap
local fb = {}

local function get_buffers()
  local buffers = api.nvim_list_bufs()
  buffers = vim.tbl_filter(function(buf)
    return vim.bo[buf].buflisted
  end, buffers)
  return buffers
end

local function align_element(content)
  local max = {}
  vim.tbl_map(function(item)
    max[#max + 1] = #item
  end, content)
  table.sort(max)
  max = max[#max]

  local res = {}
  vim.tbl_map(function(item)
    local fill = (' '):rep(max - #item)
    res[#res + 1] = item .. fill
  end, content)

  return res
end

local function hotkey()
  --not sure 26 is enough? anyone will open 27 buffers ?
  local key = 'asdfghjklqwertyuiopzxcvbnm'
  local tbl = {}
  ---@diagnostic disable-next-line: discard-returns
  key:gsub('.', function(c)
    tbl[#tbl + 1] = c
  end)
  local index = 1
  return function()
    index = index + 1
    if index > #tbl then
      vim.notify('[FlyBuf] index is out of range')
      return index - 1
    end
    return tbl[index - 1]
  end
end

local function get_icon(bufnr)
  local ok, devicon = pcall(require, 'nvim-web-devicons')
  if not ok then
    return ''
  end
  local icon, hl = devicon.get_icon_by_filetype(vim.bo[bufnr].filetype)
  return icon .. ' ', hl
end

local function unicode_num(num)
  local tbl = {
    '➊ ',
    '➋ ',
    '➌ ',
    '➍ ',
    '➎ ',
    '➏ ',
    '➐ ',
    '➑ ',
    '➒ ',
    '➓ ',
  }
  return tbl[num] and tbl[num] or num
end

local function himap()
  return { 'SignError', 'SignWarn', 'SignInfo', 'SignHint' }
end

local function get_sign()
  local prefix = 'Diagnostic'
  local signs = {}
  local map = himap()
  for _, v in ipairs(map) do
    local text = fn.sign_getdefined(prefix .. v).text
    if not text then
      text = v:sub(5, 5)
    end
    signs[#signs + 1] = text
  end
  return signs
end

local function get_diagnsotic(buf)
  local diagnostics = vim.diagnostic.get(buf)
  local count = { 0, 0, 0, 0 }
  for _, diagnostic in ipairs(diagnostics) do
    count[diagnostic.severity] = count[diagnostic.severity] + 1
  end
  local signs = get_sign()
  local msg = ' '
  local hi = {}
  local map = himap()
  for i, v in ipairs(count) do
    if v ~= 0 then
      local start = #msg
      msg = msg .. signs[i] .. ' ' .. v .. ' '
      hi[#hi + 1] = { start, start + #(signs[i] .. ' ' .. v .. ' '), 'Diagnostic' .. map[i] }
    end
  end
  return msg, hi
end

local function max_content_width(content)
  local max = {}
  vim.tbl_map(function(item)
    max[#max + 1] = #item
  end, content)
  table.sort(max)
  return max[#max]
end

local function create_menu(opt)
  local buffers = get_buffers()
  if #buffers == 0 then
    return
  end

  local lines = {}
  local hi = {}
  local shortcut = hotkey()
  local keys = {}

  for i, buf in ipairs(buffers) do
    local name = fn.fnamemodify(api.nvim_buf_get_name(buf), ':t')
    local icon, group = get_icon(buf)
    local key = shortcut()
    if #name ~= 0 then
      lines[#lines + 1] = '[' .. key .. '] ' .. icon .. name
      hi[#hi + 1] = {
        { 0, 1, 'FlyBufBracket' },
        { 1, 2, 'FlyBufShortCut' },
        { 2, 3, 'FlyBufBracket' },
        group and { 3, 4 + #icon, group } or nil,
        { 4 + #icon, -1, 'FlyBufName' },
      }
      keys[#keys + 1] = { key, i }
    end
  end

  if #lines == 0 then
    return
  end

  lines = align_element(lines)

  for i, v in ipairs(lines) do
    local msg, hi_scope = get_diagnsotic(buffers[i])
    local start = #v
    lines[i] = v .. msg
    for _, item in ipairs(hi_scope) do
      item[1] = start + item[1]
      item[2] = start + item[2]
      table.insert(hi[i], item)
    end
  end

  local line_width = max_content_width(lines)

  local float_opt = {
    relative = 'editor',
    width = line_width < 40 and 40 or line_width,
    row = math.floor(vim.o.lines * 0.2),
    border = opt.border,
    style = 'minimal',
    title = {
      { 'Buffers ', 'FlyBufTitle' },
      { unicode_num(#lines), 'FlyBufCount' },
    },
    title_pos = 'center',
  }
  float_opt.col = math.floor(vim.o.columns * 0.5) - math.floor(float_opt.width * 0.5)
  local max_height = math.floor(vim.o.lines * 0.6)
  float_opt.height = #lines > max_height and max_height or #lines

  local bufnr = api.nvim_create_buf(false, false)
  vim.bo[bufnr].bufhidden = 'wipe'
  local winid = api.nvim_open_win(bufnr, true, float_opt)
  api.nvim_set_option_value('winhl', 'Normal:FlyBufNormal,FloatBorder:FlyBufBorder', {
    scope = 'local',
    win = winid,
  })

  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  for i, item in ipairs(hi) do
    for _, v in ipairs(item) do
      api.nvim_buf_add_highlight(bufnr, 0, v[3], i - 1, v[1], v[2])
    end
  end

  for _, item in ipairs(keys) do
    nvim_buf_set_keymap(bufnr, 'n', item[1], '', {
      noremap = true,
      nowait = true,
      callback = function()
        local buf = buffers[item[2]]
        api.nvim_win_close(winid, true)
        api.nvim_win_set_buf(0, buf)
      end,
    })
  end

  nvim_buf_set_keymap(bufnr, 'n', opt.quit, '', {
    noremap = true,
    nowait = true,
    callback = function()
      api.nvim_win_close(winid, true)
    end,
  })

  api.nvim_create_autocmd('CursorMoved', {
    buffer = bufnr,
    callback = function()
      local pos = api.nvim_win_get_cursor(winid)
      api.nvim_win_set_cursor(winid, { pos[1], 1 })
    end,
  })
  return winid
end

function fb.flybuf()
  create_menu(fb.opt)
end

function fb.setup(opt)
  fb.opt = vim.tbl_extend('force', {
    border = 'single',
    quit = 'q',
  }, opt)
end

return fb
