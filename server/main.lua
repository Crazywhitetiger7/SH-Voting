local QBCore = exports['qb-core']:GetCoreObject()

local function loadApplicants()
    local serializedData = GetResourceKvpString("applicants")
    return serializedData and json.decode(serializedData) or {}
end

local function saveApplicants(applicants)
    SetResourceKvp("applicants", json.encode(applicants))
end

local function getApplicants(applicants)
    local players = {}
    for key, value in pairs(applicants) do
        players[#players + 1] = {key = key, name = value.name, votes = value.votes or 0, Party = value.Party or 'Independent'}
    end
    return players
end

local function addApplicant(applicants, name, party)
    for key, player in pairs(applicants) do
        if player.name == name then
                TriggerClientEvent('ox_lib:notify', source, {title = 'Voting', description = 'Already an applicant', type = 'error'})
            return 
        end
    end
    
    applicants[name] = {name = name, votes = 0, Party = party} 
    TriggerClientEvent('ox_lib:notify', source, {title = 'Voting', description = 'Applicant: '..name..' Added!', type = 'success'})
    saveApplicants(applicants)
end

local function removeApplicant(applicants, playerKey)
    if not applicants[playerKey] then
        return
    end
    TriggerClientEvent('ox_lib:notify', source, {title = 'Voting', description = 'Applicant: '..applicants[playerKey].name..' Removed!', type = 'success'})
    applicants[playerKey] = nil
    saveApplicants(applicants)
end

local function saveVotedStatus(votedTable)
    SetResourceKvp("voted_data", json.encode(votedTable))
end

local function loadVotedStatus()
    local serializedData = GetResourceKvpString("voted_data")
    if serializedData then
        return json.decode(serializedData)
    else
        local defaultData = {voters = {}}
        saveVotedStatus(defaultData)
        return defaultData
    end
end

local function hasPlayerVoted(voterKey)
    return loadVotedStatus().voters[voterKey] ~= nil
end

local function voteForPlayer(applicants, playerKey, voterKey)
    local votedData = loadVotedStatus()

    if hasPlayerVoted(voterKey) then
        return
    end

    if not applicants[playerKey] then
        return
    end

    applicants[playerKey].votes = (applicants[playerKey].votes or 0) + 1
    votedData.voters[voterKey] = true
    saveVotedStatus(votedData)
    saveApplicants(applicants)
end


lib.callback.register("applicants:getApplicants", function(source)
    return getApplicants(loadApplicants())
end)

lib.callback.register("voter:canVote", function(source)
    local player = QBCore.Functions.GetPlayer(source)
    return hasPlayerVoted(player.PlayerData.citizenid) 
end)

RegisterNetEvent('resetAllVotingData', function()
    SetResourceKvp("applicants", json.encode({}))
    SetResourceKvp("voted_data", json.encode({voters = {}}))
    TriggerClientEvent('ox_lib:notify', source, {title = 'Voting', description = 'Applicant data has been reset!', type = 'inform'})
end)

RegisterNetEvent('addPlayersVote', function(applicant)
    local player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('ox_lib:notify', source, {title = 'Voting', description = 'Your Ballot options Has Been Saved, Thank you For Voting!', type = 'inform'})
    voteForPlayer(loadApplicants(), applicant, player.PlayerData.citizenid)
end)

RegisterNetEvent("applicants:addApplicant", function(applicantID, applicantParty)
    local player = QBCore.Functions.GetPlayer(tonumber(applicantID))
    if not player then return end
    addApplicant(loadApplicants(), player.PlayerData.charinfo.firstname.." "..player.PlayerData.charinfo.lastname, applicantParty)
end)

RegisterNetEvent("applicants:removeApplicant", function(applicant)
    removeApplicant(loadApplicants(), applicant)
end)

