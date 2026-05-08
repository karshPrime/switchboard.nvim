
-- Env.Lua

local Env = {}

-- confirm tmux is installed
function Env.is_tmux_installed()
    return vim.fn.executable( "tmux" ) == 1
end

-- check if session is in tmux
function Env.is_tmux_running()
    return vim.env.TMUX ~= nil
end

return Env

