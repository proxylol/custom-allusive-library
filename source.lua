-- Original library: Allusive UI Library
-- Modified by @blankfelony
-- v1.2

local cloneref = cloneref or function(obj)
	return obj
end

local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Lighting = cloneref(game:GetService("Lighting"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local WIDTH, HEIGHT = 620, 420
local TOPBAR, SIDEBAR = 44, 150
local MINI_WIDTH = 240

local Theme = {
	Background = Color3.fromRGB(12, 13, 15),
	Panel = Color3.fromRGB(22, 28, 38),
	Element = Color3.fromRGB(32, 38, 51),
	Stroke = Color3.fromRGB(52, 66, 89),
	Accent = Color3.fromRGB(152, 181, 255),
	AccentDark = Color3.fromRGB(66, 80, 115),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(180, 180, 180),
}

local Fonts = {
	Bold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold),
	Regular = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
	Mono = Font.new("rbxasset://fonts/families/RobotoMono.json"),
}

local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function tween(obj, time, props)
	local tw = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function corner(radius)
	return create("UICorner", { CornerRadius = radius and UDim.new(0, radius) or UDim.new(1, 0) })
end

local function stroke(transparency)
	return create("UIStroke", {
		Color = Theme.Stroke,
		Transparency = transparency or 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(top, bottom, left, right)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
		PaddingRight = UDim.new(0, right),
	})
end

local function list(gap, direction)
	return create("UIListLayout", {
		Padding = UDim.new(0, gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = direction or Enum.FillDirection.Vertical,
	})
end

local function label(props)
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.FontFace = props.FontFace or Fonts.Bold
	props.TextColor3 = props.TextColor3 or Theme.Text
	props.Text = props.Text or ""
	return create("TextLabel", props)
end

local function commas(n)
	local s = tostring(math.floor(n + 0.5))
	local k
	repeat
		s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until k == 0
	return s
end

local function escape(text)
	return (tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function keyName(key)
	return key and key.Name or "None"
end

local function getGuiParent()
	if gethui then
		local ok, hui = pcall(gethui)
		if ok and hui then
			return hui
		end
	end
	return CoreGui
end

local Blur = {}
Blur.__index = Blur

function Blur.new(frame, connections)
	local self = setmetatable({}, Blur)
	local camera = workspace.CurrentCamera

	local dof = Lighting:FindFirstChild("AllusiveBlur") or Instance.new("DepthOfFieldEffect")
	dof.Name = "AllusiveBlur"
	dof.FarIntensity = 0
	dof.FocusDistance = 0.05
	dof.InFocusRadius = 0.1
	dof.NearIntensity = 1
	dof.Parent = Lighting

	local old = camera:FindFirstChild("AllusiveBlur")
	if old then
		old:Destroy()
	end

	local folder = create("Folder", { Name = "AllusiveBlur", Parent = camera })
	local part = create("Part", {
		Name = "Root",
		Color = Color3.new(0, 0, 0),
		Material = Enum.Material.Glass,
		Size = Vector3.new(1, 1, 0),
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Locked = true,
		CastShadow = false,
		Transparency = 0.98,
		Parent = folder,
	})
	local mesh = create("SpecialMesh", {
		MeshType = Enum.MeshType.Brick,
		Offset = Vector3.new(0, 0, -0.000001),
		Parent = part,
	})

	local area = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	local corners = { Vector2.zero, Vector2.zero, Vector2.zero }
	local enabled = true

	local function toWorld(point)
		local ray = camera:ScreenPointToRay(point.X, point.Y)
		return ray.Origin + ray.Direction * 0.001
	end

	local function update()
		local topLeft, topRight, bottomRight = toWorld(corners[1]), toWorld(corners[2]), toWorld(corners[3])
		local cf = camera.CFrame
		part.CFrame = CFrame.fromMatrix((topLeft + bottomRight) / 2, cf.XVector, cf.YVector, cf.ZVector)
		mesh.Scale = Vector3.new((topRight - topLeft).Magnitude, (topRight - bottomRight).Magnitude, 0)
	end

	local function refresh()
		local offset = camera.ViewportSize.Y / 2560 * 48 + 8
		local size = area.AbsoluteSize - Vector2.new(offset, offset)
		local pos = area.AbsolutePosition + Vector2.new(offset / 2, offset / 2)
		corners = { pos, pos + Vector2.new(size.X, 0), pos + size }
		update()
	end

	local settings = UserSettings().GameSettings
	local function apply()
		part.Transparency = (enabled and settings.SavedQualityLevel.Value >= 8) and 0.98 or 1
		dof.Enabled = enabled
	end

	table.insert(connections, camera:GetPropertyChangedSignal("CFrame"):Connect(update))
	table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh))
	table.insert(connections, camera:GetPropertyChangedSignal("FieldOfView"):Connect(update))
	table.insert(connections, area:GetPropertyChangedSignal("AbsolutePosition"):Connect(refresh))
	table.insert(connections, area:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh))
	table.insert(connections, settings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(apply))

	apply()
	refresh()

	function self:set_enabled(value)
		enabled = value
		apply()
	end

	self.folder, self.dof = folder, dof
	return self
