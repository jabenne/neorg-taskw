local neorg = require('neorg.core')
local Job = require'plenary.job'

local module = neorg.modules.create('external.taskwarrior')

module.setup = function ()
    return {
        requires = {
            'core.neorgcmd'
        }
    }
end

module.load = function ()
    module.required['core.neorgcmd'].add_commands_from_table({
        ['tw-ins-tasks'] = {
            args = 0,
            condition = 'norg',
            name = 'external.taskwarrior.ins'
        }
    })
end

module.private = {
    tw_ins_tasks = function ()
        local j = Job:new({
            command = 'task',
            args = { 'scheduled:today', 'export', 'rc.json.array=off' },
        }):sync()

        local tasks = {}
        for idx, json_task in pairs(j) do
            tasks[idx] = vim.json.decode(json_task)
        end
        for idx, task in pairs(tasks) do
            if task.status == 'pending' then
                local pos = vim.api.nvim_win_get_cursor(0)
                local nline = "- ( ) [" .. task.project .. "] " .. task.description
                vim.api.nvim_set_current_line(nline)
                vim.api.nvim_buf_set_lines(0, pos[1], pos[1], false, {nline})
            end
        end

    end
}

module.on_event = function (event)
    if event.split_type[2] == 'external.taskwarrior.ins' then
        module.private.tw_ins_tasks()
    end
end

module.events.subscribed = {
    ['core.neorgcmd'] = {
        ['external.taskwarrior.ins'] = true
    }
}

return module
