---@diagnostic disable: duplicate-set-field
local RESOURCE <const> = glib._RESOURCE
local CONTEXT <const> = glib._CONTEXT
local EVENT <const> = '__%s:%s:%s'

local peds = {}
local ped = {}

--------------------- FUNCTIONS ---------------------

local function set_ped_options(obj, options)
  local data = options.data
  if data then
    if data.max_health then obj:setmaxhealth(data.max_health) end
    if data.relationship_group and data.relationship_group ~= '' then obj:setrelationshipgroup(data.relationship_group) end
  end

  obj:setranges(options.ranges)
  obj:setcombatai(options.combat_ai)
  obj:setflags(options.flags?.combat)
  obj:setproofs(options.proofs)

  return obj
end

function ped.catch(netID, options)
  local obj = {}
  obj.netID = netID
  obj.entity = NetworkGetEntityFromNetworkId(netID)
  obj.options = {
    data = {},
    ranges = {},
    combat_ai = {},
    flags = {
      combat = {}
    },
    proofs = {}
  }
  -- set_ped_options(obj, options)
  obj = setmetatable(obj, {__index = ped})
  local data = options.data
  if data then
    if data.max_health then obj:setmaxhealth(data.max_health) end
    if data.relationship_group and data.relationship_group ~= '' then obj:setrelationshipgroup(data.relationship_group) end
  end
  print(json.encode(options))
  obj:setranges(options.ranges)
  obj:setcombatai(options.combat_ai)
  obj:setflags(options.flags?.combat)
  obj:setproofs(options.proofs)
  peds[netID] = obj
  return peds[netID]
end

function ped.get(netID) return peds[netID] end

function ped.remove(netID)
  local ped = ped.get(netID)
  if not ped then return end
  ped:destroy()
end

function ped:doesexist() return DoesEntityExist(self.entity) end

function ped:destroy()
  if self:doesexist() then
    local entity = self.entity
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
  end
  peds[self.netID] = nil
  self = nil
end

function ped:setmaxhealth(health)
  if not self:doesexist() then return end
  local entity = self.entity
  SetEntityMaxHealth(entity, health)
  SetEntityHealth(entity, health)
  self.options.data.max_health = health
  return self
end

function ped:setrelationshipgroup(group)
  if not self:doesexist() then return end
  SetPedRelationshipGroupHash(self.entity, group)
  self.options.data.relationship_group = group
  return self
end

function ped:setranges(ranges)
  if not self:doesexist() then return end
  local entity = self.entity
  SetEntityLodDist(entity, ranges.lod)
  SetPedIdRange(entity, ranges.id)
  SetPedSeeingRange(entity, ranges.seeing)
  SetPedVisualFieldPeripheralRange(entity, ranges.peripheral)
  SetPedHearingRange(entity, ranges.hearing)
  self.options.data.ranges = ranges
  return self
end

function ped:setcombatai(combat_ai)
  if not self:doesexist() then return end
  local entity = self.entity
  SetPedCombatAbility(entity, combat_ai.ability)
  SetPedCombatMovement(entity, combat_ai.movement)
  SetPedCombatRange(entity, combat_ai.range)
  SetPedAlertness(entity, combat_ai.alertness)
  SetPedAccuracy(entity, combat_ai.accuracy)
  SetPedTargetLossResponse(entity, combat_ai.target_response)
  self.options.combat_ai = combat_ai
  return self
end

function ped:setflags(combat)
  if not self:doesexist() then return end
  local entity = self.entity
  for i = 1, #combat do
    local flag = combat[i]
    SetPedCombatAttributes(entity, flag, true)
  end
  self.options.flags.combat = combat
  return self
end

function ped:setproofs(proofs)
  if not self:doesexist() then return end
  local entity = self.entity
  SetPedDiesWhenInjured(entity, not proofs.injured or true)
  SetEntityProofs(entity, proofs.bullet or false, proofs.fire or false, proofs.explosion or false, proofs.collision or false, proofs.melee or false, proofs.steam or false, true, proofs.water or false)
  SetEntityInvincible(entity, proofs.invincible or false)
  print('proofs', proofs.invincible)
  self.options.proofs = proofs
  return self
end

--------------------- EVENTS ---------------------

RegisterNetEvent(string.format(EVENT, RESOURCE, 'client', 'ped_initialise'), ped.catch)
RegisterNetEvent(string.format(EVENT, RESOURCE, 'client', 'ped_destroy'), ped.remove)

return {}