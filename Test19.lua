--// 📦 ProFuiLikeUI.lua
local ProUI = {}

-- 🪟 ฟังก์ชันสร้างหน้าต่างหลัก
function ProUI:CreateWindow(settings)
    settings = settings or {}
    local Title = settings.Title or "Pro FUI UI"
    local Size = settings.Size or UDim2.new(0, 400, 0, 300)
    local Theme = (settings.Theme or "Dark"):lower()
    local Draggable = (settings.Draggable ~= false)

    -- 🧱 UI Objects
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ProFuiUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    local Main = Instance.new("Frame")
    Main.Size = Size
    Main.Position = UDim2.new(0.5, -Size.X.Offset/2, 0.5, -Size.Y.Offset/2)
    Main.BackgroundColor3 = Theme == "dark" and Color3.fromRGB(20, 20, 25) or Color3.fromRGB(230, 230, 230)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = Draggable
    Main.Parent = ScreenGui
    Main.ClipsDescendants = true

    local UICorner = Instance.new("UICorner", Main)
    UICorner.CornerRadius = UDim.new(0, 8)

    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 35)
    Header.BackgroundColor3 = Theme == "dark" and Color3.fromRGB(40, 40, 55) or Color3.fromRGB(200, 200, 200)
    Header.Text = Title
    Header.TextColor3 = Theme == "dark" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 16
    Header.Parent = Main

    local TabHolder = Instance.new("Frame")
    TabHolder.Size = UDim2.new(1, 0, 1, -35)
    TabHolder.Position = UDim2.new(0, 0, 0, 35)
    TabHolder.BackgroundTransparency = 1
    TabHolder.Parent = Main

    local Tabs = {}

    function Tabs:AddTab(name)
        local Tab = Instance.new("Frame")
        Tab.Name = name
        Tab.Size = UDim2.new(1, 0, 1, 0)
        Tab.BackgroundTransparency = 1
        Tab.Visible = false
        Tab.Parent = TabHolder

        local Elements = {}

        function Elements:AddButton(title, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -20, 0, 30)
            btn.Position = UDim2.new(0, 10, 0, #Tab:GetChildren() * 35 + 10)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Text = title
            btn.Parent = Tab
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
        end

        function Elements:AddToggle(title, default, callback)
            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.new(1, -20, 0, 30)
            toggle.Position = UDim2.new(0, 10, 0, #Tab:GetChildren() * 35 + 10)
            toggle.BackgroundColor3 = default and Color3.fromRGB(90, 150, 90) or Color3.fromRGB(70, 70, 90)
            toggle.TextColor3 = Color3.new(1, 1, 1)
            toggle.Font = Enum.Font.Gotham
            toggle.TextSize = 14
            toggle.Text = title
            toggle.Parent = Tab

            local state = default
            toggle.MouseButton1Click:Connect(function()
                state = not state
                toggle.BackgroundColor3 = state and Color3.fromRGB(90, 150, 90) or Color3.fromRGB(70, 70, 90)
                if callback then callback(state) end
            end)
        end

        Tab.Visible = true
        return Elements
    end

    return Tabs
end

return ProUI
