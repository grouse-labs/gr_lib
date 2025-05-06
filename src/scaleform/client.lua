local enum = glib.enum
local brief_types = enum 'eBriefTypes' {
  DIALOGUE = 0,
  HELP = 1,
  MISSION = 2
}

local KEY <const> = 'SC_LBL_'
local labels = 0
local scaleform = {}
local _mt = {
  __name = 'scaleform',
  __index = scaleform
}

---@param key string
---@param label string
local function add_label(key, label)
  if DoesTextLabelExist(key) and GetLabelText(key) == label then return end
  AddTextEntry(key, label)
  labels += 1
end

---@param value number
---@return boolean is_int
local function is_int(value) return value == math.floor(value) end

---@param key string?
---@param value string|number|boolean|{name: string, texture: boolean} The value to add.
local function add_param(key, value)
  if type(value) == 'string' then
    if key and not brief_types[value] then
      add_label(key, value)
      BeginTextCommandScaleformString(key)
      EndTextCommandScaleformString()
    else
      ScaleformMovieMethodAddParamLatestBriefString(brief_types[value] --[[@as integer]])
    end
  elseif type(value) == 'number' then
    if is_int(value) then
      PushScaleformMovieFunctionParameterInt(value)
    else
      PushScaleformMovieFunctionParameterFloat(value)
    end
  elseif type(value) == 'boolean' then
    PushScaleformMovieFunctionParameterBool(value)
  elseif type(value) == 'table' and value.texture then
    if value.texture then
      ScaleformMovieMethodAddParamTextureNameString(value.name)
    end
  else
    error(('unsupported Parameter type [%s]'):format(type(value)), 2)
  end
end

---@param args any|table The arguments to add.
local function add_params(args)
  args = type(args) == 'table' and args or {args}
  for i = 1, #args do
    add_param(KEY..labels, args[i])
  end
end

---@param begin fun(): boolean
---@param args table|any
---@param ret_val string? The return value type.
---@param finish fun(): any?
---@return any?
local function call(begin, args, ret_val, finish)
  if not begin() then return end
  add_params(args)
  if not ret_val then finish() return end
  local result = EndScaleformMovieMethodReturnValue()
  repeat Wait(0) until IsScaleformMovieMethodReturnValueReady(result)
  if ret_val == 'boolean' then
    return GetScaleformMovieMethodReturnValueBool(result)
  elseif ret_val == 'integer' then
    return GetScaleformMovieMethodReturnValueInt(result)
  else
    return GetScaleformMovieMethodReturnValueString(result)
  end
end

---@param name string
---@return integer handle
local function req_scaleform(name)
  local handle = RequestScaleformMovie(name)
  repeat Wait(0) until HasScaleformMovieLoaded(handle)
  return handle
end

---@param options scaleform_options
---@return scaleform
function scaleform.new(options)
  local obj = setmetatable({}, _mt)
  local name = options.name
  local screen = options.screen
  local hud = screen.hud or false
  local header = screen.header or false
  local frontend = screen.frontend or false
  local full = screen.full or not hud and not header and not frontend and not screen.x and not screen.y
  local x = screen.x or 0
  local y = screen.y or 0
  local scale = options.scale
  local width = scale and scale.width or 0
  local height = scale and scale.height or 0
  local render = options.render
  local colour = options.colour
  local r = colour and colour.r or 255
  local g = colour and colour.g or 255
  local b = colour and colour.b or 255
  local a = colour and colour.a or 255
  local handle = not hud and req_scaleform(name) or type(hud) == 'number' and is_int(hud) and glib.stream.scaleformhud(hud)
  if not handle then error('failed to load scaleform: ' .. name) end
  obj.handle = handle
  obj.is_drawing = false
  obj.fullscreen = full
  obj.frontend = frontend
  obj.header = header
  obj.hud = hud
  obj.x = x
  obj.y = y
  obj.width = width
  obj.height = height
  obj.r = r
  obj.g = g
  obj.b = b
  obj.a = a

  if render then
    obj:setrender(render.name, render.model, render.large, render.super_large)
  end

  return obj
end

local scaleform_methods = {
  main = BeginScaleformMovieMethod,
  frontend = BeginScaleformMovieMethodOnFrontend,
  header = BeginScaleformMovieMethodOnFrontendHeader,
  hud = BeginScaleformScriptHudMovieMethod
}

