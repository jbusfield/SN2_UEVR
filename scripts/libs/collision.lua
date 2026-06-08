local uevrUtils = require("libs/uevr_utils")
local paramModule = require("libs/core/params")
local controllers = require("libs/controllers")
require("libs/enums/unreal")

local M = {}

local collisionConfigDev = nil
local status = {}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[collision] " .. text, logLevel)
	end
end

local NamedChannels = {
    WorldStatic = 0,
    WorldDynamic = 1,
    Pawn = 2,
    Visibility = 3,
    Camera = 4,
    PhysicsBody = 5,
    Vehicle = 6,
    Destructible = 7,
}

local parametersFileName = "collision_parameters"
local parameters = {
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

local paramManager = paramModule.new(parametersFileName, parameters, true)
paramManager:load(true)

local function getParameter(key)
    return paramManager:getFromActiveProfile(key)
end

local function setParameter(key, value, persist)
    return paramManager:setInActiveProfile(key, value, persist)
end

local createConfigMonitor = doOnce(function()
	uevrUtils.registerUEVRCallback("on_collision_config_param_change", function(key, value)
		setParameter(key, value, true)
	end)
end, Once.EVER)

function M.init(isDeveloperMode, logLevel)
	if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
        collisionConfigDev = require("libs/config/collision_config_dev")
        collisionConfigDev.init(paramManager)
		createConfigMonitor()
    else
    end
end

function M.destroy(id)
    if status.colliders == nil or status.colliders[id] == nil then return end
	local collider = uevrUtils.getValid(status.colliders[id]["collider"])
	if collider ~= nil then
		uevrUtils.destroyComponent(collider, false, false)
	end
	status.colliders[id] = nil
end

function M.getLocation(id)
    if status.colliders == nil or status.colliders[id] == nil then
        return nil
    end
    local collider = uevrUtils.getValid(status.colliders[id]["collider"])
    if collider ~= nil then
        return collider:K2_GetComponentLocation()
    end
    return nil
end

local function updateColliders()
	if status.colliders == nil then
		return
	end

    local locations = {}
    local rotations = {}
	for id, data in pairs(status.colliders) do
        if locations[data.handed] == nil then
            locations[data.handed] = controllers.getControllerLocation(data.handed)
		end
        if rotations[data.handed] == nil then
            rotations[data.handed] = controllers.getControllerRotation(data.handed)
		end
		local collider = data.collider
		if collider ~= nil and collider.K2_SetWorldLocation ~= nil then
			collider:K2_SetWorldLocation(locations[data.handed], true, reusable_hit_result, false)
			collider:K2_SetWorldRotation(rotations[data.handed], true, reusable_hit_result, false)
		end
	end
end

function M.create(id, collisionParent, handed)
    if collisionParent ~= nil then
		M.destroy(id)
		local collider = uevrUtils.create_component_of_class("Class /Script/Engine.SphereComponent", false, nil, false, collisionParent)
		if collider ~= nil then
			collider:SetSphereRadius(5.0, false)
			collider:SetCollisionObjectType(2)       -- ECC_Pawn
			collider:SetCollisionEnabled(3)          -- QueryOnly
			collider:SetCollisionResponseToAllChannels(0)
			collider:SetCollisionResponseToChannel(0, 2)  -- WorldStatic / walls
			collider:SetCollisionResponseToChannel(1, 2)  -- WorldDynamic / door mesh
			collider:SetCollisionResponseToChannel(19, 1) -- GameTraceChannel6 / NP pre-hit detector
            
            collider:SetVisibility(false)
			
            collider.bGenerateOverlapEvents = true

			if status.colliders == nil then status.colliders = {} end
			status.colliders[id] = {collider = collider, handed = handed}
            return collider
		end
	end

end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    updateColliders()
end)

return M