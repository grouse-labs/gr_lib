if _VERSION:gsub('%D', '') < ('5.4'):gsub('%D', '') then error('Lua version 5.4 or higher is required', 0) end

local RES_NAME <const> = GetCurrentResourceName()
local GLIB <const> = 'gr_lib'

local get_res_meta = GetResourceMetadata
local VERSION <const> = get_res_meta(GLIB, 'version', 0)
local URL <const> = get_res_meta(GLIB, 'url', 0)
local DES <const> = get_res_meta(GLIB, 'description', 0)

local get_convar = GetConvar
local debug_mode = get_convar('glib:debug', 'false') == 'true'

local load, load_resource_file = load, LoadResourceFile
local export = exports[GLIB]

local CONTEXT <const> = IsDuplicityVersion() and 'server' or 'client'

--------------------- FUNCTIONS ---------------------

---@param glib CGlib
---@param module string
---@return function?
local function import(glib, module)
  local dir = 'src/'..module..'/'
  local file = load_resource_file(GLIB, dir..CONTEXT..'.lua')
  local shared = load_resource_file(GLIB, dir..'shared.lua')

  file = shared and file and string.format('%s\n%s', shared, file) or shared or file

  if not file then return end
  local result, err = load(file, '@@'..GLIB..'/'..dir..CONTEXT, 't', _ENV)
  if not result or err then return error('error occured loading module \''..module..'\''..(err and '\n\t'..err or ''), 3) end
  glib[module] = result()
  if debug_mode then print('^3[glib]^7 - ^2loaded `glib` module^7 ^5\''..module..'\'^7') end
  return glib[module]
end

---@param glib CGlib
---@param index string
---@param ... any
---@return function
local function call(glib, index, ...)
  local module = rawget(glib, index) or import(glib, index)
  if not module then
    local method = function(...) return export[index](nil, ...) end
    if index == 'audio' or index  =='github' then
      method = method()
    elseif not ... then
      glib[index] = method
    end
    module = method
  end
  return module
end

--------------------- OBJECT ---------------------

---@version 5.4
---@class CGlib
---@field _VERSION string
---@field _URL string
---@field _DESCRIPTION string
---@field _DEBUG boolean
---@field _RESOURCE string
---@field _CONTEXT string
---@field enum fun(name: string|enum_options, tbl: enum_options?): enum|fun(name: string|enum_options, tbl: enum_options?): enum
---@field audio audio
---@field callback callback
---@field kvp kvp
---@field ped ped
---@field github github
---@field stream stream
---@field scaleform fun(scaleform_options: scaleform_options): scaleform
---@field getped fun(netID: integer): ped|nil Returns a ped object from a network ID. <br> If the ped does not exist, it will return `nil`.
---@field print fun(...): msg: string Prints a message to the console. <br> If `glib:debug` is set to `false`, it will not print the message. <br> Returns the message that was printed.
---@field require fun(module_name: string): module: unknown `mod_name` needs to be a dot seperated path from resource to module. <br> Credits to [Lua Modules Loader](http://lua-users.org/wiki/LuaModulesLoader) by @lua-users & ox_lib's [`require`](https://github.com/overextended/ox_lib/blob/cdf840fc68ace1f4befc78555a7f4f59d2c4d020/imports/require/shared.lua#L149).
local glib = setmetatable({
  _VERSION = VERSION,
  _URL = URL,
  _DESCRIPTION = DES,
  _DEBUG = debug_mode,
  _RESOURCE = RES_NAME,
  _CONTEXT = CONTEXT,
  print = function(...)
    local msg = '^3['..RES_NAME..']^7 - '..(...)
    if debug_mode then
      print(msg)
    end
    return msg
  end
}, {
  __name = GLIB,
  __version = VERSION,
  __tostring = function(t)
    local address = string.format('%s: %p', GLIB, t)
    if debug_mode then
      local msg = string.format('^3[%s]^7 - ^2library^7 ^5\'%s\'^7 v^5%s^7\n%s', RES_NAME, GLIB, VERSION, address)
      for k, v in pairs(t) do
        if type(v) == 'table' then
          msg = msg..string.format('\n^3[%s]^7 - ^2`glib` module^7 ^5\'%s\'^7 ^2is loaded^7\n%s: %p', RES_NAME, k, k, v)
        end
      end
    return msg
    end
    return address
  end,
  __index = call,
  __call = call
})

_ENV.glib = glib
_ENV.enum = glib.enum
_ENV.require = glib.require

--------------------- ENV FUNCTIONS ---------------------
local resource_states = enum('resource_states')

---@param resource_name string
---@return boolean? valid
function IsResourceValid(resource_name)
  local state = GetResourceState(resource_name)
  return resource_states:search(state) and resource_states:search(state) ~= 'invalid'
end

if CONTEXT == 'server' then

  ---@param src integer|string? The source to check.
  ---@return boolean? valid
  function IsSrcAPlayer(src)
    src = src or source
    return tonumber(src) and tonumber(src) > 0 and DoesPlayerExist(src)
  end

end

return glib