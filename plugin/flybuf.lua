local nvim_set_hl, nvim_create_user_command = vim.api.nvim_set_hl, vim.api.nvim_create_user_command
if vim.fn.exists('g:loaded_flybuf') == 1 then
  return
end

vim.g.loaded_flybuf = 1

nvim_create_user_command('FlyBuf', function()
  require('flybuf').toggle()
end, {})

nvim_set_hl(0, 'FlyBufNormal', {
  default = true,
})

nvim_set_hl(0, 'FlyBufBorder', {
  link = 'Constant',
  default = true,
})

nvim_set_hl(0, 'FlyBufTitle', {
  link = 'Title',
  default = true,
})

nvim_set_hl(0, 'FlyBufCount', {
  link = 'KeyWord',
  default = true,
})

nvim_set_hl(0, 'FlyBufCount', {
  link = 'KeyWord',
  default = true,
})

nvim_set_hl(0, 'FlyBufBracket', {
  link = 'Comment',
  default = true,
})

nvim_set_hl(0, 'FlyBufNum', {
  link = 'Number',
  default = true,
})

nvim_set_hl(0, 'FlyBufName', {
  default = true,
})

nvim_set_hl(0, 'FlyBufShortCut', {
  link = '@variable.builtin',
  default = true,
})

nvim_set_hl(0, 'FlyBufSelect', {
  link = 'Type',
  default = true,
})
