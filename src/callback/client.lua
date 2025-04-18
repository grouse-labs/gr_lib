--[[
  https://github.com/overextended/ox_lib

  This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

  Copyright © 2025 Linden <https://github.com/thelindat>
]]
local RES_NAME <const> = glib._RESOURCE
local EVENT <const> = '__gr_cb_%s'
local game_timer = GetGameTimer
local invoke = Citizen.InvokeNative
local await = Citizen.Await
local unpack = table.unpack

local timers = {} ---@type {[string]: integer}
local callbacks = {} ---@type {[string]: function}

local callback = {}

--------------------- FUNCTIONS ---------------------

---@param event string The callback to delay.
---@param delay integer? The delay in milliseconds before the callback can be triggered.
---@return boolean delayed
local function is_callback_delayed(event, delay)
  if not delay or type(delay) ~= 'number' or delay <= 0 then return false end

  local time = game_timer()

  if (timers[event] or 0) > time then return true end

  timers[event] = time + delay

  return false
end

---@param key string The key of the callback to call.
---@param ... any Additional arguments to pass to the callback.
local function receive_callback(key, ...)
  local cb = callbacks[key] --[[@as function?]]

  if not cb then return end

  callbacks[key] = nil

  cb(...)
end

---@param error string?
---@return string?
local function get_formated_stack_trace(error) -- Based on [doStackFormat](https://github.com/citizenfx/fivem/blob/476f550dfb5d35b53ff9db377445be76db7c28bc/data/shared/citizen/scripting/lua/scheduler.lua#L482)
  local stack_trace = invoke(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())
  return stack_trace and string.format('^1SCRIPT ERROR: %s^7\n%s', error or '', stack_trace) or stack_trace
end

---@param success boolean
---@param result any
---@param ... any
---@return any, any
local function pass_callback_result(success, result, ...)
  if not success then
    if result then
      return print(get_formated_stack_trace(result))
    end
    return false
  end

  return result, ...
end

---@param name string The callback `name`.
---@param cb function The callback function.
-- Registers an event handler with a callback to the respective enviroment
function callback.register(name, cb)
  if not name or type(name) ~= 'string' then error('bad argument #1 to \'register\' (string expected, got '..type(name)..')', 2) end
  if not cb or type(cb) ~= 'function' then error('bad argument #2 to \'register\' (function expected, got '..type(cb)..')', 2) end

  RegisterNetEvent(EVENT:format(name), function(resource, key, ...)
    TriggerServerEvent(EVENT:format(resource), key, pass_callback_result(pcall(cb, ...)))
  end)
end

---@param name string The callback `name`.
---@param delay integer? The delay in milliseconds before the callback is triggered.
---@param cb function The receiving callback function.
---@param ... any Additional arguments to pass to the callback.
-- Triggers a callback with the given name and calls back the data through the given function.
function callback.trigger(name, delay, cb, ...)
  if is_callback_delayed(name, delay) then return end
  if not name or type(name) ~= 'string' then error('bad argument #1 to \'trigger\' (string expected, got '..type(name)..')', 2) end
  if cb ~= false and type(cb) ~= 'function' then error('bad argument #3 to \'trigger\' (function expected, got '..type(cb)..')', 2) end

  local key do
    repeat
      key = string.format('%s:%s', name, math.random(0, 100000))
    until not callbacks[key]
  end

  TriggerServerEvent(string.format(EVENT, name), RES_NAME, key, ...)

  local p = not cb and promise.new()

  callbacks[key] = function(response, ...)
    response = {response, ...}
    if p then
      return p:resolve(response)
    else
      cb(unpack(response))
    end
  end

  if p then
    SetTimeout(5000, function() p:reject(('callback event \'%s\' timed out'):format(key)) end)
    return unpack(await(p))
  end
end

---@param name string The callback `name`.
---@param delay integer? The delay in milliseconds before the callback is triggered.
---@param ... any Additional arguments to pass to the callback.
---@return ...
function callback.await(name, delay, ...)
  if not name or type(name) ~= 'string' then error('bad argument #1 to \'await\' (string expected, got '..type(name)..')', 2) end
  if ... then
    local args = {...}
    if args[1] and type(args[1]) == 'function' then error('bad argument #3 to \'await\' (callback function is redundant)', 2) end
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  return callback.trigger(name, delay, false, ...)
end

--------------------- EVENTS ---------------------

RegisterNetEvent(string.format(EVENT, RES_NAME), receive_callback)

--------------------- OBJECT ---------------------

return setmetatable(callback, {
  __name = 'callback',
  __newindex = function() error('attempt to edit a read-only object', 2) end
})
