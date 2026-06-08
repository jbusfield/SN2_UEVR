local uevrUtils = require('libs/uevr_utils')
local controllers = require('libs/controllers')
local configui = require("libs/configui")
local reticule = require("libs/reticule")
local hands = require('libs/hands')
local attachments = require('libs/attachments')
local input = require('libs/input')
local pawnModule = require('libs/pawn')
local animation = require('libs/animation')
local montage = require('libs/montage')
local interaction = require('libs/interaction')
local ui = require('libs/ui')
local remap = require('libs/remap')
local ik = require('libs/ik')
local mathLib = require('libs/core/math_lib')
local handsAnimation = require('libs/hands_animation')

uevrUtils.setLogLevel(LogLevel.Debug)


--uevrUtils.setDeveloperMode(true)
--hands.enableConfigurationTool()

ui.init()
montage.init()
interaction.init()
attachments.init()
attachments.setGripUpdateTimeout(400)
reticule.init()
pawnModule.init()
remap.init()
input.init()
ik.init()
hands.setAutoCreateHands(false)

USN2Statics = uevrUtils.find_default_instance("Class /Script/Subnautica2.SN2Statics")

local status = {}

local HandsType = {
	None = 0,
	Forearms = 1,
	IKArms = 2,
	-- None = 1,
	-- Forearms = 2,
	-- IKArms = 3,
}

local versionTxt = "v1.0.0"
local title = "Subnautica 2, First Person Mod " .. versionTxt
local configDefinition = {
	{
		panelLabel = "Subnautica 2 Config",
		saveFile = "subnautica_2_config",
		layout = spliceableInlineArray
		{
			{ widgetType = "text", id = "title", label = title },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "Control" }, { widgetType = "begin_rect", },
                -- {
                --     widgetType = "combo",
                --     id = "handedness_type",
                --     label = "Handedness",
                --     selections = {"Left", "Right"},
                --     initialValue = 2,
				-- 	isHidden = true,
                -- },
                {
                    widgetType = "combo",
                    id = "hands_type",
                    label = "Hands Type",
                    --selections = {"None", "Forearms", "IK Arms"},
                    selections = {"Forearms", "IK Arms"},
                    initialValue = 1,
                },
                {
					widgetType = "checkbox",
					id = "enable_fog",
					label = "Enable Fog",
					initialValue = false
				},
                {
					widgetType = "checkbox",
					id = "physical_driving",
					label = "Physical Driving",
					initialValue = false
				},
				{ widgetType = "indent", width = 20 },
				{
					widgetType = "text",
					id = "physical_driving_info",
					wrapped = true,
					hidden = true,
					label = "   When in the TadPole, momentarily grip with both hands to grab the steering wheel",
				},
				{ widgetType = "unindent", width = 20 },
			    -- {
                --     widgetType = "drag_float3",
                --     id = "tadpole_right_hand_rotation_offset",
                --     label = "TadPole Right Hand Rotation Offset",
                --     speed = 0.5,
                --     range = {-360, 360},
                --     initialValue = {0,0,0}
                -- },
			    -- {
                --     widgetType = "drag_float3",
                --     id = "tadpole_right_hand_location_offset",
                --     label = "TadPole Right Hand Location Offset",
                --     speed = 0.1,
                --     range = {-1000, 1000},
                --     initialValue = {0,0,0}
                -- },
 			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "UI" }, { widgetType = "begin_rect", },
				expandArray(ui.getConfigurationWidgets, {{id="uevr_ui_reduceMotionSickness",isHidden=true}}),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "Input" }, { widgetType = "begin_rect", },
				expandArray(input.getConfigurationWidgets, {{id="uevr_input_config_pawnRotationMode",isHidden=true}}),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			-- { widgetType = "indent", width = 20 }, { widgetType = "text", label = "Reticule" }, { widgetType = "begin_rect", },
			-- 	expandArray(reticule.getConfigurationWidgets,{{id="uevr_reticule_eye_dominance",isHidden=true},{id="uevr_reticule_eye_dominance_offset",isHidden=true}}),
			-- { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			-- { widgetType = "new_line" },

		}
	}
}

