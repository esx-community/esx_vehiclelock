ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('esx_vehiclelock:requestPlayerCars', function(source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = plate
	}, function(result)
		cb(result[1] ~= nil)
	end)
end)

ESX.RegisterServerCallback('esx_vehiclelock:playerJob', function(source, cb)

	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local job = xPlayer.job.name

	cb(job)
end)