---@param method string The method to call.
---@param args any|table The arguments to pass to the method.
---@param ret_val string? The return value type.
---@return any?
function scaleform:call(method, args, ret_val)
  if not self.handle then error('attempted to call method with invalid scaleform handle') end
  local _type = self.frontend and 'frontend' or self.header and 'header' or self.hud and 'hud' or 'main'
  local begin = scaleform_methods[_type]
  local finish = not ret_val and EndScaleformMovieMethod or EndScaleformMovieMethodReturnValue
  return call(function() return begin(self.handle, method) end, args, ret_val, finish)
end

---@param fullscreen boolean Whether to set the scaleform to fullscreen.
---@return scaleform self The scaleform object.
function scaleform:setfullscreen(fullscreen)
  self.fullscreen = fullscreen
  return self
end

---@param x number? The x position of the scaleform.
---@param y number? The y position of the scaleform.
---@param width number? The width of the scaleform.
---@param height number? The height of the scaleform.
---@return scaleform self The scaleform object.
function scaleform:setproperties(x, y, width, height)
  if self.fullscreen then error('cannot set properties when full screen is enabled') end
  self.x = x or self.x
  self.y = y or self.y
  self.width = width or self.width
  self.height = height or self.height
  return self
end

---@param r integer? The red value of the scaleform.
---@param g integer? The green value of the scaleform.
---@param b integer? The blue value of the scaleform.
---@param a integer? The alpha value of the scaleform.
---@return scaleform self The scaleform object.
function scaleform:setcolour(r, g, b, a)
  self.r = r or self.r
  self.g = g or self.g
  self.b = b or self.b
  self.a = a or self.a
  return self
end

---@param name string The name of the render target.
---@param model string|integer The model of the render target.
---@param large boolean? Whether to set the render target to large.
---@param super_large boolean? Whether to set the render target to super large.
---@return scaleform self The scaleform object.
function scaleform:setrender(name, model, large, super_large)
  if self.target then ReleaseNamedRendertarget(self.target_name) end
  model = type(model) == 'string' and joaat(model) or model

  if not IsNamedRendertargetRegistered(name) then
    if large then
      SetScaleformMovieToUseLargeRt(self.handle, true)
    elseif super_large then
      SetScaleformMovieToUseSuperLargeRt(self.handle, true)
    end

    if not RegisterNamedRendertarget(name, false) then error('failed to register named rendertarget: ' .. name) end
    if not IsNamedRendertargetLinked(name) then LinkNamedRendertarget(model) end

    self.target = GetNamedRendertargetRenderId(name)
    self.target_name = name
  end
  return self
end

---@return boolean is_drawing Whether the scaleform is currently drawing.
function scaleform:isdrawing() return self.is_drawing end

---@param await boolean? Whether to wait for the scaleform to finish drawing.
---@param mask scaleform The scaleform to use as a mask.
---@return scaleform|false? self The scaleform object.
function scaleform:draw(await, mask)
  if self.is_drawing then return end
  self.is_drawing = true
  local p = await and promise.new()
  CreateThread(function()
    while self.is_drawing do
      if self.target then
        SetTextRenderId(self.target)
        SetScriptGfxDrawOrder(4)
        SetScriptGfxDrawBehindPausemenu(true)
        SetScaleformFitRendertarget(self.handle, true)
      end

      if self.fullscreen then
        if not mask then
          DrawScaleformMovieFullscreen(self.handle, self.r, self.g, self.b, self.a, 0)
        else
          DrawScaleformMovieFullscreenMasked(self.handle, mask.handle, mask.r or self.r, mask.g or self.g, mask.b or self.b, mask.a or self.a)
        end
      else
        DrawScaleformMovie(self.handle, self.x, self.y, self.width, self.height, self.r, self.g, self.b, self.a, 0)
      end

      if self.target then
        SetTextRenderId(1)
      end
      Wait(0)
    end
    if await then promise:resolve(self) end
  end)
  return await and Citizen.Await(p --[[@as promise]])
end

---@return scaleform self The scaleform object.
function scaleform:stopdrawing()
  if self.is_drawing then
    self.is_drawing = false
  end
  return self
end

function scaleform:destroy()
  if self.target then ReleaseNamedRendertarget(self.target_name) end
  if self.handle then SetScaleformMovieAsNoLongerNeeded(self.handle) end
  self = nil
end

return scaleform.new