local function regenerateHands(value)
    hands.setAutoCreateHands(value == HandsType.Forearms)
    ik.setAutoCreateArms(value == HandsType.IKArms)

    hands.destroyHands()
    ik.destroyAll()
end

local function hideScubaMask()
	local scubaMaskComponent = uevrUtils.getValid(pawn, {"ScubaMaskSections"})
	if scubaMaskComponent ~= nil then
		local children = scubaMaskComponent.AttachChildren
		if children ~= nil then
			for i, child in ipairs(children) do
				child:SetHiddenInGame(true)
			end
		end
	end
end

ik.registerOnDestroyCallback(function(ikInstance)
	--detach attachments first so they dont get "lost" when hands are destroyed
	attachments.detachGripAttachments(Handed.Right)
	attachments.detachGripAttachments(Handed.Left)
end)

hands.registerOnDestroyCallback(function()
	--detach attachments first so they dont get "lost" when hands are destroyed
	attachments.detachGripAttachments(Handed.Right)
	attachments.detachGripAttachments(Handed.Left)
end)

hands.onCreatedCallback(function(hand, component, name)
	print("Created hand", name)
	component:SetMaterial(0, component:GetMaterial(1))
end)

ik.registerOnMeshCreatedCallback(function(meshComponentList, ikInstance)
	for i, meshComponent in ipairs(meshComponentList or {}) do
		meshComponent:SetMaterial(0, meshComponent:GetMaterial(1))
	end
end)

function getCustomIKComponent(rigID)
	local path = "Pawn"
	if status.currentVehicle == "TadPole" then
		path = "Pawn.Pilot"
	end
    return {{descriptor = path .. ".Body"}, {descriptor = path .. ".Hands", animation = "Arms", optional = true}}
end

-- Prevents the animation that moves the weapon away from the skeletal root
local function disableCopyPoseDriver(weaponMesh)
	local animInstance = uevrUtils.getValid(weaponMesh, {"AnimScriptInstance"})
	if animInstance == nil then return end
	if animInstance.SetMeshDriver ~= nil then
		animInstance:SetMeshDriver(nil)
	end
	if animInstance.ValidSourceMesh ~= nil then
		animInstance.ValidSourceMesh = false
	end
end

local function getWeaponMesh()
	local weaponMesh = nil
    local equippedItemsComponent = uevrUtils.getValid(pawn, {"EquippedItemsComponent"})
	if equippedItemsComponent ~= nil then
		local equippedWeapon = equippedItemsComponent:GetEquippedTool()
		--print("Equipped weapon:", equippedWeapon:get_full_name())
		if equippedWeapon ~= nil then
			weaponMesh = equippedWeapon.EquippedMesh
			if weaponMesh == nil then
				weaponMesh = equippedWeapon.RootComponent
			end
		-- else
		-- 	equippedWeapon = equippedItemsComponent:GetEquippableInSlot(uevrUtils.tagFromString("RightItemSocket"));
		-- 	print("Equipped weapon in right item socket:", equippedWeapon)
		-- 	if equippedWeapon ~= nil then
		-- 		weaponMesh = equippedWeapon.EquippedMesh
		-- 	end
		end
	end

    return weaponMesh
end

attachments.registerOnGripUpdateCallback(function()
    local weaponMesh = getWeaponMesh()
	if weaponMesh ~= status.currentWeapon then
		status.currentWeapon = weaponMesh

		--unlock wrist if no weapon is equipped
		if weaponMesh == nil then
			ik.lockWristAxis("ef80f4a6-9402-43eb-95f7-006392f0b54d", false, false, false)
		end
	end

    local rightHandComponent = nil
   	local leftHandComponent = nil
    if configui.getValue("hands_type") == HandsType.None then
        rightHandComponent = controllers.getController(Handed.Right)
        leftHandComponent = controllers.getController(Handed.Left)
    elseif configui.getValue("hands_type") == HandsType.Forearms then
        rightHandComponent = hands.getHandComponent(Handed.Right)
        leftHandComponent = hands.getHandComponent(Handed.Left)
    elseif configui.getValue("hands_type") == HandsType.IKArms then
        rightHandComponent = ik.getCurrentMesh()
		leftHandComponent = ik.getCurrentMesh()
    end

    local weaponAttachSocket =  "hand_r" --"ToolSocket" --"hand_rSocket" --"RightItemSocket" --"middle_03_r"
	return rightHandComponent and weaponMesh, rightHandComponent, weaponAttachSocket
end)