end

function Blur:destroy()
	self.folder:Destroy()
	self.dof:Destroy()
end

local notifyHolder

local function getNotifyHolder()
	if notifyHolder and notifyHolder.Parent then
		return notifyHolder
	end
	local parent = getGuiParent()
	local old = parent:FindFirstChild("AllusiveNotifications")
	if old then
		old:Destroy()
	end
	local gui = create("ScreenGui", {
		Name = "AllusiveNotifications",
		ResetOnSpawn = false,
		DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})
	notifyHolder = create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 250, 1, -32),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})
	return notifyHolder
end

local Library = {}
Library.__index = Library

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

function Library.notify(selfOrOpts, maybeOpts)
	local opts = maybeOpts or selfOrOpts
	local holder = getNotifyHolder()

	local wrapper = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = holder,
	})

	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(280, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Parent = wrapper,
	}, { corner(6), stroke(0.4), padding(9, 10, 12, 12), list(3) })

	local titleRow = create("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = card,
	})

	create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(2, 12),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = titleRow,
	}, { corner() })

	label({
		Text = opts.title or "Notification",
		TextSize = 14,
		TextColor3 = Theme.Accent,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -8, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleRow,
	})

	if opts.text and opts.text ~= "" then
		label({
			Text = opts.text,
			FontFace = Fonts.Regular,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = card,
		})
	end

	tween(card, 0.45, { Position = UDim2.fromOffset(0, 0) })

	task.delay(opts.duration or 4, function()
		tween(card, 0.35, { Position = UDim2.fromOffset(280, 0) }).Completed:Wait()
		wrapper:Destroy()
	end)
end

local function iconButton(parent, order)
	local button = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Element,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(22, 22),
		LayoutOrder = order,
		Parent = parent,
	}, { corner(4) })
	button.MouseEnter:Connect(function()
		tween(button, 0.25, { BackgroundTransparency = 0.4 })
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.25, { BackgroundTransparency = 1 })
	end)
	return button
end

local function bar(parent, rotation, width)
	return create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width or 10, 2),
		Rotation = rotation or 0,
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = parent,
	}, { corner() })
end

