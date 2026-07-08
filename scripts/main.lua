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
local gestures = require('libs/gestures')
local collision = require('libs/collision')
local plugin = require('libs/core/plugin')
--local debugModule = require("libs/uevr_debug")

--uevrUtils.setLogLevel(LogLevel.Debug)
--attachments.setLogLevel(LogLevel.Debug)
--animation.setLogLevel(LogLevel.Debug)

--uevrUtils.setDeveloperMode(true)
--hands.enableConfigurationTool()
-- uevrUtils.profiler:toggle(true)
-- register_key_bind("F4", function()
--     print("F4 pressed")
--     uevrUtils.profiler:report()
-- end)

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
collision.init()
hands.setAutoCreateHands(false)

USN2Statics = uevrUtils.find_default_instance("Class /Script/Subnautica2.SN2Statics")

local status = {}
uevrUtils.setHandedness(Handed.Right)

local HandsType = {
	None = 0,
	Forearms = 1,
	IKArms = 2,
	-- None = 1,
	-- Forearms = 2,
	-- IKArms = 3,
}

local versionTxt = "v1.0.3"
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
                -- {
				-- 	widgetType = "checkbox",
				-- 	id = "enable_fog",
				-- 	label = "Enable Fog",
				-- 	initialValue = true
				-- },
                {
					widgetType = "checkbox",
					id = "physical_interaction",
					label = "Physical Interaction",
					initialValue = false
				},
				{ widgetType = "begin_group", id = "physical_interaction_info_group", isHidden = true },
				{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "How to use" }, { widgetType = "begin_rect", },
                { widgetType = "indent", width = 10 },
				{ widgetType = "text", wrapped = true, label = "Grab objects: Grip left or right while your hand is in contact with the object", },
				{ widgetType = "text", wrapped = true, label = "Put object in inventory: Reach hand up to ear while gripping object and then release grip", },
				{ widgetType = "text", wrapped = true, label = "Open Inventory: Grip with empty hand near ear", },
				{ widgetType = "text", wrapped = true, label = "Swim up/down: Grips do not affect movement up/down in this mode. Use Right Stick forward/back", },
				{ widgetType = "text", wrapped = true, label = "Open Lockers/Storage: Grip with hand on locker/storage", },
				{ widgetType = "text", wrapped = true, label = "Small Storage: Trigger with hand on storage", },
				{ widgetType = "text", wrapped = true, label = "Press Buttons/Interactables: Trigger with hand on button/interactable", },
				{ widgetType = "text", wrapped = true, label = "Break Large Resources: Swing and hit the resource with your MultiTool activated (or with your hand for resources that don't require MultiTool)", },
				{ widgetType = "text", wrapped = true, label = "Frighten Predator: Swing and hit the predator with your MultiTool activated", },
                { widgetType = "unindent", width = 10 },
            	{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
				{ widgetType = "new_line" },
				{ widgetType = "end_group", },
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
				{
					widgetType = "checkbox",
					id = "hide_hover_widget",
					label = "Hide Hover Overlays",
					initialValue = false
				},
				expandArray(ui.getConfigurationWidgets, {{id="uevr_ui_reduceMotionSickness",isHidden=true}}),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			-- { widgetType = "indent", width = 20 }, { widgetType = "text", label = "Overlay" }, { widgetType = "begin_rect", },
            --     {
            --         widgetType = "drag_float2",
            --         id = "overlay_scale",
            --         label = "Scale",
            --         speed = .01,
            --         range = {0.01, 2},
            --         initialValue = {1, 1}
            --     },
            -- { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			-- { widgetType = "new_line" },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "Input" }, { widgetType = "begin_rect", },
				expandArray(input.getConfigurationWidgets, {{id="uevr_input_config_pawnRotationMode",isHidden=true}}),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "Reticule" }, { widgetType = "begin_rect", },
				expandArray(reticule.getConfigurationWidgets,{{id="uevr_reticule_eye_dominance",isHidden=true},{id="uevr_reticule_eye_dominance_offset",isHidden=true}}),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			{
				widgetType = "tree_node",
				id = "advanced_settings",
				initialOpen = false,
				label = "Advanced"
			},
                {
					widgetType = "checkbox",
					id = "disable_reflections",
					label = "Disable Reflections",
					initialValue = false
				},
				{ widgetType = "indent", width = 20 },
				{
					widgetType = "text",
					id = "disable_reflections_info",
					wrapped = true,
					label = "Disabling reflections can fix small mismatches between the right and left eyes that can annoy some users. Disabling reflections however, can have a small FPS penalty.",
				},
				{ widgetType = "unindent", width = 20 },
                {
					widgetType = "checkbox",
					id = "disable_post_process_materials",
					label = "Disable Post Process Materials",
					initialValue = true
				},
				{ widgetType = "indent", width = 20 },
				{
					widgetType = "text",
					id = "disable_post_process_materials_info",
					wrapped = true,
					label = "Disabling post process materials can boost FPS.",
				},
				{ widgetType = "unindent", width = 20 },
			{ widgetType = "tree_pop" }

		}
	}
}
-- local options = {
-- 	{label = "Default", shape=ui.ShapeEnum.Flat, headLockedUISize = 2.0, headLockedUIPosition = {X=0, Y=0, Z=2.0}},
-- 	{label = "Helmet", shape=ui.ShapeEnum.Cylinder, headLockedUISize = 0.53, headLockedUIPosition = {X=-0.02, Y=-0.07, Z=0.34}}
-- }
-- ui.setHeadLockedUIOptions(options)

