---@diagnostic disable: duplicate-set-field
local RESOURCE <const> = glib._RESOURCE
local CONTEXT <const> = glib._CONTEXT
local EVENT <const> = '__%s:%s:%s'

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
      if owner ~= -1 and (not obj.owner or owner ~= obj.owner) then
        TriggerClientEvent(string.format(EVENT, RESOURCE, 'client', 'ped_initialise'), owner, netID, obj.options)
        obj.owner = owner
        sleep = 1000
        if obj.options.onEnteredScope then
          obj.options.onEnteredScope(entity, owner)
        end
      elseif owner == -1 and obj.owner and obj.owner ~= -1 then
        TriggerClientEvent(string.format(EVENT, RESOURCE, 'client', 'ped_destroy'), obj.owner, netID)
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

---@param ped integer Ped handle
---@param flags integer[]?
---@param is_reset boolean?
local function set_flags(ped, flags, is_reset)
  if not ped or not flags then return end
  for i = 1, #flags do
    local flag = flags[i]
    if not is_reset then
      SetPedConfigFlag(ped, flag, true)
    else
      SetPedResetFlag(ped, flag, true)
    end
  end
end

function ped.new(model, coords, options)
  local obj = {}
  obj.model = model
  obj.coords = coords
  obj.options = options or {
    data = {
      orphan_mode = 0,
      bucket = 0,
      max_health = 100,
      armour = 0,
      relationship_group = ''
    },
    weapons = {
      model = nil,
      ammo = 0,
      hidden = false,
      brandish = false,
      components = {}
    },
    components = {
      default = nil,
      random = nil,
      {component_id = 0, drawable_id = 0, texture_id = 0, palette_id = 0},
    },
    props = {
      random = nil,
      {component_id = 0, drawable_id = 0, texture_id = 0, attach = true},
    },
    ranges = {
      lod = 150,
      id = 100.0,
      seeing = 100.0,
      peripheral = 30.0,
      hearing = 50.0,
      shout = 50.0
    },
    combat_ai = {
      ability = 50,
			accuracy = 50,
			alertness = 0,
			movement = 0,
			range = 0,
			target_response = 0
    },
    flags = {
      combat = {},
      config = {},
      reset = {}
    },
    proofs = {
			injured = true,
			bullet = false,
			fire = false,
			explosion = false,
			collision = false,
			melee = false,
			steam = false,
			water = false,
			invincible = false
		},
    onEnteredScope = function(entity, owner) print('entered: '..owner) end,
    onExitedScope = function(entity, owner) print('exited: '..owner) end,
  }
  local entity = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
  local netID = NetworkGetNetworkIdFromEntity(entity)
  obj.netID = netID
  obj.entity = entity
  obj.owner = 0
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
  ped.setweapon(obj, weapons.model, weapons.ammo, weapons.hidden, weapons.brandish, weapons.components)
  ped.setcomponents(obj, options.components)
  ped.setprops(obj, options.props)
  ped.setranges(obj, options.ranges)
  ped.setcombatai(obj, options.combat_ai)
  ped.setflags(obj, options.flags)
  ped.setproofs(obj, options.proofs)

  TriggerEvent('gr_lib:ped_catch', netID, obj)
  listen_to_ped_scope(obj)
  return setmetatable(obj, {__index = ped})
end

function ped:doesexist() return self.exists end

function ped:destroy()
  if self.exists then DeleteEntity(self.entity) end
  local netID = self.netID
  TriggerClientEvent(string.format(EVENT, RESOURCE, 'client', 'ped_destroy'), -1, self.netID)
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
  self.ranges = ranges or self.options.ranges
  return self
end

function ped:setcombatai(combat_ai)
  if not self.exists then return end
  self.combat_ai = combat_ai or self.combat_ai
  return self
end

function ped:setflags(flags)
  if not self.exists then return end
  if flags.config then
    set_flags(self.entity, flags.config, false)
  end
  if flags.reset then
    set_flags(self.entity, flags.reset, true)
  end
  self.options.flags = flags or self.options.flags
  return self
end

function ped:setproofs(proofs)
  if not self.exists then return end
  self.options.proofs = proofs
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