show buffers in a float window and support use shortcut to open buffer

## Install

- lazy.nvim

```lua
require('lazy').setup({
    {'glepnir/flybuf.nvim', cmd = 'FlyBuf', config = function()
         require('flybuf').setup({})
    end,}
})
```


- packer

```lua
  use {'glepnir/flybuf.nvim', cmd = 'FlyBuf', config = function()
         require('flybuf').setup({})
    end,}
```

## Usage

- press `FlyBuf` command then press hotkey open buffer


## License MIT