function Library.new(opts)
	opts = opts or {}

	if getgenv and getgenv().AllusiveCustom then
		pcall(function()
			getgenv().AllusiveCustom:destroy()
		end)
	end

	local self = setmetatable({
		_tabs = {},
		_connections = {},
		_state = "open",
		_binding = false,
		_toggleKey = opts.toggleKey or Enum.KeyCode.LeftAlt,
	}, Library)

	if getgenv then
		getgenv().AllusiveCustom = self
	end

	local gui = create("ScreenGui", {
		Name = "AllusiveCustom",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getGuiParent(),
	})

	local container = create("Frame", {
		Name = "Container",
		Position = UDim2.new(0.5, -WIDTH / 2, 0.5, -HEIGHT / 2),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
		Parent = gui,
	}, { corner(10), stroke(0.5) })

	local scale = create("UIScale", { Parent = container })

	local topbar = create("TextButton", {
		Name = "Topbar",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, TOPBAR),
		Parent = container,
	})

	create("ImageLabel", {
		Image = "rbxassetid://107819132007001",
		ImageColor3 = Theme.Accent,
		ScaleType = Enum.ScaleType.Fit,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Parent = topbar,
	})

	local title = label({
		Text = opts.title or "Allusive",
		TextSize = 15,
		TextColor3 = Theme.Accent,
		TextTransparency = 0.2,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 40, 0.5, opts.subtitle and -8 or 0),
		Size = UDim2.new(1, -110, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = topbar,
	})

	create("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(155, 155, 155), Color3.fromRGB(255, 255, 255)),
		Parent = title,
	})

	if opts.subtitle then
		label({
			Text = opts.subtitle,
			FontFace = Fonts.Regular,
			TextSize = 12,
			TextColor3 = Theme.Accent,
			TextTransparency = 0.6,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 40, 0.5, 9),
			Size = UDim2.new(1, -110, 0, 14),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = topbar,
		})
	end

	local controls = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(50, 22),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = topbar,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 6),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local minimizeButton = iconButton(controls, 1)
	bar(minimizeButton, 0, 10)

	local closeButton = iconButton(controls, 2)
	bar(closeButton, 45, 12)
	bar(closeButton, -45, 12)

	create("Frame", {
		Position = UDim2.fromOffset(0, TOPBAR),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = container,
	})

	create("Frame", {
		Position = UDim2.fromOffset(SIDEBAR, TOPBAR + 1),
		Size = UDim2.new(0, 1, 1, -TOPBAR - 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = container,
	})

	local tabList = create("ScrollingFrame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(0, TOPBAR + 1),
		Size = UDim2.new(0, SIDEBAR, 1, -TOPBAR - 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = container,
	}, { padding(10, 10, 10, 10), list(4) })

	local pages = create("Frame", {
		Name = "Pages",
		Position = UDim2.fromOffset(SIDEBAR + 1, TOPBAR + 1),
		Size = UDim2.new(1, -SIDEBAR - 1, 1, -TOPBAR - 1),
		BackgroundTransparency = 1,
		Parent = container,
	})

	self._gui, self._container, self._scale = gui, container, scale
	self._tabList, self._pages = tabList, pages

	local dragging, dragStart, startPos
	local function beginDrag(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging, dragStart, startPos = true, input.Position, container.Position
		local conn
		conn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				conn:Disconnect()
			end
		end)
	end

	topbar.InputBegan:Connect(beginDrag)
	tabList.InputBegan:Connect(beginDrag)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))

	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed or self._binding or input.KeyCode ~= self._toggleKey then
			return
		end
		self:set_state(self._state == "closed" and "open" or "closed")
	end))

	minimizeButton.MouseButton1Click:Connect(function()
		self:set_state(self._state == "minimized" and "open" or "minimized")
	end)

	closeButton.MouseButton1Click:Connect(function()
		self:set_state("closed")
		Library.notify({
			title = "Menu closed",
			text = ("Press %s to open it again."):format(keyName(self._toggleKey)),
			duration = 3,
		})
	end)

	return self
end

function Library:set_state(state)
	self._state = state
	local container = self._container

	if state == "closed" then
		tween(container, 0.3, { Size = UDim2.fromOffset(0, 0) }).Completed:Connect(function()
			if self._state == "closed" then
				container.Visible = false
			end
		end)
		if self._blur then
			self._blur:set_enabled(false)
		end
		return
	end

	container.Visible = true
	if self._blur then
		self._blur:set_enabled(state == "open")
	end

	local target = state == "minimized" and Vector2.new(MINI_WIDTH, TOPBAR) or Vector2.new(WIDTH, HEIGHT)
	local screen = self._gui.AbsoluteSize
	local size = target * self._scale.Scale
	local pos = container.AbsolutePosition
	local x = math.clamp(pos.X, 0, math.max(0, screen.X - size.X))
	local y = math.clamp(pos.Y, 0, math.max(0, screen.Y - size.Y))

	tween(container, 0.45, {
		Size = UDim2.fromOffset(target.X, target.Y),
		Position = UDim2.fromOffset(x, y),
	})
