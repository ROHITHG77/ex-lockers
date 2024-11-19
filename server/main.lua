local ESX = nil
CreateThread(function ()
    if GetResourceState('es_extended') ~= 'missing' and GetResourceState('es_extended') ~= 'unknown' then
        while GetResourceState('es_extended') ~= 'started' do Wait(0) end
        ESX = exports['es_extended']:getSharedObject()
    end
end)

exports.ox_inventory:registerHook('swapItems', function(payload)
    if payload.toType == 'stash' then
        local result = MySQL.scalar.await('SELECT 1 FROM tslockers WHERE lockerid = ?', {payload.toInventory})
        if result then
            return false
        end
    end
end, {
    print = true,
    itemFilter = {
        money = true,
        black_money = true
    }
})

local GetPlayer = function(id)
    if ESX then
        return ESX.GetPlayerFromId(id)
    end
end

local RegisterStash = function (lockerid,label)
    exports.ox_inventory:RegisterStash(lockerid, label, Config.MaxSlots, Config.MaxWeight) 
end

RegisterNetEvent("rgx-lockers:server:CreateLocker", function(code, area)
    local src = source
    local xPlayer = GetPlayer(src)
    local branch = area
    local passcode = code
    local allowed = true
    if code and xPlayer then
        local plyIdentifier = xPlayer.identifier
        MySQL.query('SELECT * FROM tslockers WHERE branch = ?', {branch}, function(result)
            if result[1] then
                for k,v in pairs(result) do
                    if v.owner == plyIdentifier then
                        allowed = false
                    end
                end
                if allowed then
                    local lockerid = plyIdentifier..branch
                    MySQL.insert('INSERT INTO tslockers (lockerid, owner, password, branch) VALUES (?, ?, ?, ?)', {lockerid, plyIdentifier, passcode, branch}, function(id)
                        RegisterStash(lockerid,"Locker No:"..id)
                        TriggerClientEvent('ox_lib:defaultNotify', src, {
                            title = 'Locker',
                            description = 'You Created Locker with Locker ID: '..id,
                            status = 'success'
                        })
                    end)
                else
                    TriggerClientEvent('ox_lib:defaultNotify', src, {
                        title = 'Locker',
                        description = 'You can only create 1 locker in this area',
                        status = 'error'
                    })
                end
            else
                local lockerid = plyIdentifier..branch
                MySQL.insert('INSERT INTO tslockers (lockerid,owner, password, branch) VALUES (?, ?, ?, ?)', {lockerid,plyIdentifier, passcode, branch}, function(id)
                    RegisterStash(lockerid,"Locker No:"..id)
                    TriggerClientEvent('ox_lib:defaultNotify', src, {
                        title = 'Locker',
                        description = 'You Created Locker with Locker ID: '..id,
                        status = 'success'
                    })
                end)
            end
        end)
    end
end)

RegisterNetEvent('rgx-lockers:server:DeleteLocker', function(id)
    local lockerid = id
    local src = source
    local xPlayer = GetPlayer(src)
    if xPlayer and lockerid then
        local plyIdentifier = xPlayer.identifier
        MySQL.query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
                for k,v in pairs(result) do
                    if tostring(v.lockerid) == tostring(lockerid) and v.owner == plyIdentifier then
                        MySQL.query('DELETE FROM ox_inventory WHERE name = ?', { v.lockerid })
                        MySQL.query('DELETE FROM tslockers WHERE lockerid = ?', {v.lockerid}, function(result)
                            TriggerClientEvent('ox_lib:defaultNotify', src, {
                                title = 'Locker',
                                description = 'You Deleted the Locker with Locker ID: '..id,
                                status = 'success'
                            })
                        end)
                    end
                end
            end
        end)
    end
end)

RegisterNetEvent('rgx-lockers:server:ChangePass', function(lid, pass)
    local src = source
    local lockerid = lid
    local password = pass
    local xPlayer = GetPlayer(src)
    if xPlayer and lockerid then
        local plyIdentifier = xPlayer.identifier
        MySQL.query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
                for k,v in pairs(result) do
                    if tostring(v.lockerid) == tostring(lockerid) then
                        if v.owner == plyIdentifier then
                            MySQL.update('UPDATE tslockers SET password = ? WHERE lockerid = ? ', {password, lockerid}, function(affectedRows)
                                if affectedRows then
                                    TriggerClientEvent('ox_lib:defaultNotify', src, {
                                        title = 'Locker',
                                        description = 'Password Changed',
                                        status = 'success'
                                    })
                                end
                            end)
                        else
                            TriggerClientEvent('ox_lib:defaultNotify', src, {
                                title = 'Locker',
                                description = "You are not Authorized to change the password!",
                                status = 'error'
                            })
                        end
                    end
                end
            end
        end)
    end
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'rgx-lockers' or resourceName == GetCurrentResourceName() then
        while GetResourceState('ox_inventory') ~= 'started' do Wait(50) end
        MySQL.query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
                for k,v in pairs(result) do
                    RegisterStash(v.lockerid,"Locker No:"..v.dbid)
                end
            end
        end)
    end
end)

lib.callback.register('rgx-lockers:getLockers', function(source, area)
    local result = MySQL.query.await('SELECT * FROM tslockers WHERE branch = ?', {area})
    return result or nil
end)