local function cleanup()
    status = {}
end


local function getGrabItem(handed)
	if status.grabItem ~= nil then
		return status.grabItem[handed]
	end
	return nil
end
local function getGrabItemParent(handed)
	local grabItem = getGrabItem(handed)
	if grabItem ~= nil then
		return uevrUtils.getValid(grabItem.parent)
	end
	return nil
end
local function getGrabItemComponent(handed)
	local grabItem = getGrabItem(handed)
	if grabItem ~= nil then
		return uevrUtils.getValid(grabItem.component)
	end
	return nil
end
local function isGrabbingItem(handed)
	return status.grabItem ~= nil and status.grabItem[handed] ~= nil and status.grabItem[handed].parent ~= nil
end
local function releaseGrabItem(handed)
	if status.grabItem ~= nil then status.grabItem[handed] = nil end
end

local function isItemGrippedByOtherHand(handed, itemActor)
	if itemActor == nil then return false end
	local otherGrab = status.grabItem and status.grabItem[1 - handed]
	if otherGrab == nil or otherGrab.parent == nil then return false end
	local otherSource = uevrUtils.getValid(otherGrab.sourceActor)
	local otherParent = uevrUtils.getValid(otherGrab.parent)
	if otherSource ~= nil and otherSource == itemActor then return true end
	if otherParent ~= nil and otherParent == itemActor then return true end
	return false
end

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
	collision.destroy("right_hand")
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
	local collisionParent = uevrUtils.getValid(pawn)
	for i, meshComponent in ipairs(meshComponentList or {}) do
		meshComponent:SetMaterial(0, meshComponent:GetMaterial(1))
		if collisionParent == nil and meshComponent.GetOwner ~= nil then
			collisionParent = uevrUtils.getValid(meshComponent:GetOwner())
		end
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

local defaultAttachOptions = {
	detachFromOriginOnGrip = false,
	maintainWorldPositionOnDetachFromOrigin = true,
	detachFromParentOnRelease = true,
	maintainWorldPositionOnDetachFromParent = true,
	reattachToOriginOnRelease = true,
	restoreTransformToOriginOnReattach = true,
	useZeroTransformOnReattach = false,
	allowChildVisibilityHandling = false,
	allowChildHiddenInGameHandling = false,
	allowRenderInMainPassHandling = false,
    useCurrentAttachedSocketName = false,
	allowMobiltyChange = true
}

local function getHandComponents()
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

    return rightHandComponent, leftHandComponent
end

attachments.registerOnGripUpdateCallback(function()
    local weaponMesh = getWeaponMesh()
	if weaponMesh == nil and isGrabbingItem(Handed.Right) then
		weaponMesh = getGrabItemComponent(Handed.Right)
	end

	if weaponMesh ~= status.currentWeapon then
		status.currentWeapon = weaponMesh

		--unlock wrist if no weapon is equipped
		if weaponMesh == nil then
			ik.lockWristAxis("ef80f4a6-9402-43eb-95f7-006392f0b54d", false, false, false)
		end
	end

	local rightHandComponent, leftHandComponent = getHandComponents()

   --local weaponAttachSocket =  "hand_r" --"ToolSocket" --"hand_rSocket" --"RightItemSocket" --"middle_03_r"
	local leftItemMesh = getGrabItemComponent(Handed.Left)
	return rightHandComponent and weaponMesh, rightHandComponent, "hand_r", leftItemMesh, leftItemMesh and leftHandComponent, "hand_l", defaultAttachOptions
end)

