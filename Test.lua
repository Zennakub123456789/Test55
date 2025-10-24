-- ProFuiLikeUI.lua
-- UI library inspired by the profeiy-style mod menu in the picture.
-- Single-file UI library for Roblox (works with runners / mobile). No external dependencies.
-- Features: Window header, tabs, tab buttons, toggles, slider, button, label, dropdown, draggable (touch + mouse), rounded corners, simple animations, save position.

local ProFui = {}
ProFui.__index = ProFui

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Settings (tweakable)
local DEFAULT_THEME = {
    Background = Color3.fromRGB(11,13,18),
    Accent = Color3.fromRGB(6,182,213), -- top bar
    TabAccent = Color3.fromRGB(124,58,237), -- purple line
    Panel = Color3.fromRGB(18,18,24),
    Text = Color3.fromRGB(240,240,240),
    MutedText = Color3.fromRGB(180,180,180),
}

-- Helpers
local function newInstance(className, props)
    local obj = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            if type(k) == "number" then
                -- allow direct children
            else
                pcall(function() obj[k] = v end)
            end
        end
    end
    return obj
end

local function applyCorner(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = frame
    return corner
end

local function makeDraggable(gui, handle)
    -- handle: the input element (Frame) used for dragging (header)
    handle = handle or gui
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        gui.Position = newPos
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Core UI builder
function ProFui.new(name, opts)
    opts = opts or {}
    local theme = opts.Theme or DEFAULT_THEME
    local savePosKey = opts.SavePositionKey or ("ProFui_Pos_" .. tostring(game.PlaceId))

    local self = setmetatable({}, ProFui)
    self.Name = name or "ProFui"
    self.Theme = theme
    self.savePosKey = savePosKey
    self.Window = nil
    self.Tabs = {}

    -- create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = self.Name .. "_GUI"
    screenGui.Parent = (game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.ResetOnSpawn = false

    -- main frame
    local main = newInstance("Frame", {
        Name = "Main",
        Parent = screenGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 360, 0, 520),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
    })
    applyCorner(main, 14)

    -- header
    local header = newInstance("Frame", {
        Name = "Header",
        Parent = main,
        Size = UDim2.new(1, 0, 0, 44),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
    })
    applyCorner(header, 14)

    local title = newInstance("TextLabel", {
        Name = "Title",
        Parent = header,
        Text = "!! " .. tostring(self.Name) .. " !!",
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- thin accent line
    local accentLine = newInstance("Frame", {
        Name = "AccentLine",
        Parent = main,
        Size = UDim2.new(1, -12, 0, 4),
        Position = UDim2.new(0, 6, 0, 44),
        BackgroundColor3 = theme.TabAccent,
        BorderSizePixel = 0,
    })
    applyCorner(accentLine, 6)

    -- tab buttons container
    local tabButtons = newInstance("Frame", {
        Name = "TabButtons",
        Parent = main,
        Size = UDim2.new(1, -12, 0, 48),
        Position = UDim2.new(0, 6, 0, 54),
        BackgroundTransparency = 1,
    })
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = tabButtons
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)

    -- content area
    local content = newInstance("Frame", {
        Name = "Content",
        Parent = main,
        Size = UDim2.new(1, -12, 1, -120),
        Position = UDim2.new(0, 6, 0, 108),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
    })
    applyCorner(content, 10)

    -- inner scrolling frame for items
    local scroll = newInstance("ScrollingFrame", {
        Name = "Scroll",
        Parent = content,
        Size = UDim2.new(1, -12, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
        BackgroundTransparency = 1,
        ScrollBarImageColor3 = theme.TabAccent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    local list = Instance.new("UIListLayout")
    list.Parent = scroll
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)

    -- store refs
    self.ScreenGui = screenGui
    self.Main = main
    self.Header = header
    self.Title = title
    self.TabButtons = tabButtons
    self.Content = content
    self.Scroll = scroll
    self.ListLayout = list

    -- draggable
    makeDraggable(main, header)

    -- expose window object
    self.Window = {}
    self.Window.ScreenGui = screenGui
    self.Window.Main = main
    self.Window.AddTab = function(title)
        local tab = {}
        local tabIndex = #self.Tabs + 1

        -- create tab button
        local btn = newInstance("TextButton", {
            Name = "TabBtn_" .. tostring(title),
            Parent = tabButtons,
            Text = tostring(title),
            Size = UDim2.new(0, 80, 1, 0),
            BackgroundColor3 = Color3.fromRGB(31,31,35),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = theme.Text,
        })
        applyCorner(btn, 8)

        -- tab page container (frame inside content)
        local page = newInstance("Frame", {
            Name = "Page_" .. tostring(title),
            Parent = content,
            Size = UDim2.new(1, -12, 1, -12),
            Position = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1,
            Visible = false,
        })
        local pageScroll = newInstance("ScrollingFrame", {
            Name = "PageScroll",
            Parent = page,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarImageColor3 = theme.TabAccent,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        })
        local pageList = Instance.new("UIListLayout")
        pageList.Parent = pageScroll
        pageList.SortOrder = Enum.SortOrder.LayoutOrder
        pageList.Padding = UDim.new(0, 8)

        -- show first tab by default
        if tabIndex == 1 then
            page.Visible = true
            btn.BackgroundColor3 = theme.TabAccent
            btn.TextColor3 = Color3.new(1,1,1)
        end

        btn.MouseButton1Click:Connect(function()
            for i, t in ipairs(self.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = Color3.fromRGB(31,31,35)
                t.Button.TextColor3 = theme.Text
            end
            page.Visible = true
            btn.BackgroundColor3 = theme.TabAccent
            btn.TextColor3 = Color3.new(1,1,1)
        end)

        tab.Button = btn
        tab.Page = page
        tab.PageScroll = pageScroll
        tab.PageList = pageList

        -- functions to add elements
        function tab:AddLabel(text)
            local frame = newInstance("Frame", {Parent = pageScroll, Size = UDim2.new(1, -12, 0, 28), BackgroundTransparency = 1})
            local lbl = newInstance("TextLabel", {Parent = frame, Text = tostring(text), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = theme.Text, Font = Enum.Font.GothamSemibold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            return lbl
        end

        function tab:AddButton(text, callback)
            local frame = newInstance("Frame", {Parent = pageScroll, Size = UDim2.new(1, -12, 0, 36), BackgroundTransparency = 1})
            local btn = newInstance("TextButton", {Parent = frame, Text = tostring(text), Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(40,40,44), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = theme.Text})
            applyCorner(btn, 8)
            btn.MouseButton1Click:Connect(function()
                pcall(function() if callback then callback() end end)
            end)
            return btn
        end

        function tab:AddToggle(text, default, callback)
            local container = newInstance("Frame", {Parent = pageScroll, Size = UDim2.new(1, -12, 0, 36), BackgroundTransparency = 1})
            local label = newInstance("TextLabel", {Parent = container, Text = tostring(text), Size = UDim2.new(0.72, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = theme.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            local box = newInstance("ImageButton", {Parent = container, Size = UDim2.new(0, 34, 0, 22), Position = UDim2.new(0.78, 0, 0.18, 0), BackgroundColor3 = Color3.fromRGB(32,32,36), BorderSizePixel = 0})
            applyCorner(box, 6)
            local knob = newInstance("Frame", {Parent = box, Size = UDim2.new(0.48, 0, 0.9, 0), Position = UDim2.new(default and 0.5 or 0.02, 0, 0.05, 0), BackgroundColor3 = default and theme.Accent or Color3.fromRGB(120,120,120)})
            applyCorner(knob, 6)

            local state = default and true or false
            box.MouseButton1Click:Connect(function()
                state = not state
                if state then
                    knob:TweenPosition(UDim2.new(0.5, 0, 0.05, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)
                    knob.BackgroundColor3 = theme.Accent
                else
                    knob:TweenPosition(UDim2.new(0.02, 0, 0.05, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)
                    knob.BackgroundColor3 = Color3.fromRGB(120,120,120)
                end
                pcall(function() if callback then callback(state) end end)
            end)

            return {Container = container, Set = function(_, val)
                if val ~= state then
                    box:CaptureFocus() -- harmless nudge
                    box:ReleaseFocus()
                    box:TweenSize(box.Size, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
                    state = val
                    if state then
                        knob.Position = UDim2.new(0.5, 0, 0.05, 0)
                        knob.BackgroundColor3 = theme.Accent
                    else
                        knob.Position = UDim2.new(0.02, 0, 0.05, 0)
                        knob.BackgroundColor3 = Color3.fromRGB(120,120,120)
                    end
                    pcall(function() if callback then callback(state) end end)
                end
            end}
        end

        function tab:AddSlider(text, min, max, default, callback)
            local container = newInstance("Frame", {Parent = pageScroll, Size = UDim2.new(1, -12, 0, 50), BackgroundTransparency = 1})
            local label = newInstance("TextLabel", {Parent = container, Text = tostring(text), Size = UDim2.new(0.6, 0, 0, 18), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, TextColor3 = theme.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            local valueLabel = newInstance("TextLabel", {Parent = container, Text = tostring(default), Size = UDim2.new(0.4, -6, 0, 18), Position = UDim2.new(0.6, 6, 0, 0), BackgroundTransparency = 1, TextColor3 = theme.MutedText, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right})

            local track = newInstance("Frame", {Parent = container, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 24), BackgroundColor3 = Color3.fromRGB(52,52,58), BorderSizePixel = 0})
            applyCorner(track, 8)
            local fill = newInstance("Frame", {Parent = track, Size = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = theme.Accent, BorderSizePixel = 0})
            applyCorner(fill, 8)
            local knob = newInstance("Frame", {Parent = track, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.5, -7, 0, -1), BackgroundColor3 = Color3.fromRGB(255, 204, 0), BorderSizePixel = 0})
            applyCorner(knob, 14)

            local range = max - min
            local current = tonumber(default) or min
            local dragging = false

            local function setValueFromX(x)
                local rel = math.clamp(x / track.AbsoluteSize.X, 0, 1)
                local val = min + math.floor(rel * range + 0.5)
                current = val
                fill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, -7, 0, -1)
                valueLabel.Text = tostring(val)
                pcall(function() if callback then callback(val) end end)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setValueFromX(input.Position.X - track.AbsolutePosition.X)
                end
            end)
            track.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then
                        setValueFromX(input.Position.X - track.AbsolutePosition.X)
                    end
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            -- initialize
            local relInit = (current - min) / math.max(1, range)
            fill.Size = UDim2.new(relInit, 0, 1, 0)
            knob.Position = UDim2.new(relInit, -7, 0, -1)
            valueLabel.Text = tostring(current)

            return {Container = container, Set = function(_, val)
                val = math.clamp(tonumber(val) or min, min, max)
                current = val
                local rel = (current - min) / math.max(1, range)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, -7, 0, -1)
                valueLabel.Text = tostring(current)
                pcall(function() if callback then callback(current) end end)
            end}
        end

        function tab:AddDropdown(text, options, default, callback)
            options = options or {}
            local container = newInstance("Frame", {Parent = pageScroll, Size = UDim2.new(1, -12, 0, 36), BackgroundTransparency = 1})
            local label = newInstance("TextLabel", {Parent = container, Text = tostring(text), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = theme.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            local down = newInstance("TextButton", {Parent = container, Text = tostring(default or options[1] or "Select"), Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.new(0.62, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(38,38,44), BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = theme.MutedText})
            applyCorner(down, 8)

            local listFrame = newInstance("Frame", {Parent = container, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 6), BackgroundColor3 = Color3.fromRGB(28,28,34), Visible = false, BorderSizePixel = 0})
            applyCorner(listFrame, 8)
            local listLayout = Instance.new("UIListLayout")
            listLayout.Parent = listFrame
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local selected = default or down.Text

            local function refreshOptions()
                for _, v in ipairs(listFrame:GetChildren()) do
                    if v:IsA("TextButton") then v:Destroy() end
                end
                for i, opt in ipairs(options) do
                    local optBtn = newInstance("TextButton", {Parent = listFrame, Text = tostring(opt), Size = UDim2.new(1, -8, 0, 28), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = theme.Text})
                    optBtn.Position = UDim2.new(0, 4, 0, 4 + (i-1) * 32)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        down.Text = tostring(opt)
                        listFrame.Visible = false
                        pcall(function() if callback then callback(opt) end end)
                    end)
                end
                -- adjust size
                local count = #options
                listFrame.Size = UDim2.new(1, 0, 0, math.clamp(count * 32 + 8, 0, 200))
            end

            down.MouseButton1Click:Connect(function()
                listFrame.Visible = not listFrame.Visible
                if listFrame.Visible then refreshOptions() end
            end)

            refreshOptions()
            return {Container = container, Set = function(_, val)
                selected = val
                down.Text = tostring(val)
                pcall(function() if callback then callback(val) end end)
            end}
        end

        table.insert(self.Tabs, tab)
        return tab
    end

    return self.Window
end

-- Return library
return ProFui
