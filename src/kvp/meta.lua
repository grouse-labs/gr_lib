---@class kvp
---@field _find fun(handle: integer): string[]
---@field find fun(prefix: string?): string[]
---@field set fun(key: string, value: string|number): true?
---@field get fun(key: string): string|number?
---@field remove fun(key: string)
---@field setnosync fun(key: string, value: string|number): true?
---@field removenosync fun(key: string)
---@field addmethod fun(name: string, handler: function)
---@field flush fun()
---@field findexternal fun(resource: string, prefix: string?): string[]
---@field getexternal fun(resource: string, key: string): string|number?
---@field [string] function
--[[
 # Example; equivalent to qb-inventory's `SaveInventory` export
  kvp.addmethod('saveplayerinventory', function(id, items)

    local json_string = {}

    for slot, item in pairs(items) do
      if item then
        json_string[#json_string + 1] = {
          name = item.name,
          amount = item.amount,
          info = item.info,
          type = item.type,
          slot = slot,
        }
      end
    end

    kvp.set('inventory:'..id, json.encode(json_string))
  end)

  kvp.saveplayerinventory(1, {
    [1] = {name = 'test', amount = 1, info = {}, type = 'item'},
    [2] = {name = 'test2', amount = 1, info = {}, type = 'item'},
    [3] = {name = 'test3', amount = 1, info = {}, type = 'item'},
  })

  print(json.encode(kvp.find('inventory')))

  prints --> [inventory:1]
]]--