if vim.fn.exists('g:loaded_flybuf') == 1 then
  return
end

vim.g.loaded_flybuf = 1

vim.api.nvim_create_user_command('FlyBuf', function()
  require('flybuf').flybuf()
end, {})

vim.api.nvim_set_hl(0, 'FlyBufNormal', {
  default = true,
})

vim.api.nvim_set_hl(0, 'FlyBufBorder', {
  link = 'Constant',
  default = true,
})

vim.api.nvim_set_hl(0, 'FlyBufTitle', {
  link = 'Title',
  default = true,
})

vim.api.nvim_set_hl(0, 'FlyBufCount', {
  link = 'KeyWord',
  default = true,
})

vim.api.nvim_set_hl(0, 'FlyBufCount', {
  link = 'KeyWord',
  default = true,
})

vim.api.nvim_set_hl(0, 'FlyBufBracket', {
  link = 'Comment',
  default = true,
})

vim.api.nvim_set_hl(0, 'FlyBufName', {})

vim.api.nvim_set_hl(0, 'FlyBufShortCut', {
  link = '@parameter',
  default = true,
})
