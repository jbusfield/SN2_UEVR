local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local paramModule = require("libs/core/params")

local M = {}

local parameterDefaults = {
    channels = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    shape = "capsule",
    radius = 5.0,
    position = {0.0, 0.0, 0.0},
    rotation = {0.0, 0.0, 0.0},
    scale = {1.0, 1.0, 1.0},
    collision_enabled = 0,
    collision_object_type = 0,
    visibile = false,
    generate_overlap_events = true,
    attachTo = 1, -- 0 = left hand, 1 = right hand, 2 = head
}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[collision config] " .. text, logLevel)
	end
end

function M.init(paramManager)
end

return M
