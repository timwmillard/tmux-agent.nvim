# tmux-agent.nvim

Send your current file location or a code selection from Neovim directly to an AI agent running in a tmux pane.

Works with any CLI agent (`claude`, `opencode`, `codex`, `aider`, `llm`, etc.). If the agent isn't running, the plugin opens a new tmux window or split pane and starts it for you. Multiple agents can run simultaneously — each is tracked independently.

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
    keymap        = '<leader>cc',
})
```

| Option          | Default    | Description                                                                                   |
|-----------------|------------|-----------------------------------------------------------------------------------------------|
| `agent`         | `'claude'` | Agent binary name or path; sets preset defaults for `claude`, `opencode`, `codex`            |
| `window_name`   | agent name | tmux window name created when launching the agent; defaults to the agent name                 |
| `startup_delay` | `1.5`      | Seconds to wait after launching the agent before pasting (`opencode`/`codex` default to `3`) |
| `launch_mode`   | `'window'` | Where to create the agent if not running: `'window'`, `'split_right'`, `'split_below'`       |

## Keymaps

The plugin does not set any keymaps. Add them in your config:

```lua
local ta = require('tmux-agent')

vim.keymap.set('n', '<leader>cc', function() ta.send_location() end,  { desc = 'Send file:line to agent' })
vim.keymap.set('v', '<leader>cc', function() ta.send_selection() end, { desc = 'Send selection to agent' })
```

Both functions accept optional `(agent_name, mode)` arguments to override the config defaults. To bind multiple agents to different keys:

```lua
local ta = require('tmux-agent')

vim.keymap.set('n', '<leader>cc', function() ta.send_location('claude') end,    { desc = 'Send to claude' })
vim.keymap.set('v', '<leader>cc', function() ta.send_selection('claude') end,   { desc = 'Send selection to claude' })

vim.keymap.set('n', '<leader>co', function() ta.send_location('opencode') end,  { desc = 'Send to opencode' })
vim.keymap.set('v', '<leader>co', function() ta.send_selection('opencode') end, { desc = 'Send selection to opencode' })

vim.keymap.set('n', '<leader>cg', function() ta.send_location('codex') end,     { desc = 'Send to codex' })
vim.keymap.set('v', '<leader>cg', function() ta.send_selection('codex') end,    { desc = 'Send selection to codex' })
```

## Commands

`:TmuxAgent` is the single entry point. It accepts an optional agent name and an optional `open=` flag, and works with visual ranges.

```
:TmuxAgent [agent] [open=window|split_right|split_below]
```

| Command                              | Description                              |
|--------------------------------------|------------------------------------------|
| `:TmuxAgent`                         | Default agent, default open mode         |
| `:TmuxAgent claude`                  | Use claude agent                         |
| `:TmuxAgent open=split_right`        | Default agent, split right               |
| `:TmuxAgent claude open=split_right` | claude agent, split right                |
| `:TmuxAgent claude open=split_below` | claude agent, split below                |
| `:TmuxAgentDebug [agent]`            | Print pane detection info                |

Both `agent` and `open=` support tab completion.

If the agent is already running in a pane, the command reuses that pane regardless of `open=`. The open mode only applies when creating a new pane.

## Troubleshooting

Run `:TmuxAgentDebug` to see:

- The resolved path of the agent binary
- All tmux panes in the current session
- Running agent processes and their PIDs
- Which pane `find_agent_pane()` resolves to

If the agent binary is not found, make sure it is installed and available in `$PATH`.
