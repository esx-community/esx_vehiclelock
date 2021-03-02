ESX = nil

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

			if lockStatus == 4 then
				ClearPedTasks(playerPed)
			end
		end
	end

	isRunningWorkaround = false
end

function ToggleVehicleLock()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local vehicle

	Citizen.CreateThread(function()
		StartWorkaroundTask()
	end)

	if IsPedInAnyVehicle(playerPed, false) then
		vehicle = GetVehiclePedIsIn(playerPed, false)
	else
		vehicle = GetClosestVehicle(coords, 8.0, 0, 71)
	end

	if not DoesEntityExist(vehicle) then
		--ESX.ShowNotification("~o~No vehicles to lock nearby.")
		exports['mythic_notify']:DoHudText('error', 'No vehicles to lock nearby.')
		return
	end

	ESX.TriggerServerCallback('esx_vehiclelock:requestPlayerCars', function(isOwnedVehicle)

		if isOwnedVehicle then
			local lockStatus = GetVehicleDoorLockStatus(vehicle)
			local vehicleLabel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))

			local dict = "anim@mp_player_intmenu@key_fob@"
    
			RequestAnimDict(dict)
			while not HasAnimDictLoaded(dict) do
				Citizen.Wait(100)
			end

			if lockStatus == 1 then -- unlocked
				--SetVehicleDoorsLocked(vehicle, 2)
				--PlayVehicleDoorCloseSound(vehicle, 1)
				SetVehicleDoorShut(vehicle, 0, false)
				SetVehicleDoorShut(vehicle, 1, false)
				SetVehicleDoorShut(vehicle, 2, false)
				SetVehicleDoorShut(vehicle, 3, false)
				SetVehicleDoorsLocked(vehicle, 2)
				PlayVehicleDoorCloseSound(vehicle, 1)

				--ESX.ShowNotification('You have ~r~locked~s~ your ~y~'..vehicleLabel ..'~s~.')
				exports['mythic_notify']:DoHudText('error', 'You have locked your '..vehicleLabel ..'.')

				if not IsPedInAnyVehicle(PlayerPedId(), true) then
					TaskPlayAnim(GetPlayerPed(-1), dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
				end
					SetVehicleLights(vehicle, 2)
						Citizen.Wait(150)
					SetVehicleLights(vehicle, 0)
						Citizen.Wait(150)
					SetVehicleLights(vehicle, 2)
						Citizen.Wait(150)
					SetVehicleLights(vehicle, 0)
			elseif lockStatus == 2 then -- locked
				SetVehicleDoorsLocked(vehicle, 1)
				PlayVehicleDoorOpenSound(vehicle, 0)

				--ESX.ShowNotification('You have ~g~unlocked~s~ your ~y~'..vehicleLabel ..'~s~.')
				exports['mythic_notify']:DoHudText('success', 'You have unlocked your '..vehicleLabel ..'.')

				if not IsPedInAnyVehicle(PlayerPedId(), true) then
					TaskPlayAnim(GetPlayerPed(-1), dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
				end
					SetVehicleLights(vehicle, 2)
						Citizen.Wait(150)
					SetVehicleLights(vehicle, 0)
						Citizen.Wait(150)
					SetVehicleLights(vehicle, 2)
						Citizen.Wait(150)
					SetVehicleLights(vehicle, 0)
			end
		end

	end, ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if IsControlJustReleased(0, 303) and IsInputDisabled(0) then
			ToggleVehicleLock()
			Citizen.Wait(300)
		end
	end
end)
