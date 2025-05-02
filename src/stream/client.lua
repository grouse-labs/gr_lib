local stream = {}

--------------------- FUNCTIONS ---------------------

local function is_int(x) return type(x) == 'number' and x % 1 == 0 end

local function timer(time, limit) return GetGameTimer() - time >= limit end

---@param asset string|number The asset to load.
---@param isloaded fun(asset: string|number): boolean The function to check if the asset is loaded.
---@param load fun(asset: string|number) The function to load the asset.
---@param retvals boolean? ret_val The return value of the load function.
---@return boolean loaded Whether the asset was loaded.
local function load_asset(asset, isloaded, load, retvals)
  local ret_val = retvals and load(asset) or nil
  if not isloaded(ret_val or asset) then
    local start = GetGameTimer()
    repeat Wait(0) until isloaded(ret_val or asset) or timer(start, 5000)
    if not isloaded(asset) then error('failed to load asset: ' .. asset) end
  end
  return ret_val or true
end

function stream.animdict(dictionary)
  if type(dictionary) ~= 'string' then error('bad arguement #1 to `stream.animdict` (string expected, got ' .. type(dictionary) .. ')') end
  return load_asset(dictionary, HasAnimDictLoaded, RequestAnimDict)
end

function stream.model(model)
  if type(model) ~= 'string' and not is_int(model) then error('bad arguement #1 to `stream.model` (string or number expected, got ' .. type(model) .. ')') end
  model = is_int(model) and model or joaat(model) & 0xFFFFFFFF
  if not IsModelInCdimage(model) and not IsModelValid(model) then error('bad arguement #1 to `stream.model` (invalid model: ' .. model .. ')') end
  return load_asset(model, HasModelLoaded, RequestModel)
end

function stream.ptfx(asset)
  if type(asset) ~= 'string' then error('bad arguement #1 to `stream.ptfx` (string expected, got ' .. type(asset) .. ')') end
  return load_asset(asset, HasNamedPtfxAssetLoaded, RequestNamedPtfxAsset)
end

function stream.textdict(dictionary)
  if type(dictionary) ~= 'string' then error('bad arguement #1 to `stream.textdict` (string expected, got ' .. type(dictionary) .. ')') end
  return load_asset(dictionary, HasStreamedTextureDictLoaded, RequestStreamedTextureDict)
end

function stream.headshot(ped)
  if not is_int(ped) then error('bad arguement #1 to `stream.headshot` (integer expected, got ' .. type(ped) .. ')') end
  return load_asset(ped, function(handle)
    ---@cast handle -string
    return IsPedheadshotReady(handle) and IsPedheadshotValid(handle)
  end, RegisterPedheadshot, true)
end

function stream.scaleform(scaleform)
  if type(scaleform) ~= 'string' then error('bad arguement #1 to `stream.scaleform` (string expected, got ' .. type(scaleform) .. ')') end
  return load_asset(scaleform, HasScaleformMovieLoaded, RequestScaleformMovie, true)
end

--------------------- OBJECT ---------------------

return setmetatable(stream, {
  __name = 'stream',
  __newindex = function() error('attempt to edit a read-only object', 2) end
})