attachments.registerAttachmentInitializedCallback(function(attachment)
	print("Attachment initialized callback for attachment", attachment:get_full_name())
	disableCopyPoseDriver(attachment)
	local isWavemaker = string.find(attachment:get_full_name(), "BP_Wakemaker") ~= nil
	if isWavemaker then
		attachment:HideBoneByName(uevrUtils.fname_from_string("wakemaker_l"), 0)
		attachment:HideBoneByName(uevrUtils.fname_from_string("forearmGrip_l"), 0)
		attachment:HideBoneByName(uevrUtils.fname_from_string("grip_l"), 0)
		local batteryChild = uevrUtils.getChildComponent(attachment, "ToolBatteryMesh_Left")
		if batteryChild ~= nil then
			batteryChild:SetHiddenInGame(true)
		end
	end
	ik.lockWristAxis("ef80f4a6-9402-43eb-95f7-006392f0b54d", isWavemaker, isWavemaker, false)
end)

local function cleanup()
    status = {}
end

local function setBodyOffsets()
	local equippedItems = uevrUtils.getValid(status.currentPawn, {"EquippedItemsComponent", "EquippedItems"})
	if equippedItems ~= nil then
		for index, equippedItem in ipairs(equippedItems) do
			local blueprintItems = equippedItem.BlueprintCreatedComponents
			if blueprintItems ~= nil then
				local offset = input.getHeadOffset()
				--print("Updating body mesh offset with head offset", offset.X, offset.Y, offset.Z)
				if offset ~= nil then
					offset.X = -offset.X
					offset.Y = -offset.Y
					offset.Z = -offset.Z
					for blueprintIndex, blueprintItem in ipairs(blueprintItems) do
						local className = blueprintItem:get_class()
						if blueprintItem:is_a(uevrUtils.get_class("Class /Script/Engine.SkeletalMeshComponent")) then
							--print("Found a skeletal mesh component in equipped items, applying body offset", offset.X, offset.Y, offset.Z)
							blueprintItem.RelativeLocation = offset
						end
					end
				end
			end
		end
	end
end

local function hideLowHealthBackground()
	local foundWidgets = {}
	local widgetClass = uevrUtils.get_class("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WBP_PlayerIndicator_LowHealth.WBP_PlayerIndicator_LowHealth_C")
    ---@diagnostic disable-next-line: undefined-field
    WidgetBlueprintLibrary:GetAllWidgetsOfClass(uevrUtils.get_world(), foundWidgets, widgetClass, false)
	if foundWidgets ~= nil and #foundWidgets > 0 then
		for _, widget in ipairs(foundWidgets) do
			widget:SetVisibility(1)
		end
	else
		delay(3000, hideLowHealthBackground)
	end
end


function on_level_change(level)
    cleanup()
    regenerateHands(configui.getValue("hands_type") or 1)
	hideScubaMask()
	uevrUtils.setUEVRParam("VR_AimMethod", 1)
	delay(5000, function()
		uevrUtils.setUEVRParam("VR_AimMethod", 0)
	end)

	hideLowHealthBackground()
end

local function getTopLevelWidgetsOnScreen(layerNames)
    local result = {}

	local windowManager = USN2Statics:GetWindowManager(uevrUtils.get_world())
    --local windowManager = uevrUtils.find_first_of("Class /Script/UWECommonUI.WindowManager", false)
    local mainScreen = windowManager and windowManager.MainScreen or nil
    if mainScreen == nil then
        return result
    end


    for _, layerName in ipairs(layerNames) do
        local layer = mainScreen[layerName]
        if layer ~= nil then
            local widget = layer.DisplayedWidget
            if widget ~= nil then
                table.insert(result, {
                    layer = layerName,
                    widget = widget,
                    className = widget:get_class():get_full_name(),
                    fullName = widget:get_full_name(),
                })
            end
        end
    end

    return result
end

