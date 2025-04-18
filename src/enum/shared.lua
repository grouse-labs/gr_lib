---@diagnostic disable: assign-type-mismatch, param-type-mismatch, missing-fields, need-check-nil
local context = glib._CONTEXT

---@class CEnum
---@field new fun(name: string|table, tbl: table?): CEnum
---@field set fun(self: CEnum, key: string|vector|number, value: string|vector|number): self: CEnum
---@field lookup fun(self: CEnum, var: string|vector|number): pair: string|vector|number|CEnum?
---@field search fun(self: CEnum, var: string|vector|number): parent_key: string|vector|number?, result: CEnum|string|vector|number?
---@field addalias fun(self: CEnum, key: string|vector|number, alias: string|vector|number): CEnum
---@field [string|vector] CEnum?
---@field [string|vector|number] string|vector|number
local enum = {}
local _mt = {
  __name = 'enum',
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

---@param tbl {[string|vector|number]: string|vector|number|(string|vector|number)[]} The table to convert to a local enum.
---@return CEnum obj The converted table.
local function create_lookup_tables(tbl)
  local obj = {}
  obj.__type = is_array(tbl) and 'array' or 'table'
  obj.__keys = {}
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
    if type_a == 'table' or type_b == 'table'  then return false end
    if type_a == type_b then
      if type_a == 'number' then
        return a < b
      elseif type_a == 'string' and type(obj[a]) == 'number' then
        return obj[a] < obj[b]
      elseif type_a:find('vec') then
        return #a < #b
      end
      return a < b
    end
    return false
  end)
  return obj
end

---@param obj CEnum The enum object to stringify.
---@param indent number The current indentation level.
---@return string str The string representation of the enum object.
local function stringify(obj, indent)
  local str = '{\n'
  ---@diagnostic disable-next-line: invisible
  local obj_type = obj.__type

  for k, v in pairs(obj) do
    local key_type = type(k)
    local key = key_type == 'string' and ('%s'):format(k) or ('[%s]'):format(tostring(k))
    if type(v) == 'table' then
      local nested_str = stringify(v, indent + 1)
      if obj_type == 'array' then
        str = str..string.rep('\t', indent)..key..' = '..nested_str..',\n'
      else
        str = str..string.rep('\t', indent)..key..' = '..nested_str..',\n'
      end
    else
      if obj_type == 'array' then
        str = str..string.rep('\t', indent)..key..' = '..(type(v) == 'string' and ('%q'):format(v) or tostring(v))..',\n'
      else
        str = str..string.rep('\t', indent)..key..' = '..(type(v) == 'string' and ('%q'):format(v) or tostring(v))..',\n'
      end
    end
  end

  return str:sub(1, -3)..'\n'..string.rep('\t', indent - 1)..'}'
end

---@param name string The name of the enum file.
---@param tbl table The table to convert to a local enum.
local function to_file(name, tbl)
  if SaveResourceFile(glib._RESOURCE, name..'.lua', 'return '..tostring(tbl), -1) then
    glib.print('^2`enum` file created^7 ^5\''..name..'\'^7\nmove file to ^5\'gr_lib/src/enum/enums\'^7 to intialise globally')
  end
end

---@param name string|{[string|vector|number]: string|vector|number|(string|vector|number)[]} If `string` is the name of the enum. <br> If `table` is the table to convert to a local enum.
---@param tbl {[string|vector|number]: string|vector|number|(string|vector|number)[]}? The table to convert to a global enum. 
---@return CEnum obj The created enum object.
-- If `tbl` is nil, attempts to load the enum `name` from the global enums directory.<br>
-- If `tbl` is nil and `name` is a table, it will create a local enum from the table.<br>
-- If `name` is a string and `tbl` is a table, it will create an enum from the table and save it to the global enums directory.
function enum.new(name, tbl)
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

  tbl = tbl or name --[[@as {[string|vector|number]: string|vector|number|(string|vector|number)[]}=]]
  local obj = setmetatable(create_lookup_tables(tbl), _mt)
  if name_type == 'string' and context == 'server' then
    to_file(name, obj)
  end

  return obj
end

---@return fun(): string|vector|number?, string|vector|number|CEnum?
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

