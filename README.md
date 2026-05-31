# tmux-agent.nvim

Send your current file location or a code selection from Neovim directly to an AI agent running in a tmux pane.

Works with any CLI agent (`claude`, `aider`, `llm`, etc.). If the agent isn't running, the plugin opens a new tmux window and starts it for you.

## How it works

- **Normal mode** — sends `file.lua:42` to the agent and switches focus to its pane
- **Visual mode** — sends the selected lines as a fenced code block with file path and line range

Example of what gets sent in visual mode:

```
/home/user/project/src/foo.lua:10-20
```lua
local function foo()
    return 42
end
```

```

The plugin finds the agent pane by walking the process tree — no hardcoded pane IDs needed. If a matching process isn't found in any existing pane, it creates a new tmux window, launches the agent, and returns the pane target.

## Requirements

- Neovim 0.8+
- tmux
- A CLI AI agent on your `$PATH` (defaults to `claude`)

## Installation

### lazy.nvim

```lua
{
    'timwmillard/tmux-agent.nvim',
    opts = {},
}
```

### packer.nvim

```lua
use {
    'timwmillard/tmux-agent.nvim',
    config = function()
        require('tmux-agent').setup()
    end,
}
```

## Configuration

```lua
require('tmux-agent').setup({
    agent       = 'claude',    -- CLI agent to launch and detect
    window_name = 'claude',    -- tmux window name used when creating a new window
    keymap      = '<leader>cc', -- set to false to disable the default keymap
})
```

| Option        | Default         | Description                                             |
|---------------|-----------------|---------------------------------------------------------|
| `agent`       | `'claude'`      | Name or path of the agent binary                        |
| `window_name` | `'claude'`      | Name of the tmux window created when launching an agent |
| `keymap`      | `'<leader>cc'`  | Key used in both normal and visual mode; `false` to skip |

## Keymaps

| Mode   | Key           | Action                                      |
|--------|---------------|---------------------------------------------|
| Normal | `<leader>cc`  | Send `file:line` to the agent pane          |
| Visual | `<leader>cc`  | Send selected lines as a fenced code block  |

To bind the actions manually:

```lua
require('tmux-agent').setup({ keymap = false })

vim.keymap.set('n', '<leader>cc', require('tmux-agent').send_location)
vim.keymap.set('v', '<leader>cc', require('tmux-agent').send_selection)
```

## Commands

| Command           | Description                                       |
|-------------------|---------------------------------------------------|
| `:TmuxAgentSend`  | Send location or selection (range-aware)          |
| `:TmuxAgentDebug` | Print pane detection info for troubleshooting     |

## Troubleshooting

Run `:TmuxAgentDebug` to see:

- The resolved path of the agent binary
- All tmux panes in the current session
- Running agent processes and their PIDs
- Which pane `find_agent_pane()` resolves to

If the agent binary is not found, make sure it is installed and available in `$PATH`.
