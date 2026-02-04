# glib

A library of portable FiveM lua modules.

## Features

- **require** | (Now) a toned-back recreation of the Lua `package` library in pure lua, allowing you to import and use modules in your scripts.
- **audio** | Allows full manipulation of FiveM native audio, with variables, looping and cancelling.
- **callback** | It's just [ox_lib's callback system](https://github.com/overextended/ox_lib/tree/master/imports/callback) incase for some reason you're not using that resource...
- **enum** | Creates C-style enums which can be either global or local and have O(1) index time.
- **kvp** | Exposes FiveM KVP functions, with accessible parameters, allowing more robust database usage.
- **locale** | A localisation and translation module, based on the [i18n.lua library by kikito](https://github.com/kikito/i18n.lua/tree/master).
- **scaleform** | Complete scaleform manager, exposing Frontend, HUD, Header, Fullscreen and RenderTarget scaleforms.
- **netscene** | Complete netscne manager, allowing for quick and easy setup of netscenes.
- **stream** | Streaming asset loader, exposing most needed streaming functions with baked-in timeouts.
  
## Table of Contents

- [glib](#glib)
  - [Features](#features)
  - [Table of Contents](#table-of-contents)
    - [Credits](#credits)
    - [Installation](#installation)
    - [Configuration](#configuration)
      - [Annotations](#annotations)
        - [Usage (VS Code)](#usage-vs-code)
      - [Server CFG](#server-cfg)
    - [Documentation](#documentation)
      - [require](#require)
      - [audio](#audio)
      - [callback](#callback)
      - [enum](#enum)
      - [kvp](#kvp)
      - [locale](#locale)
      - [scaleform](#scaleform)
      - [netscene](#netscene)
      - [stream](#stream)

### Credits

- [overextended](https://github.com/overextended/ox_lib/)
- [0xWaleed](https://github.com/citizenfx/fivem/pull/736)
- [DurtyFrees' Data Dumps](https://github.com/DurtyFree/gta-v-data-dumps)
- [kikito](https://github.com/kikito/i18n.lua/tree/master)

### Installation

- Always use the reccomended FiveM artifacts, last tested on [23683](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/).
- Download the latest version from [releases](https://github.com/grouse-labs/gr_lib/releases/latest).
- Extract the contents of the zip file into your resources folder, into a folder which starts after your framework or;
- Ensure the script in your `server.cfg` after your framework and before any script this is a dependency for.
- Change `sets locale "en-AU"` to `setr locale "en-AU"` in your `server.cfg` and make sure it's updated to your [language code](https://gist.github.com/Josantonius/b455e315bc7f790d14b136d61d9ae469).

### Configuration

#### Annotations

Function completion is available for all functions, enums and classes. This means you can see what parameters a function takes, what an enum value is, or what a class field is. This is done through [Lua Language Server](https://github.com/LuaLS/lua-language-server).

##### Usage (VS Code)

- Install [cfxlua-vscode](https://marketplace.visualstudio.com/items?itemName=overextended.cfxlua-vscode).
- Open your settings (Ctrl + ,) and add the following:
  - Search for `Lua.workspace.library`, and create a new entry pointing to the root of the resource, for example:

```json
"Lua.workspace.library": ["F:/resources/[gr]/gr_lib/"],
```

#### Server CFG

The following is how to activate debug mode.

```cfg
##############
### GR LIB ###
##############

setr glib:debug true # Set to true to enable debug mode for glib, which will log all events and prints to the console.
```

### Documentation

#### require

```lua
---@param mod_name string The name of the module to require.
---@return unknown
function require(mod_name)
```

`mod_name` needs to be a dot seperated path from resource to module.

#### audio

```lua
---@param create boolean?
---@return integer id, integer index
function audio.getsoundid(create)

---@param id integer
function audio.releasesoundid(id)

---@param id integer
---@param cb function?
---@param sleep integer?
---@return unknown?
function audio.awaitsound(id, cb, sleep)

---@param create_id boolean?
---@param bank string
---@param sound_name string
---@param ref string
---@param networked boolean
---@param in_replay true
---@param loops integer
---@return integer id
function audio.playsound(create_id, bank, sound_name, ref, networked, in_replay, loops)

---@param create_id boolean?
---@param bank string
---@param sound_name string
---@param entity integer
---@param ref string
---@param networked boolean
---@param in_replay true
---@param loops integer
---@return integer id
function audio.playsoundfromentity(create_id, bank, sound_name, entity, ref, networked, in_replay, loops)

---@param create_id boolean?
---@param bank string
---@param sound_name string
---@param pos vector3|{x: number, y: number, z: number}
---@param ref string
---@param range number
---@param networked boolean
---@param in_replay true
---@param loops integer
---@return integer id
function audio.playsoundatcoords(create_id, bank, sound_name, pos, ref, range, networked, in_replay, loops)

---@param coords vector3|{x: number, y: number, z: number}
---@param id integer?
function audio.updatecoords(coords, id)

---@param id integer?
function audio.stopsound(id)

---@param variable string
---@param value number
---@param id integer
function audio.setvariable(variable, value, id)

---@return integer[]
function audio.getactive()
```

- `networked: boolean` plays the sound across the network.
- `in_replay: boolean` sounds are recorded in Rockstar editor replays.
- `loops: integer` -1 plays a sound until stopped, otherwise loops sounds `loops` times.

#### callback

```lua
---@param name string
---@param cb fun(...): ...
function callback.register(name, cb)

--------------------- SERVER ---------------------

---@param player integer|string
---@param name string
---@param cb fun(...): ...
---@param ... any
function callback.trigger(player, name, cb, ...)

---@param player integer|string
---@param name string
---@param ... any
---@return ...
function callback.await(player, name, ...)

--------------------- CLIENT ---------------------

---@param name string
---@param delay integer|false?
---@param cb fun(...): ...
---@param ... any
function callback.trigger(name, delay, cb, ...)

---@param name string
---@param delay integer|false?
---@param ... any
---@return ...
function callback.await(name, delay, ...)
```

#### enum

```lua
---@class enum_options
---@field [string|vector|number] string|vector|number|enum_options|[]
```

```lua
---@param name string|enum_options
---@param tbl enum_options?
---@return enum
-- If `tbl` is nil, attempts to load the enum `name` from the global enums directory.
-- If `tbl` is nil and `name` is a table, it will create a local enum from the table.
-- If `name` is a string and `tbl` is a table, it will create an enum from the table.
function enum.new(name, tbl)
```

- `name: string|enum_options`
  - If `string` is the name of the enum.
  - If `table` is the table to convert to a local enum.
- `tbl: enum_options?` The table to convert to a global enum.
- `returns: enum` The created enum object.

```lua
---@param key string|vector|number
---@param value string|vector|number
function enum:set(key, value)

---@param var string|vector|number
---@return enum|string|vector|number? pair
-- Retrieves the value or key associated with a given variable in the enum.
-- Supports bidirectional lookups (e.g. `name-to-value` and `value-to-name`).
-- If the variable is not found, it returns `nil`.
-- If the variable is found, it returns the value or key associated with the variable.
function enum:lookup(var)

---@param var string|vector|number
---@return string|vector|number? parent_key, enum|string|vector|number? result
-- Searches for a variable in the enum and returns the parent key (if any) and the value associated with the variable.
-- Supports nested enums as well as bidirectional lookups (e.g. `name-to-value` and `value-to-name`).
-- If the variable is not found, it returns `nil` for both the parent key and the result.
-- If the variable is found, it returns the parent key (if any) and the value associated with the variable.
function enum:search(var)

---@param key string|vector|number
---@param alias string|vector|number
---@return enum
function enum:addalias(key, alias)

---@param parent_key string|vector?
---@param key string|number|vector
---@param value string|number|vector
---@return enum
function enum:addkey(parent_key, key, value)
```

#### kvp

```lua
---@param handle integer
---@return string[] keys
function kvp._find(handle)

---@param prefix string?
---@return string[] keys
function kvp.find(prefix)

---@param key string
---@param value string|number
---@return true? success
function kvp.set(key, value)

---@param key string
---@return string|number? value
function kvp.get(key)

---@param key string
function kvp.remove(key)

--------------------- SERVER ---------------------

---@param key string
---@param value string|number
---@return true? success
function kvp.setnosync(key, value)

---@param key string
function kvp.removenosync(key)

---@param name string
---@param handler function
function kvp.addmethod(name, handler)

function kvp.flush()

--------------------- CLIENT ---------------------

---@param resource string
---@param prefix string?
---@return string[] keys
function kvp.findexternal(resource, prefix)

---@param resource string
---@param key string
---@return string|number? value
function kvp.getexternal(resource, key)
```

#### locale

```lua
---@param context string? The context to load into.
---@param data table The data to load.
function locale.load(context, data)

---@param key string A dot-separated key.
---@param value string A phrase to set.
function locale.set(key, value)

---@param resource string? The resource name.
---@param file string? The name of the file to load. <br> This has to be a dot-notated path to the file. <br> The default is `locales.<dialect>`.
function locale.loadfile(resource, file)

---@param key string The key to translate.
---@param data table? The data to interpolate.
---@return string string The translated phrase.
function locale.translate(key, data)

---@param key string
---@return boolean
function locale.iskeyvalid(key)
```

#### scaleform

```lua
---@class scaleform_options
---@field name string? The name of the scaleform.
---@field screen {full: boolean?, frontend: boolean?, header: boolean?, hud: integer?, x: number?, y: number?}
---@field scale {width: number?, height: number?}?
---@field colour {r: integer?, g: integer?, b: integer?, a: integer?}?
---@field render {name: string, model: string|integer, large: boolean?, super_large: boolean?}?
```

```lua
---@param options scaleform_options
---@return scaleform
function scaleform.new(options)

---@param method string
---@param args any|table
---@param ret_val string?
---@return any?
function scaleform:call(method, args, ret_val)

---@param fullscreen boolean
---@return scaleform
function scaleform:setfullscreen(fullscreen)

---@param x number?
---@param y number?
---@param width number?
---@param height number?
---@return scaleform
function scaleform:setproperties(x, y, width, height)

---@param r integer?
---@param g integer?
---@param b integer?
---@param a integer?
---@return scaleform
function scaleform:setcolour(r, g, b, a)

---@param name string
---@param model string|integer
---@param large boolean?
---@param super_large boolean?
---@return scaleform
function scaleform:setrender(name, model, large, super_large)

---@return boolean is_drawing
function scaleform:isdrawing()

---@param await boolean?
---@param mask scaleform
---@return scaleform|false?
function scaleform:draw(await, mask)

---@return scaleform
function scaleform:stopdrawing()

function scaleform:destroy()
```

#### netscene

```lua
---@class scene_options
---@field scene {coords: vector3, rotation: vector3, order: integer?, hold: boolean?, looped: boolean?, stop_phase: number?, start_phase: number?, speed: number?}
---@field peds {dict: string, anim: string, entity: integer?, model: integer|string?, blend_in: number?, blend_out: number?, scene_flags: integer?, ragdoll_flags: integer?, move_delta: number?, ik_flags: integer?}[]?
---@field objs {dict: string, anim: string, entity: integer?, model: integer|string?, door: boolean?, blend_in: number?, blend_out: number?, scene_flags: integer?}?
```

```lua
---@param scene_options scene_options
---@return netscene
function netscene.new(scene_options)

function netscene:stop()

---@param cb fun(phase: number, ...: unknown): boolean
---@param ... unknown Arguments to parse to the callback function.
function netscene:start(cb, ...)

---@param peds boolean?
---@param objs boolean?
function netscene:clear(peds, objs)

---@return number
function netscene:getphase()
```

#### stream

```lua
---@param dictionary string
---@return boolean
function stream.animdict(dictionary)

---@param model string|number
---@return boolean
function stream.model(model)

---@param asset string
---@return boolean
function stream.ptfx(asset)

---@param dictionary string
---@return boolean
function stream.textdict(dictionary)

---@param ped integer
---@param transparent boolean?
---@return integer|false headshot_handle
function stream.headshot(ped, transparent)

---@param movie string
---@return integer|false scaleform_handle
function stream.scaleform(movie)

---@param component integer
---@return boolean
function stream.scaleformhud(component)

---@param bank string
---@param networked boolean?
---@return boolean
function stream.audio(bank, networked)
```
