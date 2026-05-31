if vim.g.loaded_tmux_agent then return end
vim.g.loaded_tmux_agent = true

vim.api.nvim_create_user_command('TmuxAgentDebug', function()
    require('tmux-agent').debug()
end, { desc = 'Diagnose tmux-agent pane detection' })

vim.api.nvim_create_user_command('TmuxAgentSend', function(opts)
    local ta = require('tmux-agent')
    if opts.range > 0 then
        ta.send_selection()
    else
        ta.send_location()
    end
end, { range = true, desc = 'Send location or selection to agent pane' })
