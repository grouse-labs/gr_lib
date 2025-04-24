---@diagnostic disable: duplicate-set-field
local setters_nosync = {string = SetResourceKvpNoSync, number = SetResourceKvpIntNoSync, float = SetResourceKvpFloatNoSync}

---@param key string
---@param value string|number
---@return true? success
function kvp.setnosync(key, value)
  local _type = type(value)
  return setters_nosync[_type] and setters_nosync[_type](key, value)
end

---@param key string
function kvp.removenosync(key) DeleteResourceKvpNoSync(key) end

---@param name string
---@param handler function
function kvp.addmethod(name, handler)
  if kvp[name] then
    error(('%s is already defined'):format(name), 2)
  end

  kvp[name] = handler
  exports(name, handler)
end

function kvp.flush() FlushResourceKvp() end

exports('kvpfind', kvp.find)
exports('kvpset', kvp.set)
exports('kvpget', kvp.get)
exports('kvpremove', kvp.remove)
exports('kvpsetnosync', kvp.setnosync)
exports('kvpremovenosync', kvp.removenosync)
exports('kvpflush', kvp.flush)

return kvp