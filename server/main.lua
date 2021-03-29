ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function getIdentity(source)
	local identifier = GetPlayerIdentifiers(source)[1]
	local result = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {['@identifier'] = identifier})
	if result[1] ~= nil then
		local identity = result[1]

		return {
			identifier = identity['identifier'],
			firstname = identity['firstname'],
			lastname = identity['lastname']
		}
	else
		return nil
	end
end

RegisterServerEvent("esx_wanted:wantedPlayer")
AddEventHandler("esx_wanted:wantedPlayer", function(Playerid, wantedTime, wantedReason)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_wanted:wantedPlayer', {Playerid = Playerid, wantedTime = wantedTime, wantedReason = wantedReason})
    local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local tPlayer = ESX.GetPlayerFromId(Playerid)

	if not xPlayer or xPlayer.job == nil or xPlayer.job.name ~= 'police' then
		return
	end
	
	if not tPlayer then
		TriggerClientEvent("pNotify:SendNotification", source, { text = "شهروند در سرور نیست.", type = "error", timeout = 5000, layout = "bottomCenter"})
		return
	end
	
	WantedPlayer(Playerid, wantedTime)
	
	local name2 = getIdentity(Playerid)
	fal = name2.firstname .. " " .. name2.lastname
	TriggerClientEvent('esx_wanted:ShowPoliceWarn', -1, "اطلاع به کلیه نیروها، " .. fal .. " تحت تعقیب قرار گرفت.");
	TriggerClientEvent("pNotify:SendNotification", src, { text = "بازیکن تحت تعقیب قرار گرفت.", type = "success", timeout = 5000, layout = "bottomCenter"})
	TriggerClientEvent("pNotify:SendNotification", Playerid, { text = "شما به مدت " .. wantedTime .. " ماه به دلیل " .. wantedReason .. " تحت تعقیب قرار گرفتید.", type = "success", timeout = 5000, layout = "bottomCenter"})
end)

function WantedPlayer(wantedPlayer, wantedTime)
    TriggerClientEvent("esx_wanted:wantedPlayer",wantedPlayer, wantedTime)
	EditWantedTime(wantedPlayer, wantedTime)
end

function EditWantedTime(wantedPlayer, wantedTime)
    local xPlayer = ESX.GetPlayerFromId(wantedPlayer)
	if xPlayer == nil then
		return
	end

	local Identifier = xPlayer.identifier
	MySQL.Async.execute(
       "UPDATE users SET wanted = @newWantedTime WHERE identifier = @identifier",
        {
			['@identifier'] = Identifier,
			['@newWantedTime'] = tonumber(wantedTime)
		}
	)
end

ESX.RegisterServerCallback("esx_wanted:retrieveWantedPlayers", function(source, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_wanted:retrieveWantedPlayers', {})
	local wantedPersons = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer or xPlayer.job == nil or xPlayer.job.name ~= 'police' then
		cb(wantedPersons)
		return
	end

    MySQL.Async.fetchAll("SELECT firstname, lastname, wanted, identifier FROM users WHERE wanted > @wanted", { ["@wanted"] = 0 }, function(result)
        for i = 1, #result, 1 do
			local yPlayer = ESX.GetPlayerFromIdentifier(result[i].identifier)
			if yPlayer then
				table.insert(wantedPersons, { 
					name = result[i].firstname .. " " .. result[i].lastname,
					wantedTime = result[i].wanted,
					playersrc = yPlayer.source
				})
			end
		end
		cb(wantedPersons)
	end)
end)

function UnWanted(wantedPlayer)
	local src = source
    local xPlayer = ESX.GetPlayerFromId(wantedPlayer)
    TriggerClientEvent("esx_wanted:unWantedPlayer", wantedPlayer)
	EditWantedTime(wantedPlayer, 0)
end

ESX.RegisterServerCallback("esx_wanted:retrieveWantedTime", function(source, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_wanted:retrieveWantedTime', {})
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local Identifier = xPlayer.identifier

	MySQL.Async.fetchAll("SELECT wanted FROM users WHERE identifier = @identifier", { ["@identifier"] = Identifier }, function(result)
        local WantedTime = tonumber(result[1].wanted)
		if WantedTime > 0 then
            cb(true, WantedTime, src)
		else
			cb(false, 0)
		end
	end)
end)

RegisterServerEvent("esx_wanted:updateWantedTime")
AddEventHandler("esx_wanted:updateWantedTime", function(newWantedTime)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_wanted:updateWantedTime', {newWantedTime = newWantedTime})
    local src = source
    EditWantedTime(src, newWantedTime)
    if Config.WantedBlip and newWantedTime > 0 then
        TriggerClientEvent('esx_wanted:setBlip', -1, src)
    end
end)

RegisterServerEvent("esx_wanted:unWantedPlayer")
AddEventHandler("esx_wanted:unWantedPlayer", function(Player)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_wanted:unWantedPlayer', {player = player})
	local src = source
    local xPlayer = ESX.GetPlayerFromId(Player)
    if xPlayer ~= nil then
		UnWanted(xPlayer.source)
	else
		TriggerClientEvent("pNotify:SendNotification", src, { text = "این شهروند در حال حاضر در شهر نیست.", type = "error", timeout = 5000, layout = "bottomCenter"})
    end
end)