local function enableFog(enabled)
	uevrUtils.set_cvar_int("r.VolumetricCloud", enabled and 1 or 0)
	uevrUtils.set_cvar_int("r.VolumetricFog", 1)
	--uevrUtils.set_cvar_int("r.Atmosphere ", enabled and 1 or 0)
	uevrUtils.set_cvar_int("ShowFlag.VolumetricCloud", enabled and 1 or 0)
	uevrUtils.set_cvar_int("ShowFlag.VolumetricFog", enabled and 1 or 0)
	uevrUtils.set_cvar_int("ShowFlag.UWEWaterLighting", enabled and 1 or 0)
end

setInterval(5000, setBodyOffsets)
setInterval(5000, hideScubaMask)

local screenWidgets = {}
setInterval(1000, function()
	local layerNames = {
        "HUD",
        "Modal",
        --"AboveModal",
        "PauseScreen",
        --"AbovePauseScreen",
        --"Debug",
    }

	local widgets = getTopLevelWidgetsOnScreen(layerNames)
    local currentWidgets = {}
	for i, widgetInfo in ipairs(widgets) do
		local widget = widgetInfo.widget
		local widgetKey = tostring(widget) --keys look like sol.uevr::API::UObject*: 00000233A4B9FEA8
		local isShown = true --widget:IsShown()
		currentWidgets[widgetKey] = {widget = widget, isShown = isShown}

		-- Check if this is a new widget or state changed
		local previousState = screenWidgets[widgetKey]
		if previousState == nil or previousState.isShown ~= isShown then
			-- State changed - update viewport accordingly
			if isShown then
				ui.addViewportWidget(widget)
			else
				ui.removeViewportWidget(widget)
			end
		end
	end

	-- Check for removed widgets and clean up
	for widgetKey, widgetData in pairs(screenWidgets) do
		if currentWidgets[widgetKey] == nil then
			-- Widget was removed - remove from viewport if it was shown
			if widgetData.isShown then
				ui.removeViewportWidget(widgetData.widget)
			end
		end
	end

	-- Update the tracked widgets
	screenWidgets = currentWidgets
end)

local function updateVehicleOrientation()
	if status.physicalDriving ~= nil and status.physicalDriving.isGrippingWheel then
		local pc = uevr.api:get_player_controller(0)
		if pc ~= nil and pc.ControlRotation ~= nil then
			if status.vehiclePitch == nil then
				status.vehiclePitch = pc.ControlRotation.Pitch
				status.vehicleYaw = pc.ControlRotation.Yaw
			end
			local leftRotation = controllers.getControllerRotation(Handed.Left)
			local rightRotation = controllers.getControllerRotation(Handed.Right)
			local averagePitch = nil
			local averageRoll = nil

			if leftRotation ~= nil and rightRotation ~= nil then
				averagePitch = ((leftRotation.Pitch or 0) + (rightRotation.Pitch or 0)) * 0.5
				averageRoll = ((leftRotation.Roll or 0) + (rightRotation.Roll or 0)) * 0.5
			elseif rightRotation ~= nil then
				averagePitch = rightRotation.Pitch
				averageRoll = rightRotation.Roll
			elseif leftRotation ~= nil then
				averagePitch = leftRotation.Pitch
				averageRoll = leftRotation.Roll
			end

			if averagePitch ~= nil and averageRoll ~= nil then
				status.vehiclePitch = averagePitch - 15
				status.vehicleYaw = mathLib.normalizeDeg180(status.vehicleYaw + (averageRoll * 0.03))
				status.physicalDriving.pitchDelta = mathLib.normalizeDeg180(status.vehiclePitch - (pc.ControlRotation.Pitch or status.vehiclePitch))
				status.physicalDriving.yawDelta = mathLib.normalizeDeg180(status.vehicleYaw - (pc.ControlRotation.Yaw or status.vehicleYaw))
			else
				status.physicalDriving.pitchDelta = 0
				status.physicalDriving.yawDelta = 0
			end
		end
	end
end

