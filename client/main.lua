local ESX = nil
local PlayerData = {}

CreateThread(function ()
    if GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
    end
end)

RegisterNetEvent('esx:playerLoaded', function ()
    PlayerData = ESX.GetPlayerData()
end)

CreateThread(function()
    if Config.Target then
        for k, v in pairs(Config.LockerZone) do
            exports['ox_target']:addBoxZone({
                coords = v.coords,
                size = vec3(1.5,1.5,1.5),
                rotation = 1,
                debug = false,
                drawSprite = true,
                options = {
                    {
                        icon = "fas fa-lock",
                        label = "Open Locker",
                        lockerArea = k,
                        distance = v.DrawDistance,
                        onSelect = function ()
                            lib.callback('rgx-lockers:getLockers', false, function(data)
                                TriggerEvent("rgx-lockers:OpenMenu", { locker = k, info = data })
                            end, k)
                        end
                    },
                }
            })
        end
    else
        for k, v in pairs(Config.LockerZone) do
            v.point = lib.points.new(v.coords, v.DrawDistance)
            function v.point:nearby()
                DrawText3Ds(v.coords.x, v.coords.y, v.coords.z + 1.0, "Press ~r~[G]~s~ To Open ~y~Locker~s~")
                DisableControlAction(0, 47)
                if IsDisabledControlJustPressed(0, 47) then
                    lib.callback('rgx-lockers:getLockers', false, function(data)
                        TriggerEvent("rgx-lockers:OpenMenu", { locker = k, info = data })
                    end, k)
                end
            end
        end
    end
end)    

RegisterNetEvent("rgx-lockers:OpenMenu", function(data)
    lib.registerContext({
        id = 'locker_menu',
        title = 'Titan Lockers',
        options = {
            ['Create Locker'] = {
                description = 'Create A Locker',
                arrow = true,
                event = 'rgx-lockers:CreateLocker',
                args = {
                    branch = data.locker
                }
            },
            ['Open Your Locker'] = {
                description = 'Open Self Locker',
                arrow = true,
                event = 'rgx-lockers:OpenSelfLocker',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            },
            ['Delete Locker'] = {
                description = 'Delete Existing Locker',
                arrow = true,
                event = 'rgx-lockers:LockerListDelete',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            },
            ['Change Locker Password'] = {
                description = 'Change Existing Locker Password',
                arrow = true,
                event = 'rgx-lockers:LockerChangePass',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            }
        }
    })
    lib.showContext('locker_menu')
end)

RegisterNetEvent('rgx-lockers:LockerChangePass', function(data)
    local plyIdentifier = PlayerData.identifier
    if not plyIdentifier then
        plyIdentifier = ESX.GetPlayerData().identifier
    end
    local lockers = data.arg
    if lockers then
        local exist = false
        for k, v in pairs(lockers) do
            if plyIdentifier == v.owner then
                exist = true
                TriggerEvent('rgx-lockers:client:ChangePassword', { data = v })
            end
        end
        if not exist then
            lib.defaultNotify({
                title = 'Lockers',
                description = 'You don\'t have a locker',
                status = 'error'
            })
        end
    else
        lib.defaultNotify({
            title = 'Lockers',
            description = 'You don\'t have a locker',
            status = 'error'
        })
    end
end)

RegisterNetEvent('rgx-lockers:LockerListDelete', function(data)
    local plyIdentifier = PlayerData.identifier
    if not plyIdentifier then
        plyIdentifier = ESX.GetPlayerData().identifier
    end
    local lockers = data.arg
    if lockers then
        local exist = false
        for k, v in pairs(lockers) do
            if plyIdentifier == v.owner then
                exist = true
                TriggerEvent('rgx-lockers:client:DeleteLocker', { data = v, id = v.lockerid })
            end
        end
        if not exist then
            lib.defaultNotify({
                title = 'Lockers',
                description = 'You don\'t have a locker',
                status = 'error'
            })
        end
    else
        lib.defaultNotify({
            title = 'Lockers',
            description = 'You don\'t have a locker',
            status = 'error'
        })
    end
end)

RegisterNetEvent('rgx-lockers:client:ChangePassword', function(info)
    local data = info.data
    local id = data.lockerid
    local input = lib.inputDialog('Titan Lockers',
        { { type = "input", label = "Locker Password", password = true, icon = 'lock' } })
    if input and input[1] then
        TriggerServerEvent('rgx-lockers:server:ChangePass', id, input[1])
    end
end)

RegisterNetEvent('rgx-lockers:client:DeleteLocker', function(info)
    local id = info.id
    lib.registerContext({
        id = 'delete_locker_confirmation',
        title = 'Delete Locker',
        menu = 'locker_menu',
        options = {
            ['Confirm'] = {
                description = 'Confirm Deletion of Your Locker',
                arrow = true,
                serverEvent = 'rgx-lockers:server:DeleteLocker',
                args = id
            },
            ['Cancel'] = {
                description = 'Cancel Deletion of Your Locker',
                arrow = true,
                menu = 'locker_menu'
            }
        }
    })
    lib.showContext('delete_locker_confirmation')
end)

function OpenTSLocker(lid)
    exports.ox_inventory:openInventory('stash', lid)
end

RegisterNetEvent('rgx-lockers:OpenSelfLocker', function(info)
    local plyIdentifier = PlayerData.identifier
    if not plyIdentifier then
        plyIdentifier = ESX.GetPlayerData().identifier
    end
    local lockers = info.arg
    if lockers then
        local exist = false
        for k, v in pairs(lockers) do
            if plyIdentifier == v.owner then
                exist = true
                OpenTSLocker(v.lockerid) 
            end
        end
        if not exist then
            lib.defaultNotify({
                title = 'Lockers',
                description = 'You don\'t have a locker',
                status = 'error'
            })
        end
    else
        lib.defaultNotify({
            title = 'Lockers',
            description = 'You don\'t have a locker',
            status = 'error'
        })
    end
end)

RegisterNetEvent("rgx-lockers:CreateLocker", function(data)
    local area = data.branch
    local input = lib.inputDialog('Titan Lockers - Create Password',
        { { type = "input", label = "Locker Password", password = true, icon = 'lock' } })
    if input and input[1] then
        TriggerServerEvent("rgx-lockers:server:CreateLocker", input[1], area)
    end
end)

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 500
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 80)
end