attachments.registerAttachmentInitializedCallback(function(attachment)
	--print("Attachment initialized callback for attachment", attachment:get_full_name())
	disableCopyPoseDriver(attachment)
	local isWavemaker = string.find(attachment:get_full_name(), "BP_Wakemaker") ~= nil
	if isWavemaker and uevrUtils.getValid(attachment) ~= nil and attachment.HideBoneByName ~= nil then
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

attachments.registerAttachmentChangeCallback(function(id, gripHand, attachment)

	status.zeroManagedComponent = nil
	if attachment ~= nil and attachment:GetOwner() ~= nil and string.find(attachment:GetOwner():get_full_name(), "BP_WaterSlug_C", 1, true) then
		status.zeroManagedComponent = attachment:GetOwner()
	end

	if attachment ~= nil and string.find(attachment:get_full_name(), "SurvivalMultiTool", 1, true) then
		--print("Enabling right hand tool collision")
		collision.disableCollisionByLabel("Right Hand Tool", false)
	else
		--print("Disabling right hand tool collision")
		collision.disableCollisionByLabel("Right Hand Tool", true)
	end
	if status.currentAttachment == nil then status.currentAttachment = {} end
	status.currentAttachment[gripHand] = attachment
end)

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
	delay(1000, function()
		uevrUtils.setUEVRParam("VR_AimMethod", 0)
	end)

	hideLowHealthBackground()
	collision.disableCollisionByLabel("Right Hand Tool", true)
	input.setAimRotationOffset({-17,0,0})

end

--WBP_HoverTargetInfo_C /Engine/Transient.GameEngine_2147482582.SN2GameInstance_2147482520.WBP_MainScreen_C_2147478153.WidgetTree_2147478152.WBP_HUDScreen_C_2147478144.WidgetTree_2147478143.WBP_HoverTargetInfo
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

		--print("Widget class name:", widgetInfo.className)
		--get a reference to the hover widget so it can be hidden or shown on the tick
		if widgetInfo.className == "WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WBP_HUDScreen.WBP_HUDScreen_C" then
			status.hoverWidget = widget.WBP_HoverTargetInfo
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

local function setOverlayScale()
    local widget = uevrUtils.find_first_instance("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/WBP_MainScreen.WBP_MainScreen_C", false)
    if widget ~= nil then
        --print("Changing main widget layout")
        local customScale = uevrUtils.getNativeValue(configui.getValue("overlay_scale"))
        customScale = {X = customScale[1], Y = customScale[2]}
        uevrUtils.setWidgetLayout(widget, status.isInInteractiveUI and {1.0, 1.0} or {customScale.X, customScale.Y}, status.isInInteractiveUI and {0.0, 0.0} or {1 - customScale.X, 1 - customScale.Y})
    end
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
				print("Holding TadPole") -- not working well
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

	local isInInteractiveUI = ui.isRemapDisabled()
    if status.isInInteractiveUI ~= isInInteractiveUI then
        status.isInInteractiveUI = isInInteractiveUI
        setOverlayScale()
    end

	if status.forceGrip and status.forceGrip[Handed.Right] then
		--print(attachments.getCurrentGripAnimation(Handed.Right))
		if isGrabbingItem(Handed.Right) then uevrUtils.executeUEVRCallbacks("attachment_grip_animation_changed", attachments.getCurrentGripAnimation(Handed.Right), Handed.Right) end
	end
	if status.forceGrip and status.forceGrip[Handed.Left] then
		if isGrabbingItem(Handed.Left) then uevrUtils.executeUEVRCallbacks("attachment_grip_animation_changed", attachments.getCurrentGripAnimation(Handed.Left), Handed.Left) end
	end

	-- Water slug offsets at end of animation without this
	if status.zeroManagedComponent ~= nil then
		if status.zeroManagedComponent.UWESkeletalMeshComponentManaged ~= nil and status.zeroManagedComponent.UWESkeletalMeshComponentManaged.RelativeLocation ~= nil then
			status.zeroManagedComponent.UWESkeletalMeshComponentManaged.RelativeLocation.X = 0
			status.zeroManagedComponent.UWESkeletalMeshComponentManaged.RelativeLocation.Y = 0
			status.zeroManagedComponent.UWESkeletalMeshComponentManaged.RelativeLocation.Z = 0
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

gestures.registerSwipeRightCallback(function(strength, hand)
    if hand == Handed.Right then
    	status["hasSwipeRight"] = true
		delay(600, function() status["hasSwipeRight"] = false end)
    else
        status["hasSwipeLeft"] = true
		delay(600, function() status["hasSwipeLeft"] = false end)
    end
end, true, true)

gestures.registerSwipeLeftCallback(function(strength, hand)
    if hand == Handed.Right then
    	status["hasSwipeRight"] = true
		delay(600, function() status["hasSwipeRight"] = false end)
    else
        status["hasSwipeLeft"] = true
		delay(600, function() status["hasSwipeLeft"] = false end)
    end
end, true, true)

--------------------------- Grabbed object velocity calculations --------------------
local GRAB_THROW_VELOCITY_SCALE = 1.0

local function resetGrabVelocityTracking(grabItem)
	if grabItem == nil then return end
	grabItem.velocity = { X = 0, Y = 0, Z = 0 }
	grabItem.lastLoc = nil
	local component = uevrUtils.getValid(grabItem.component)
	if component ~= nil and component.K2_GetComponentLocation ~= nil then
		local loc = component:K2_GetComponentLocation()
		grabItem.lastLoc = { X = loc.X, Y = loc.Y, Z = loc.Z }
	end
end

local function clearGrabVelocityTracking(grabItem)
	if grabItem == nil then return end
	grabItem.velocity = nil
	grabItem.lastLoc = nil
end

local function updateGrabVelocityTracking(grabItem, delta)
	if grabItem == nil then return end
	local component = uevrUtils.getValid(grabItem.component)
	if component == nil or delta == nil or delta <= 0 or component.K2_GetComponentLocation == nil then
		return
	end

	local loc = component:K2_GetComponentLocation()
	local last = grabItem.lastLoc
	local vel = grabItem.velocity
	if vel == nil then
		vel = { X = 0, Y = 0, Z = 0 }
		grabItem.velocity = vel
	end

	if last ~= nil then
		local invDelta = 1 / delta
		vel.X = (loc.X - last.X) * invDelta
		vel.Y = (loc.Y - last.Y) * invDelta
		vel.Z = (loc.Z - last.Z) * invDelta
	end

	if last == nil then
		grabItem.lastLoc = { X = loc.X, Y = loc.Y, Z = loc.Z }
	else
		last.X = loc.X
		last.Y = loc.Y
		last.Z = loc.Z
	end
end
---------------------------
local function checkBreakingNodeTargetNames(parent, targetNames)
	for _, targetName in ipairs(targetNames) do
		--print("checkBreakingNodeTargetNames", targetName, parent:get_full_name())
		if string.find(parent:get_full_name(), targetName, 1, true) then
			status["hasSwipeRight"] = false
			status["hasSwipeLeft"] = false
			return true
		end
	end
	return false
end

local function checkForBreakingResourceNodeByLabel(label, targetNames_A, targetNames_RT)
	local collisionComponents = collision.getCollisionComponentsByLabel(label)
	--print("Checking for breaking resource node", #collisionComponents)
	if collisionComponents ~= nil and #collisionComponents > 0 then
		for _, component in ipairs(collisionComponents) do
			local parent = component:GetOwner()
			if parent ~= nil then
				if label == "Right Hand Tool" and parent:is_a(uevrUtils.get_class("Class /Script/UWEAI.UWEAIPawn")) then
					status["hasSwipeRight"] = false
					status["hasSwipeLeft"] = false
					status.needsRTPress = true
					--print("Hit the target")
					return true
				else
					--print("checkForBreakingResourceNode", label, parent:get_full_name(), component:get_full_name(), parent:get_full_name())
					if checkBreakingNodeTargetNames(parent, targetNames_A) then
						--print("checkForBreakingResourceNode found", label, parent:get_full_name(), component:get_full_name(), parent:get_full_name())
						status.needsAPress = true
						return true
					end
					if checkBreakingNodeTargetNames(parent, targetNames_RT) then
						status.needsRTPress = true
						return true
					end
				end
			end
		end
	end
	return false
end

local function checkForBreakingResourceNode()
	if status["hasSwipeRight"] or status["hasSwipeLeft"] then
		if not checkForBreakingResourceNodeByLabel("Right Hand Tool", {"BP_ResourceNode"}, {"BP_CG_BulbFlower","BP_AcidAnemoneFruit","BP_CherimoyaRotsac_Cage"}) then
			checkForBreakingResourceNodeByLabel("Right Hand Overlap", {"BP_ResourceNode", "BP_CherimoyaRotsac_Cage"}, {})
		end
	end
end

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
	-- Prevent the pawn from pitching with arm movements
	local scriptInstance = uevrUtils.getValid(pawn, {"Mesh", "AnimScriptInstance"})
	if scriptInstance ~= nil and scriptInstance.AnimationComponent ~= nil then
		scriptInstance.AnimationComponent.LocalCameraRotation.Pitch = 0
		scriptInstance.AnimationComponent.LocalCameraRotation.Yaw = 0
		scriptInstance.AnimationComponent.LocalCameraRotation.Roll = 0
	end

	updateVehicleOrientation()

	local reticuleResource = uevrUtils.getValid(status.hoverWidget,{"CurrentInteractionBrush", "ResourceObject"})
	if reticuleResource ~= nil then
		local name = reticuleResource:get_full_name()
		if configui.getValue("hide_hover_widget") then
			status.hoverWidget:SetVisibility(1)
		else
			status.hoverWidget:SetVisibility(string.find(name, "Reticle") and 1 or 0)
		end
	end

	if status.grabItem ~= nil then
		for _, grabItem in pairs(status.grabItem) do
			updateGrabVelocityTracking(grabItem, delta)
		end
	end

	checkForBreakingResourceNode()

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


---------------------------------------------------------------------------------
--- Pickup handling
---------------------------------------------------------------------------------
-- Exact worldpop blueprint suffix -> pickup class to spawn
local WORLD_POP_PICKUP_CLASSES = {
	BP_WorldPopSpawnedCopper_C = "BlueprintGeneratedClass /Game/Blueprints/Items/Resources/BP_Copper.BP_Copper_C",
	BP_WorldPopSpawnedTitanium_C = "BlueprintGeneratedClass /Game/Blueprints/Items/Resources/BP_Titanium.BP_Titanium_C",
	BP_WorldPopSpawnedLead_C = "BlueprintGeneratedClass /Game/Blueprints/Items/Resources/BP_Lead.BP_Lead_C",
	BP_WorldPopSpawnedQuartz_C = "BlueprintGeneratedClass /Game/Blueprints/Items/Resources/BP_Quartz.BP_Quartz_C",
	BP_WorldPopSpawnedSilver_C = "BlueprintGeneratedClass /Game/Blueprints/Items/Resources/BP_Silver.BP_Silver_C",
	BP_WorldPopSpawnedSulfur_C = "BlueprintGeneratedClass /Game/Blueprints/Items/Resources/BP_Sulfur.BP_Sulfur_C",
	BP_WaterSlugWorldPopProxy_C = "BlueprintGeneratedClass /Game/Blueprints/Items/BP_WaterSlug.BP_WaterSlug_C",
	BP_LuciferRotsac_C = "BlueprintGeneratedClass /Game/Blueprints/Items/Resources/BP_LuciferRotsac.BP_LuciferRotsac_C",
	BP_AcidAnemone_MedigelSac_C = "BlueprintGeneratedClass /Game/Blueprints/Resources/BP_AcidAnemone_MedigelSac_Dropped.BP_AcidAnemone_MedigelSac_Dropped_C",
	BP_Halfmoon_variant02_C = "BlueprintGeneratedClass /Game/Blueprints/AI/Agents/SmallCreature007_Halfmoon/BP_Halfmoon_variant02.BP_Halfmoon_variant02_C",
}
-- Substring fallback when worldpop class name doesn't match suffix keys exactly
local WORLD_POP_PICKUP_SUBSTRINGS = {
	WorldPopSpawnedCopper = WORLD_POP_PICKUP_CLASSES.BP_WorldPopSpawnedCopper_C,
	WorldPopSpawnedTitanium = WORLD_POP_PICKUP_CLASSES.BP_WorldPopSpawnedTitanium_C,
	WorldPopSpawnedLead = WORLD_POP_PICKUP_CLASSES.BP_WorldPopSpawnedLead_C,
	WorldPopSpawnedQuartz = WORLD_POP_PICKUP_CLASSES.BP_WorldPopSpawnedQuartz_C,
	WorldPopSpawnedSilver = WORLD_POP_PICKUP_CLASSES.BP_WorldPopSpawnedSilver_C,
	WorldPopSpawnedSulfur = WORLD_POP_PICKUP_CLASSES.BP_WorldPopSpawnedSulfur_C,
	WaterSlug = WORLD_POP_PICKUP_CLASSES.BP_WaterSlugWorldPopProxy_C,
	LuciferRotsac = WORLD_POP_PICKUP_CLASSES.BP_LuciferRotsac_C,
	AcidAnemone = WORLD_POP_PICKUP_CLASSES.BP_AcidAnemone_MedigelSac_C,
	Halfmoon = WORLD_POP_PICKUP_CLASSES.BP_Halfmoon_variant02_C,
}
--should we be able to pick up scannables?
--checkForCollision called forComponent:  StaticMeshComponent /Game/Maps/Main/L_Main/_Generated_/18HIIUCZJ2M7G1J4XJ7JHQPOP.L_Main.PersistentLevel.BP_Rebreather_Scannable_C_UAID_C87F54668C7CE18902_1350195401.BaseMesh

local function getWorldPopClassName(worldPopActor)
	local classObj = worldPopActor:get_class()
	if classObj == nil or classObj.get_full_name == nil then
		return worldPopActor:get_full_name()
	end
	return classObj:get_full_name()
end

local function getWorldPopBlueprintSuffix(worldPopActor)
	local className = getWorldPopClassName(worldPopActor)
	local suffix = string.match(className, "([^%.%s]+_C)%s*$")
	if suffix ~= nil then
		return suffix
	end
	return className
end

local function getPickupClassPathForWorldPop(worldPopActor)
	local className = getWorldPopClassName(worldPopActor)
	local suffix = getWorldPopBlueprintSuffix(worldPopActor)
	local path = WORLD_POP_PICKUP_CLASSES[suffix]
	if path ~= nil then
		print("[worldpop] matched", suffix, "->", path)
		return path
	end
	for key, fallbackPath in pairs(WORLD_POP_PICKUP_SUBSTRINGS) do
		if string.find(className, key, 1, true) then
			print("[worldpop] matched (substring)", key, "in", suffix, "->", fallbackPath)
			return fallbackPath
		end
	end
	print("[worldpop] no pickup mapping for", className, "(suffix:", suffix, ")")
	return nil
end

local function getWorldPopGripMesh(worldPopActor, meshComponent)
	if meshComponent ~= nil and uevrUtils.getValid(meshComponent) ~= nil then
		return meshComponent
	end
	local staticMesh = uevrUtils.getValid(worldPopActor, {"StaticMesh"})
	if staticMesh ~= nil then
		return staticMesh
	end
	return uevrUtils.getValid(worldPopActor, {"RootComponent"})
end

local function hideWorldPopActor(worldPopActor)
	worldPopActor:SetActorHiddenInGame(true)
	worldPopActor:SetActorEnableCollision(false)
end

local function spawnPickupProxyForWorldPop(worldPopActor, meshComponent)
	--print("Spawning pickup proxy for worldpop", worldPopActor:get_full_name(), meshComponent:get_full_name())
	local classPath = getPickupClassPathForWorldPop(worldPopActor)
	if classPath == nil then
		--print("[worldpop] no pickup mapping for", getWorldPopClassName(worldPopActor))
		return nil, nil
	end

	local transform = meshComponent:K2_GetComponentToWorld()
	local pickup = uevrUtils.spawn_actor_of_class(classPath, transform, 1, nil)
	if pickup == nil then
		--print("[worldpop] spawn failed retrying by loading asset:", classPath)
		uevrUtils.getLoadedAsset(classPath)
		pickup = uevrUtils.spawn_actor_of_class(classPath, transform, 1, nil)
	end
	if pickup == nil then
		local gripMesh = getWorldPopGripMesh(worldPopActor, meshComponent)
		if gripMesh ~= nil then
			--print("[worldpop] spawn failed, gripping worldpop actor directly:", worldPopActor:get_full_name())
			return worldPopActor, gripMesh
		end
		print("[worldpop] spawn failed and no grip mesh:", classPath)
		return nil, nil
	end

	local mesh = pickup.Mesh
	if mesh == nil then
		mesh = pickup.MeshComponent
		if mesh == nil then
			--print("[worldpop] spawned pickup has no Mesh or MeshComponent:", pickup:get_full_name())
			uevrUtils.destroy_actor(pickup)
			return nil, nil
		end
	end

	mesh:SetMobility(EComponentMobility.Movable)
    mesh:SetCollisionEnabled(ECollisionEnabled.QueryAndPhysics)
    mesh:SetCollisionObjectType(ECollisionChannel.ECC_PhysicsBody)
    mesh.BodyInstance.bSimulatePhysics = true
    mesh.BodyInstance.bEnableGravity = false
    mesh:SetEnableGravity(false)
    mesh:WakeAllRigidBodies()
    mesh:SetSimulatePhysics(false)
    mesh:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.Ignore)

	hideWorldPopActor(worldPopActor)
	--print("[worldpop] spawned pickup proxy:", pickup:get_full_name(), "from", classPath)
	return pickup, mesh
end

local resourceAttachOptions = {
	detachFromOriginOnGrip = false,
	maintainWorldPositionOnDetachFromOrigin = true,
	detachFromParentOnRelease = true,
	maintainWorldPositionOnDetachFromParent = true,
	reattachToOriginOnRelease = false,
	restoreTransformToOriginOnReattach = false,
	useZeroTransformOnReattach = false,
	allowChildVisibilityHandling = false,
	allowChildHiddenInGameHandling = false,
	allowRenderInMainPassHandling = false,
    useCurrentAttachedSocketName = false,
	allowMobiltyChange = true
}
local function gripResourceItem(handed, parent, component, usePhysicsHandle, sourceActor)
	print("Gripping resource item", parent:get_full_name(), component:get_full_name(), usePhysicsHandle)

	-- Register the grab before attach/physics changes so the other hand sees it immediately.
	if status.grabItem == nil then status.grabItem = {} end
	if status.grabItem[handed] == nil then status.grabItem[handed] = {} end
	status.grabItem[handed].component = component
	status.grabItem[handed].parent = parent
	status.grabItem[handed].sourceActor = sourceActor or parent
	status.grabItem[handed].usePhysicsHandle = usePhysicsHandle or false
	resetGrabVelocityTracking(status.grabItem[handed])

	component:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.Ignore)
	if parent.NetMulticast_SetPhysicsEnabled ~= nil then
		parent:NetMulticast_SetPhysicsEnabled(false, true)
		--parent:SetReplicatedCollisionEnabled(false)
		--parent:SetReplicatedSimulatePhysics(false)
	end

	resourceAttachOptions.usePhysicsHandle = usePhysicsHandle or false
	local rightHandComponent, leftHandComponent = getHandComponents()
	if handed == Handed.Right then
		local rightSuccess = attachments.attachToMesh(component, rightHandComponent, "hand_r", Handed.Right, resourceAttachOptions)
	else
		local leftSuccess = attachments.attachToMesh(component, leftHandComponent, "hand_l", Handed.Left, resourceAttachOptions)
	end
