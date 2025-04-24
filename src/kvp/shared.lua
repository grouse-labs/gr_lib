local kvp = {}
local setters = {string = SetResourceKvp, number = SetResourceKvpInt, float = SetResourceKvpFloat}
local getters = {GetResourceKvpString, GetResourceKvpInt, GetResourceKvpFloat}

---@param handle integer
---@return string[] keys
function kvp._find(handle)
  local keys = {}
  local key
  repeat
    key = FindKvp(handle)
    if key then
      glib.print(('%s: %s'):format(key, kvp.get(key)))
      keys[#keys + 1] = key
    end
  until not key
  EndFindKvp(handle)
  return keys
end

---@param prefix string?
---@return string[] keys
function kvp.find(prefix) return kvp._find(StartFindKvp(prefix or '')) end

---@param key string
---@param value string|number
---@return true? success
function kvp.set(key, value)
  local _type = type(value)
  return setters[_type] and setters[_type](key, value)
end

---@param key string
---@return string|number? value
function kvp.get(key)
  local value
  for i = 1, #getters do
    value = getters[i](key)
    if value then break end
  end
  return value
end

---@param key string
function kvp.remove(key) DeleteResourceKvp(key) end

_ENV.kvp = kvp