end

function Library:set_toggle_key(key)
	self._toggleKey = key
end

function Library:load()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		local function rescale()
			self._scale.Scale = math.clamp(workspace.CurrentCamera.ViewportSize.X / 1400, 0.5, 1)
		end
		rescale()
		table.insert(self._connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale))
	end

	tween(self._container, 0.5, { Size = UDim2.fromOffset(WIDTH, HEIGHT) })
	self._blur = Blur.new(self._container, self._connections)
end

function Library:destroy()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
	if self._blur then
		self._blur:destroy()
	end
	self._gui:Destroy()
end

function Library:_select(tab)
	for _, t in ipairs(self._tabs) do
		local on = t == tab
		t._page.Visible = on
		tween(t._button, 0.4, { BackgroundTransparency = on and 0.5 or 1 })
		tween(t._label, 0.4, { TextTransparency = on and 0.2 or 0.7, TextColor3 = on and Theme.Accent or Theme.Text })
		tween(t._pin, 0.4, { BackgroundTransparency = on and 0 or 1 })
		if t._icon then
			tween(t._icon, 0.4, { ImageTransparency = on and 0.2 or 0.8, ImageColor3 = on and Theme.Accent or Theme.Text })
		end
	end
end

function Library:create_tab(name, icon)
	local tab = setmetatable({ _library = self, _order = 0 }, Tab)

	local button = create("TextButton", {
		Name = "Tab",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = #self._tabs + 1,
		Parent = self._tabList,
	}, { corner(5) })

	local pin = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(2, 16),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = button,
	}, { corner() })

	local textX = 14
	if icon and icon ~= "" then
		tab._icon = create("ImageLabel", {
			Image = icon,
			ImageTransparency = 0.8,
			ScaleType = Enum.ScaleType.Fit,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			Parent = button,
		})
		textX = 34
	end

	local text = label({
		Text = name,
		TextSize = 13,
		TextTransparency = 0.7,
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1, -textX, 1, 0),
		Parent = button,
	})

	local page = create("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollBarImageTransparency = 0.5,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = self._pages,
	}, { padding(12, 14, 14, 14), list(14) })

	tab._button, tab._label, tab._pin, tab._page = button, text, pin, page

	button.MouseButton1Click:Connect(function()
		self:_select(tab)
	end)

	table.insert(self._tabs, tab)
	if #self._tabs == 1 then
		self:_select(tab)
	end

	return tab
end

function Tab:create_section(name)
	self._order += 1

	local holder = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = self._order,
		Parent = self._page,
	}, { list(6) })

	label({
		Text = name,
		TextSize = 13,
		TextColor3 = Theme.Accent,
		TextTransparency = 0.3,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 1,
		Parent = holder,
	})

	local rows = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	}, { list(8) })

	return setmetatable({ _library = self._library, _rows = rows, _count = 0 }, Section)
end

function Section:_row()
	self._count += 1
	return create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		LayoutOrder = self._count,
		Parent = self._rows,
	}, { corner(5), stroke(0.6), padding(9, 9, 12, 12) })
end

