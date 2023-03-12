show buffers in a float window and support use shortcut to open buffer

![image](https://user-images.githubusercontent.com/41671631/224526523-c6fb61df-a573-44c8-91b3-6986535c1977.png)

## Features

- support show diagnostics
- simply usage

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

## Options

```lua
{
    border  -- border
    quit    -- default is q to close the flybuf window
}
```

## Usage

- press `FlyBuf` command then press hotkey open buffer


## License MIT
