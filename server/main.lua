local peds = {}

local function ped_catch(netID, obj)
  if not obj or not obj.ped then return end
  if not DoesEntityExist(obj.ped) then return end
  peds[netID] = obj
end

local function ped_get(netID)
  if not peds[netID] then return end
  local obj = peds[netID]
  if not DoesEntityExist(obj.ped) then
    peds[netID] = nil
    return
  end
  return obj
end

local function ped_remove(netID)
  if not peds[netID] then return end
  peds[netID] = nil
end

AddEventHandler('gr_lib:ped_catch', ped_catch)
AddEventHandler('gr_lib:ped_remove', ped_remove)

exports('getped', ped_get)