local function releaseVehicle()
	print("Releasing vehicle, resetting orientation and detaching accessories")
	status.vehiclePitch = nil
	status.vehicleYaw = nil
	if status.physicalDriving ~= nil then
		status.physicalDriving.pitchDelta = 0
		status.physicalDriving.yawDelta = 0
	end
	uevrUtils.executeUEVRCallbacks("on_accessory_detach", Handed.Right)
	uevrUtils.executeUEVRCallbacks("on_accessory_detach", Handed.Left)
	handsAnimation.setHoldingAttachment(Handed.Right, nil)
	handsAnimation.setHoldingAttachment(Handed.Left, nil)
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	if pawn == nil then return end

	if pawn.BPC_PowerCell ~= nil then
		status.currentPawn = pawn.Pilot
		status.currentVehicle = "TadPole"
	else
		status.currentPawn = pawn
		status.currentVehicle = "Default"
	end
	if status.lastVehicle ~= status.currentVehicle then
		status.physicalDriving = nil
		releaseVehicle()

		status.lastVehicle = status.currentVehicle
		pawnModule.setCurrentProfileByLabel(pawn.BPC_PowerCell ~= nil and "TadPole" or "Default")
		input.setCurrentProfileByLabel(pawn.BPC_PowerCell ~= nil and "TadPole" or "Default")
		ik.setCurrentProfileByLabel(pawn.BPC_PowerCell ~= nil and "TadPole" or "Default")
		ik.setPawn(status.currentPawn)
		regenerateHands(configui.getValue("hands_type") or 1)
		hideScubaMask()
		if status.currentVehicle == "TadPole" then
			uevr.params.vr.recenter_view()
		end
	end

	--zero body rotation when in vehicle
	if pawn.BPC_PowerCell ~= nil then
		status.currentPawn.RootComponent.RelativeRotation.Pitch = 0
		status.currentPawn.RootComponent.RelativeRotation.Yaw = 0
		status.currentPawn.RootComponent.RelativeRotation.Roll = 0
	end

	-- Fix for cinematics
	local isMovementLocked = pawn ~= nil and pawn.AttachedToOwner ~= nil
	if status.isMovementLocked ~= isMovementLocked then
		status.isMovementLocked = isMovementLocked
		if status.currentVehicle == "Default" then
			local inBioBed = pawn.AttachedToOwner ~= nil and string.find(pawn.AttachedToOwner:get_full_name(), "BioBed")
			local holdingTadPole = pawn.AttachedToOwner ~= nil and string.find(pawn.AttachedToOwner:get_full_name(), "Tadpole")
			local touchingAdaptation = false
			if pawn.AttachedToOwner ~= nil and pawn.AttachedToOwner.AttachmentComponentsCache ~= nil then
				for _, component in ipairs(pawn.AttachedToOwner.AttachmentComponentsCache) do
					if string.find(component:get_full_name(), "BlightCoreRewardButton") then
						touchingAdaptation = true
						break
					end
				end
			end

			if inBioBed or status.inBioBed then
				input.setRotationModeRotationDisabled(status.isMovementLocked)
				input.setOverridePawnRotationMode(status.isMovementLocked and 1 or nil)
				--input.setOverrideAimMethod(status.isMovementLocked and 1 or nil)

				input.setMeshRelativePositionDisabled(status.isMovementLocked)
				ui.setCustomState("viewLocked", uevrUtils.ternary(status.isMovementLocked, true, nil), 2)
				ui.setCustomState("decouplePitch", uevrUtils.ternary(status.isMovementLocked, false, nil), 2)
				ui.setCustomState("autoAdjustUI", uevrUtils.ternary(status.isMovementLocked, false, nil), 2)
				ui.setCustomState("handsEnabled", uevrUtils.ternary(status.isMovementLocked, false, nil), 2)
				ui.setCustomState("pawnArmBones", uevrUtils.ternary(status.isMovementLocked, true, nil), 2)
				--ui.setCustomState("inputEnabled", uevrUtils.ternary(status.isMovementLocked, false, nil), 2)
				--status.forceHead = status.isMovementLocked
				pawn.Head:SetHiddenInGame(not status.isMovementLocked)
				pawn.Hair:SetHiddenInGame(not status.isMovementLocked)

				uevrUtils.enableCameraLerp(status.isMovementLocked, true, true, true, status.isMovementLocked and 0.02 or 1.0)
			end
			if holdingTadPole or status.holdingTadPole then
				print("Holding TadPole")
				-- input.setRotationModeRotationDisabled(status.isMovementLocked)
				-- input.setOverridePawnRotationMode(status.isMovementLocked and 1 or nil)
				-- input.setOverrideAimMethod(status.isMovementLocked and 1 or nil)
				-- input.setMeshRelativePositionDisabled(status.isMovementLocked)
				input.setRotationModeRotationDisabled(status.isMovementLocked)
				input.setOverridePawnRotationMode(status.isMovementLocked and 1 or nil)
				input.setOverrideAimMethod(status.isMovementLocked and 1 or nil)

				delay(1000, function()
					ui.setCustomState("inputEnabled", uevrUtils.ternary(status.isMovementLocked, false, nil), 2)
				end)
			end
			if touchingAdaptation or status.touchingAdaptation then
				print("Touching Adaptation")
				input.setRotationModeRotationDisabled(status.isMovementLocked)
				input.setOverridePawnRotationMode(status.isMovementLocked and 1 or nil)
				input.setOverrideAimMethod(status.isMovementLocked and 1 or nil)

				-- input.setRotationModeRotationDisabled(status.isMovementLocked)
				-- input.setOverridePawnRotationMode(status.isMovementLocked and 1 or nil)
				-- input.setOverrideAimMethod(status.isMovementLocked and 1 or nil)
				-- input.setMeshRelativePositionDisabled(status.isMovementLocked)
				delay(2000, function()
					ui.setCustomState("inputEnabled", uevrUtils.ternary(status.isMovementLocked, false, nil), 2)
				end)
			end
			
			status.inBioBed = inBioBed
			status.holdingTadPole = holdingTadPole
			status.touchingAdaptation = touchingAdaptation
		end
	end

