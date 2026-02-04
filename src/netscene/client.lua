local stream = glib.stream
local netscene = {}
local _mt = {
  __name = 'netscene',
  __index = netscene
}

--------------------- FUNCTIONS ---------------------

---@param scene_options scene_options
---@return netscene
function netscene.new(scene_options)
  local obj = setmetatable({}, _mt)
  local scene_data = scene_options.scene
  local peds, objs = scene_options.peds, scene_options.objs
  local coords = scene_data.coords
  local rotation = scene_data.rotation
  local order = scene_data.order or 2
  local hold = scene_data.hold or false
  local looped = scene_data.looped or false
  local stop_phase = scene_data.stop_phase or 1.0
  local start_phase = scene_data.start_phase or 0.0
  local speed = scene_data.speed or 1.0
  local scene = NetworkCreateSynchronisedScene(
    coords.x,
    coords.y,
    coords.z,
    rotation.x,
    rotation.y,
    rotation.z,
    order,
    hold,
    looped,
    stop_phase,
    start_phase,
    speed
  )

  obj.nethandle = scene
  obj.handle = NetworkGetLocalSceneFromNetworkId(scene)
  obj.coords = coords
  obj.rotation = rotation
  obj.order = order
  obj.hold = hold
  obj.looped = looped
  obj.stop_phase = stop_phase
  obj.start_phase = start_phase
  obj.speed = speed
  obj.peds = {}
  obj.objs = {}

  if peds then
    for i = 1, #peds do
      local ped = peds[i]
      local entity = ped.entity
      local model = ped.model

      if not entity then
        if not model then break end -- error handling
        if not stream.model(model) then break end -- error handling
        entity = CreatePed(0, model, coords.x, coords.y, coords.z, 0.0, true, true)
      end

      local dict = ped.dict

      if not stream.animdict(dict) then break end -- error handling

      local anim = ped.anim
      local blend_in = ped.blend_in or 8.0
      local blend_out = ped.blend_out or -8.0
      local scene_flags = ped.scene_flags or 0
      local ragdoll_flags = ped.ragdoll_flags or 0
      local move_delta = ped.move_delta or 1000.0
      local ik_flags = ped.ik_flags or 0

      NetworkAddPedToSynchronisedScene(entity, scene, dict, anim, blend_in, blend_out, scene_flags, ragdoll_flags, move_delta, ik_flags)
      obj.peds[#obj.peds + 1] = entity
    end
  end

  if objs then
    for i = 1, #objs do
      local object = objs[i]
      local entity = object.entity
      local model = object.model
      local door = object.door or false

      if not entity then
        if not model then break end -- error handling
        if not stream.model(model) then break end -- error handling
        entity = CreateObject(model, coords.x, coords.y, coords.z, true, true, door)
      end

      local dict = object.dict

      if not stream.animdict(dict) then break end -- error handling

      local anim = object.anim
      local blend_in = object.blend_in or 8.0
      local blend_out = object.blend_out or -8.0
      local scene_flags = object.scene_flags or 0

      NetworkAddEntityToSynchronisedScene(entity, scene, dict, anim, blend_in, blend_out, scene_flags)
      obj.objs[#obj.objs + 1] = entity
    end
  end

  return obj
end

function netscene:stop()
  NetworkStopSynchronisedScene(self.nethandle)
end

---@param cb fun(phase: number, ...: unknown): boolean
---@param ... unknown Arguments to parse to the callback function.
function netscene:start(cb, ...)
  local handle = self.nethandle
  NetworkStartSynchronisedScene(handle)
  repeat
    Wait(100)
    if cb then cb(netscene:getphase(), ...) end
  until netscene:getphase() >= (self.hold and self.stop_phase or self.stop_phase - 0.01) or netscene:getphase() == 0.0
end

---@param peds boolean?
---@param objs boolean?
function netscene:clear(peds, objs)
  if peds then
    for i = 1, #self.peds do
      local entity = self.peds[i]
      SetEntityAsMissionEntity(entity, true, true)
      DeletePed(entity)
    end
  end
  if objs then
    for i = 1, #self.objs do
      local entity = self.objs[i]
      SetEntityAsMissionEntity(entity, true, true)
      DeleteEntity(entity)
    end
  end
end

---@return number
function netscene:getphase()
  self.handle = IsSynchronizedSceneRunning(self.handle) and self.handle or NetworkGetLocalSceneFromNetworkId(self.nethandle)
  return GetSynchronizedScenePhase(self.handle)
end

return netscene.new