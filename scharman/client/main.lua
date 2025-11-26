-- CLIENT - MAIN
ESX = exports['es_extended']:getSharedObject()

CreateThread(function()
    Config.InfoPrint('Initialisation du script client...')
    while not ESX.IsPlayerLoaded() do Wait(100) end
    Config.SuccessPrint('Script client initialisé avec succès!')
    Config.DebugPrint('Version: 2.0.0')
end)

if Config.Debug then
    RegisterCommand('scharman_info', function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        print('═══════════════════════════════════════════════════════════════')
        print('Position: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
        print('Heading: ' .. heading)
        print('═══════════════════════════════════════════════════════════════')
    end, false)
    
    RegisterCommand('scharman_reload', function()
        Config.InfoPrint('Rechargement du script...')
        TriggerEvent('scharman:client:reload')
    end, false)
    
    Config.InfoPrint('Commandes de debug disponibles: /scharman_info, /scharman_reload')
end

Config.DebugPrint('Fichier client/main.lua chargé avec succès')
