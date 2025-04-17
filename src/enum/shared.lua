local context = glib._CONTEXT

---@class CEnum
---@field private __keys string|number[]
---@field new fun(name: string|table, tbl: table?): CEnum
---@field lookup fun(self: CEnum, var: string|number): string|number|CEnum?
---@field [string] CEnum
local enum = {}
local _mt = {
  __name = 'enum',
  __type = 'enum',
  __index = enum
}

---@param t table The table to check.
---@return boolean is_array True if the table is an array, false otherwise.
local function is_array(t)
  if type(t) ~= 'table' then return false end
  if not t[0] and not t[1] then return false end
  local i, lim = t[0] and 0 or 1, t[0] and #t - 1 or #t
  for j = i, lim do
    if t[j] == nil then return false end
  end
  return true
end

---@param path string The path to the enum file.
---@return table? enum The loaded enum file or nil if it doesn't exist.
local function get_enum_file(path)
  local success, file = pcall(load, LoadResourceFile('gr_lib', path..'.lua'), '@@'..path..'.lua', 't', _ENV)
  return success and file and file() --[[@as table?]]
end

---@param tbl {[string|number]: string|number|(string|number)[]} The table to convert to a local enum.
---@return CEnum obj The converted table.
local function create_lookup_tables(tbl)
  local obj = {}
  obj.__keys = {}
  if is_array(tbl) then
    for i = 0, #tbl do
      local val = tbl[i]
      if val then
        if type(val) == 'table' then
          obj[val] = setmetatable(create_lookup_tables(val), _mt)
        else
          obj[val] = i
          obj[i] = val
        end
        obj.__keys[i] = val
      end
    end
  else
    for k, v in pairs(tbl) do
      if type(v) == 'table' then
        obj[k] = setmetatable(create_lookup_tables(v), _mt)
      else
        obj[k] = v
        obj[v] = k
      end
      obj.__keys[#obj.__keys + 1] = k
    end
    table.sort(obj.__keys, function(a, b)
      local type_a, type_b = type(a), type(b)
      if type_a == 'number' and type_b == 'number' then
        return a < b
      elseif type_a == 'string' and type_b == 'string' then
        local val_a, val_b = obj[a], obj[b]
        if type(val_a) ~= 'table' and type(val_b) ~= 'table' then
          return val_a < val_b
        end
        return a < b
      end
      return false
    end)
  end
  return obj
end

---@param obj CEnum The enum object to stringify.
---@param indent number The current indentation level.
---@return string str The string representation of the enum object.
local function stringify(obj, indent)
  local str = '{\n'
  local int_keys = ''
  local alpha_keys = ''
  for k, v in pairs(obj) do
    local key = type(k) == 'string' and ('[%q]'):format(k) or ('[%d]'):format(k)
    if type(v) == 'table' then
      local nested_str = stringify(v, indent + 1)
      alpha_keys = alpha_keys..string.rep('\t', indent)..key..' = '..nested_str..',\n'
    else
      int_keys = int_keys..string.rep('\t', indent)..('[%d] = %q,\n'):format(v, k)
      alpha_keys = alpha_keys..string.rep('\t', indent)..('[%q] = %d,\n'):format(k, v)
    end
  end
  str = str..int_keys..alpha_keys
  return str:sub(1, -3)..'\n'..string.rep('\t', indent - 1)..'}'
end

---@param name string The name of the enum file.
---@param tbl table The table to convert to a local enum.
local function to_file(name, tbl)
  if SaveResourceFile(glib._RESOURCE, name..'.lua', '---@enum '..name..'\nreturn '..tostring(tbl), -1) then
    glib.print('^2`enum` file created^7 ^5\''..name..'\'^7\nmove file to ^5\'gr_lib/src/enum/enums\'^7 to intialise globally')
  end
end

---@param name string|{[string|number]: string|number|(string|number)[]} If `string` is the name of the enum. <br> If `table` is the table to convert to a local enum.
---@param tbl {[string|number]: string|number|(string|number)[]}? The table to convert to a global enum. 
---@return CEnum obj The created enum object.
function enum.new(name, tbl) -- If `tbl` is nil, attempts to load the enum `name` from the global enums directory. <br> If `tbl` is nil and `name` is a table, it will create a local enum from the table. <br> If `name` is a string and `tbl` is a table, it will create an enum from the table and save it to the global enums directory.
  local name_type = type(name)
  if name_type ~= 'string' and name_type ~= 'table' then
    error('bad argument #1 to \'enum.new\' (string or table expected, got '..name_type..')', 2)
  end
  if tbl and type(tbl) ~= 'table' then
    error('bad argument #2 to \'enum.new\' (table or nil expected, got '..type(tbl)..')', 2)
  end

  name = name_type == 'string' and name:lower() or name
  if name_type == 'string' then
    local file = get_enum_file('src/enum/enums/'..name)
    if not tbl and not file then error('enum file \''..name..'\' not found', 2) end
    if file then
      return setmetatable(create_lookup_tables(file), _mt)
    end
  end

  tbl = tbl or name --[[@as {[string]: number|string}|(string|number)[]=]]
  local obj = setmetatable(create_lookup_tables(tbl), _mt)
  if name_type == 'string' and context == 'server' then
    to_file(name, obj)
  end

  return obj
end

---@return fun(): string?, number|CEnum?
function _mt:__pairs()
  local i = 0
  local keys = self.__keys
  local lim = #keys
  return function()
    i += 1
    if i > lim then return end
    local key = keys[i]
    return key, self[key]
  end
end

---@return string enum The string representation of the enum object.
function _mt:__tostring() return stringify(self, 1) end

function _mt:__newindex() error('attempt to edit a read-only object', 2) end

---@param var string|number The variable to look up.
---@return string|number|CEnum? pair The pair to `var` in the enum.
-- Retrieves the value or key associated with a given variable in the enum. <br> Supports bidirectional lookups (e.g. `name-to-value` and `value-to-name`).
function enum:lookup(var)
  local result = self[var]
  return result
end

return setmetatable(enum, {
  __name = _mt.__name,
  __newindex = _mt.__newindex,
  __call = function(_, name, tbl)
    return enum.new(name, tbl)
  end
})