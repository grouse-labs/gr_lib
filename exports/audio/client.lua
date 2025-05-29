local audio = {}
local active_sounds = {}

--------------------- FUNCTIONS ---------------------

local function loop_sound(id, args, loops, method)
  CreateThread(function()
    local lim = loops > 0 and loops
    if lim then
      for _ = 1, lim do
        audio.awaitsound(id, function()
          method(id, table.unpack(args))
        end)
      end
    else
      audio.awaitsound(id, function()
        method(id, table.unpack(args))
        loop_sound(id, args, loops, method)
      end)
    end
  end)
end

function audio.getsoundid(create)
  local active_sound = -1
  if not create then
    active_sound = next(active_sounds) and #active_sounds or -1
  else
    for i = 1, 195 do
      if not active_sounds[i] then
        active_sounds[i] = GetSoundId()
        active_sound = i
        CreateThread(function()
          audio.awaitsound(active_sounds[i], function()
            audio.releasesoundid(active_sounds[i])
            active_sounds[i] = nil
          end)
        end)
        break
      end
    end
  end
  return active_sounds[active_sound], active_sound
end

function audio.releasesoundid(id)
  id = id or audio.getsoundid()
  if not id or id < 0 then return end
  ReleaseSoundId(id)
end

function audio.awaitsound(id, cb, sleep)
  sleep = sleep or 0
  repeat
    Wait(sleep)
  until HasSoundFinished(id)
  if cb and type(cb) == 'function' then
    cb()
  end
end

function audio.playsound(create_id, bank, sound_name, ref, networked, in_replay, loops)
  if bank and bank ~= '' and not glib.stream.audio(bank, networked) then error('failed to load audio bank: ' ..bank) end
  local id = create_id and audio.getsoundid(create_id) or -1
  PlaySoundFrontend(id, sound_name, ref or '0', in_replay or false)
  ReleaseNamedScriptAudioBank(bank)
  if loops then
    loop_sound(id, {
      sound_name,
      ref or '',
      in_replay or false
    }, loops, PlaySoundFrontend)
  end
  return id
end

function audio.playsoundfromentity(create_id, bank, sound_name, entity, ref, networked, in_replay, loops)
  if not glib.stream.audio(bank, networked) then error('failed to load audio bank: ' ..bank) end
  local id = create_id and audio.getsoundid(create_id) or -1
  PlaySoundFromEntity(id, sound_name, entity, ref or '0', networked, in_replay or false)
  ReleaseNamedScriptAudioBank(bank)
  if loops then
    loop_sound(id, {
      sound_name,
      entity,
      ref or '',
      networked,
      in_replay or false
    }, loops, PlaySoundFromEntity)
  end
  return id
end

function audio.playsoundatcoords(create_id, bank, sound_name, pos, ref, range, networked, in_replay, loops)
  if not glib.stream.audio(bank, networked) then error('failed to load audio bank: ' ..bank) end
  local id = create_id and audio.getsoundid(create_id) or -1
  PlaySoundFromCoord(id, sound_name, pos.x, pos.y, pos.z, ref or '0', networked, range, in_replay or false)
  ReleaseNamedScriptAudioBank(bank)
  if loops then
    loop_sound(id, {
      sound_name,
      pos.x,
      pos.y,
      pos.z,
      ref or '',
      networked,
      range,
      in_replay or false
    }, loops, PlaySoundFromCoord)
  end
  return id
end

function audio.updatecoords(coords, id)
  id = id or audio.getsoundid()
  if not id or id < 0 then return end
  UpdateSoundCoord(id, coords.x, coords.y, coords.z)
end

function audio.stopsound(id)
  id = id or audio.getsoundid()
  if not id or id < 0 then return end
  StopSound(id)
  audio.awaitsound(id, audio.releasesoundid)
end

function audio.setvariable(variable, value, id)
  id = id or audio.getsoundid()
  if not id or id < 0 then return end
  SetVariableOnSound(id, variable, value)
end

function audio.getactive()
  return active_sounds
end

--------------------- EVENTS ---------------------

AddEventHandler('onResourceStop', function(resource)
  if resource ~= glib._RESOURCE then return end
  for _, id in pairs(active_sounds) do
    audio.releasesoundid(id)
  end
  ReleaseScriptAudioBank()
end)

--------------------- OBJECT ---------------------

glib.audio = function() return audio end
