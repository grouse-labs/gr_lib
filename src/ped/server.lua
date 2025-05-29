---@diagnostic disable: duplicate-set-field
local RESOURCE <const> = glib._RESOURCE
local EVENT <const> = '__glib:%s:%s'

local ped = {}

--------------------- FUNCTIONS ---------------------

local function listen_to_ped_scope(obj)
  local entity = obj.entity
  local sleep = 1000
  CreateThread(function()
    local netID = obj.netID
    while DoesEntityExist(entity) do
      Wait(sleep)
      local owner = NetworkGetEntityOwner(entity)
      if owner ~= -1 and owner ~= obj.owner then
        TriggerClientEvent(string.format(EVENT, 'client', 'ped_initialise'), owner, netID, obj.options)
        obj.owner = owner
        sleep = 1000
        if obj.options.onEnteredScope then
          obj.options.onEnteredScope(entity, owner)
        end
      elseif owner == -1 and obj.owner ~= -1 then
        TriggerClientEvent(string.format(EVENT, 'client', 'ped_destroy'), obj.owner, netID)
        obj.owner = -1
        sleep = 2500
        if obj.options.onExitedScope then
          obj.options.onExitedScope(entity, owner)
        end
      end
    end
    obj.exists = false
    obj:destroy()
  end)
end

---@param handle integer Ped handle
---@param flags integer[]?
---@param is_reset boolean?
local function set_flags(handle, flags, is_reset)
  if not handle or not flags then return end
  for i = 1, #flags do
    local flag = flags[i]
    if not is_reset then
      SetPedConfigFlag(handle, flag, true)
    else
      SetPedResetFlag(handle, flag, true)
    end
  end
end

function ped.new(model, coords, options)
  local obj = {}
  obj.model = model
  obj.coords = coords
  obj.options = {}
  obj.options.data = {
    orphan_mode = options.data?.orphan_mode or 0,
    bucket = options.data?.bucket or 0,
    max_health = options.data?.max_health or 100,
    armour = options.data?.armour or 0,
    relationship_group = options.data?.relationship_group or ''
  }
  obj.options.weapons = {
    model = options.weapons?.model or nil,
    ammo = options.weapons?.ammo or 0,
    hidden = options.weapons?.hidden or false,
    brandish = options.weapons?.brandish or false,
    components = options.weapons?.components or {}
  }
  obj.options.components = options.components or {}
  obj.options.props = options.props or {}
  obj.options.ranges = {
    lod = options.ranges?.lod or 150,
    id = options.ranges?.id or 100.0,
    seeing = options.ranges?.seeing or 100.0,
    peripheral = options.ranges?.peripheral or 30.0,
    hearing = options.ranges?.hearing or 50.0,
    shout = options.ranges?.shout or 50.0
  }
  obj.options.combat_ai = {
    ability = options.combat_ai?.ability or 50,
    accuracy = options.combat_ai?.accuracy or 50,
    alertness = options.combat_ai?.alertness or 0,
    movement = options.combat_ai?.movement or 0,
    range = options.combat_ai?.range or 0,
    target_response = options.combat_ai?.target_response or 0
  }
  obj.options.flags = {
    combat = options.flags?.combat or {},
    config = options.flags?.config or {},
    reset = options.flags?.reset or {}
  }
  obj.options.proofs = {
    injured = options.proofs?.injured or true,
    bullet = options.proofs?.bullet or false,
    fire = options.proofs?.fire or false,
    explosion = options.proofs?.explosion or false,
    collision = options.proofs?.collision or false,
    melee = options.proofs?.melee or false,
    steam = options.proofs?.steam or false,
    water = options.proofs?.water or false,
    invincible = options.proofs?.invincible or false
  }
  obj.options.onEnteredScope = options.onEnteredScope
  obj.options.onExitedScope = options.onExitedScope
  local entity = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
  repeat Wait(0) until DoesEntityExist(entity)
  local netID = NetworkGetNetworkIdFromEntity(entity)
  obj.netID = netID
  obj.entity = entity
  obj.owner = -1
  obj.exists = true

  SetEntityIgnoreRequestControlFilter(entity, true)

  options = obj.options
  local data = options.data
  ped.setorphanmode(obj, data.orphan_mode)
  ped.setbucket(obj, data.bucket)
  ped.setmaxhealth(obj, data.max_health)
  ped.setarmour(obj, data.armour)
  if data.relationship_group and data.relationship_group ~= '' then
    ped.setrelationshipgroup(obj, data.relationship_group)
  end
  local weapons = options.weapons
  ped.setweapon(obj, weapons?.model, weapons?.ammo, weapons?.hidden, weapons?.brandish, weapons?.components)
  ped.setcomponents(obj, options?.components)
  ped.setprops(obj, options?.props)
  ped.setranges(obj, {})
  ped.setcombatai(obj, options?.combat_ai)
  ped.setflags(obj, options?.flags)
  ped.setproofs(obj, options?.proofs)

  TriggerEvent('gr_lib:ped_catch', netID, obj)
  listen_to_ped_scope(obj)
  return setmetatable(obj, {__index = ped})
