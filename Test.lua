-- This code was modified to ignore other players and display a remaining object counter UI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Event = ReplicatedStorage:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")

-- Radius threshold to group items together (20 studs wide = 10 stud radius from center)
local CLUSTER_RADIUS = 10 

-- Setup the Screen GUI to show objects left
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local existingGui = PlayerGui:FindFirstChild("ObjectCounterGui")
if existingGui then existingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ObjectCounterGui"
ScreenGui.ResetOnSpawn = false

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(0, 300, 0, 50)
TextLabel.Position = UDim2.new(0.5, -150, 0.35, -25) -- Placed in the center, slightly upper-middle
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextStrokeTransparency = 0 -- Adds a clean black outline for visibility
TextLabel.Font = Enum.Font.SourceSansBold
TextLabel.TextSize = 28
TextLabel.Text = "Objects Remaining: Calculating..."
TextLabel.Parent = ScreenGui

ScreenGui.Parent = PlayerGui

-- Helper function to check if a model belongs to any player in the server
local function isAPlayer(instance)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and instance:IsDescendantOf(player.Character) then
            return true
        end
    end
    return false
end

-- Function to find the highest assembly/parent model that isn't the Workspace itself
local function getRootTarget(part)
    local current = part
    while current.Parent and current.Parent ~= Workspace and current.Parent:IsA("Model") do
        current = current.Parent
    end
    return current
end

-- Function to gather unique unanchored parent roots and map them to their parts
local function getUnanchoredClusters()
    local roots = {}
    local rootToParts = {}

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") and not object.Anchored then
            -- Strictly ignore ALL players (including local player)
            if not isAPlayer(object) then
                local root = getRootTarget(object)
                
                if not rootToParts[root] then
                    rootToParts[root] = {}
                    table.insert(roots, root)
                end
                table.insert(rootToParts[root], object)
            end
        end
    end
    return roots, rootToParts
end

-- Main execution function
local function teleportToClusters()
    local roots, rootToParts = getUnanchoredClusters()
    local processed = {}
    
    -- Track total parent objects left to clear
    local totalRemaining = #roots
    TextLabel.Text = "Objects Remaining: " .. totalRemaining

    for i, rootA in ipairs(roots) do
        if not processed[rootA] then
            local posA = rootA:GetPivot().Position
            local clusterRoots = {rootA}
            processed[rootA] = true

            -- Look for other unanchored parents within a 20-stud diameter circle (10-stud radius)
            for j = i + 1, #roots do
                local rootB = roots[j]
                if not processed[rootB] then
                    local posB = rootB:GetPivot().Position
                    if (posA - posB).Magnitude <= CLUSTER_RADIUS then
                        table.insert(clusterRoots, rootB)
                        processed[rootB] = true
                    end
                end
            end

            -- Calculate the exact center position of this gathered cluster
            local centerSum = Vector3.new(0, 0, 0)
            for _, root in ipairs(clusterRoots) do
                centerSum = centerSum + root:GetPivot().Position
            end
            local clusterCenter = centerSum / #clusterRoots

            -- Teleport the character to the center of the cluster
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")

            if rootPart then
                -- Teleport slightly above the center point to prevent clipping
                rootPart.CFrame = CFrame.new(clusterCenter + Vector3.new(0, 3, 0))
                
                -- Wait 0.3 seconds for physics alignment / stability
                task.wait(0.3)

                -- Fire the Network Owner event for every single part inside this cluster
                for _, root in ipairs(clusterRoots) do
                    local parts = rootToParts[root]
                    if parts then
                        for _, part in ipairs(parts) do
                            if part:IsDescendantOf(Workspace) then
                                Event:FireServer(part, part.CFrame)
                            end
                        end
                    end
                end
            end

            -- Update UI counter after finishing the cluster
            totalRemaining = totalRemaining - #clusterRoots
            TextLabel.Text = "Objects Remaining: " .. totalRemaining
        end
    end

    -- Clean up text once everything is finished
    TextLabel.Text = "All Objects Claimed!"
    task.wait(2)
    
    -- Fade out UI nicely
    local tween = TweenService:Create(TextLabel, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1})
    tween:Play()
    tween.Completed:Connect(function()
        ScreenGui:Destroy()
    end)
end

-- Run the teleport cycle
teleportToClusters()

