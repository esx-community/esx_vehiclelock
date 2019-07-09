ESX = nil

local sharedPlates = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand('givekey',function(source, n, args)
	
	local target = stringsplit(args, " ")
	
	TriggerClientEvent('esx_vehiclelock:giveKey', source, target[2] )
	
end)


ESX.RegisterServerCallback('esx_vehiclelock:requestPlayerCars', function(source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	
	MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = plate
	}, function(result)
		cb(result[1] ~= nil)
	end)
end)

--This checks to see if our target already owns a key, if not, registers it in the table.
ESX.RegisterServerCallback('esx_vehiclelock:giveKey',function(source, cb, plate, target)
	local targetPed = ESX.GetPlayerFromId(target)
	local plateCheck = nil

	if(sharedPlates[plate])then

		for k,v in pairs(sharedPlates[plate]) do

			if v == targetPed.identifier then 
				cb('alreadyKey')
				plateCheck = true
				return
			end
			plateCheck = false
		end

		if not plateCheck then
			table.insert(sharedPlates[plate], targetPed.identifier)
			cb('added')
		end
	else
		sharedPlates[plate] = {targetPed.identifier}
		cb('added')
	end

end)

--This checks if player has had a key given to them before unlocking car
ESX.RegisterServerCallback('esx_vehiclelock:giveKey',function(source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	if(sharedPlates[plate])then
		for k,v in pairs(sharedPlates[plate]) do
			if v == xPlayer.identifier then
				cb(true)
				return
			end
		end
	end
end)

-- splits the chat message string on the inputed seperator
function stringsplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end