end
local function isCarryingLocker()
	local anim = status.currentPawn and status.currentPawn.BPC_CharacterAnimationComponent
	return anim and anim.bIsCarrying and anim.CarryableActor and string.find(anim.CarryableActor:get_full_name(), "FloatingLocker", 1, true)
end

local triggerNames = {"Button", "Lever", "Blackbox_Clickable", "Nrtv_QuartzChip", "SupplyCrate", "SupplyLocker", "BioBed", "ScannerStation", "ModificationStation", "ProcessorStation", "Fabricator" , "BatteryTerminal",  "PilotVehicleInteraction","UpgradeInventoryInteraction", "ComputerTextInterface", "BlightCoreRewardButton","ScanningButton"}
local triggerDPadNames = {"LabelWidget"}
local function checkForTriggerCollision(handed)
	local collisionComponents = collision.getCollisionComponentsByLabel(handed == Handed.Right and "Right Hand Overlap" or "Left Hand Overlap")
	print("Collision components:", collisionComponents, #collisionComponents)
	if collisionComponents ~= nil and #collisionComponents > 0 then
		for _, component in ipairs(collisionComponents) do
			print("checkForTriggerCollision called forComponent:", component:get_full_name())
			for _, triggerDPadName in ipairs(triggerDPadNames) do
				if string.find(component:get_full_name(), triggerDPadName, 1, true) then
					status.needDPadDown = true
					return true
				end
			end
			for _, triggerName in ipairs(triggerNames) do
				if string.find(component:get_full_name(), triggerName, 1, true) then
					status.needsAPress = true
					return true
				end
			end
		end
	end
	return false
end

local gripNames = {"Lever", "BP_RecipeGainDataCard_Button", "UWEInventoryInteractionComponent", "Nrtv_QuartzChip", "Blackbox_Clickable", "SupplyLocker", "Ladder","PowerInventoryInteraction", "PilotVehicleInteraction", "UpgradeInventoryInteraction", "BlightCoreRewardButton"}
local function checkForGripCollision(handed)
	local collisionComponents = collision.getCollisionComponentsByLabel(handed == Handed.Right and "Right Hand Overlap" or "Left Hand Overlap")
	print("Collision components:", collisionComponents, #collisionComponents)
	if collisionComponents ~= nil and #collisionComponents > 0 then
		for _, component in ipairs(collisionComponents) do
			print("checkForGripCollision called forComponent:", component:get_full_name())
			for _, gripName in ipairs(gripNames) do
				if string.find(component:get_full_name(), gripName, 1, true) then
					status.needsAPress = true
					return true
				end
			end
		end
	end
	return false
end

local function checkForCollision(handed)
	if status.currentAttachment ~= nil and status.currentAttachment[handed] ~= nil then return end
	if isGrabbingItem(handed) then return end

	local collisionComponents = collision.getCollisionComponentsByLabel(handed == Handed.Right and "Right Hand Overlap" or "Left Hand Overlap")
	print("Collision components:", collisionComponents, #collisionComponents)
	if collisionComponents ~= nil and #collisionComponents > 0 then
		for _, component in ipairs(collisionComponents) do
			--print("checkForCollision called forComponent:", component:get_full_name())
			local parent = component:GetOwner()
			-- Skip if the other hand is already gripping this item (compare source actor for proxy grips).
			if isItemGrippedByOtherHand(handed, parent) then
				--print("  Other hand already gripping this item, skipping")
			else
				if component:is_a(uevrUtils.get_class("Class /Script/Engine.CapsuleComponent")) then
					--print("  Found CapsuleComponent component with parent", parent:get_full_name())
					if parent ~= nil then
						local pickup, mesh = spawnPickupProxyForWorldPop(parent, parent.RootComponent)
						if pickup ~= nil and mesh ~= nil then
							gripResourceItem(handed, pickup, mesh, false, parent)
							return true
						end
					end
				elseif parent:is_a(uevrUtils.get_class("Class /Script/UWEInventory.UWEBaseItem")) then
					--print("  Found UWEBaseItem component with parent")
					if parent ~= nil then
						gripResourceItem(handed, parent, component, false)
						return true
					end
				elseif parent:is_a(uevrUtils.get_class("Class /Script/UWEWorldPopulation2.UWEWorldPopResourceBaseActor")) then
					--print("  Found UWEWorldPopResourceBaseActor pickup", parent:get_full_name())
					local pickup, mesh = spawnPickupProxyForWorldPop(parent, component)
					if pickup ~= nil and mesh ~= nil then
						gripResourceItem(handed, pickup, mesh, false, parent)
						return true
					end
				elseif parent:is_a(uevrUtils.get_class("Class /Script/Subnautica2.SN2PickupItem")) then
					--print("  Found SN2PickupItem pickup", parent:get_full_name(), parent:get_class():get_full_name())
					if string.find(parent:get_full_name(), "BP_AcidAnemone_MedigelSac_C", 1, true) then
						local pickup, mesh = spawnPickupProxyForWorldPop(parent, component)
						if pickup ~= nil and mesh ~= nil then
							gripResourceItem(handed, pickup, mesh, false, parent)
							return true
						end
					end
					gripResourceItem(handed, parent, component, false)
					return true
				--cant use the mobile locker until we find a way to disbale collision while holding it
				-- elseif parent:is_a(uevrUtils.get_class("Class /Script/UWECarryable.UWECarryableActorPowered")) and string.find(component:get_full_name(), "UWECarryableRootComponent", 1, true) then
				-- 	print("  Found UWECarryableActorPowered pickup", parent:get_full_name())
				-- 	if false or not isCarryingLocker() then -- skip if already carry locker via game mechanics
				-- 		gripResourceItem(handed, parent, component, false)
				-- 		--component:SetCollisionObjectType(32)--ECollisionChannel.ECC_Pawn)
				-- 		--component:SetCollisionResponseToAllChannels(ECollisionResponse.Overlap)
				-- 		--component:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.Ignore)
				-- 		status.grabItem[handed].isLocker = true
				-- 		return true
				-- 	end
				elseif component:is_a(uevrUtils.get_class("Class /Script/Engine.SphereComponent")) then
					--instead of using the SphereComponent get the parents MeshComponent
					--print("  Found SphereComponent component with parent", parent:get_full_name())
					if parent.MeshComponent ~= nil then
						--print("Gripping Unknown pickup", parent:get_full_name(), component:get_full_name())
						component:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.Ignore)
						if parent.NetMulticast_SetPhysicsEnabled ~= nil then
							parent:NetMulticast_SetPhysicsEnabled(false, true)
						end

						gripResourceItem(handed, parent, component, false)
						return true
					end
				end
			end
		end
	end
	return false
