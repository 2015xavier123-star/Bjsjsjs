local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local SpawnedInToys = workspace:WaitForChild(LocalPlayer.Name .. "SpawnedInToys")

local SpawnToy = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
local SetNetworkOwner = ReplicatedStorage.GrabEvents.SetNetworkOwner
local StickyPartEvent = ReplicatedStorage.PlayerEvents.StickyPartEvent

local OceanModel = workspace.Map.AlwaysHereTweenedObjects.Ocean.Object.ObjectModel
local OceanParts = OceanModel:GetChildren()
local OceanPart = OceanParts[22] -- grab the 22nd part

local Shurikens = {}

for i = 1, 10 do
    if LocalPlayer:FindFirstChild("CanSpawnToy") and not LocalPlayer.CanSpawnToy.Value then
        LocalPlayer.CanSpawnToy.Changed:Wait()
    end

    local shuriken
    local conn

    conn = SpawnedInToys.ChildAdded:Connect(function(child)
        if child.Name == "NinjaShuriken" then
            shuriken = child

            if conn then
                conn:Disconnect()
                conn = nil
            end
        end
    end)

    task.spawn(function()
        SpawnToy:InvokeServer(
            "NinjaShuriken",
            HumanoidRootPart.CFrame * CFrame.new(5, 10 + i, 20),
            Vector3.new()
        )
    end)

    repeat
        task.wait()
    until shuriken

    local sticky = shuriken:WaitForChild("StickyPart")

    for attempt = 1, 30 do
        SetNetworkOwner:FireServer(sticky, sticky.CFrame)

        local owner = sticky:FindFirstChild("PartOwner")

        if owner and owner.Value == LocalPlayer.Name then
            break
        end

        task.wait()
    end

    for _, part in ipairs(shuriken:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanTouch = false
            part.CanQuery = false
        end
    end

    sticky.AssemblyLinearVelocity = Vector3.new(0, 9e9, 0)

    Shurikens[#Shurikens + 1] = {
        Shuriken = shuriken,
        Sticky = sticky
    }

    shuriken.Name = "TsunamiShurk" .. i
end

if not OceanPart then
    return
end

for _, data in ipairs(Shurikens) do
    local sticky = data.Sticky

    if sticky and sticky.Parent then
        sticky.AssemblyLinearVelocity = Vector3.zero

        SetNetworkOwner:FireServer(sticky, sticky.CFrame)

        task.wait()

        StickyPartEvent:FireServer(
            sticky,
            OceanPart,
            CFrame.new(0, 3e9, 0)
        )

        task.wait(0.02)
    end
end