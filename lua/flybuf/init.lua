local api, fn = vim.api, vim.fn
local nvim_buf_set_keymap = api.nvim_buf_set_keymap
local fb = {}

local function fname_path(buf)
  local sep = vim.loop.os_uname().version:match('Windows') and '\\' or '/'
  local fname = api.nvim_buf_get_name(buf)
  local parts = vim.split(fname, sep)
  return table.concat(parts, sep, #parts - 1, #parts)
end

local function get_buffers()
  local bufnrs = vim.tbl_filter(function(buf)
    return vim.bo[buf].buflisted
  end, api.nvim_list_bufs())

  table.sort(bufnrs, function(a, b)
    return fn.getbufinfo(a)[1].lastused > fn.getbufinfo(b)[1].lastused
  end)

  local buffers = {}

  for _, bufnr in ipairs(bufnrs) do
    local flag = bufnr == vim.fn.bufnr('') and '%' or (bufnr == vim.fn.bufnr('#') and '#' or ' ')

    local element = {
      bufnr = bufnr,
      flag = flag,
      name = fname_path(bufnr),
    }

    if flag == '#' or flag == '%' then
      local idx = ((buffers[1] ~= nil and buffers[1].flag == '%') and 2 or 1)
      table.insert(buffers, idx, element)
    else
      table.insert(buffers, element)
    end
  end

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

local function hotkey(key)
  local tbl = {}
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
  if icon == nil then
    icon = "*"
  end
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

local function create_ns()
  local name = 'FlyBuf'
  local all = api.nvim_get_namespaces()
  if not all[name] then
    return api.nvim_create_namespace(name)
  end
  return all[name]
end

local function max_buf_len(buffers)
  local max = {}
  vim.tbl_map(function(item)
    max[#max + 1] = #tostring(item.bufnr)
  end, buffers)
  table.sort(max)
  return max[#max]
end

local function flattern_tbl(tbl, indexs)
  local tmp = {}
  for k, v in ipairs(tbl) do
    if not vim.tbl_contains(indexs, k) then
      tmp[#tmp + 1] = v
    end
  end
  return tmp
end

local function create_menu(opt)
  local buffers = get_buffers()
  if #buffers == 0 then
    return
  end

  local lines = {}
  local hi = {}
  local shortcut = hotkey(opt.hotkey)
  local keys = {}
  local ns = create_ns()
  local max_len = max_buf_len(buffers)

  for i, item in ipairs(buffers) do
    local icon, group = get_icon(item.bufnr)
    local key = shortcut()
    if #item.name ~= 0 then
      local num_len = #tostring(item.bufnr)
      local need_fill = max_len - num_len
      num_len = num_len + need_fill
      lines[#lines + 1] = '['
        .. key
        .. '] '
        .. item.bufnr
        .. (' '):rep(need_fill)
        .. ' '
        .. icon
        .. item.name
      local start = group and 4 + num_len + #icon or 4 + num_len
      hi[#hi + 1] = {
        { 0, 1, 'FlyBufBracket' },
        { 1, 2, 'FlyBufShortCut' },
        { 2, 3, 'FlyBufBracket' },
        { 4, 4 + num_len, 'FlyBufNum' },
        { start + 1, start + 1 + #item.name, 'FlyBufName' },
      }
      table.insert(hi[#hi], group and { 4 + num_len, 4 + num_len + #icon, group } or nil)
      keys[#keys + 1] = { key, i }
    end
  end

  if #lines == 0 then
    return
  end

  lines = align_element(lines)

  for i, v in ipairs(lines) do
    local msg, hi_scope = get_diagnsotic(buffers[i].bufnr)
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
  vim.bo[bufnr].buftype = 'nofile'
  local winid = api.nvim_open_win(bufnr, true, float_opt)
  api.nvim_win_set_hl_ns(winid, ns)
  api.nvim_set_option_value('winhl', 'Normal:FlyBufNormal,FloatBorder:FlyBufBorder', {
    scope = 'local',
    win = winid,
  })

  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  local function gen_highlight()
    for i, item in ipairs(hi) do
      for _, v in ipairs(item) do
        api.nvim_buf_add_highlight(bufnr, ns, v[3], i - 1, v[1], v[2])
      end
    end
  end

  gen_highlight()

  for _, item in ipairs(keys) do
    nvim_buf_set_keymap(bufnr, 'n', item[1], '', {
      noremap = true,
      nowait = true,
      callback = function()
        local buf = buffers[item[2]].bufnr
        api.nvim_win_close(winid, true)
        api.nvim_win_set_buf(0, buf)
      end,
    })
  end

  local wipes = {}
  nvim_buf_set_keymap(bufnr, 'n', opt.mark, '', {
    noremap = true,
    nowait = true,
    callback = function()
      local index = api.nvim_win_get_cursor(winid)[1]
      local start, _end = unpack(hi[index][5])
      if not vim.tbl_contains(vim.tbl_keys(wipes), index) then
        local id = api.nvim_buf_set_extmark(bufnr, ns, index - 1, start, {
          end_col = _end,
          hl_group = 'FlyBufSelect',
        })
        wipes[index] = id
      else
        local id = wipes[index]
        api.nvim_buf_del_extmark(bufnr, ns, id)
        api.nvim_buf_set_extmark(bufnr, ns, index - 1, start, {
          end_col = _end,
          hl_group = 'FlyBufName',
        })
        wipes[index] = nil
      end
    end,
  })

  --delele buffers by mark
  nvim_buf_set_keymap(bufnr, 'n', opt.delete, '', {
    noremap = true,
    nowait = true,
    callback = function()
      local content = api.nvim_buf_get_lines(bufnr, 0, -1, false)
      if not wipes or #wipes == 0 then
        local row = api.nvim_win_get_cursor(winid)[1]
        wipes[row] = true
      end

      for index, _ in pairs(wipes or {}) do
        api.nvim_buf_call(buffers[index].bufnr, function()
          api.nvim_buf_delete(buffers[index].bufnr, { force = true })
        end)
        table.remove(content, index)
        table.remove(hi, index)
      end

      local indexs = vim.tbl_keys(wipes)
      buffers = flattern_tbl(buffers, indexs)
      content = flattern_tbl(content, indexs)
      hi = flattern_tbl(hi, indexs)

      wipes = {}
      vim.bo[bufnr].modifiable = true
      if #content == 0 then
        api.nvim_win_close(winid, true)
      else
        api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
        vim.bo[bufnr].modifiable = false
        gen_highlight()
        api.nvim_win_set_config(winid, { height = #content })
      end
    end,
  })

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

  api.nvim_create_autocmd('BufDelete', {
    buffer = bufnr,
    callback = function()
      api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end,
  })
  return winid
end

function fb.flybuf()
  create_menu(fb.opt)
end

function fb.setup(opt)
  fb.opt = vim.tbl_extend('force', {
    hotkey = 'asdfghwertyuiopzcvbnm',
    border = 'single',
    quit = 'q',
    mark = 'l',
    delete = 'x',
  }, opt)
end

return fb
