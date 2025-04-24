---@diagnostic disable: assign-type-mismatch, param-type-mismatch, missing-fields, need-check-nil
local context = glib._CONTEXT

---@type table<enum, string|number|vector>
local reverse_lookup = {}
local enum = {}
local _mt = {
  __name = 'enum',
  __index = enum
}

---@param path string The path to the enum file.
---@return table? enum The loaded enum file or nil if it doesn't exist.
local function get_enum_file(path)
  local success, file = pcall(load, LoadResourceFile(glib._RESOURCE, path..'.lua') or LoadResourceFile('gr_lib', path..'.lua'), '@@'..path..'.lua', 't', _ENV)
  return success and file and file() --[[@as table?]]
end

---@param tbl enum_options The table to convert to a local enum.
---@return enum obj The converted table.
local function create_lookup_tables(tbl)
  local obj = {}
  reverse_lookup[obj] = {}
  for k, v in pairs(tbl) do
    if type(v) == 'table' and table.type(v) ~= 'array' then
      obj[k] = setmetatable(create_lookup_tables(v), _mt)
    else
      obj[k] = v
      reverse_lookup[obj][v] = k
    end
  end
  return obj
end

---@param obj enum The enum object to stringify.
---@param indent number The current indentation level.
---@return string str The string representation of the enum object.
local function stringify(obj, indent)
  local str = '{\n'
  local obj_type = table.type(obj)

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

---@param name string|enum_options If `string` is the name of the enum. <br> If `table` is the table to convert to a local enum.
---@param tbl enum_options? The table to convert to a global enum. 
---@return enum obj The created enum object.
-- If `tbl` is nil, attempts to load the enum `name` from the global enums directory.<br>
-- If `tbl` is nil and `name` is a table, it will create a local enum from the table.<br>
-- If `name` is a string and `tbl` is a table, it will create an enum from the table.
function enum.new(name, tbl)
  local name_type = type(name)
  if name_type ~= 'string' and name_type ~= 'table' then
    error('bad argument #1 to \'enum.new\' (string or table expected, got '..name_type..')', 2)
  end
  if tbl and type(tbl) ~= 'table' then
    error('bad argument #2 to \'enum.new\' (table or nil expected, got '..type(tbl)..')', 2)
  end

  tbl = tbl or name --[[@as enum_options]]
  local obj = setmetatable(create_lookup_tables(tbl), _mt)
  if name_type == 'string' and context == 'server' then
    to_file(name, obj)
  end

  return obj
end

---@return string enum The string representation of the enum object.
function _mt:__tostring() return stringify(self, 1) end

function _mt:__newindex() error('attempt to edit a read-only object', 2) end

---@param key string|vector|number The key to set the value for.<br>The key must exist in the enum.
---@param value string|vector|number The value to set for the key.
function enum:set(key, value)
  if not self[key] then error('key \''..key..'\' does not exist', 2) end
  local reverse = reverse_lookup[self]
  local entry = self[key]

  self[key] = value
  reverse[entry] = nil
  reverse[value] = key

  return self
end

---@param var string|vector|number The variable to look up.
---@return enum|string|vector|number? pair The pair to `var` in the enum.
-- Retrieves the value or key associated with a given variable in the enum.<br>
-- Supports bidirectional lookups (e.g. `name-to-value` and `value-to-name`).<br>
-- If the variable is not found, it returns `nil`.<br>
-- If the variable is found, it returns the value or key associated with the variable.
function enum:lookup(var)
  local result = self[var] or reverse_lookup[self][var]
  return result
end

---@param var string|vector|number The `var` to search for.
---@return string|vector|number? parent_key, enum|string|vector|number? result
-- Searches for a variable in the enum and returns the parent key (if any) and the value associated with the variable.<br>
-- Supports nested enums as well as bidirectional lookups (e.g. `name-to-value` and `value-to-name`).<br>
-- If the variable is not found, it returns `nil` for both the parent key and the result.<br>
-- If the variable is found, it returns the parent key (if any) and the value associated with the variable.
function enum:search(var)
  local result = self[var] or reverse_lookup[self][var]
  if result then return nil, result end
  for k, v in pairs(self) do
    if type(v) == 'table' then
      local _, res = v:search(var)
      if res then return k, res end
    end
  end
end

---@param key string|vector|number The key to add an alias for.<br>The key must exist in the enum and be of the same type as the intialised key type.
---@param alias string|vector|number The alias to add.
---@return enum self The enum object.
function enum:addalias(key, alias)
  if self[alias] then error('alias \''..alias..'\' already exists', 2) end
  if not self[key] then error('key \''..key..'\' does not exist', 2) end
  local entry = self[key]
  local entry_type = type(entry) == 'table' and table.type(entry) or 'value'
  if entry_type ~= 'array' and entry_type ~= 'value' then error('key \''..key..'\' is an enum', 2) end

  entry = entry_type == 'value' and {entry} or entry

  entry[#entry + 1] = alias
  self[key] = entry
  reverse_lookup[self][alias] = key

  return self
end

---@param parent_key string|vector?
---@param key string|number|vector The key to add.
---@param value string|number|vector The value to add to the associated key.
---@return enum self The enum object.
function enum:addkey(parent_key, key, value)
  if self[key] then error('key \''..key..'\' already exists', 2) end
  if parent_key and not self[parent_key] then error('key \''..parent_key..'\' does not exist', 2) end

  local obj = self[parent_key] or self
  local obj_type = type(obj) == 'table' and table.type(obj) or 'value'
  if obj_type == 'array' and obj_type == 'value' then error('key \''..parent_key..'\' is not an enum', 2) end


  rawset(obj, key, value)
  reverse_lookup[obj][value] = key
  return self
end

---@param name string|enum_options} If `string` is the name of the enum. <br> If `table` is the table to convert to a local enum.
---@param tbl enum_options? The table to convert to a global enum.
---@return enum|fun(obj: enum_options): enum obj The created enum object or a function to create a global enum.
-- Allows creating a global enum or a local enum.<br>
-- If `name` is a string and `tbl` is nil, it will attempt to load the enum from the global enums directory.<br>
-- If an enum is not found, it will return a function to create a global enum.<br>
-- eg. `enum 'someEnum' {on = 1, off = 0}` or `enum('someEnum')({on = 1, off = 0})`<br>
-- If `name` is a string and `tbl` is a table, it will create a global enum from the table.<br>
-- If `name` is a table and `tbl` is nil, it will create a local enum from the table.<br>
return function(name, tbl)
  local name_type = type(name)
  if not tbl and name_type == 'string' then
    local file = get_enum_file('enums/'..name) or get_enum_file('src/enum/enums/'..name)
    if file then
      return setmetatable(create_lookup_tables(file), _mt)
    else
      return function(obj) return enum.new(name, obj) end
    end
  end
  return enum.new(name, tbl)
end