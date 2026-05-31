local M = {}

local presets = {
    claude   = { launch_args = nil,        startup_delay = 1.5 },
    codex    = { launch_args = nil, startup_delay = 3 },
    opencode = { launch_args = nil, startup_delay = 3 },
}

M.config = {
    agent         = 'claude',
    window_name   = nil,
    keymap        = '<leader>cc',
    startup_delay = 1.5,
    launch_args   = nil,
}

local function find_agent_pane()
    local pane_map = {}
    local out = vim.fn.system("tmux list-panes -s -F '#{pane_pid}|#{session_name}:#{window_index}.#{pane_index}'")
    for line in out:gmatch('[^\n]+') do
        local pid, target = line:match('^(%d+)|(.+)$')
        if pid then pane_map[tonumber(pid)] = target end
    end

    local ppid_of = {}
    local agent_pids = {}
    local agent_path = vim.fn.exepath(M.config.agent)
    local ps = vim.fn.system('ps -A -o pid=,ppid=,command=')
    for line in ps:gmatch('[^\n]+') do
        local pid_s, ppid_s, cmd = line:match('^%s*(%d+)%s+(%d+)%s+(.-)%s*$')
        if pid_s then
            local pid = tonumber(pid_s)
            ppid_of[pid] = tonumber(ppid_s)
            if (agent_path ~= '' and cmd:find(agent_path, 1, true))
                or cmd == M.config.agent
                or cmd:match('^' .. vim.pesc(M.config.agent) .. ' ') then
                agent_pids[pid] = true
            end
        end
    end

    for pid in pairs(agent_pids) do
        local cur, seen = pid, {}
        while cur and cur > 1 and not seen[cur] do
            seen[cur] = true
            if pane_map[cur] then return pane_map[cur] end
            cur = ppid_of[cur]
        end
    end
    return nil
end

-- Returns target, prompt_was_launched (true if initial_text was embedded in the launch command)
local function get_or_create_pane(initial_text)
    local target = find_agent_pane()
    if target then
        vim.notify('tmux-agent: found pane ' .. target, vim.log.levels.INFO)
        return target, false
    end

    local session = vim.fn.system("tmux display-message -p '#S'"):gsub('[%s\n]+', '')
    if session == '' then
        vim.notify('tmux-agent: not inside a tmux session', vim.log.levels.ERROR)
        return nil, false
    end

    local win = vim.fn.system(
        'tmux new-window -t ' .. vim.fn.shellescape(session) .. ': -P -F \'#{window_index}\' -n '
        .. vim.fn.shellescape(M.config.window_name)
    ):gsub('[%s\n]+', '')
    local new_target = session .. ':' .. win .. '.0'
    vim.notify('tmux-agent: created pane ' .. new_target, vim.log.levels.INFO)

    if initial_text and M.config.launch_args then
        local args = M.config.launch_args:gsub('{prompt}', vim.trim(initial_text))
        local cmd = M.config.agent .. ' ' .. args
        vim.fn.system('tmux send-keys -t ' .. vim.fn.shellescape(new_target) .. ' ' .. vim.fn.shellescape(cmd) .. ' Enter')
        return new_target, true
    end

    vim.fn.system('tmux send-keys -t ' .. vim.fn.shellescape(new_target) .. ' ' .. vim.fn.shellescape(M.config.agent) .. ' Enter')
    vim.fn.system('sleep ' .. M.config.startup_delay)
    return new_target, false
end

local function send_to_pane(target, text)
    local tmp = vim.fn.tempname()
    local f = io.open(tmp, 'w')
    if not f then vim.notify('tmux-agent: cannot open temp file', vim.log.levels.ERROR); return end
    f:write(text)
    f:close()
    vim.fn.system('tmux load-buffer -b tmux-agent-send ' .. vim.fn.shellescape(tmp))
    vim.fn.system('tmux paste-buffer -b tmux-agent-send -t ' .. vim.fn.shellescape(target))
    vim.fn.system('tmux delete-buffer -b tmux-agent-send')
    vim.fn.delete(tmp)
end

local function switch_to_pane(target)
    local current = vim.fn.system("tmux display-message -p '#S'"):gsub('[%s\n]+', '')
    local t_session = target:match('^(.+):%d+%.%d+$')
    local esc = vim.fn.shellescape(target)
    if t_session and current == t_session then
        vim.fn.system('tmux select-window -t ' .. esc)
        vim.fn.system('tmux select-pane -t ' .. esc)
    else
        vim.fn.system('tmux switch-client -t ' .. esc)
    end
end

function M.send_location()
    local file = vim.fn.expand('%:p')
    local lnum = vim.fn.line('.')
    local text = file .. ':' .. lnum .. ' '
    local target, launched = get_or_create_pane(text)
    if not target then return end
    if not launched then send_to_pane(target, text) end
    switch_to_pane(target)
end

function M.send_selection()
    local file = vim.fn.expand('%:p')
    local ft = vim.bo.filetype
    local s = vim.fn.line('v')
    local e = vim.fn.line('.')
    if s > e then s, e = e, s end
    if s == 0 or e == 0 then
        vim.notify('tmux-agent: no visual selection', vim.log.levels.WARN)
        return
    end
    local lines = vim.fn.getline(s, e)
    local text = file .. ':' .. s .. '-' .. e
        .. '\n```' .. ft .. '\n'
        .. table.concat(lines, '\n')
        .. '\n```\n\n'
    local target, launched = get_or_create_pane(text)
    if not target then return end
    if not launched then send_to_pane(target, text) end
    switch_to_pane(target)
end

function M.debug()
    local agent_path = vim.fn.exepath(M.config.agent)
    print('agent: ' .. M.config.agent)
    print('agent_path: ' .. (agent_path ~= '' and agent_path or '(not found in PATH)'))

    local panes = vim.fn.system("tmux list-panes -s -F '#{pane_pid}|#{session_name}:#{window_index}.#{pane_index}'")
    print('panes:\n' .. panes)

    local ps = vim.fn.system('ps -A -o pid=,ppid=,command= | grep -v grep | grep -i ' .. vim.fn.shellescape(M.config.agent))
    print('agent processes:\n' .. ps)

    local target = find_agent_pane()
    print('find_agent_pane() => ' .. (target or 'nil'))
end

function M.setup(opts)
    opts = opts or {}
    local preset = presets[opts.agent or M.config.agent] or {}
    M.config = vim.tbl_deep_extend('force', M.config, preset, opts)
    M.config.window_name = M.config.window_name or M.config.agent

    if M.config.keymap then
        vim.keymap.set('n', M.config.keymap, M.send_location,  { desc = 'Send file:line to agent' })
        vim.keymap.set('v', M.config.keymap, M.send_selection, { desc = 'Send selection to agent' })
    end
end

return M