end)

uevrUtils.registerUEVRCallback("on_input_mesh_relative_position_change", function(x, y)
	local currentPawn = uevrUtils.getValid(status.currentPawn)
	if currentPawn ~= nil and currentPawn.Mesh ~= nil then
		currentPawn.Mesh.RelativeLocation.X = x
		currentPawn.Mesh.RelativeLocation.Y = y
		currentPawn.Body.RelativeLocation.X = x
		currentPawn.Body.RelativeLocation.Y = y
		currentPawn.Head.RelativeLocation.X = x
		currentPawn.Head.RelativeLocation.Y = y
		currentPawn.Hair.RelativeLocation.X = x
		currentPawn.Hair.RelativeLocation.Y = y
		currentPawn.Neck.RelativeLocation.X = x
		currentPawn.Neck.RelativeLocation.Y = y
		currentPawn.Feet.RelativeLocation.X = x
		currentPawn.Feet.RelativeLocation.Y = y
	end
end)

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
	-- Prevent the pawn from pitching with arm movements
	local scriptInstance = uevrUtils.getValid(pawn, {"Mesh", "AnimScriptInstance"})
	if scriptInstance ~= nil and scriptInstance.AnimationComponent ~= nil then
		scriptInstance.AnimationComponent.LocalCameraRotation.Pitch = 0
		scriptInstance.AnimationComponent.LocalCameraRotation.Yaw = 0
		scriptInstance.AnimationComponent.LocalCameraRotation.Roll = 0
	end

	updateVehicleOrientation()
end)

local ANALOG_MAX = 32767
local VEHICLE_PITCH_DELTA_FOR_FULL_INPUT = 20
local VEHICLE_PITCH_DEADZONE = 0.05
local VEHICLE_YAW_DELTA_FOR_FULL_INPUT = 10

local function scaleYawDeltaToThumbValue(delta, fullInputDelta)
	if delta == nil or fullInputDelta == nil or fullInputDelta == 0 then
		return 0
	end

	local normalized = delta / fullInputDelta
	local clamped = math.max(-1, math.min(1, normalized))
	return math.floor(clamped * ANALOG_MAX)
end

local function scalePitchDeltaToThumbValue(delta)
	if delta == nil then
		return 0
	end

	local magnitude = math.abs(delta)
	if magnitude <= VEHICLE_PITCH_DEADZONE then
		return 0
	end

	local normalized = math.max(0, math.min(1, (magnitude - VEHICLE_PITCH_DEADZONE) / (VEHICLE_PITCH_DELTA_FOR_FULL_INPUT - VEHICLE_PITCH_DEADZONE)))
	local curved = normalized * normalized
	local signedValue = curved * (delta < 0 and -1 or 1)
	return math.floor(signedValue * ANALOG_MAX)
