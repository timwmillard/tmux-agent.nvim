if vim.g.loaded_tmux_agent then return end
vim.g.loaded_tmux_agent = true

local function dispatch(opts)
    local ta = require('tmux-agent')
    local agent, mode

    for _, arg in ipairs(vim.split(opts.args, '%s+')) do
        if arg:match('^open=') then
            mode = arg:sub(6)
        elseif arg ~= '' then
            agent = arg
        end
    end

    if opts.range > 0 then
        ta.send_selection(agent, mode)
    else
        ta.send_location(agent, mode)
    end
end

local valid_open = { window = true, split_right = true, split_below = true }

local function complete(arg_lead)
    local results = {}
    if arg_lead:match('^open=') then
        local val = arg_lead:sub(6)
        for mode in pairs(valid_open) do
            if mode:find(val, 1, true) == 1 then
                results[#results + 1] = 'open=' .. mode
            end
        end
    else
        local ta = require('tmux-agent')
        for name in pairs(ta.presets) do
            if name:find(arg_lead, 1, true) == 1 then
                results[#results + 1] = name
            end
        end
        for mode in pairs(valid_open) do
            local candidate = 'open=' .. mode
            if candidate:find(arg_lead, 1, true) == 1 then
                results[#results + 1] = candidate
            end
        end
    end
    return results
end

vim.api.nvim_create_user_command('TmuxAgent', dispatch, {
    range = true,
    nargs = '*',
    complete = complete,
    desc = 'Send location or selection to agent. Args: [agent] [open=window|split_right|split_below]',
})

vim.api.nvim_create_user_command('TmuxAgentDebug', function(opts)
    require('tmux-agent').debug(opts.args ~= '' and opts.args or nil)
end, { nargs = '?', desc = 'Diagnose tmux-agent pane detection' })
