# tmux-agent.nvim

Send your current file location or a code selection from Neovim directly to an AI agent running in a tmux pane.

Works with any CLI agent (`claude`, `opencode`, `codex`, `aider`, `llm`, etc.). If the agent isn't running, the plugin opens a new tmux window and starts it for you.

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

- Neovim 0.8+ (0.12+ for built-in `vim.pack`)
- tmux
- A CLI AI agent on your `$PATH` (defaults to `claude`)

## Installation

### Neovim 0.12+ (built-in)

```lua
vim.pack.add('timwmillard/tmux-agent.nvim', {
    config = function()
        require('tmux-agent').setup()
    end,
})
```

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

The plugin has built-in presets for `claude`, `opencode`, and `codex` — just set `agent` and everything else is configured automatically:

```lua
-- claude (default)
require('tmux-agent').setup({ agent = 'claude' })

-- opencode
require('tmux-agent').setup({ agent = 'opencode' })

-- codex
require('tmux-agent').setup({ agent = 'codex' })
```

For a custom agent or to override preset values:

```lua
require('tmux-agent').setup({
    agent         = 'aider',
    startup_delay = 2,
    launch_args   = nil,  -- nil = paste after startup; '{prompt}' = positional arg; '--flag {prompt}' = named flag
    keymap        = '<leader>cc',
})
```

| Option         | Default        | Description                                                                         |
|----------------|----------------|-------------------------------------------------------------------------------------|
| `agent`        | `'claude'`     | Agent binary name or path; sets preset defaults for `claude`, `opencode`, `codex`   |
| `window_name`  | agent name     | tmux window name created when launching the agent; defaults to the agent name       |
| `keymap`       | `'<leader>cc'` | Key in normal and visual mode; `false` to skip                                      |
| `startup_delay`| `1.5`          | Seconds to wait after launching the agent before pasting (used when `launch_args` is nil) |
| `launch_args`  | `nil`          | Arg template for passing the prompt at launch; `{prompt}` is replaced with the file location |

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