end

uevrUtils.registerOnPreInputGetStateCallback(function(retval, user_index, state)
	if ui.isRemapDisabled() ~= true then
		if configui.getValue("physical_driving") and status.currentVehicle ~= "Default" then
			if status.physicalDriving == nil then status.physicalDriving = {} end
			local leftGripPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			local rightGripPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			local newGripPressed = leftGripPressed and rightGripPressed
			if status.physicalDriving.isGripping ~= newGripPressed then
				status.physicalDriving.isGripping = newGripPressed
				if newGripPressed then
					status.physicalDriving.isGrippingWheel = not status.physicalDriving.isGrippingWheel 
					if status.physicalDriving.isGrippingWheel then
						--print("Gripping wheel")
						local rotation = configui.getValue("tadpole_right_hand_rotation_offset") or {0,0,0}
						local location = configui.getValue("tadpole_right_hand_location_offset") or {0,0,0}
						--uevrUtils.executeUEVRCallbacks("on_accessory_attach", Handed.Right, pawn.Mesh, "steeringWheel_hand_r", 0, {-6.2, 5.2, -4.0}, {0, -180, 0})
						--uevrUtils.executeUEVRCallbacks("on_accessory_attach", Handed.Left, pawn.Mesh, "steeringWheel_hand_l", 0, {6.2, -5.2, 4.0}, {0, 0, -180})
						uevrUtils.executeUEVRCallbacks("on_accessory_attach", Handed.Right, pawn.Mesh, "steeringWheel_hand_r", 0, {-6.7, 5.1, -0.6}, {0, -171.5, 0})
						uevrUtils.executeUEVRCallbacks("on_accessory_attach", Handed.Left, pawn.Mesh, "steeringWheel_hand_l", 0, {6.7, -5.1, 0.6}, {0, 0, -188.5})
						handsAnimation.setHoldingAttachment(Handed.Right, "scanner")
						handsAnimation.setHoldingAttachment(Handed.Left, "scanner")
					else
						--print("Not gripping wheel")
						releaseVehicle()
					end
				end
			end
			if not status.physicalDriving.isGrippingWheel or newGripPressed then
				uevrUtils.unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
				uevrUtils.unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
				state.Gamepad.sThumbRY = 0
				state.Gamepad.sThumbRX = 0
				state.Gamepad.sThumbLY = 0
				state.Gamepad.sThumbLX = 0
			end
			if status.physicalDriving.isGrippingWheel then
				state.Gamepad.sThumbRY = scalePitchDeltaToThumbValue(status.physicalDriving.pitchDelta)
				state.Gamepad.sThumbRX = scaleYawDeltaToThumbValue(status.physicalDriving.yawDelta, VEHICLE_YAW_DELTA_FOR_FULL_INPUT)
			end
		else
		end
	end
end)

configui.onUpdate("tadpole_right_hand_rotation_offset", function(value)
	--pawn.Mesh is correct here because we want the tadpole mesh
	local location = configui.getValue("tadpole_right_hand_location_offset") or {X=0, Y=0, Z=0}
	uevrUtils.executeUEVRCallbacks("on_accessory_attach", Handed.Left, pawn.Mesh, "steeringWheel_hand_l", 0, {location.X or 0, location.Y or 0, location.Z or 0}, {value.Pitch, value.Yaw, value.Roll})
end)

configui.onUpdate("tadpole_right_hand_location_offset", function(value)
	local rotation = configui.getValue("tadpole_right_hand_rotation_offset") or {Pitch=0, Yaw=0, Roll=0}
	uevrUtils.executeUEVRCallbacks("on_accessory_attach", Handed.Left, pawn.Mesh, "steeringWheel_hand_l", 0, {value.X or 0, value.Y or 0, value.Z or 0}, {rotation.Pitch or 0, rotation.Yaw or 0, rotation.Roll or 0})
end)

configui.onCreateOrUpdate("hands_type", function(value)
    regenerateHands(value)
end)

configui.onCreateOrUpdate("enable_fog", function(value)
	enableFog(value)
end)

configui.onCreateOrUpdate("physical_driving", function(value)
	configui.setHidden("physical_driving_info", not value)
end)

configui.create(configDefinition)