---@param key string|vector|number The key to set the value for.
---@param value string|vector|number The value to set for the key.
function enum:set(key, value)
  if not self[key] then error('key \''..key..'\' does not exist', 2) end
  if type(value) ~= 'string' and type(value) ~= 'number' then error('value must be a string or number', 2) end
  local old_value = self[key]
  if type(old_value) == 'table' and not is_array(old_value) then error('key \''..key..'\' is a table', 2) end

  self[key] = value

  local keys = self.__keys
  table.remove(keys, old_value)
  for i = 1, #keys do
    if keys[i] <= value then
      keys[#keys + 1] = value
      break
    end
  end

  local reverse_key = self[old_value]
  if is_array(reverse_key) then
    for i = 1, #reverse_key do
      if reverse_key[i] == key then
        table.remove(reverse_key, i)
        break
      end
    end
  else
    self[old_value] = nil
  end

  rawset(self, value, key)

  return self
end

---@param var string|vector|number The variable to look up.
---@return CEnum|string|vector|number? pair The pair to `var` in the enum.
-- Retrieves the value or key associated with a given variable in the enum.<br>
-- Supports bidirectional lookups (e.g. `name-to-value` and `value-to-name`).<br>
-- If the variable is not found, it returns `nil`.<br>
-- If the variable is found, it returns the value or key associated with the variable.
function enum:lookup(var)
  local result = self[var]
  return result
end

---@param var string|vector|number The `var` to search for.
---@return string|vector|number? parent_key, CEnum|string|vector|number? result
-- Searches for a variable in the enum and returns the parent key (if any) and the value associated with the variable.<br>
-- Supports nested enums as well as bidirectional lookups (e.g. `name-to-value` and `value-to-name`).<br>
-- If the variable is not found, it returns `nil` for both the parent key and the result.<br>
-- If the variable is found, it returns the parent key (if any) and the value associated with the variable.
function enum:search(var)
  local result = self[var]
  if result then return nil, result end
  for k, v in pairs(self) do
    if type(v) == 'table' then
      local _, res = v:search(var)
      if res then return k, res end
    end
  end
end

---@param key string|vector|number The key to add an alias for.
---@param alias string|vector|number The alias to add.
---@return CEnum self The enum object.
function enum:addalias(key, alias)
  if self[alias] then error('alias \''..alias..'\' already exists', 2) end
  if not self[key] then error('key \''..key..'\' does not exist', 2) end
  local val = self[key]
  if type(val) == 'table' and not is_array(val) then error('key \''..key..'\' is a table', 2) end
  local _type = self.__type

  rawset(self, alias, val)

  if _type ~= 'array' then
    for i = 1, #self.__keys do
      if self.__keys[i] == key or self.__keys[i] == val then
        table.insert(self.__keys, i + 1, alias)
        break
      end
    end
  end

  local reverse_key = self[val]
  if is_array(reverse_key) then
    reverse_key[#reverse_key + 1] = alias
  else
    self[val] = {reverse_key, alias}
  end

  return self
end

---@param name string|{[string|vector|number]: string|vector|number|(string|vector|number)[]} If `string` is the name of the enum. <br> If `table` is the table to convert to a local enum.
---@param tbl {[string|vector|number]: string|vector|number|(string|vector|number)[]}? The table to convert to a global enum.
---@return CEnum|fun(obj: {[string|vector|number]: string|vector|number|(string|vector|number)[]}): CEnum obj The created enum object or a function to create a global enum.
-- Allows creating a global enum or a local enum.<br>
-- If `name` is a string and `tbl` is nil, it will attempt to load the enum from the global enums directory.<br>
-- If an enum is not found, it will return a function to create a global enum.<br>
-- eg. `enum 'someEnum' {on = 1, off = 0}` or `enum('someEnum')({on = 1, off = 0})`<br>
-- If `name` is a string and `tbl` is a table, it will create a global enum from the table.<br>
-- If `name` is a table and `tbl` is nil, it will create a local enum from the table.<br>
return function(name, tbl)
  local name_type = type(name)
  if not tbl and name_type == 'string' then
    local file = get_enum_file('src/enum/enums/'..name)
    if file then
      return setmetatable(create_lookup_tables(file), _mt)
    else
      return function(obj) return enum.new(name, obj) end
    end
  end
  return enum.new(name, tbl)
end