local function info(parent, titleText, descText, rightSpace, order)
	local holder = create("Frame", {
		Size = UDim2.new(1, -rightSpace, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = order or 0,
		Parent = parent,
	}, { list(2) })

	local titleLabel = label({
		Text = titleText or "",
		TextSize = 15,
		TextTransparency = 0.15,
		Size = UDim2.new(1, 0, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = holder,
	})

	local descLabel
	if descText and descText ~= "" then
		descLabel = label({
			Text = descText,
			FontFace = Fonts.Regular,
			TextSize = 13,
			TextColor3 = Theme.Accent,
			TextTransparency = 0.5,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = holder,
		})
	end

	return holder, titleLabel, descLabel
end

local function hover(button, row, titleLabel)
	button.MouseEnter:Connect(function()
		tween(titleLabel, 0.3, { TextTransparency = 0 })
		tween(row, 0.3, { BackgroundTransparency = 0.3 })
	end)
	button.MouseLeave:Connect(function()
		tween(titleLabel, 0.3, { TextTransparency = 0.15 })
		tween(row, 0.3, { BackgroundTransparency = 0.5 })
	end)
end

local function overlay(row)
	return create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = row,
	})
end

local function pill(parent, text)
	local frame = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		Parent = parent,
	}, { corner(4), padding(0, 0, 8, 8) })

	local text = label({
		Text = text,
		TextSize = 12,
		TextColor3 = Theme.Accent,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = frame,
	})

	return frame, text
end

function Section:create_toggle(opts)
	local row = self:_row()
	local _, titleLabel = info(row, opts.title, opts.description, 50)

	local switch = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(28, 14),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		Parent = row,
	}, { corner() })

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Theme.AccentDark,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = switch,
	}, { corner() })

	local button = overlay(row)
	hover(button, row, titleLabel)

	local toggle = { value = false }

	function toggle:set(value, silent)
		value = value and true or false
		self.value = value
		tween(switch, 0.4, { BackgroundColor3 = value and Theme.Accent or Color3.new(0, 0, 0) })
		tween(knob, 0.4, {
			Position = value and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = value and Theme.Accent or Theme.AccentDark,
		})
		if not silent and opts.callback then
			task.spawn(opts.callback, value)
		end
	end

	button.MouseButton1Click:Connect(function()
		toggle:set(not toggle.value)
	end)

	if opts.default then
		toggle:set(true)
	end

	return toggle
end

