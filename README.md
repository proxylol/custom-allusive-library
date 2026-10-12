# custom allusive library

this is my edit of [Allusive UI](https://github.com/MarchHubOnTopFr/Allusive-UI). i really liked how allusive looks (the dark theme, the blue accent, the blurry glass background) but the big cards wasted way too much space, so i rewrote the layout. everything is now rows inside sections, every row has a title and a description, and i added some stuff i was missing like stat counters, a log box, keybinds and proper minimize/close buttons.

if you've used rayfield before it should feel pretty familiar.

## loading it

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/proxylol/custom-allusive-library/refs/heads/main/source.lua"))()
```

## basic example

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/proxylol/custom-allusive-library/refs/heads/main/source.lua"))()

local window = Library.new({
    title = "My Hub",
    subtitle = "Some Game",
})

local main = window:create_tab("Main")
local movement = main:create_section("Movement")

movement:create_toggle({
    title = "Infinite Jump",
    description = "Jump again while you're in the air.",
    callback = function(enabled)
        print("Infinite Jump:", enabled)
    end,
})

movement:create_slider({
    title = "Walk Speed",
    description = "How fast you walk.",
    min = 16,
    max = 100,
    value = 16,
    callback = function(speed)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
    end,
})

window:load()
```

always call `window:load()` at the very end, after you've made all your tabs. that's what actually opens the window and turns the blur on.

## how it's laid out

```
window
└── tab          (on the left sidebar)
    └── section  (a little heading with rows under it)
        └── rows (toggles, sliders, buttons, etc)
```

## the window

### `Library.new(options)`

makes the window. if you run your script again it deletes the old window first, so you don't end up with 5 menus stacked on top of each other.

| option | type | default | what it does |
| --- | --- | --- | --- |
| `title` | string | `"Allusive"` | name in the top bar |
| `subtitle` | string | nothing | smaller text under the title |
| `toggleKey` | `Enum.KeyCode` | `LeftAlt` | key that opens/closes the menu |

### window functions

| function | what it does |
| --- | --- |
| `window:create_tab(name, icon?)` | adds a tab. icon is optional, it's an image id like `"rbxassetid://123"`. the first tab gets selected by itself |
| `window:load()` | opens the window. call it once at the end |
| `window:notify(options)` | shows a notification, see [notifications](#notifications) |
| `window:set_state(state)` | `"open"`, `"minimized"` or `"closed"` |
| `window:set_toggle_key(keyCode)` | changes the open/close key |
| `window:destroy()` | gets rid of the whole thing (window, blur, connections) |

### stuff the window does by itself

- the **–** button minimizes it into a small pill with just the title. press it again to open it back up
- the **×** button closes it fully, and you get a notification telling you which key opens it again
- the toggle key (left alt by default) opens/closes it
- you can drag it from the top bar or any empty spot on the sidebar
- if it would open off screen (like you dragged the pill to the top), it moves itself back so the whole thing is visible
- the blur only shows when the window is fully open, so your screen isn't blurry while it's closed
- on mobile it scales down to fit

## sections

### `tab:create_section(name)`

adds a section to a tab. all the elements below get made on a section.

```lua
local settings = tab:create_section("Settings")
```

## elements

every row has a `title` and an optional `description`. if the description is long it just wraps and the row gets taller.

callbacks run in their own thread, so you can use `task.wait` or `WaitForChild` in them without freezing the ui, and if your callback errors it won't break the menu.

### toggle

```lua
local toggle = section:create_toggle({
    title = "Auto Farm",
    description = "Farms for you while you're afk.",
    default = false,
    callback = function(enabled) end,
})
```

| option | type | default | what it does |
| --- | --- | --- | --- |
| `title` | string | | the title |
| `description` | string | nothing | text under the title |
| `default` | boolean | `false` | start turned on. if it's `true` the callback runs once when it's made |
| `callback` | function | nothing | gets `true` or `false` every time it's flipped |

you get back `toggle.value` (current state) and `toggle:set(value, silent?)`. pass `true` as `silent` if you want to change it without running the callback.

you can click anywhere on the row, not just the switch.

### slider

```lua
local slider = section:create_slider({
    title = "Field of View",
    description = "Camera FOV.",
    min = 70,
    max = 120,
    step = 1,
    value = 90,
    suffix = "°",
    callback = function(value) end,
})
```

| option | type | default | what it does |
| --- | --- | --- | --- |
| `title` | string | | the title |
| `description` | string | nothing | text under the title |
| `min` | number | `0` | lowest value |
| `max` | number | `100` | highest value |
| `step` | number | `1` | snaps to this. if it's under 1 (like `0.1`) it shows a decimal |
| `value` | number | `min` | starting value (doesn't run the callback) |
| `suffix` | string | `""` | text after the number, like `" studs/s"` |
| `callback` | function | nothing | gets the new value, only when it actually changes |

you get back `slider.value` and `slider:set(value, silent?)`.

### button

```lua
section:create_button({
    title = "Rejoin",
    description = "Rejoins the server.",
    buttonText = "Go",
    callback = function() end,
})
```

| option | type | default | what it does |
| --- | --- | --- | --- |
| `title` | string | | the title |
| `description` | string | nothing | text under the title |
| `buttonText` | string | `"Run"` | text in the little pill on the right |
| `callback` | function | nothing | runs when you click the row |

### keybind

```lua
local keybind = section:create_keybind({
    title = "Menu Key",
    description = "Click it, then press a key. Esc cancels.",
    default = Enum.KeyCode.LeftAlt,
    callback = function(keyCode)
        window:set_toggle_key(keyCode)
    end,
})
```

| option | type | default | what it does |
| --- | --- | --- | --- |
| `title` | string | | the title |
| `description` | string | nothing | text under the title |
| `default` | `Enum.KeyCode` | nothing | starting key |
| `callback` | function | nothing | gets the new `Enum.KeyCode` after you pick one |

click the row, it shows `...`, press any keyboard key and that's the new bind. esc cancels. while it's waiting for a key the menu's toggle key is ignored, so you won't close the menu by accident while setting it.

the keybind only stores the key, it doesn't do anything by itself. you decide what it does in the callback. if you want a "change menu key" option, just pass the key to `window:set_toggle_key` like in the example.

you get back `keybind.value` and `keybind:set(keyCode, silent?)`.

### stats

a row of number boxes. when you change one the number counts up to the new value, and it flashes blue for a sec if it went up. good for money counters and stuff.

```lua
local stats = section:create_stats({
    { key = "coins", title = "Coins", value = 0, suffix = " c" },
    { key = "kills", title = "Kills", value = 0 },
    { key = "earned", title = "Earned", value = 0, prefix = "+" },
})

stats.coins:set(1500)
stats.kills:set(3)
```

each one can have:

| field | type | what it does |
| --- | --- | --- |
| `key` | string | what you use to get it from the table (`stats.coins`). if you skip it, use the position instead (`stats[1]`) |
| `title` | string | small label above the number |
| `value` | number | starting value |
| `prefix` | string | text before the number |
| `suffix` | string | text after the number |

each stat has `stat.value` and `stat:set(number)`. numbers get rounded and get commas (`12,400`). 2 to 4 stats per row looks best.

### log

a small console box with timestamps. newest line is at the bottom.

```lua
local log = section:create_log({
    title = "Log",
    height = 100,
    lines = 7,
})

log:add("Started farming")
log:clear()
```

| option | type | default | what it does |
| --- | --- | --- | --- |
| `title` | string | nothing | label above the box |
| `height` | number | `100` | how tall the box is in pixels |
| `lines` | number | `7` | how many lines it keeps, older ones get removed |

`log:add(message)` adds a line with the time in front, `log:clear()` empties it.

a line is about 13px tall, so a 100px box fits around 7 lines. if you make it taller, bump `lines` up too.

### paragraph

just text with a title, for instructions or credits or whatever.

```lua
local info = section:create_paragraph({
    title = "Status",
    text = "Waiting for the round to start.",
})

info:set("Round started!")
info:set_title("Live")
```

`paragraph:set(text)` changes the text, `paragraph:set_title(text)` changes the title.

## notifications

```lua
window:notify({
    title = "Saved",
    text = "Your settings were saved.",
    duration = 4,
})
```

`Library.notify({...})` works too if you don't have a window.

| option | type | default | what it does |
| --- | --- | --- | --- |
| `title` | string | `"Notification"` | the top line |
| `text` | string | nothing | the message, wraps if it's long |
| `duration` | number | `4` | seconds before it slides away |

they stack up in the bottom right corner.

## full example

this uses pretty much everything:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/proxylol/custom-allusive-library/refs/heads/main/source.lua"))()

local window = Library.new({ title = "My Hub", subtitle = "Example Game" })

local playerTab = window:create_tab("Player")
local farmTab = window:create_tab("Farm")
local settingsTab = window:create_tab("Settings")

local movement = playerTab:create_section("Movement")

movement:create_toggle({
    title = "Noclip",
    description = "Walk through walls.",
    callback = function(enabled) end,
})

movement:create_slider({
    title = "Walk Speed",
    min = 16,
    max = 100,
    value = 16,
    callback = function(speed)
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = speed
        end
    end,
})

local farm = farmTab:create_section("Auto Farm")

local stats = farm:create_stats({
    { key = "coins", title = "Coins earned", value = 0 },
    { key = "runs", title = "Runs", value = 0 },
})

local log = farm:create_log({ title = "Log", height = 100, lines = 7 })

local coins, runs = 0, 0

farm:create_button({
    title = "Fake a run",
    description = "Adds some coins so you can see the counters move.",
    buttonText = "Go",
    callback = function()
        coins += math.random(10, 50)
        runs += 1
        stats.coins:set(coins)
        stats.runs:set(runs)
        log:add("Run " .. runs .. " finished")
        window:notify({ title = "Run finished", text = "Total coins: " .. coins })
    end,
})

local interface = settingsTab:create_section("Interface")

interface:create_keybind({
    title = "Menu Key",
    description = "Opens and closes the menu.",
    default = Enum.KeyCode.LeftAlt,
    callback = function(key)
        window:set_toggle_key(key)
    end,
})

window:load()
```

## changing the colors

the colors are in the `Theme` table at the top of `source.lua`:

```lua
local Theme = {
    Background = Color3.fromRGB(12, 13, 15),   -- window
    Panel = Color3.fromRGB(22, 28, 38),        -- rows, selected tab
    Element = Color3.fromRGB(32, 38, 51),      -- stat boxes, button hover
    Stroke = Color3.fromRGB(52, 66, 89),       -- outlines
    Accent = Color3.fromRGB(152, 181, 255),    -- the blue
    AccentDark = Color3.fromRGB(66, 80, 115),  -- toggle knob when off
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(180, 180, 180),
}
```

window size is right above it (`WIDTH`, `HEIGHT`, `TOPBAR`, `SIDEBAR`, `MINI_WIDTH`) if you want it bigger or smaller.

## random things to know

- there's no config saving, everything starts at its default every time you run the script
- it uses `gethui`, `getgenv` and `cloneref` if your executor has them, if not it just falls back to CoreGui
- the glass blur only shows if your graphics are on 8 or higher (same as the original allusive)
- i switched the font to Montserrat because Gotham SSm (what the original uses) puts weird gaps in letters like "m" at small sizes

## credits

big thanks to [MarchHubOnTopFr](https://github.com/MarchHubOnTopFr/Allusive-UI) for the original Allusive UI. the style, colors and blur effect are all from there, i mostly rewrote the layout, the elements and the window controls. the original is MIT licensed, see `LICENSE`.
