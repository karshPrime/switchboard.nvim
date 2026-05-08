-- term_actions.lua

local Helpers = require("switchboard.helpers")

local TermActions = {}


vim.o.splitright = true
vim.o.splitbelow = true


--
-- get project directory for terminal cwd
local function get_project_dir()
    return vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel 2>/dev/null || pwd"))
end

--
-- run command in a new background tab (new buffer, hidden)
function TermActions.new_window(aCmd, aWindowName, aErrorName)
    if not aCmd then
        local lExtension = Helpers.get_file_extension()
        vim.notify("Error: " .. aErrorName .. " command not found for ." .. lExtension, vim.log.levels.ERROR)
        return 1
    end

    local lProjectDir = get_project_dir()
    vim.cmd("tabnew")
    vim.cmd("lcd " .. lProjectDir)
    vim.fn.termopen(aCmd, { cwd = lProjectDir })
    vim.cmd("tabprevious")
end

--
-- run command in a floating window (overlay equivalent)
function TermActions.overlay(aCmd, aSleepDuration, aWidth, aHeight, aErrorName)
    if not aCmd then
        local lExtension = Helpers.get_file_extension()
        vim.notify("Error: " .. aErrorName .. " command not found for ." .. lExtension, vim.log.levels.ERROR)
        return 1
    end

    local lProjectDir = get_project_dir()

    local lEditor_width = vim.o.columns
    local lEditor_height = vim.o.lines

    local lWin_width = math.floor(lEditor_width * aWidth / 100)
    local lWin_height = math.floor(lEditor_height * aHeight / 100)
    local lCol = math.floor((lEditor_width - lWin_width) / 2)
    local lRow = math.floor((lEditor_height - lWin_height) / 2)

    local lBuf = vim.api.nvim_create_buf(false, true)

    local lOpts = {
        relative = "editor",
        width = lWin_width,
        height = lWin_height,
        col = lCol,
        row = lRow,
        style = "minimal",
        border = "rounded",
    }

    local lWin = vim.api.nvim_open_win(lBuf, true, lOpts)

    vim.fn.termopen(aCmd, {
        cwd = lProjectDir,
        on_exit = function()
            if aSleepDuration >= 0 then
                vim.defer_fn(function()
                    if vim.api.nvim_win_is_valid(lWin) then
                        vim.api.nvim_win_close(lWin, true)
                    end
                end, aSleepDuration * 1000)
            end
        end,
    })
    vim.cmd("startinsert")
end

--
-- run command in a split pane
function TermActions.split_window(aCmd, aSide, aWidth, aHeight, aNewPane, aErrorName)
    if not aCmd then
        local lExtension = Helpers.get_file_extension()
        vim.notify("Error: " .. aErrorName .. " command not found for ." .. lExtension, vim.log.levels.ERROR)
        return 1
    end

    local lProjectDir = get_project_dir()

    if aSide == "v" then
        vim.cmd("split")
    else
        vim.cmd("vsplit")
    end

    vim.cmd("term " .. aCmd)
end

return TermActions
