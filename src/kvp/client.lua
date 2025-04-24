---@diagnostic disable: duplicate-set-field
local getters_external = {GetExternalKvpString, GetExternalKvpInt, GetExternalKvpFloat}

---@param resource string
---@param prefix string?
---@return string[] keys
function kvp.findexternal(resource, prefix)
  if not IsResourceValid(resource) then error(('%s is not a valid resource'):format(resource), 2) end
  return kvp._find(StartFindExternalKvp(resource, prefix or ''))
end

---@param resource string
---@param key string
---@return string|number? value
function kvp.getexternal(resource, key)
  if not IsResourceValid(resource) then error(('%s is not a valid resource'):format(resource), 2) end
  local value
  for i = 1, #getters_external do
    value = getters_external[i](resource, key)
    if value then break end
  end
  return value
end

return kvp