end

function ped:doesexist() return self.exists end

function ped:destroy()
  if self.exists then DeleteEntity(self.entity) end
  local netID = self.netID
  TriggerClientEvent(string.format(EVENT, 'client', 'ped_destroy'), -1, self.netID)
  TriggerEvent('gr_lib:ped_remove', netID)
  self = nil
end

function ped:setorphanmode(mode)
  if not self.exists then return end
  SetEntityOrphanMode(self.entity, mode)
  self.options.data.orphan_mode = mode
  return self
end

function ped:setbucket(bucket)
  if not self.exists then return end
  SetEntityRoutingBucket(self.entity, bucket)
  self.options.data.bucket = bucket
  return self
end

function ped:setmaxhealth(health)
  if not self.exists then return end
  self.options.data.max_health = health
  return self
end

function ped:setarmour(armour)
  if not self.exists then return end
  SetPedArmour(self.entity, armour)
  self.options.data.armour = armour
  return self
end

function ped:setrelationshipgroup(group)
  if not self.exists then return end
  self.options.data.relationship_group = group
  return self
end

function ped:setweapon(model, ammo, hidden, brandish, components)
  if not self.exists then return end
  local entity = self.entity
  if model then
    GiveWeaponToPed(entity, model, ammo or 0, hidden or false, brandish or false)
    self.options.weapons.model = model
    self.options.weapons.ammo = ammo or 0
    self.options.weapons.hidden = hidden or false
    self.options.weapons.brandish = brandish or false
    if brandish and GetSelectedPedWeapon(entity) ~= model then
      SetCurrentPedWeapon(entity, model, true)
    end
  else
    RemoveAllPedWeapons(entity, true)
  end
  if components then
    for i = 1, #components do
      local component = components[i]
      if component then
        GiveWeaponComponentToPed(entity, model, component)
      end
    end
    self.options.weapons.components = components or self.options.weapons.components
  end
  return self
end

function ped:setcomponents(components)
  if not self.exists then return end
  local entity = self.entity
  if components.default then
    SetPedDefaultComponentVariation(entity)
  elseif components.random then
    SetPedRandomComponentVariation(entity, 0)
  else
    for i = 1, #components do
      local component = components[i]
      if component then
        SetPedComponentVariation(entity, component.component_id, component.drawable_id, component.texture_id, component.palette_id)
      end
    end
  end
  self.options.components = components or self.options.components
  return self
end

function ped:setprops(props)
  if not self.exists then return end
  local entity = self.entity
  if props.random then
    SetPedRandomProps(entity)
  else
    for i = 1, #props do
      local prop = props[i]
      if prop then
        SetPedPropIndex(entity, prop.component_id, prop.drawable_id, prop.texture_id, prop.attach or false)
      end
    end
  end
  self.options.props = props or self.options.props
  return self
end

function ped:setranges(ranges)
  if not self.exists then return end
  self.ranges = ranges or {
    lod = 150,
    id = 100.0,
    seeing = 100.0,
    peripheral = 30.0,
    hearing = 50.0,
    shout = 50.0
  }
  return self
end

function ped:setcombatai(combat_ai)
  if not self.exists then return end
  self.combat_ai = combat_ai or {
    ability = 50,
    accuracy = 50,
    alertness = 0,
    movement = 0,
    range = 0,
    target_response = 0
  }
  return self
end

function ped:setflags(flags)
  if not self.exists then return end
  if flags?.config then
    set_flags(self.entity, flags.config, false)
  end
  if flags?.reset then
    set_flags(self.entity, flags.reset, true)
  end
  self.options.flags = flags or {
    combat = {},
    config = {},
    reset = {}
  }
  return self
end

function ped:setproofs(proofs)
  if not self.exists then return end
  self.options.proofs = proofs or {
    injured = true,
    bullet = false,
    fire = false,
    explosion = false,
    collision = false,
    melee = false,
    steam = false,
    water = false,
    invincible = false
  }
  return self
end

---@param states table<string, any>
function ped:setstates(states)
  if not self.exists then return end
  local entity = Entity(self.entity)
  for k, v in pairs(states) do
    entity.state[string.format('%s:%s', RESOURCE, k)] = v
  end
  return self
end

return ped