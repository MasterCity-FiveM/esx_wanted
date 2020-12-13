local PlayerData = {}
local wantedTime = 0
blip = nil
blips = {}
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)

AddEventHandler('onClientMapStart', function()
	Citizen.Wait(20000)

	ESX.TriggerServerCallback("esx_wanted:retrieveWantedTime", function(inWanted, newWantedTime, id)
		if inWanted then
			wantedTime = newWantedTime
			exports.pNotify:SendNotification({text = "شما تحت تعقیب می باشید.", type = "success", timeout = 4000})
			InWanted()
		end
	end)
end)

RegisterNetEvent("esx_wanted:wantedPlayer")
AddEventHandler("esx_wanted:wantedPlayer", function(newWantedTime)
	wantedTime = newWantedTime
	InWanted()
end)

RegisterNetEvent("esx_wanted:unWantedPlayer")
AddEventHandler("esx_wanted:unWantedPlayer", function()
	wantedTime = 0
	InWanted()
end)

function InWanted()
	Citizen.CreateThread(function()
		while wantedTime > 0 do
			exports.pNotify:SendNotification({text = "شما تا " .. wantedTime .. " دقیقه دیگر تحت تعقیب می باشید.", type = "info", timeout = 4000})
			wantedTime = wantedTime - 1
			TriggerServerEvent("esx_wanted:updateWantedTime", wantedTime)
			
			Citizen.Wait(60000)
			
			if wantedTime == 0 then
				exports.pNotify:SendNotification({text = "مدت تحت تعقیب قرار گرفتن شما به پایان رسید.", type = "success", timeout = 4000})
				TriggerServerEvent("esx_wanted:updateWantedTime", 0)
			end
		end
	end)
end

RegisterNetEvent("esx_wanted:openWantedMenu")
AddEventHandler("esx_wanted:openWantedMenu", function()
	OpenPoliceWantedMenu()
end)

function OpenPoliceWantedMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'police_wanted', {
		title    = _U('add_chat'),
		align    = 'right',
		elements = {
			{label = "افراد تحت تعقیب", value = 'open_unwanted'},
			{label = "افزودن فرد جدید", value = 'open_wanted'}
	}}, function(data, menu)
		if data.current.value == 'open_wanted' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'wanted_choose_id_menu',
				{ title = "کد ملی" }, function(data1, menu1)
					local PlayerSRC = tonumber(data1.value)
					if PlayerSRC == nil then
						exports.pNotify:SendNotification({text = "مقدار وارد شده صحیح نیست.", type = "error", timeout = 4000})
					else
						menu1.close()
						
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'wanted_choose_time_menu',
							{ title = "مدت تحت تعقیب - دقیقه" }, function(data2, menu2)
								local wantedTime = tonumber(data2.value)
								if wantedTime == nil then
									exports.pNotify:SendNotification({text = "مقدار وارد شده صحیح نیست.", type = "error", timeout = 4000})
								else
									menu2.close()
									ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'wanted_choose_time_menu',
										{ title = "علت" }, function(data3, menu3)
											local reason = data3.value
											if reason == nil then
												exports.pNotify:SendNotification({text = "مقدار وارد شده صحیح نیست.", type = "error", timeout = 4000})
											else
												menu3.close()
												
												TriggerServerEvent("esx_wanted:wantedPlayer", PlayerSRC, wantedTime, reason)
											end	
										end, function(data3, menu3)
												menu3.close()
										end)
										
								end	
							end, function(data2, menu2)
									menu2.close()
							end)
							
					end	
				end, function(data1, menu1)
						menu1.close()
				end)
		elseif data.current.value == 'open_unwanted' then
			local elements = {}

			ESX.TriggerServerCallback("esx_wanted:retrieveWantedPlayers", function(playerArray)
				if #playerArray == 0 then
					exports.pNotify:SendNotification({text = "لیست مجرمان تحت تعقیب خالی می باشد.", type = "success", timeout = 4000})
					return
				end
		
				for i = 1, #playerArray, 1 do
					table.insert(elements, {label = _U('wanted_player', playerArray[i].name, playerArray[i].wantedTime),name = playerArray[i].name, value = playerArray[i].playersrc})
				end
		
				ESX.UI.Menu.Open(
					'default', GetCurrentResourceName(), 'wanted_unwanted_menu',
					{
						title = "افراد تحت تعقیب",
						align = "center",
						elements = elements
					},
				function(data2, menu2)
					local source = data2.current.value
					local playername = data2.current.name
		
					TriggerServerEvent("esx_wanted:unWantedPlayer", source)

					if PlayerData.job and PlayerData.job.name == 'police' then
						exports.pNotify:SendNotification({text = "شهروند از حالت تحت تعقیب خارج شد.", type = "success", timeout = 4000})
					end
					
					menu2.close()
				end, function(data2, menu2)
					menu2.close()
				end)
			end)
		end
	end, function(data, menu)
		menu.close()
	end)
end

RegisterNetEvent('esx_wanted:setBlip')
AddEventHandler('esx_wanted:setBlip', function(Playerid)
	if PlayerData.job and PlayerData.job.name == 'police' then
		local id = GetPlayerFromServerId(Playerid)
		local ped = GetPlayerPed(id)
		local x, y, z = table.unpack(GetEntityCoords(ped, true))
		blip = AddBlipForCoord(x, y, z)
		SetBlipSprite(blip, 161)
		SetBlipScale(blip, 2.0)
		SetBlipColour(blip, 1)
		SetBlipDisplay(blip, 4)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('wanted_player_show'))
		EndTextCommandSetBlipName(blip)
		SetBlipAsShortRange(blip, true)
		table.insert(blips, blip)
		Wait(Config.ShowTime)
		for i, blip in pairs(blips) do 
			RemoveBlip(blip)
		end
	end
end)

RegisterNetEvent('esx_wanted:ShowPoliceWarn')
AddEventHandler('esx_wanted:ShowPoliceWarn', function(message)
	if PlayerData.job and PlayerData.job.name == 'police' then
		exports.pNotify:SendNotification({text = message, type = "info", timeout = 6000})
	end
end)