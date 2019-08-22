ESX               = nil

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local isRunningWorkaround = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function StartWorkaroundTask()
	if isRunningWorkaround then
		return
	end
	
	local timer = 0
	local playerPed = PlayerPedId()
	isRunningWorkaround = true
	
	while timer < 100 do
		Citizen.Wait(0)
		timer = timer + 1
		
		local vehicle = GetVehiclePedIsTryingToEnter(playerPed)
		
		if DoesEntityExist(vehicle) then
			local lockStatus = GetVehicleDoorLockStatus(vehicle)
			
			if lockStatus > 2 then
				ClearPedTasks(playerPed)
			end
		end
	end
	
	isRunningWorkaround = false
end

function ToggleVehicleLock()
	local vehicle
	
	Citizen.CreateThread(function()
		StartWorkaroundTask()
	end)
	
	if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
		vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
	else
		local player = GetPlayerPed(-1)
		local pos = GetEntityCoords(player)
		local entityWorld = GetOffsetFromEntityInWorldCoords(player, 0.0, 9.0, 0.0)
		local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 2, player, 0)
		local a, b, c, d, vehicleHandle = GetRaycastResult(rayHandle)
		vehicle = vehicleHandle
		if not DoesEntityExist(vehicle) then
			player = GetPlayerPed(-1)
			pos = GetEntityCoords(player)
			entityWorld = GetOffsetFromEntityInWorldCoords(player, 9.0, 0.0, 0.0)
			rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 2, player, 0)
			a, b, c, d, vehicleHandle = GetRaycastResult(rayHandle)
			vehicle = vehicleHandle
		end
	end
	
	if not DoesEntityExist(vehicle) then --If no vehicle still found after ray cast, then return as dork
		return
	end
	
	local plate = GetVehicleNumberPlateText(vehicle)
	if plate ~= nil then
		ESX.TriggerServerCallback('esx_vehiclelock:requestPlayerCars', function(isOwnedVehicle)
			if isOwnedVehicle then
				local lockStatus = GetVehicleDoorLockStatus(vehicle)
				if lockStatus == 1 then -- unlocked
					playAnim()
					SetVehicleDoorsLocked(vehicle, 2)
					SetVehicleDoorsLockedForAllPlayers(vehicle, true)
					TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, "lock", 0.2)
					exports['mythic_notify']:DoCustomHudText('inform',  _U('message_locked') , 5000)
				elseif lockStatus > 1 then -- locked
					playAnim()
					SetVehicleDoorsLocked(vehicle, 1)
					SetVehicleDoorsLockedForAllPlayers(vehicle, false)
					TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, "unlock", 0.2)
					exports['mythic_notify']:DoCustomHudText('inform', _U('message_unlocked'), 5000)
				end
			else --start check to see if key has been given to player.
				ESX.TriggerServerCallback('esx_vehiclelock:hasKey', function(cb)
					if cb then
						local lockStatus = GetVehicleDoorLockStatus(vehicle)
						if lockStatus == 1 then -- unlocked
							playAnim()
							SetVehicleDoorsLocked(vehicle, 2)
							SetVehicleDoorsLockedForAllPlayers(vehicle, true)
							TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, "lock", 0.2)
							exports['mythic_notify']:DoCustomHudText('inform',  _U('message_locked') , 5000)
						elseif lockStatus > 1 then -- locked
							playAnim()
							SetVehicleDoorsLocked(vehicle, 1)
							SetVehicleDoorsLockedForAllPlayers(vehicle, false)
							TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, "unlock", 0.2)
							exports['mythic_notify']:DoCustomHudText('inform', _U('message_unlocked'), 5000)
						end
					end
				end, plate)
			end
		end, plate)
	end
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		
		if IsControlJustReleased(0, Keys['U']) then
			ToggleVehicleLock()
			Citizen.Wait(300)
			
			-- D-pad down on controllers works, too!
		elseif IsControlJustReleased(0, 173) and not IsInputDisabled(0) then
			ToggleVehicleLock()
			Citizen.Wait(300)
		end
	end
end)

--animation for key fob
function playAnim()
	local player = GetPlayerPed(-1)
	if not IsPedInAnyVehicle(player) then
		RequestAnimDict('anim@mp_player_intmenu@key_fob@')
		while not HasAnimDictLoaded('anim@mp_player_intmenu@key_fob@') do
			Citizen.Wait(0)
			RequestAnimDict('anim@mp_player_intmenu@key_fob@')
		end
		TaskPlayAnim(player, 'anim@mp_player_intmenu@key_fob@', 'fob_click_fp',2.0, 2.5, 1000, 49, 0, 0, 0, 0)
	end
end

--start of give key
RegisterNetEvent('esx_vehiclelock:giveKey')
AddEventHandler('esx_vehiclelock:giveKey', function(target)
	
	local ped = GetPlayerPed(-1)
	local vehicle = nil
	
	if IsPedInAnyVehicle(ped, false) then
		vehicle = GetVehiclePedIsIn(ped, false)
	else
		local pos = GetEntityCoords(ped)
		local entityWorld = GetOffsetFromEntityInWorldCoords(ped, 0.0, 20.0, 0.0)
		local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, ped, 0)
		local a, b, c, d, vehicleHandle = GetRaycastResult(rayHandle)
		if not DoesEntityExist(vehicleHandle) then --If not vehicle still found after ray cast, then return as dork
			return --not vehicle found. Do some shit here. 
		else
			vehicle = vehicleHandle
		end
	end
	
	if not DoesEntityExist(vehicle) then
		return --not vehicle excists so lets break shit..
	end
	
	local plate = GetVehicleNumberPlateText(vehicle)
	ESX.TriggerServerCallback('esx_vehiclelock:requestPlayerCars', function(cb)
		
		if cb then
			ESX.TriggerServerCallback('esx_vehiclelock:giveKeyServer', function(_cb)
				if _cb == ('alreadyKey') then
					ESX.ShowNotification('This person already has a key')
				elseif _cb == 'added' then
					ESX.ShowNotification('You gave out a key.')
				end
			end,  plate, target)
		elseif not cb then 
			exports['mythic_notify']:DoCustomHudText('error', 'You don\'t own this vehicle', 5000)
		else
			exports['mythic_notify']:DoCustomHudText('error', 'You broke something, please contact a dev.', 5000)
		end
		
	end, plate)
	
end)

RegisterNetEvent('InteractSound_CL:PlayWithinDistance')
AddEventHandler('InteractSound_CL:PlayWithinDistance', function(playerNetId, maxDistance, soundFile, soundVolume)
	local lCoords = GetEntityCoords(GetPlayerPed(-1))
	local eCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerNetId)))
	local distIs  = Vdist(lCoords.x, lCoords.y, lCoords.z, eCoords.x, eCoords.y, eCoords.z)
	if(distIs <= maxDistance) then
		SendNUIMessage({
			transactionType     = 'playSound',
			transactionFile     = soundFile,
			transactionVolume   = soundVolume
		})
	end
end)