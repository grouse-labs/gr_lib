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
  local ret_val = retvals and load(asset)
  if not isloaded(retvals and ret_val or asset) then
    local start = GetGameTimer()
    if not ret_val then load(asset) end
    repeat Wait(0) until isloaded(retvals and ret_val or asset) or timer(start, 5000)
    if not isloaded(asset) then error('failed to load asset: ' .. asset) end
  end
  return ret_val or true
end

function stream.animdict(dictionary)
  if type(dictionary) ~= 'string' then error('bad argument #1 to `stream.animdict` (string expected, got ' .. type(dictionary) .. ')') end
  return load_asset(dictionary, HasAnimDictLoaded, RequestAnimDict)
end

function stream.model(model)
  if type(model) ~= 'string' and not is_int(model) then error('bad argument #1 to `stream.model` (string or number expected, got ' .. type(model) .. ')') end
  model = is_int(model) and model or joaat(model) & 0xFFFFFFFF
  if not IsModelInCdimage(model) and not IsModelValid(model) then error('bad arguement #1 to `stream.model` (invalid model: ' .. model .. ')') end
  return load_asset(model, HasModelLoaded, RequestModel)
end

function stream.ptfx(asset)
  if type(asset) ~= 'string' then error('bad argument #1 to `stream.ptfx` (string expected, got ' .. type(asset) .. ')') end
  return load_asset(asset, HasNamedPtfxAssetLoaded, RequestNamedPtfxAsset)
end

function stream.textdict(dictionary)
  if type(dictionary) ~= 'string' then error('bad argument #1 to `stream.textdict` (string expected, got ' .. type(dictionary) .. ')') end
  return load_asset(dictionary, HasStreamedTextureDictLoaded, RequestStreamedTextureDict)
end

function stream.headshot(ped)
  if not is_int(ped) then error('bad argument #1 to `stream.headshot` (integer expected, got ' .. type(ped) .. ')') end
  return load_asset(ped, function(handle)
    ---@cast handle -string
    return IsPedheadshotReady(handle) and IsPedheadshotValid(handle)
  end, RegisterPedheadshot, true)
end

function stream.scaleformhud(component)
  if type(component) ~= 'number' then error('bad argument #1 to `stream.scaleformhud` (number expected, got ' .. type(component) .. ')') end
  return load_asset(component, HasScaleformScriptHudMovieLoaded, RequestScaleformScriptHudMovie)
end

function stream.audio(bank, networked)
  if type(bank) ~= 'string' then error('bad argument #1 to `stream.audio` (string expected, got ' .. type(bank) .. ')') end
  if networked and type(networked) ~= 'boolean' then error('bad arguement #2 to `stream.audio` (boolean expected, got ' .. type(networked) .. ')') end
  return load_asset(bank, RequestScriptAudioBank, function()
    if not HintScriptAudioBank(bank, networked) then return end
    ---@diagnostic disable-next-line: redundant-parameter
    return RequestScriptAudioBank(bank, networked, (1 << (0-128)))
  end)
end

--------------------- OBJECT ---------------------

return setmetatable(stream, {
  __name = 'stream',
  __newindex = function() error('attempt to edit a read-only object', 2) end
})