local blips = {}

local function notifyNewBlip(blipData)
    TriggerClientEvent("esx_blipscreator:newBlip", -1, blipData)
end

local function registerBlip(builder, cb)
    table.insert(blips, builder)
    notifyNewBlip(builder)

    if (not (builder.temporary)) then
        MySQL.Async.insert("INSERT INTO esx_blips (data) VALUES (@data)", {
            ["@data"] = json.encode(builder)
        }, function(id)
            if (id ~= 0 and id ~= nil) then
                cb(true)
                return
            end
            cb(false)
        end)
    end
end

CreateThread(function()
    MySQL.Async.fetchAll("SELECT * FROM esx_blips", {}, function(rows)
        if (#rows <= 0 or (not rows)) then
            return
        end

        for k, v in pairs(rows) do
            local blipData <const> = json.decode(v.data)
            blipData.position = vector3(blipData.position.x, blipData.position.y, blipData.position.z)
            blips[k] = blipData
        end

        print(("Loaded %i blips"):format(#rows))
    end)
end)

-- Receive a blips request from player
RegisterNetEvent("esx_blipscreator:requestBlips", function()
    local _src <const> = source
    TriggerClientEvent("esx_blipscreator:cbBlips", _src, blips)
end)

-- Add a blip
RegisterNetEvent("esx_blipscreator:createBlip", function(blipBuilder)
    local _src <const> = source

    local xPlayer <const> = ESX.GetPlayerFromId(_src)

    if (xPlayer.getGroup() ~= "superadmin") then
        TriggerClientEvent("esx:showNotification", _src, "Vous n'avez pas la permission de faire cette action")
        return
    end

    if (not (validateBlipBuilder(blipBuilder))) then
        TriggerClientEvent("esx:showNotification", _src, "Votre blip n'a pas été créé car les paramètres rentrés sont incorrects")
        return
    end

    registerBlip(blipBuilder, function(success)
        TriggerClientEvent("esx:showNotification", _src, success and "Blip ~g~créé" or "Blip ~r~non créé ~s~(erreur survenue)")
    end)
end)