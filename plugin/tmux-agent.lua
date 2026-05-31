if vim.g.loaded_tmux_agent then return end
vim.g.loaded_tmux_agent = true

local function dispatch(opts, mode)
    local ta = require('tmux-agent')
    local agent = opts.args ~= '' and opts.args or nil
    if opts.range > 0 then
        ta.send_selection(agent, mode)
    else
        ta.send_location(agent, mode)
    end
end

vim.api.nvim_create_user_command('TmuxAgent', function(opts)
    dispatch(opts, nil)
end, { range = true, nargs = '?', desc = 'Send location or selection to agent (default launch mode)' })

vim.api.nvim_create_user_command('TmuxAgentWindow', function(opts)
    dispatch(opts, 'window')
end, { range = true, nargs = '?', desc = 'Send location or selection to agent in a new window' })

vim.api.nvim_create_user_command('TmuxAgentPane', function(opts)
    dispatch(opts, 'pane')
end, { range = true, nargs = '?', desc = 'Send location or selection to agent in a vertical split pane' })

vim.api.nvim_create_user_command('TmuxAgentVPane', function(opts)
    dispatch(opts, 'vpane')
end, { range = true, nargs = '?', desc = 'Send location or selection to agent in a vertical split pane' })

vim.api.nvim_create_user_command('TmuxAgentHPane', function(opts)
    dispatch(opts, 'hpane')
end, { range = true, nargs = '?', desc = 'Send location or selection to agent in a horizontal split pane' })

vim.api.nvim_create_user_command('TmuxAgentDebug', function(opts)
    require('tmux-agent').debug(opts.args ~= '' and opts.args or nil)
end, { nargs = '?', desc = 'Diagnose tmux-agent pane detection' })
