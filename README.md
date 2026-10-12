# Custom Allusive UI

A compact Roblox UI library for executor scripts, based on [Allusive UI](https://github.com/MarchHubOnTopFr/Allusive-UI). It keeps Allusive's dark, blue-accented look and blurred backdrop, but lays everything out as rows inside sections instead of large cards, so a lot more fits on screen.

- Sidebar tabs, each holding sections of rows
- Toggles, sliders, buttons, keybinds, stat counters, a log box and paragraphs, all with titles and descriptions
- Top bar with minimize and close buttons, plus a key to open and close the menu
- Drag the window by the top bar or the sidebar; it always reopens fully on screen
- Slide-in notifications
- Scales down automatically on mobile

## Loading

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/customAllusive.lua"))()
```

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/customAllusive.lua"))()

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
    description = "How fast your character walks.",
    min = 16,
    max = 100,
    value = 16,
    callback = function(speed)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
    end,
})

window:load()
```

Call `window:load()` once, after you've built every tab. It plays the opening animation and turns on the blur.

## Structure

```
Window
└── Tab            (shown in the sidebar)
    └── Section    (a heading with a stack of rows under it)
        └── Rows   (toggle, slider, button, keybind, stats, log, paragraph)
```

## Window

### `Library.new(options)`

Creates the window and returns it. If a window from this library already exists (for example because you re-executed your script), it's destroyed first, so you never get duplicates.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | string | `"Allusive"` | Name shown in the top bar. |
| `subtitle` | string | none | Smaller line under the title. |
| `toggleKey` | `Enum.KeyCode` | `LeftAlt` | Key that opens and closes the menu. |

### Window methods

| Method | Description |
| --- | --- |
| `window:create_tab(name, icon?)` | Adds a tab to the sidebar and returns it. `icon` is an optional image id such as `"rbxassetid://123"`. The first tab is selected automatically. |
| `window:load()` | Shows the window. Call it once, after building your tabs. |
| `window:notify(options)` | Shows a notification. See [Notifications](#notifications). |
| `window:set_state(state)` | `"open"`, `"minimized"` or `"closed"`. |
| `window:set_toggle_key(keyCode)` | Changes the key that opens and closes the menu. |
| `window:destroy()` | Removes the window, its blur and all of its connections. |

### Window controls

- **Minimize (–)** shrinks the window into a small pill showing the title. Press it again to expand.
- **Close (×)** hides the window completely. A notification tells the player which key brings it back.
- **The toggle key** (Left Alt by default) switches between closed and open.
- **Dragging** works from the top bar or any empty space in the sidebar.
- **Screen edges:** when the window opens or expands, it moves back onto the screen if it would go past an edge.
- **Blur:** the blurred backdrop is only on while the window is fully open.

## Sections

### `tab:create_section(name)`

Adds a section to the tab and returns it. Sections appear in the order you create them. Every element below is created on a section.

```lua
local settings = tab:create_section("Settings")
```

## Elements

Every row has a `title` and an optional `description`. Long descriptions wrap onto extra lines and the row grows to fit.

Callbacks run in their own thread, so they can yield (`task.wait`, `WaitForChild`) without freezing the UI. An error in a callback won't break the menu.

### Toggle

```lua
local toggle = section:create_toggle({
    title = "Auto Farm",
    description = "Farms automatically while you're AFK.",
    default = false,
    callback = function(enabled) end,
})
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | string | | Row title. |
| `description` | string | none | Text under the title. |
| `default` | boolean | `false` | Starts on. The callback runs once at creation if this is `true`. |
| `callback` | function | none | Called with `true` or `false` whenever the toggle changes. |

| Returns | Description |
| --- | --- |
| `toggle.value` | Current state. |
| `toggle:set(value, silent?)` | Changes the state. Pass `true` as `silent` to skip the callback. |

The whole row is clickable, not just the switch.

### Slider

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

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | string | | Row title. |
| `description` | string | none | Text under the title. |
| `min` | number | `0` | Lowest value. |
| `max` | number | `100` | Highest value. |
| `step` | number | `1` | Values snap to this increment. A step below 1 (such as `0.1`) shows one decimal place. |
| `value` | number | `min` | Starting value. Doesn't run the callback. |
| `suffix` | string | `""` | Text after the number, such as `" studs/s"`. |
| `callback` | function | none | Called with the new value, only when it actually changes. |

| Returns | Description |
| --- | --- |
| `slider.value` | Current value. |
| `slider:set(value, silent?)` | Sets the value (clamped and snapped to `step`). |

### Button

```lua
section:create_button({
    title = "Rejoin",
    description = "Rejoins the current server.",
    buttonText = "Go",
    callback = function() end,
})
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | string | | Row title. |
| `description` | string | none | Text under the title. |
| `buttonText` | string | `"Run"` | Text in the small pill on the right. |
| `callback` | function | none | Called when the row is clicked. |

Returns a table with `title`, the title `TextLabel`, in case you want to rename the button later.

### Keybind

```lua
local keybind = section:create_keybind({
    title = "Menu Key",
    description = "Click, then press a new key. Esc cancels.",
    default = Enum.KeyCode.LeftAlt,
    callback = function(keyCode)
        window:set_toggle_key(keyCode)
    end,
})
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | string | | Row title. |
| `description` | string | none | Text under the title. |
| `default` | `Enum.KeyCode` | none | Starting key, shown in the pill. |
| `callback` | function | none | Called with the new `Enum.KeyCode` after the player picks one. |

| Returns | Description |
| --- | --- |
| `keybind.value` | Current key. |
| `keybind:set(keyCode, silent?)` | Changes the key. |

Clicking the row shows `...` until the player presses a keyboard key, and Esc cancels. While it's listening, the menu's own toggle key is ignored, so binding a key never accidentally closes the menu.

The keybind element only records a key. Your callback decides what the key does. To make the menu's open/close key changeable, pass the new key to `window:set_toggle_key` as in the example.

### Stats

A row of counters. When a value changes, the number counts up to it and briefly flashes the accent colour if it went up.

```lua
local stats = section:create_stats({
    { key = "coins", title = "Coins", value = 0, suffix = " c" },
    { key = "kills", title = "Kills", value = 0 },
    { key = "earned", title = "Earned", value = 0, prefix = "+" },
})

stats.coins:set(1500)
stats.kills:set(3)
```

Each entry accepts:

| Field | Type | Description |
| --- | --- | --- |
| `key` | string | Name to look the stat up by in the returned table. If you leave it out, use its position instead (`stats[1]`). |
| `title` | string | Small label above the number. |
| `value` | number | Starting value. |
| `prefix` | string | Text before the number. |
| `suffix` | string | Text after the number. |

Every stat has `stat.value` and `stat:set(number)`. Numbers are rounded and shown with thousands separators (`12,400`). Two to four stats per row fit well.

### Log

A small console with timestamped lines. The newest line is at the bottom.

```lua
local log = section:create_log({
    title = "Log",
    height = 100,
    lines = 7,
})

log:add("Started farming")
log:clear()
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | string | none | Label above the box. |
| `height` | number | `100` | Height of the box in pixels. |
| `lines` | number | `7` | How many lines to keep. Older lines are removed. |

| Returns | Description |
| --- | --- |
| `log:add(message)` | Adds a line, with the current time in front of it. |
| `log:clear()` | Removes every line. |

Match `lines` to `height`: each line is about 13px tall, so a 100px box holds about 7.

### Paragraph

Plain text with a title, useful for instructions or credits.

```lua
local info = section:create_paragraph({
    title = "Status",
    text = "Waiting for the round to start.",
})

info:set("Round started!")
info:set_title("Live")
```

| Returns | Description |
| --- | --- |
| `paragraph:set(text)` | Changes the body text. |
| `paragraph:set_title(text)` | Changes the title. |

## Notifications

```lua
window:notify({
    title = "Saved",
    text = "Your settings were saved.",
    duration = 4,
})
```

`Library.notify({...})` does the same thing without a window.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | string | `"Notification"` | Heading line. |
| `text` | string | none | Body text. Wraps onto extra lines. |
| `duration` | number | `4` | Seconds before it slides away. |

Notifications stack in the bottom-right corner, newest at the bottom.

## Full example

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/customAllusive.lua"))()

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

## Customising the look

Colours are in the `Theme` table near the top of `customAllusive.lua`:

```lua
local Theme = {
    Background = Color3.fromRGB(12, 13, 15),   -- window
    Panel = Color3.fromRGB(22, 28, 38),        -- rows, selected tab
    Element = Color3.fromRGB(32, 38, 51),      -- stat boxes, button hover
    Stroke = Color3.fromRGB(52, 66, 89),       -- outlines and dividers
    Accent = Color3.fromRGB(152, 181, 255),    -- highlights, toggles, titles
    AccentDark = Color3.fromRGB(66, 80, 115),  -- toggle knob when off
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(180, 180, 180),
}
```

The window size is set by `WIDTH`, `HEIGHT`, `TOPBAR`, `SIDEBAR` and `MINI_WIDTH` just above it.

## Notes

- **No config saving.** Toggles and sliders start from their defaults every time the script runs.
- **Executor functions are optional.** The library uses `gethui`, `getgenv` and `cloneref` when the executor provides them, and falls back to `CoreGui` otherwise.
- **Blur depends on graphics quality.** The glass backdrop only shows at graphics quality 8 or higher, as in the original Allusive.
- **Font:** all text uses Montserrat. Gotham SSm, which the original uses, renders odd gaps around letters like "m" at small sizes.

## Credits

Based on [Allusive UI](https://github.com/MarchHubOnTopFr/Allusive-UI) by MarchHubOnTopFr, released under the MIT License. The window style, colours and blur effect come from the original. The row layout, elements and window controls were rewritten.