end

local function releaseGrippedComponents(handed, noPhysics)
	if not isGrabbingItem(handed) then
		if status.hasRightHandInventory and handed == Handed.Right then
			status.needsMenuPress = true
			status.hasRightHandInventory = false
		end
		if status.hasLeftHandInventory and handed == Handed.Left then
			status.needsMenuPress = true
			status.hasLeftHandInventory = false
		end
	else
		if status.hasRightHandInventory and handed == Handed.Right then
			status.needsAPress = true
			status.hasRightHandInventory = false
		end
		if status.hasLeftHandInventory and handed == Handed.Left then
			status.needsAPress = true
			status.hasLeftHandInventory = false
		end
	end

	if not isGrabbingItem(handed) then return end

	--print("Releasing gripped components")
	local grabItem = getGrabItem(handed)
	local grabComponent = grabItem ~= nil and uevrUtils.getValid(grabItem.component) or nil

	local grabParent = getGrabItemParent(handed)
	if grabParent ~= nil and grabParent.NetMulticast_SetPhysicsEnabled ~= nil then
		grabParent:NetMulticast_SetPhysicsEnabled(true, true)
	end

	attachments.detachGripAttachments(handed)

	if grabComponent ~= nil then
		if noPhysics ~= true then
			---@diagnostic disable-next-line: need-check-nil
			local velocity = grabItem.velocity or { X = 0, Y = 0, Z = 0 }
			local impulse = {
				X = velocity.X * GRAB_THROW_VELOCITY_SCALE,
				Y = velocity.Y * GRAB_THROW_VELOCITY_SCALE,
				Z = velocity.Z * GRAB_THROW_VELOCITY_SCALE,
			}
			grabComponent:AddImpulse(impulse, uevrUtils.fname_from_string("None"), true)
		end
		--disable the hand collision for a few seconds so the dropped item can get out of the way
		collision.setCollisionResponseToChannelByLabel(handed == Handed.Right and "Right Hand Collision" or "Left Hand Collision", ECollisionChannel.ECC_PhysicsBody, ECollisionResponse.Ignore)
		delay(1500, function()
			collision.setCollisionResponseToChannelByLabel(handed == Handed.Right and "Right Hand Collision" or "Left Hand Collision", ECollisionChannel.ECC_PhysicsBody, ECollisionResponse.Block)
		end)
		grabComponent:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.Block)

		--clearGrabVelocityTracking(grabItem)
	end

	releaseGrabItem(handed)
