--[[
  https://github.com/overextended/ox_lib

  This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

  Copyright © 2025 Linden <https://github.com/thelindat>
]]
local RESOURCE = glib._RESOURCE
local get_resource_state = GetResourceState
local _require = require

local resource_states = enum('resource_states')

--------------------- OBJECT ---------------------

---@type {[string]: {env: table, contents: (fun(): ...)}}
local packages = {}
local package = {
  path = './?.lua;./?/init.lua;./?/shared/import.lua',
  preload = {},
  loaded = {}
}

--------------------- FUNCTIONS ---------------------

---@param resource_name string
---@return boolean? valid
local function is_resource_valid(resource_name)
  local state = get_resource_state(resource_name)
  return resource_states.valid[state] and not resource_states.invalid[state]
end

---@param mod_name string
---@param contents function
local function bld_mod_preload_cache(mod_name, contents)
  package.preload[mod_name] = function()
    packages[mod_name] = packages[mod_name] or {}
    packages[mod_name].env = _ENV
    packages[mod_name].contents = contents
    glib.print('^2loaded module^7 ^5\''..mod_name..'\'^7')
    return packages[mod_name].contents()
  end
end

---@param mod_name string The name of the module to load. <br> This has to be a dot-separated path to the module. <br> For example, `bridge.init`.
---@return function|table|false result, string errmsg
local function load_module(mod_name)
  local current_package = ''
  local errmsg = ''
  for i = 1, #package.searchers do
    local result, err = package.searchers[i](mod_name)
    if result ~= false then
      current_package = err
      package.loaded[current_package] = result or result == nil
      return package.loaded[current_package], current_package
    end
    errmsg = errmsg..'\n\t'..err
  end
  return false, errmsg
end

---@param mod_name string The name of the module to search for. <br> This has to be a dot-separated path to the module. <br> For example, `bridge.init`.
---@param pattern string? A pattern to search for the module. <br> This has to be a string with a semicolon-separated list of paths. <br> For example, `./?.lua;./?/init.lua`.
---@return string mod_path, string? errmsg The path to the module, and an error message if the module was not found.
function package.searchpath(mod_name, pattern) -- Based on the Lua [`package.searchpath`](https://github.com/lua/lua/blob/c1dc08e8e8e22af9902a6341b4a9a9a7811954cc/loadlib.c#L474) function, [Lua Modules Loader](http://lua-users.org/wiki/LuaModulesLoader) by @lua-users & ox_lib's [`package.searchpath`](https://github.com/overextended/ox_lib/blob/cdf840fc68ace1f4befc78555a7f4f59d2c4d020/imports/require/shared.lua#L50) function.
  if type(mod_name) ~= 'string' then error('bad argument #1 to \'search_path\' (string expected, got '..type(mod_name)..')', 2) end
  local mod_path = mod_name:gsub('%.', '/')
  local resource, dir, contents = mod_name:match('^%@?(%w+%_?%-?%w+)'), '', ''
  local errmsg = nil
  pattern = pattern or package.path
  if not is_resource_valid(resource) then resource = RESOURCE; mod_path = RESOURCE..'/'..mod_path end
  for subpath in pattern:gmatch('[^;]+') do
    local file = subpath:gsub('%?', mod_path)
    dir = file:match('^./%@?%w+%_?%-?%w+(.*)')
    mod_name = resource..dir:gsub('%/', '.'):gsub('.lua', '') --[[@as string]]
    if package.preload[mod_name] then return mod_name end
    contents = LoadResourceFile(resource, dir)
    if contents then
      local module_fn, err = load(contents, '@@'..resource..dir, 't', _ENV)
      if module_fn then
        bld_mod_preload_cache(mod_name, module_fn)
        break
      end
      errmsg = (errmsg or '')..(err and '\n\t'..err or '')
    end
  end
  return package.preload[mod_name] and mod_name or false, errmsg
end

---@type (fun(mod_name: string, env: table?): function|false, string)[]
package.searchers = {
  ---@param mod_name string
  ---@return function|table|false result, string errmsg
  function(mod_name)
    local success, contents = pcall(_require, mod_name)
    if success then
      mod_name = mod_name:match('([^%.]+)$')
      bld_mod_preload_cache(mod_name, function() return contents end)
      return package.preload[mod_name](), mod_name
    end
    return false, contents
  end,
  ---@param mod_name string
  ---@return function|table|false result, string errmsg
  function(mod_name)
    local mod_path, err = package.searchpath(mod_name)
    if mod_path and not err then
      local module = package.loaded[mod_path]
      if module then return module, mod_path end
      return package.preload[mod_path] and package.preload[mod_path](), mod_path
    end
    return false, 'module \''..mod_name..'\' not found'..(err and '\n\t'..err or '')
  end
}

---@param mod_name string The name of the module to require.
---@return unknown
-- `mod_name` needs to be a dot seperated path from resource to module. <br> Credits to [Lua Modules Loader](http://lua-users.org/wiki/LuaModulesLoader) by @lua-users & ox_lib's [`require`](https://github.com/overextended/ox_lib/blob/cdf840fc68ace1f4befc78555a7f4f59d2c4d020/imports/require/shared.lua#L149).
function package.require(mod_name)
  if type(mod_name) ~= 'string' then error('bad argument #1 to \'require\' (string expected, got '..type(mod_name)..')', 2) end
  local errmsg = 'bad argument #1 to \'require\' (module \''..mod_name..'\' not found)'
  if package.loaded[mod_name] then return package.loaded[mod_name] end
  local result, err = load_module(mod_name)
  if result then return result end
  error(errmsg..'\n\t'..err, 2)
end

return package.require