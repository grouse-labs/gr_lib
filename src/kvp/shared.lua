local kvp = {}
local set = SetResourceKvp
local get = GetResourceKvpString

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
---@param value string
---@return true? success
function kvp.set(key, value)
  if type(value) ~= 'string' then value = tostring(value) end
  return set(key, value)
end

---@param key string
---@return string|number? value
function kvp.get(key)
  local value = get(key)
  if not value then return nil end
  local num = tonumber(value)
  return num or value
end

---@param key string
function kvp.remove(key) DeleteResourceKvp(key) end

_ENV.kvp = kvp