end

local function onGripChanged(handed, isGripping)
	if isGripping then
		--print("Gripping", handed)
		checkForGripCollision(handed) -- non-gripping activation
		if checkForCollision(handed) then
			if status.forceGrip == nil then status.forceGrip = {} end
			status.forceGrip[handed] = true
			--ugly hack to make hands animate correctly for world items
			delay(200, function()
				status.forceGrip[handed] = false
			end)
		end
	else
		--print("Not gripping", handed)
		--if status.lockHold == false then
			releaseGrippedComponents(handed)
		--end
	end
end

local function onTriggerChanged(handed, isTriggering)
	if isTriggering then
		--print("Triggering", handed)
		if checkForTriggerCollision(handed) then
			--print("Triggered")
		end
	else
	end
end
---------------------------------------------------------------------------------
--- End of Pickup handling
---------------------------------------------------------------------------------
uevrUtils.createDeferral("right_hand_inventory", 200, function()
	--print("Right hand inventory cooldown finished - can reload again")
	status.hasRightHandInventory = false
end)
uevrUtils.createDeferral("left_hand_inventory", 200, function()
	--print("Left hand inventory cooldown finished - can reload again")
	status.hasLeftHandInventory = false
end)

local STICK_DEADZONE = 22000
local xInputStatus = {}
local function checkGrabState(state)
	local isEatingRight, isGrabbingGlassesRight, gripHeadRight, isGrabbingEarRight, triggerMouthRight, isScratchingEyesRight, triggerHeadRight, isScratchingEarRight = gestures.getHeadGestures(state, Handed.Right, true)
	local isEatingLeft, isGrabbingGlassesLeft, gripHeadLeft, isGrabbingEarLeft, triggerMouthLeft, isScratchingEyesLeft, triggerHeadLeft, isScratchingEarLeft = gestures.getHeadGestures(state, Handed.Left, true)
	if isGrabbingEarRight then
		status.hasRightHandInventory = isGrabbingEarRight
		uevrUtils.updateDeferral("right_hand_inventory")
		--print("Grabbing ear")
	end
	if isGrabbingEarLeft then
		status.hasLeftHandInventory = isGrabbingEarLeft
		uevrUtils.updateDeferral("left_hand_inventory")
		--print("Grabbing ear")
	end

	if status.needsAPress then
		uevrUtils.pressButton(state, XINPUT_GAMEPAD_A)
		--print("PRESSING A")
		status.needsAPress = false
	end
	if status.needsMenuPress then
		uevrUtils.pressButton(state, XINPUT_GAMEPAD_BACK)
		ui.setCustomState("viewLocked", true, 20)
		delay(1000, function()
			ui.setCustomState("viewLocked", nil)
		end)
		status.needsMenuPress = false
	end
	if status.needsRTPress then
		state.Gamepad.bRightTrigger = 255
		status.needsRTPress = false
	end
	if status.needDPadDown then
		uevrUtils.pressButton(state, XINPUT_GAMEPAD_DPAD_DOWN)
		status.needDPadDown = false
	end
	if status.needDPadUp then
		uevrUtils.pressButton(state, XINPUT_GAMEPAD_DPAD_UP)
		status.needDPadUp = false
	end
	if status.needDPadLeft then
		uevrUtils.pressButton(state, XINPUT_GAMEPAD_DPAD_LEFT)
		status.needDPadLeft = false
	end
	if status.needDPadRight then
		uevrUtils.pressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT)
		status.needDPadRight = false
	end

	local isGrippingLeft = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
	local isGrippingRight = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
	if xInputStatus.isGrippingLeft ~= isGrippingLeft then
		xInputStatus.isGrippingLeft = isGrippingLeft
		onGripChanged(Handed.Left, isGrippingLeft)
	end
	if xInputStatus.isGrippingRight ~= isGrippingRight then
		xInputStatus.isGrippingRight = isGrippingRight
		onGripChanged(Handed.Right, isGrippingRight)
	end

	local isTriggeringLeft = state.Gamepad.bLeftTrigger > 0
	local isTriggeringRight = state.Gamepad.bRightTrigger > 0
	if xInputStatus.isTriggeringLeft ~= isTriggeringLeft then
		xInputStatus.isTriggeringLeft = isTriggeringLeft
		onTriggerChanged(Handed.Left, isTriggeringLeft)
	end
	if xInputStatus.isTriggeringRight ~= isTriggeringRight then
		xInputStatus.isTriggeringRight = isTriggeringRight
		onTriggerChanged(Handed.Right, isTriggeringRight)
	end

	--switch swim up/down from grip to right joystick 
	if state.Gamepad.sThumbRY > STICK_DEADZONE then
		uevrUtils.pressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
	else
		uevrUtils.unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
	end
	if state.Gamepad.sThumbRY < -STICK_DEADZONE then
		uevrUtils.pressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
	else
		uevrUtils.unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
	end
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
			if configui.getValue("physical_interaction") then
				checkGrabState(state)
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
		if configui.getValue("physical_interaction")  and status.currentVehicle == "Default" then
			checkGrabState(state)
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

configui.onCreateOrUpdate("disable_reflections", function(value)
	uevrUtils.set_cvar_int("r.Lumen.Reflections.Allow",  value and 1 or 0)
end)
configui.onCreateOrUpdate("disable_post_process_materials", function(value)
	uevrUtils.set_cvar_int("r.postprocessing.disablematerials",  value and 1 or 0)
end)

configui.onCreateOrUpdate("physical_driving", function(value)
	configui.setHidden("physical_driving_info", not value)
end)

configui.onCreateOrUpdate("physical_interaction", function(value)
	configui.setHidden("physical_interaction_info_group", not value)
end)

configui.onCreateOrUpdate("overlay_scale", function(value)
    setOverlayScale()
end)

configui.create(configDefinition)