function Section:create_slider(opts)
	local min, max = opts.min or 0, opts.max or 100
	local step = opts.step or 1
	local suffix = opts.suffix or ""

	local row = self:_row()
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })

	local top = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = row,
	})
	local _, titleLabel = info(top, opts.title, opts.description, 70)

	local valueLabel = label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(70, 14),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 11,
		TextColor3 = Theme.Accent,
		TextTransparency = 0.1,
		Parent = top,
	})

	local hitbox = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 12),
		LayoutOrder = 2,
		Parent = row,
	})

	local track = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Parent = hitbox,
	}, { corner() })

	local fill = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = track,
	}, {
		corner(),
		create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(79, 79, 79)) }),
	})

	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Theme.Text,
		BorderSizePixel = 0,
		Parent = fill,
	}, { corner() })

	hover(hitbox, row, titleLabel)

	local slider = {}

	local function format(v)
		if step < 1 then
			return ("%.1f"):format(v) .. suffix
		end
		return tostring(math.floor(v + 0.5)) .. suffix
	end

	function slider:set(value, silent)
		value = math.clamp(value, min, max)
		value = math.clamp(math.floor((value - min) / step + 0.5) * step + min, min, max)
		local changed = value ~= self.value
		self.value = value
		valueLabel.Text = format(value)
		tween(fill, 0.3, { Size = UDim2.new((value - min) / (max - min), 0, 1, 0) })
		if changed and not silent and opts.callback then
			task.spawn(opts.callback, value)
		end
	end

	local dragging = false
	local function fromX(x)
		local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		slider:set(min + (max - min) * pct)
	end

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(input.Position.X)
		end
	end)

	table.insert(self._library._connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end))

	table.insert(self._library._connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	slider:set(opts.value or min, true)

	return slider
end

function Section:create_button(opts)
	local row = self:_row()
	local _, titleLabel = info(row, opts.title, opts.description, 60)
	local frame = pill(row, opts.buttonText or "Run")

	local button = overlay(row)
	hover(button, row, titleLabel)

	button.MouseButton1Click:Connect(function()
		frame.BackgroundTransparency = 0.5
		tween(frame, 0.4, { BackgroundTransparency = 0.85 })
		if opts.callback then
			task.spawn(opts.callback)
		end
	end)

	return { title = titleLabel }
end

function Section:create_keybind(opts)
	local library = self._library
	local row = self:_row()
	local _, titleLabel = info(row, opts.title, opts.description, 90)
	local frame, text = pill(row, keyName(opts.default))

	local button = overlay(row)
	hover(button, row, titleLabel)

	local keybind = { value = opts.default }
	local listening = false

	function keybind:set(key, silent)
		self.value = key
		text.Text = keyName(key)
		if not silent and opts.callback then
			task.spawn(opts.callback, key)
		end
	end

	button.MouseButton1Click:Connect(function()
		if listening then
			return
		end
		listening = true
		library._binding = true
		text.Text = "..."
		tween(frame, 0.3, { BackgroundTransparency = 0.6 })
	end)

	table.insert(library._connections, UserInputService.InputBegan:Connect(function(input)
		if not listening or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		listening = false
		tween(frame, 0.3, { BackgroundTransparency = 0.85 })
		if input.KeyCode == Enum.KeyCode.Escape then
			text.Text = keyName(keybind.value)
		else
			keybind:set(input.KeyCode)
		end
		task.defer(function()
			library._binding = false
		end)
	end))

	return keybind
end

-- opts.options can be a list of strings or a function returning one; a function is called every
-- time the dropdown opens, so the list can change (e.g. things the player owns)
function Section:create_dropdown(opts)
	local row = self:_row()
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })

	local top = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = row,
	})
	local _, titleLabel = info(top, opts.title, opts.description, 140)

	local placeholder = opts.placeholder or "Select"
	local frame, text = pill(top, placeholder .. "  ▾")
	frame.ClipsDescendants = true
	create("UISizeConstraint", { MaxSize = Vector2.new(130, 18), Parent = frame })

	local button = overlay(top)
	hover(button, row, titleLabel)

	local listFrame = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 2,
		Parent = row,
	}, { list(4) })

	local dropdown = { value = nil }
	local open = false
	local setOpen

	local function items()
		local o = opts.options
		if type(o) == "function" then
			local ok, result = pcall(o)
			o = ok and result or {}
		end
		return o or {}
	end

	local function rebuild()
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local entries = items()
		if #entries == 0 then
			label({
				Text = opts.empty or "Nothing to pick yet.",
				FontFace = Fonts.Regular,
				TextSize = 12,
				TextColor3 = Theme.SubText,
				TextTransparency = 0.3,
				Size = UDim2.new(1, 0, 0, 22),
				Parent = listFrame,
			})
		end
		for i, item in ipairs(entries) do
			local selected = item == dropdown.value
			local option = create("TextButton", {
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Theme.Element,
				BackgroundTransparency = selected and 0.3 or 0.75,
				Size = UDim2.new(1, 0, 0, 26),
				LayoutOrder = i,
				Parent = listFrame,
			}, { corner(4), padding(0, 0, 10, 10) })
			label({
				Text = item,
				FontFace = selected and Fonts.Bold or Fonts.Regular,
				TextSize = 13,
				TextColor3 = selected and Theme.Accent or Theme.Text,
				TextTransparency = selected and 0 or 0.25,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Size = UDim2.fromScale(1, 1),
				Parent = option,
			})
			option.MouseEnter:Connect(function()
				tween(option, 0.25, { BackgroundTransparency = selected and 0.2 or 0.5 })
			end)
			option.MouseLeave:Connect(function()
				tween(option, 0.25, { BackgroundTransparency = selected and 0.3 or 0.75 })
			end)
			option.MouseButton1Click:Connect(function()
				dropdown:set(item)
				setOpen(false)
			end)
		end
	end

	setOpen = function(value)
		open = value
		if value then
			rebuild()
		end
		listFrame.Visible = value
		text.Text = (dropdown.value or placeholder) .. (value and "  ▴" or "  ▾")
	end

	function dropdown:set(value, silent)
		self.value = value
		text.Text = (value or placeholder) .. (open and "  ▴" or "  ▾")
		if not silent and opts.callback then
			task.spawn(opts.callback, value)
		end
	end

	function dropdown:refresh()
		if open then
			rebuild()
		end
	end

	button.MouseButton1Click:Connect(function()
		frame.BackgroundTransparency = 0.5
		tween(frame, 0.4, { BackgroundTransparency = 0.85 })
		setOpen(not open)
	end)

	if opts.default then
		dropdown:set(opts.default, true)
	end

	return dropdown
