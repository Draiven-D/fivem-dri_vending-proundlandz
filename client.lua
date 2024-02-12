ServerEvent = {}
script_name = GetCurrentResourceName()
ESX = nil
local InZone = false
local Token = nil
local IsDead = false
local Allmessage = {}
local MyShop = false
local CreateShop = false
local OtherShop = false
local OtherShopID = 0
local MyServerID = 0
local stat = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do Citizen.Wait(100) end

    ESX.PlayerData = ESX.GetPlayerData()
	MyServerID = GetPlayerServerId(PlayerId())
    TriggerServerEvent(script_name .. ":server:LoadConfig")
end)

RegisterNetEvent(script_name .. ":client:GetConfig")
AddEventHandler(script_name .. ":client:GetConfig",  function(f)
    Token = f.tk
    ServerEvent = f.se
	-- CreateBlipCircle(Config.Coords, "AFK", 0.0, 9, 93)
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
	ESX.PlayerData.job = job
	Citizen.Wait(3000)
end)

-- function CreateBlipCircle(coords, text, radius, color, sprite)
--     local blip = AddBlipForCoord(coords)
--     SetBlipHighDetail(blip, true)
--     SetBlipSprite(blip, sprite)
--     SetBlipScale(blip, 0.6)
--     SetBlipColour(blip, color)
--     SetBlipAsShortRange(blip, true)
--     BeginTextCommandSetBlipName("STRING")
--     AddTextComponentString(text)
--     EndTextCommandSetBlipName(blip)
-- end

function loadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Citizen.Wait(100)
	end
end

function CloseScreen()
	if MyShop then
		MyShop = false
	end
	if CreateShop then
		CreateShop = false
	end
	if OtherShop then
		OtherShop = false
	end
	FreezeEntityPosition(PlayerPedId(), false)
	SetNuiFocus(false,false)
	-- AnimpostfxStop("MenuMGSelectionIn")
end

function OpenScreen()
	-- AnimpostfxPlay("MenuMGSelectionIn", 1000, true)
	FreezeEntityPosition(PlayerPedId(), true)
	SetNuiFocus(true, true)
end

RegisterNetEvent(script_name .. ':OpenShop')
AddEventHandler(script_name .. ':OpenShop', function()
	if not MyShop and not OtherShop then
		MyShop = true
		TriggerEvent('esx_status:getStatus', 'hunger', function(status)
			stat.hw = status.val
		end)
		TriggerEvent('esx_status:getStatus', 'stress', function(status)
			stat.st = status.val
		end)
		local list = {}
		for k, v in pairs(Config.ItemList) do
			local found, amount = ESX.HasItem(v.item)
			if found then
				table.insert(list, {
					label = v.label,
					name = v.item,
					count = amount,
					choose = false
				})
			end
		end
		SendNUIMessage({
			type = "MyShop",
			items = list
		})
		OpenScreen()
	end
end)

RegisterNetEvent(script_name .. ':ReceiveMessage')
AddEventHandler(script_name .. ':ReceiveMessage', function(data)
	if InZone then
		Allmessage = data
		if MyShop and CreateShop then
			local chkshop = false
			for k, v in pairs(Allmessage) do
				if MyServerID == v.pid then
					chkshop = true
					SendNUIMessage({
						type = "UpdateMyShop",
						items = v.shop
					})
					break
				end
			end
			if not chkshop then
				SendNUIMessage({type = "CloseShop"})
				TriggerServerEvent(script_name .. ServerEvent[2], Token)
				CloseScreen()
				exports.pNotify:SendNotification({text = "ไม่มีสินค้าแล้ว", type = "error",})
			end
		end
		if OtherShop then
			local chkshop = false
			for k, v in pairs(Allmessage) do
				if OtherShopID == v.pid then
					chkshop = true
					SendNUIMessage({
						type = "UpdateOtherShop",
						name = v.message,
						items = v.shop
					})
					break
				end
			end
			if not chkshop then
				OtherShopID = 0
				SendNUIMessage({type = "CloseShop"})
				CloseScreen()
				exports.pNotify:SendNotification({text = "ไม่พบร้านค้านี้แล้ว", type = "error",})
			end
		end
	end
end)

local chk = 0

Citizen.CreateThread(function()
	while Token == nil do
        Citizen.Wait(10)
    end
	while true do
		Citizen.Wait(100)
		if InZone then
			chk = chk + 1
			if chk > 100 then
				chk = 0
				SetCurrentPedWeapon(PlayerPedId(),GetHashKey("WEAPON_UNARMED"),true)
				if MyShop and next(stat) ~= nil then
					TriggerEvent("esx_status:set", "hunger", stat.hw)
					TriggerEvent("esx_status:set", "stress", stat.st)
				end
			end
		end
	end
end)

