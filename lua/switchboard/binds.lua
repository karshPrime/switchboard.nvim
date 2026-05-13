-- Binds.lua

local Helpers = require("switchboard.helpers")

local Binds = {}

local mode_map = {
    n = "n",
    i = "i",
    v = "v",
    x = "x",
}

--
-- get binds table for a file extension
local function get_binds_for_extension(aExtension, aConfig)
    for _, lConfig in ipairs(aConfig.build_run_config) do
        if vim.tbl_contains(lConfig.extension, aExtension) then
            return lConfig.binds
        end
    end
    return nil
end

--
-- resolve a bind name to its definition { keys, modes_str }
local function resolve_bind(aBindName, aConfig)
    -- 1. project override config
    if aConfig.override_config_from_project then
        local lOverride = aConfig.project_override_config
        if type(lOverride) == "table" then
            if lOverride.binds and lOverride.binds[aBindName] then
                return lOverride.binds[aBindName]
            end
            if #lOverride > 0 then
                local lMatched = Helpers.get_matched_directory_override(aConfig)
                if lMatched and lMatched.binds and lMatched.binds[aBindName] then
                    return lMatched.binds[aBindName]
                end
            end
        end
    end

    -- 2. extension-specific binds
    local lExtension = Helpers.get_file_extension()
    local lExtBinds = get_binds_for_extension(lExtension, aConfig)
    if lExtBinds and lExtBinds[aBindName] then
        return lExtBinds[aBindName]
    end

    return nil
end

--
-- get current vim mode character
local function get_current_mode()
    local mode = vim.api.nvim_get_mode().mode
    if mode == "n" or mode == "no" then
        return "n"
    elseif mode == "i" or mode == "ic" or mode == "ix" then
        return "i"
    elseif mode == "v" or mode == "V" or mode == "\22" then
        return "v"
    elseif mode == "x" then
        return "x"
    end
    return "n"
end

--
-- check if the current mode is allowed by the bind's mode string
local function is_mode_allowed(aModeStr, aCurrentMode)
    return aModeStr:find(aCurrentMode, 1, true) ~= nil
end

--
-- execute a bind
function Binds.execute(aBindName, aConfig)
    local lBind = resolve_bind(aBindName, aConfig)
    if not lBind then
        local lExtension = Helpers.get_file_extension()
        vim.notify("Error: bind '" .. aBindName .. "' not found for " .. lExtension, vim.log.levels.ERROR)
        return
    end

    local lKeys = lBind[1]
    local lModes = lBind[2]
    local lCurrentMode = get_current_mode()

    if not is_mode_allowed(lModes, lCurrentMode) then
        return
    end

    -- escape to normal mode first if in insert mode
    if lCurrentMode == "i" then
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "n", false)
    end

    local lParsedKeys = vim.api.nvim_replace_termcodes(lKeys, true, false, true)
    vim.api.nvim_feedkeys(lParsedKeys, "n", false)
end

--
-- get all available bind names for completion
function Binds.get_available_binds(aConfig)
    local names = {}
    local seen = {}

    -- project override binds
    if aConfig.override_config_from_project then
        local lOverride = aConfig.project_override_config
        if type(lOverride) == "table" and lOverride.binds then
            for name, _ in pairs(lOverride.binds) do
                if not seen[name] then
                    table.insert(names, name)
                    seen[name] = true
                end
            end
        end
    end

    -- extension-specific binds
    local lExtension = Helpers.get_file_extension()
    local lExtBinds = get_binds_for_extension(lExtension, aConfig)
    if lExtBinds then
        for name, _ in pairs(lExtBinds) do
            if not seen[name] then
                table.insert(names, name)
                seen[name] = true
            end
        end
    end

    table.sort(names)
    return names
end

return Binds