end

function Section:create_stats(stats)
	local row = self:_row()

	local holder = create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = row,
	}, { list(8, Enum.FillDirection.Horizontal) })

	local count = #stats
	local results = {}

	for i, s in ipairs(stats) do
		local box = create("Frame", {
			Size = UDim2.new(1 / count, -8 * (count - 1) / count, 1, 0),
			BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			LayoutOrder = i,
			Parent = holder,
		}, { corner(5), stroke(0.6), padding(6, 6, 10, 10) })

		label({
			Text = s.title or "",
			FontFace = Fonts.Regular,
			TextSize = 12,
			TextColor3 = Theme.Accent,
			TextTransparency = 0.5,
			Size = UDim2.new(1, 0, 0, 14),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = box,
		})

		local valueLabel = label({
			TextSize = 16,
			TextTransparency = 0.1,
			Position = UDim2.fromOffset(0, 14),
			Size = UDim2.new(1, 0, 0, 18),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = box,
		})

		local prefix, suffix = s.prefix or "", s.suffix or ""
		local stat = { value = s.value or 0 }
		valueLabel.Text = prefix .. commas(stat.value) .. suffix

		function stat:set(value)
			local from = self.value
			self.value = value
			local counter = Instance.new("NumberValue")
			counter.Value = from
			counter.Changed:Connect(function(v)
				valueLabel.Text = prefix .. commas(v) .. suffix
			end)
			local tw = tween(counter, 0.6, { Value = value })
			tw.Completed:Connect(function()
				valueLabel.Text = prefix .. commas(value) .. suffix
				counter:Destroy()
			end)
			if value > from then
				valueLabel.TextColor3 = Theme.Accent
				tween(valueLabel, 0.8, { TextColor3 = Theme.Text })
			end
		end

		results[s.key or i] = stat
	end

	return results
end

function Section:create_log(opts)
	opts = opts or {}
	local maxLines = opts.lines or 7

	local row = self:_row()
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })

	if opts.title then
		label({
			Text = opts.title,
			TextSize = 12,
			TextTransparency = 0.15,
			Size = UDim2.new(1, 0, 0, 14),
			LayoutOrder = 1,
			Parent = row,
		})
	end

	local box = create("Frame", {
		Size = UDim2.new(1, 0, 0, opts.height or 100),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 2,
		Parent = row,
	}, { corner(4), stroke(0.7), padding(6, 6, 8, 8) })

	local text = label({
		FontFace = Fonts.Mono,
		TextSize = 10,
		TextColor3 = Theme.SubText,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		TextWrapped = true,
		RichText = true,
		Size = UDim2.fromScale(1, 1),
		Parent = box,
	})

	local lines = {}
	local log = {}

	function log:add(message)
		table.insert(lines, ('<font color="#98B5FF">%s</font> %s'):format(os.date("%X"), escape(message)))
		while #lines > maxLines do
			table.remove(lines, 1)
		end
		text.Text = table.concat(lines, "\n")
	end

	function log:clear()
		table.clear(lines)
		text.Text = ""
	end

	return log
end

function Section:create_paragraph(opts)
	local row = self:_row()
	local _, titleLabel, descLabel = info(row, opts.title, opts.text or " ", 0)

	local paragraph = {}

	function paragraph:set(text)
		descLabel.Text = text
	end

	function paragraph:set_title(text)
		titleLabel.Text = text
	end

	return paragraph
end

return Library