Citizen.CreateThread(function()
	while Token == nil do
        Citizen.Wait(10)
    end
	while true do
		Citizen.Wait(0)
		local Ppid = PlayerPedId()
		local coords = GetEntityCoords(Ppid)
		local dist = #(coords - Config.Coords)
		if (dist < 50.0) then
			-- DrawMarker(1, Config.Coords.x, Config.Coords.y, Config.Coords.z -5, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 21.0, 21.0, 5.0, 240, 100, 100, 80, false, true, 2, false, false, false, false)
			if dist < 8.0 and not IsDead then
				if not IsPedInAnyVehicle(Ppid, false) then
					if not InZone then
						NetworkSetFriendlyFireOption(false)
						ClearPlayerWantedLevel(PlayerId())
						SetCurrentPedWeapon(Ppid,GetHashKey("WEAPON_UNARMED"),true)
						InZone = true
						TriggerServerEvent(script_name .. ServerEvent[1], true)
						SendNUIMessage({type = "Noti"})
					end
					if InZone then
						DisablePlayerFiring(Ppid,true)
						DisableControlAction(0, 106, true)
						DisableControlAction(0, 80, true)
						if next(Allmessage) and not OtherShop then
							local i = 0
							for k, v in pairs(Allmessage) do
								local TargetId = GetPlayerFromServerId(v.pid)
								local Target = GetPlayerPed(TargetId)
								local Targetcoords = GetEntityCoords(Target)
								local distance = #(coords-Targetcoords)
								if distance < 10.0 and i < 29 and MyServerID ~= v.pid then
									i = i + 1
									-- if not OtherShop then
										if distance < 2.0 then
											Draw3DText(Targetcoords.x, Targetcoords.y, Targetcoords.z+1.4, '💰 ~r~[E]~s~ ~w~'.. v.message ..'~s~', 2)
											if IsControlJustReleased(0, 38) and not MyShop then
												if not OtherShop then
													OtherShop = true
													OtherShopID = v.pid
													SendNUIMessage({
														type = "OtherShop",
														name = v.message,
														items = v.shop
													})
													OpenScreen()
													break
												end
											end
										else
											Draw3DText(Targetcoords.x, Targetcoords.y, Targetcoords.z+1.4, '💰 ~w~'.. v.message ..'~s~', 2)
										end
									-- end
								end
								-- if MyServerID == v.pid then
								-- 	Draw3DText(coords.x, coords.y, coords.z, v.message, 2)
								-- end
							end
						end
					end
				else
					local veh = GetVehiclePedIsIn(Ppid, false)
					if GetPedInVehicleSeat(veh, -1) == Ppid then
						if DoesEntityExist(veh) and NetworkHasControlOfEntity(veh) then
							ESX.Game.DeleteVehicle(veh)
						end
					end
				end
			else
				if InZone then
					NetworkSetFriendlyFireOption(true)
					TriggerServerEvent(script_name .. ServerEvent[1], false)
					InZone = false
					CloseScreen()
					SendNUIMessage({type = "CloseShop"})
					SendNUIMessage({type = "CloseNoti"})
				end
			end
		else
			Citizen.Wait(800)
		end
	end
end)

local fontID = nil
Citizen.CreateThread(function()
	while fontID == nil do
		Citizen.Wait(5000)
		fontID = exports["base_font"]:GetFontId("srbn")
	end
end)

function Draw3DText(x,y,z,textInput,sc)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local distance = GetDistanceBetweenCoords(px,py,pz, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    if sc then scale = scale * sc end
    SetTextScale(0.0 * scale, 0.35 * scale)
    SetTextFont(fontID)   ------แบบอักษร 1-7
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

AddEventHandler('esx:onPlayerDeath', function()
	IsDead = true
end)

AddEventHandler('esx:onPlayerSpawn', function()
	IsDead = false
end)

RegisterNUICallback("CreateShop", function(data)
	if InZone then 
		if data.value ~= "nil" then
			CreateShop = true
			TriggerServerEvent(script_name .. ServerEvent[2], Token, data)
		else
			TriggerServerEvent(script_name .. ServerEvent[2], Token)
			CloseScreen()
			-- SendNUIMessage({type = "Exit"})
		end
	end
end)

RegisterNUICallback("BuyInput", function(data)
	if InZone and OtherShop then
		if data.Count > 0 and tonumber(OtherShopID) > 0 then
			TriggerServerEvent(script_name .. ServerEvent[3], Token, OtherShopID, data.Selected, data.Count)
		end
	end
end)

RegisterNUICallback("CloseShop", function()
	if InZone then
		TriggerServerEvent(script_name .. ServerEvent[2], Token)
		CloseScreen()
		-- SendNUIMessage({type = "Exit"})
	end
end)

RegisterNUICallback("CloseOtherShop", function()
	if InZone then
		OtherShopID = 0
		CloseScreen()
	end
end)

RegisterNUICallback("NotiError", function(result)
	TriggerEvent("pNotify:SendNotification", {text = result.data, type = "error"})
end)

AddEventHandler("onResourceStop", function(resource)
	if resource == script_name then
		FreezeEntityPosition(PlayerPedId(), false)
	end
end)