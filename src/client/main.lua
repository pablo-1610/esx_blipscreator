local xPlayer = {}
local active = false

local main <const> = RageUI.CreateMenu("Blips", "Créer un blip", nil, nil, "root_cause", "black_red")
local creator <const> = RageUI.CreateSubMenu(main, "Createur", "Créer un blip")

local builder = {
    shortRange = true,
    scale = 1.0,
    temporary = false
}

local function keyboard(TextEntry, ExampleText, MaxStringLenght, isValueInt)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    local blockInput = true
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockInput = false
        if isValueInt then
            local isNumber = tonumber(result)
            if isNumber and isNumber >= 0 then
                return result
            else
                return nil
            end
        end
        if (result == "") then
            return nil
        end
        return result
    else
        Wait(500)
        blockInput = false
        return nil
    end
end

local function valueOrDefine(value)
    return (value ~= nil and ("~b~%s"):format(value) or "~y~Définir")
end

local function createBlip(blipData)
    local blip <const> = AddBlipForCoord(blipData.position)

    SetBlipSprite(blip, blipData.sprite)
    SetBlipColour(blip, blipData.color)
    SetBlipScale(blip, blipData.scale or 1.0)
    SetBlipAsShortRange(blip, blipData.shortRange)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipData.name)
    EndTextCommandSetBlipName(blip)
end

main.Closed = function()
    active = false
end

RegisterCommand("blipscreator", function()
    if (active) then
        return
    end

    if (xPlayer.group ~= "superadmin") then
        ESX.ShowNotification("Vous n'avez pas la permission de faire cette commande !")
        return
    end

    active = true
    RageUI.Visible(main, true)

    CreateThread(function()
        while (active) do
            RageUI.IsVisible(main, function()
                RageUI.Separator("Gérer les blips")
                RageUI.Button("Créer un blip", "Appuyez pour créer un blip", {RightLabel = "→"}, true, {}, creator)
            end)

            RageUI.IsVisible(creator, function()
                RageUI.Separator("Customisez votre blip")
                RageUI.Button(("Nom: %s"):format(valueOrDefine(builder.name)), nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                    onSelected = function()
                        local name = keyboard("Nom", "", 50, false)
                        if (name ~= nil) then
                            builder.name = name
                        end
                    end
                })
                RageUI.Button(("Sprite: %s"):format(valueOrDefine(builder.sprite)), nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                    onSelected = function()
                        local sprite = keyboard("Sprite", "", 3, true)
                        if (sprite ~= nil and tonumber(sprite) ~= nil) then
                            builder.sprite = tonumber(sprite)
                        end
                    end
                })
                RageUI.Button(("Couleur: %s"):format(valueOrDefine(builder.color)), nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                    onSelected = function()
                        local color = keyboard("Couleur", "", 3, true)
                        if (color ~= nil and tonumber(color) ~= nil) then
                            builder.color = tonumber(color)
                        end
                    end
                })
                RageUI.Button(("Taille: %s"):format(valueOrDefine(builder.scale)), nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                    onSelected = function()
                        local scale = keyboard("Taille", "", 5, true)
                        if (scale ~= nil and tonumber(scale) ~= nil) then
                            builder.scale = tonumber(scale)
                        end
                    end
                })
                RageUI.Button(("Temporaire: %s"):format(builder.temporary and "~g~Oui" or "~r~Non"), nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                    onSelected = function()
                        builder.temporary = not builder.temporary
                    end
                })
                RageUI.Separator("Actions")
                RageUI.Button("Créer mon blip", nil, {RightBadge = RageUI.BadgeStyle.Tick}, validateBlipBuilder(builder), {
                    onSelected = function()
                        builder.position = GetEntityCoords(PlayerPedId())
                        TriggerServerEvent("esx_blipscreator:createBlip", builder)
                        RageUI.CloseAll()
                        active = false
                    end
                })
            end)

            Wait(0)
        end
    end)
end)

RegisterNetEvent("esx:setGroup", function(group)
    xPlayer.group = group
end)

SetTimeout(1500, function()
    xPlayer = ESX.GetPlayerData()
end)


-- Request blips for the first time
CreateThread(function()
    TriggerServerEvent("esx_blipscreator:requestBlips")
end)

-- Recieve all blips
RegisterNetEvent("esx_blipscreator:cbBlips", function(blipsData)
    for _, v in pairs(blipsData) do
        createBlip(v)
    end
end)

-- Receive a new blip
RegisterNetEvent("esx_blipscreator:newBlip", function(blipData)
    createBlip(blipData)
end)