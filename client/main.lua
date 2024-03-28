local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}

CreateThread(function()
    repeat
        PlayerData = QBCore.Functions.GetPlayerData()
        Wait(10)
    until PlayerData.job
end)


exports['ox_target']:addSphereZone({
    coords = Config.OfficeComputer,
    radius = 0.3,
    debug = Config.Debug,
    options = {{
        icon = 'fa-solid fa-computer',
        label = 'Mayor computer',
        canInteract = function()
            return PlayerData.job.name == Config.MayorJob
        end,
        onSelect = function(data)
            local applicants = lib.callback.await("applicants:getApplicants", false)
            local options = {}
            
            for _, applicant in ipairs(applicants) do
                options[#options + 1] = {
                    title = 'Remove applicant: '..applicant.name, 
                    description = 'Current Votes: '..applicant.votes..' \nParty: '..applicant.Party,
                    onSelect = function()
                        local alert = lib.alertDialog({
                            header = 'Remove '..applicant.name,
                            centered = true,
                            cancel = true
                        })
                        if alert ~= "confirm" then return end
                        TriggerServerEvent('applicants:removeApplicant', applicant.key)
                    end
                }
            end
        
            options[#options + 1] = {
                title = 'Add applicant', 
                onSelect = function()
                    local input = lib.inputDialog('Add Applicants', {'ID', 'Party'})
         
                    if not input then return end
                    TriggerServerEvent('applicants:addApplicant', input[1], input[2])
                end
            }
            options[#options + 1] = {
                title = 'Reset All Data', 
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = "Do you wish to continue? This can't be reversed.",
                        centered = true,
                        cancel = true
                    })
                    if alert ~= "confirm" then return end
                    TriggerServerEvent('resetAllVotingData')
                end
            }
            
            lib.registerContext({
                id = 'Applicants_mayor_Vote_Menu',
                title = 'Applicants - Mayor Menu',
                options = options 
            })
        
            lib.showContext('Applicants_mayor_Vote_Menu')
        end,
        distance = 2.0
    }}
})

CreateThread(function()
    for i=1, #Config.votingStands do 
        votingModels = Config.votingStands[i]
        
        exports['ox_target']:addSphereZone({
            coords = votingModels.coords,
            radius = 0.3,
            debug = Config.Debug,
            options = {{
                icon = 'fa-solid fa-square-poll-vertical',
                label = 'Vote',
                onSelect = function(data)
                    local applicants = lib.callback.await("applicants:getApplicants", false)
                    local canVote = lib.callback.await("voter:canVote", false)
                    local options = {}
                    
                    for _, applicant in ipairs(applicants) do
                        options[#options + 1] = {
                            title = applicant.name, 
                            description = 'Current Votes: '..applicant.votes,
                            disabled = canVote,
                            onSelect = function()
                                local alert = lib.alertDialog({
                                    header = 'Mayoral Election',
                                    content = 'Applicant: '..applicant.name.."\n\nParty: "..applicant.Party.."\n\nYou Only Get One Vote, This Can't Be Undone!",
                                    centered = true,
                                    cancel = true
                                })
                                if alert ~= "confirm" then return end
                                TriggerServerEvent('addPlayersVote', applicant.key)
                            end
                        }
                    end
                
                    lib.registerContext({
                        id = 'Applicants_Vote_Menu',
                        title = 'Applicants - Vote Menu',
                        options = options 
                    })
                
                    lib.showContext('Applicants_Vote_Menu')
                end,
                distance = 2.0
            }}
        })
    end
end)
