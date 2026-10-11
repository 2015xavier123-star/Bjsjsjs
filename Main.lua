-- ============================================================================
-- FULL FIX: INITIALIZATION, CORE SERVICES & BLOBMAN FEATURE LOGIC
-- ============================================================================

local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local generalChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local function autoSendChat(messageText)
	generalChannel:SendAsync(messageText)
end

-- Load Orion Library
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/Seven7-lua/Roblox/refs/heads/main/Librarys/Orion/Orion.lua')))()

-- Custom Galaxy Theme Configuration
OrionLib.Themes["AetherGalaxy"] = {
    Main = Color3.fromRGB(15, 12, 28),       -- Deep Space Dark Purple / Main Background
    Second = Color3.fromRGB(24, 20, 43),     -- Lighter Nebula Purple / Accent Frames
    Stroke = Color3.fromRGB(142, 68, 173),   -- Cosmic Purple/Violet / Borders
    Divider = Color3.fromRGB(0, 210, 255),   -- Cosmic Burst Red-Pink / Dividers
    Text = Color3.fromRGB(240, 240, 255),    -- Bright Starlight White / Main Text
    TextDark = Color3.fromRGB(130, 120, 150) -- Faded Space Dust Grey / Secondary Text
}
OrionLib.SelectedTheme = "AetherGalaxy"


autoSendChat("Script by AI_simp :P")


local variants = {
	"BlackHoleKick", "BlackHoleDetected", "BlackHole", "Black_Hole", "Blackhole",
	"Black-Hole", "BHole", "BH", "VoidHole", "Void", "VoidSphere", "DarkHole",
	"DarkSphere", "DarkOrb", "GravityHole", "GravityOrb", "SpaceHole", "SpaceOrb",
	"Singularity", "SingularityOrb", "EventHorizon", "BlackSphere", "Anomaly",
	"AnomalyHole", "SupermassiveHole", "QuantumHole",
}

-- Initial startup notification
OrionLib:MakeNotification({
    Name = "Kick Detector",
    Content = "Detector is now active and monitoring.",
    Image = "rbxassetid://4483345998",
    Time = 3
})

local variantSet = {}
for _, n in ipairs(variants) do
	variantSet[n] = true
end

local function playKickSound()
	-- Insert your sound playback logic here if needed
end

local function notifyKick(displayName, username)
	print("[KickDetect]", displayName .. " (" .. username .. ") has been kicked")
	OrionLib:MakeNotification({
		Name = "Player Kicked!",
		Content = displayName .. " (@" .. username .. ") was detected getting kicked.",
		Image = "rbxassetid://4483345998",
		Time = 5
	})
end

local function getClosestPlayer(pos)
	local closestPlr = nil
	local closestDist = math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - pos).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPlr = plr
				end
			end
		end
	end
	return closestPlr
end

local function onKickObject(obj)
	task.wait(0.05)
	local pos
	if obj:IsA("BasePart") then
		pos = obj.Position
	elseif obj:IsA("Model") and obj.PrimaryPart then
		pos = obj.PrimaryPart.Position
	else
		local p = obj:FindFirstChildWhichIsA("BasePart", true)
		if p then pos = p.Position end
	end
	if not pos then return end
	local plr = getClosestPlayer(pos)
	if not plr then return end
	playKickSound()
	notifyKick(plr.DisplayName, plr.Name)
end

Workspace.ChildAdded:Connect(function(obj)
	if obj.Name == "BlackHoleKick" or obj.Name == "BlackHoleDetected" or variantSet[obj.Name] then
		onKickObject(obj)
	end
end)

print("kicking loaded")

-- Script Settings & States
local Settings = {
	BlobmanBeta = {
		ignoreFriends = false, 
		kickMethod = "Kick Double Hands",
		currentSide = "Left", 
		selectedTarget = nil,
		unsafeBlobman = false,
		FloatAmount = 16,
		KickDelay = 0.18,
		driftKickActive = false,
		kickAllV2Active = false,
		destroyGucciActive = false,
		ignoreHeights = {526.377685546875, 5.2832231521606445},
	},
	Loop = {
		WhitelistFriends = false,
	},
	ProtectFriends = false,
	KickAllV1 = false,
	AntiExplosion = false,
	AntiKillHamburger = false,
	AntiBlobmanKill = false,
	BarrierNoclip = false,
	FloatAmount = 16,
	currentSide = "Left",
}

local State = {
	allPCLDParts = nil,
	pcldWatcherConn = nil,
	driftKickConn = nil,
	driftKickLoopId = nil,
	kickAllV2Conn = nil,
}

-- Network Events
local grabEventsFolder = ReplicatedStorage:WaitForChild("GrabEvents")
local setNetworkOwnerEvent = grabEventsFolder:WaitForChild("SetNetworkOwner")
local destroyGrabLineEvent = grabEventsFolder:WaitForChild("DestroyGrabLine")
local menuToysFolder = ReplicatedStorage:WaitForChild("MenuToys")
local SpawnToyRF = menuToysFolder:WaitForChild("SpawnToyRemoteFunction")
local DeleteToyRE = menuToysFolder:WaitForChild("DestroyToy")

local function isProtectedPlayer(name)
	return false
end

local BlobmanBetaFeature = {}

function BlobmanBetaFeature.getLocalHum()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function BlobmanBetaFeature.getLocalRoot()
	local char = LocalPlayer.Character
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

function BlobmanBetaFeature.getInv()
	return Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
end

function BlobmanBetaFeature.SetNetworkOwner(part)
	pcall(function() setNetworkOwnerEvent:FireServer(part, BlobmanBetaFeature.getLocalRoot().CFrame) end)
end

function BlobmanBetaFeature.ungrab(part)
	pcall(function() destroyGrabLineEvent:FireServer(part) end)
end

function BlobmanBetaFeature.getBlobman()
	local hum = BlobmanBetaFeature.getLocalHum()
	if hum and hum.Sit and hum.SeatPart and hum.SeatPart.Parent then
		if hum.SeatPart.Parent.Name == "CreatureBlobman" then
			return hum.SeatPart.Parent
		end
	end
	local inv = BlobmanBetaFeature.getInv()
	if inv then
		local v = inv:FindFirstChild("CreatureBlobman")
		if v and v.ClassName == "Model" and v:FindFirstChild("VehicleSeat") then return v end
	end
	return nil
end

function BlobmanBetaFeature.findAnyBlobman()
	if not Settings.BlobmanBeta.unsafeBlobman then return nil end
	local myRoot = BlobmanBetaFeature.getLocalRoot()
	local closest, closestDist = nil, math.huge
	local function checkFolder(folder)
		if not folder then return end
		for _, obj in ipairs(folder:GetChildren()) do
			if obj.Name == "CreatureBlobman" and obj:IsA("Model") then
				local seat = obj:FindFirstChild("VehicleSeat")
				if seat then
					local dist = myRoot and (obj:GetPivot().Position - myRoot.Position).Magnitude or 0
					if dist < closestDist then
						closestDist = dist
						closest = obj
					end
				end
			end
		end
	end
	checkFolder(BlobmanBetaFeature.getInv())
	if not closest then
		for _, obj in ipairs(Workspace:GetChildren()) do
			if obj.Name == "CreatureBlobman" and obj:IsA("Model") then
				local seat = obj:FindFirstChild("VehicleSeat")
				if seat then
					local dist = myRoot and (obj:GetPivot().Position - myRoot.Position).Magnitude or 0
					if dist < 100000 and dist < closestDist then
						closestDist = dist
						closest = obj
					end
				end
			end
		end
	end
	return closest
end

function BlobmanBetaFeature.spawnBlobman()
	local myRoot = BlobmanBetaFeature.getLocalRoot()
	if not myRoot then return nil end
	local existing = BlobmanBetaFeature.getBlobman()
	if existing then return existing end
	local anyBlob = BlobmanBetaFeature.findAnyBlobman()
	if anyBlob and anyBlob:FindFirstChild("VehicleSeat") then return anyBlob end
	
	local inv = BlobmanBetaFeature.getInv()
	local SpawnedToy = nil
	if inv then
		local conn
		conn = inv.ChildAdded:Connect(function(toy)
			if toy.Name == "CreatureBlobman" and toy:IsA("Model") then
				SpawnedToy = toy
				conn:Disconnect()
			end
		end)
		task.spawn(function()
			pcall(function()
				SpawnToyRF:InvokeServer("CreatureBlobman", myRoot.CFrame * CFrame.new(3, 0, 0), Vector3.zero)
			end)
		end)
		local t = tick()
		while not SpawnedToy do
			if tick() - t > 2 then conn:Disconnect() break end
			task.wait(0.01)
		end
	end
	if SpawnedToy then
		SpawnedToy:WaitForChild("VehicleSeat", 2)
		return SpawnedToy
	end
	return BlobmanBetaFeature.getBlobman()
end

function BlobmanBetaFeature.ensureBlob()
	local blob = BlobmanBetaFeature.getBlobman() or BlobmanBetaFeature.findAnyBlobman() or BlobmanBetaFeature.spawnBlobman()
	if not blob or not blob:FindFirstChild("VehicleSeat") then return nil end
	local hum = BlobmanBetaFeature.getLocalHum()
	local myRoot = BlobmanBetaFeature.getLocalRoot()
	if hum and myRoot and not hum.Sit then
		myRoot.CFrame = blob.VehicleSeat.CFrame + Vector3.new(0, 2, 0)
		blob.VehicleSeat:Sit(hum)
	end
	return blob
end

function BlobmanBetaFeature.blobGrab(blob, target, side)
	if not blob then return end
	local detector = blob:FindFirstChild(side .. "Detector")
	local weld = detector and detector:FindFirstChild(side .. "Weld")
	local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript", true)
	local remote = script and script:FindFirstChild("CreatureGrab")
	if remote then pcall(function() remote:FireServer(detector, target, weld) end) end
end

-- ============================================================================
-- GLOBAL WINDOW INITIALIZATION & TABS SETUP
-- ============================================================================
_G.Window = nil

pcall(function()
    _G.Window = OrionLib:MakeWindow({
        Name = "🌌Aether 4.2🌌",
        HidePremium = false,
        SaveConfig = true,
        ConfigFolder = "OrionTest"
    })
end)

-- Initialize First Layer Tabs securely attached to global window pointer
local Kicks = _G.Window:MakeTab({Name = "Blobman👤", Icon = "", PremiumOnly = false})
local ConfigTab = _G.Window:MakeTab({Name = "Settings⚙️", Icon = "", PremiumOnly = false})

function BlobmanBetaFeature.blobDrop(blob, target, side)
	if not blob then return end
	local detector = blob:FindFirstChild(side .. "Detector")
	local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript", true)
	local remote = script and script:FindFirstChild("CreatureDrop")
	if remote then pcall(function() remote:FireServer(detector, target) end) end
end

function BlobmanBetaFeature.blobKick(blob, target, side)
	if not blob or not target then return end
	BlobmanBetaFeature.blobGrab(blob, BlobmanBetaFeature.getLocalRoot(), side)
	task.wait(0.02)
	BlobmanBetaFeature.SetNetworkOwner(target)
	task.wait(0.02)
	target.CFrame = target.CFrame + Vector3.new(0, Settings.BlobmanBeta.FloatAmount, 0)
	task.wait(0.02)
	BlobmanBetaFeature.ungrab(target)
	task.wait(0.02)
	BlobmanBetaFeature.blobGrab(blob, target, side)
	task.wait(0.02)
	BlobmanBetaFeature.blobDrop(blob, target, side)
	task.wait(0.02)
	BlobmanBetaFeature.ungrab(target)
end

function BlobmanBetaFeature.GetPlayerList()
	local list = {}
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and not isProtectedPlayer(plr.Name) then
			table.insert(list, plr.DisplayName .. " @" .. plr.Name)
		end
	end
	return list
end

function BlobmanBetaFeature.checkTarget()
	if not Settings.BlobmanBeta.selectedTarget then return nil end
	local target = Players:FindFirstChild(Settings.BlobmanBeta.selectedTarget)
	if not target or isProtectedPlayer(Settings.BlobmanBeta.selectedTarget) then return nil end
	return target
end

local driftAngle = 0
function BlobmanBetaFeature.startDriftKick(targetName)
	driftAngle = 0
	Settings.BlobmanBeta.driftKickActive = true
	local myLoopId = tick()
	State.driftKickLoopId = myLoopId
	local driftSkipCounter = 0

	if State.driftKickConn then task.cancel(State.driftKickConn) end
	State.driftKickConn = task.spawn(function()
		local target = Players:FindFirstChild(targetName)
		if not target or target == LocalPlayer then Settings.BlobmanBeta.driftKickActive = false return end
		local blob = BlobmanBetaFeature.ensureBlob()
		if not blob then Settings.BlobmanBeta.driftKickActive = false return end

		local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript") or blob:FindFirstChild("BlobmanSeatAndOwnerScript[old]")
		local grabRemote = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
		local dropRemote = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
		local Det = blob:FindFirstChild("RightDetector") or blob:FindFirstChild("LeftDetector")
		local Weld = Det and (Det:FindFirstChild("RightWeld") or Det:FindFirstChild("LeftWeld") or Det:FindFirstChildWhichIsA("Weld"))
		local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
		local blobRoot = blob.PrimaryPart or blob:FindFirstChild("HumanoidRootPart")

		if not GE or not grabRemote or not dropRemote or not Det or not Weld or not blobRoot then
			Settings.BlobmanBeta.driftKickActive = false return
		end

		while Settings.BlobmanBeta.driftKickActive do
			if myLoopId ~= State.driftKickLoopId then break end
			local tChar = target.Character
			local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
			local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

			if tChar and tRoot and tHum and tHum.Health > 0 then
				local bringStart = tick()
				while tick() - bringStart < 0.35 do
					if myLoopId ~= State.driftKickLoopId or not Settings.BlobmanBeta.driftKickActive then break end
					blobRoot.CFrame = tRoot.CFrame
					pcall(function()
						grabRemote:FireServer(Det, tRoot, Weld)
						if driftSkipCounter % 3 == 0 then
							GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
						end
					end)
					driftSkipCounter = (driftSkipCounter + 1) % 3
					RunService.Heartbeat:Wait()
				end
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

function BlobmanBetaFeature.stopDriftKick()
	Settings.BlobmanBeta.driftKickActive = false
	if State.driftKickConn then task.cancel(State.driftKickConn) State.driftKickConn = nil end
end

function BlobmanBetaFeature.startKickAllV2()
	Settings.BlobmanBeta.kickAllV2Active = true
	task.spawn(function()
		local allPlayers2 = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and not isProtectedPlayer(p.Name) then
				if Settings.BlobmanBeta.ignoreFriends then
					local isFriend = false
					pcall(function() isFriend = LocalPlayer:IsFriendsWith(p.UserId) end)
					if isFriend then continue end
				end
				local tChar = p.Character
				local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
				local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
				if tRoot and tHum and tHum.Health > 0 then
					table.insert(allPlayers2, p)
				end
			end
		end
		
		if #allPlayers2 == 0 then Settings.BlobmanBeta.kickAllV2Active = false return end
		local blob = BlobmanBetaFeature.ensureBlob()
		if not blob then Settings.BlobmanBeta.kickAllV2Active = false return end

		local MyBlob = blob
		local scr = MyBlob:FindFirstChild("BlobmanSeatAndOwnerScript") or MyBlob:FindFirstChild("BlobmanSeatAndOwnerScript[old]")
		local CreatureGrab = scr and scr:FindFirstChild("CreatureGrab")
		local CreatureRelease = scr and scr:FindFirstChild("CreatureRelease")
		local myHRP = BlobmanBetaFeature.getLocalRoot()

		for _, targetPlayer in ipairs(allPlayers2) do
			local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if targetRoot and myHRP then
				myHRP.CFrame = targetRoot.CFrame
				task.wait(0.02)
				for i = 1, 3 do
					pcall(function()
						CreatureGrab:FireServer(MyBlob.LeftDetector, targetRoot, MyBlob.LeftDetector.LeftWeld)
						CreatureRelease:FireServer(MyBlob.LeftDetector.LeftWeld)
					end)
					if i < 3 then task.wait(0.08) end
				end
			end
		end
		Settings.BlobmanBeta.kickAllV2Active = false
	end)
end

function BlobmanBetaFeature.destroyPlayerGucci(targetPlayer)
	if not targetPlayer or targetPlayer == LocalPlayer then return false end
	local folderName = targetPlayer.Name .. "SpawnedInToys"
	local toysFolder = Workspace:FindFirstChild(folderName)
	if not toysFolder then return false end
	local myChar = LocalPlayer.Character
	local myHum = myChar and myChar:FindFirstChild("Humanoid")
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHum or not myRoot then return false end
	for _, obj in ipairs(toysFolder:GetChildren()) do
		if obj.Name == "CreatureBlobman" or obj.Name == "TractorGreen" then
			local seat = obj:FindFirstChild("VehicleSeat") or obj:FindFirstChildWhichIsA("VehicleSeat", true)
			if seat then
				local safeSpot = myRoot.CFrame
				myRoot.CFrame = seat.CFrame
				myRoot.Velocity = Vector3.zero
				seat:Sit(myHum)
				task.wait(0.3)
				if myHum.SeatPart == seat then
					myHum.Sit = false
					task.wait(0.1)
					myRoot.CFrame = safeSpot
					task.wait(1)
					obj:Destroy()
					return true
				else
					myRoot.CFrame = safeSpot
				end
			end
		end
	end
	return false
end

function BlobmanBetaFeature.StartDestroyGucciLoop()
	while Settings.BlobmanBeta.destroyGucciActive do
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not isProtectedPlayer(player.Name) and player.Character then
				BlobmanBetaFeature.destroyPlayerGucci(player)
			end
		end
		task.wait(2)
	end
end

-- Dropdown Formatting Handlers
local function parsePlayerName(displayStr)
	local atPos = string.find(displayStr, " @")
	return atPos and string.sub(displayStr, atPos + 2) or displayStr
end

Kicks:AddSection({Name = "Target Selection"})

local targetDropdown = Kicks:AddDropdown({
	Name = "Select Target",
	Default = "",
	Options = BlobmanBetaFeature.GetPlayerList(),
	Callback = function(Value)
		Settings.BlobmanBeta.selectedTarget = Value ~= "" and parsePlayerName(Value) or nil
	end
})

local function refreshDropdown()
	pcall(function()
		targetDropdown:Refresh(BlobmanBetaFeature.GetPlayerList(), true)
	end)
end
Players.PlayerAdded:Connect(refreshDropdown)
Players.PlayerRemoving:Connect(refreshDropdown)

Kicks:AddSection({Name = "Kick Operations"})

Kicks:AddDropdown({
	Name = "Kick Method",
	Default = "Kick Double Hands",
	Options = {"Kick Double Hands", "Kick Left", "Kick Right"},
	Callback = function(Value)
		Settings.BlobmanBeta.kickMethod = Value
		Settings.BlobmanBeta.currentSide = (Value == "Kick Right") and "Right" or "Left"
	end
})

Kicks:AddButton({
	Name = "Kick Target",
	Callback = function()
		local target = BlobmanBetaFeature.checkTarget()
		local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		local blob = BlobmanBetaFeature.ensureBlob()
		if not root or not blob then return end

		task.spawn(function()
			if Settings.BlobmanBeta.kickMethod == "Kick Double Hands" then
				BlobmanBetaFeature.blobKick(blob, root, "Left")
				task.wait(0.05)
				BlobmanBetaFeature.blobKick(blob, root, "Right")
			else
				BlobmanBetaFeature.blobKick(blob, root, Settings.BlobmanBeta.currentSide)
			end
		end)
	end
})





Kicks:AddToggle({
	Name = "Drift Kick",
	Default = false,
	Callback = function(Value)
		if Value then
			local target = BlobmanBetaFeature.checkTarget()
			if target then BlobmanBetaFeature.startDriftKick(target.Name) end
		else
			BlobmanBetaFeature.stopDriftKick()
		end
	end
})

Kicks:AddButton({
	Name = "Kick All V2",
	Callback = function()
		BlobmanBetaFeature.startKickAllV2()
	end
})

Kicks:AddButton({
	Name = "Decimate Server",
	Callback = function()
       -- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Configuration
local GRAB_EVENTS = ReplicatedStorage:WaitForChild("GrabEvents")
local SET_NETWORK_OWNER = GRAB_EVENTS:WaitForChild("SetNetworkOwner")
local DESTROY_GRAB_LINE = GRAB_EVENTS:WaitForChild("DestroyGrabLine")

-- Tractor Configuration
local MENU_TOYS = ReplicatedStorage:WaitForChild("MenuToys")
local SPAWN_TOY_REMOTE = MENU_TOYS:WaitForChild("SpawnToyRemoteFunction")

local LocalPlayer = Players.LocalPlayer

-- Circle configuration
local CIRCLE_CENTER = Vector3.new(0, 500000, 0) 
local CIRCLE_RADIUS = 15 

-- Global Scope Active Queues
local targets = {}
local skyPositions = {}

-- Helper function to capture network ownership for a single target
local function secureOwnership(targetRoot)
	if not targetRoot or not targetRoot.Parent then return end
	local currentCFrame = targetRoot.CFrame
	for i = 1, 5 do
		SET_NETWORK_OWNER:FireServer(targetRoot, currentCFrame)
	end
end

-- Filter functions
local function hasInPlotActive(player)
	local pPlot = player:FindFirstChild("InPlot")
	if pPlot and (pPlot:IsA("BoolValue") or pPlot:IsA("ValueBase")) and pPlot.Value == true then
		return true
	end
	if player.Character then
		local cPlot = player.Character:FindFirstChild("InPlot")
		if cPlot and (cPlot:IsA("BoolValue") or cPlot:IsA("ValueBase")) and cPlot.Value == true then
			return true
		end
	end
	return false
end

local function isFriendWithMe(player)
	local isFriend = false
	pcall(function()
		isFriend = LocalPlayer:IsFriendsWith(player.UserId)
	end)
	return isFriend
end

-- Refreshes positions layout across all indexed players dynamically
local function recalculateSkyLayout()
	local count = #targets
	if count == 0 then return end
	
	skyPositions = {}
	for index, player in ipairs(targets) do
		local angle = (index / count) * (2 * math.pi)
		local offsetX = math.cos(angle) * CIRCLE_RADIUS
		local offsetZ = math.sin(angle) * CIRCLE_RADIUS
		skyPositions[player] = CFrame.new(CIRCLE_CENTER + Vector3.new(offsetX, 0, offsetZ))
	end
end

local function handleTractorSetup(myCharacter, myRootPart)
	local toyFolderName = LocalPlayer.Name .. "SpawnedInToys"
	local toyFolder = workspace:FindFirstChild(toyFolderName)
	
	if not toyFolder or #toyFolder:GetChildren() == 0 then
		print("[TRACTOR] No active tractor detected. Spawning TractorGreen...")
		SPAWN_TOY_REMOTE:InvokeServer(
			"TractorGreen",
			CFrame.new(122.63681030273438, -5.6761736869812012, 73.04888916015625, -0.54527461528778076, 0.29209139943122864, -0.78572148084640503, 0, 0.93732714653015137, 0.34845069050788879, 0.83825749158859253, 0.19000130891799927, -0.5111006498336792),
			Vector3.new(0, -123.04299926757812, 0)
		)
		toyFolder = workspace:WaitForChild(toyFolderName, 5)
	end
	
	local seat = nil
	if toyFolder then
		seat = toyFolder:FindFirstChildWhichIsA("VehicleSeat", true) or toyFolder:FindFirstChildWhichIsA("Seat", true)
	end
	
	if not seat then
		warn("[TRACTOR] Tractor folder found but couldn't locate a Seat! Proceeding to loop anyway.")
		return
	end
	
	local humanoid = myCharacter:WaitForChild("Humanoid")
	print("[TRACTOR] Attempting to board the vehicle seat...")
	
	while humanoid and not humanoid.Sit do
		if seat and seat.Parent then
			myRootPart.CFrame = seat.CFrame + Vector3.new(0, 1, 0)
			seat:Sit(humanoid)
		end
		task.wait(0.1)
	end
	
	print("[TRACTOR] Securely seated! Commencing attack sequence.")
end

local function runMultiAttemptFreezeCycle()
	local myCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local myRootPart = myCharacter:WaitForChild("HumanoidRootPart")
	
	handleTractorSetup(myCharacter, myRootPart)
	task.wait(0.5)
	
	-- ATTEMPT CAP REDUCTION: Changed from 5 maximum tries down to 3 focused attempts
	for attempt = 1, 1 do
		print("[CYCLE] Starting Loop Attempt #" .. tostring(attempt) .. " of 3")
		
		targets = {}
		local allPlayers = Players:GetPlayers()
		
		-- Gather fresh eligible targets currently left in the game
		for _, player in ipairs(allPlayers) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				if not isFriendWithMe(player) and not hasInPlotActive(player) then
					table.insert(targets, player)
				end
			end
		end
		
		local totalTargets = #targets
		if totalTargets == 0 then
			print("[SUCCESS] All targeted players have been emptied from the server! Stopping script.")
			break
		end
		
		recalculateSkyLayout()
		
		-- =======================================================
		-- STEP 1: SET NETWORK OWNER FOR EVERYONE FIRST
		-- =======================================================
		print("[PHASE 1] Grabbing remaining " .. tostring(totalTargets) .. " players sequentially...")
		for _, targetPlayer in ipairs(targets) do
			local targetCharacter = targetPlayer.Character
			local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
			
			if targetRoot and targetRoot.Parent then
				myRootPart.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
				task.wait(0.25) 
				secureOwnership(targetRoot)
				task.wait(0.15) 
			end
		end
		
		-- =======================================================
		-- STEP 2: TELEPORT ALL TO SKY POSITION & VERIFY NEATLY
		-- =======================================================
		print("[PHASE 2] Transporting targets and verifying neat positioning...")
		for _, targetPlayer in ipairs(targets) do
			local targetCharacter = targetPlayer.Character
			local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
			local skyCFrame = skyPositions[targetPlayer]
			
			if targetRoot and targetRoot.Parent and skyCFrame then
				targetCharacter:SetPrimaryPartCFrame(skyCFrame)
				
				local startTime = os.clock()
				while (os.clock() - startTime < 2.5) do
					if not targetRoot.Parent then break end
					targetCharacter:SetPrimaryPartCFrame(skyCFrame)
					targetRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					targetRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					
					if (targetRoot.Position - skyCFrame.Position).Magnitude <= 3 then
						break
					end
					secureOwnership(targetRoot)
					task.wait(0.1)
				end
			end
		end
		
		-- =======================================================
		-- STEP 3: MASS DROP SIMULTANEOUSLY WHILE RE-LOCKING VELOCITY
		-- =======================================================
		print("[PHASE 3] Teleports verified neatly. Mass dropping everyone simultaneously...")
		for _, targetPlayer in ipairs(targets) do
			local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if targetRoot and targetRoot.Parent then
				DESTROY_GRAB_LINE:FireServer(targetRoot)
			end
		end
		
		-- Background thread to keep their velocity locked at 0 while the main loop waits
		local keepLocked = true
		task.spawn(function()
			while keepLocked do
				for _, targetPlayer in ipairs(targets) do
					local targetCharacter = targetPlayer.Character
					local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
					local skyCFrame = skyPositions[targetPlayer]
					
					if targetRoot and targetRoot.Parent and skyCFrame then
						if not hasInPlotActive(targetPlayer) then
							targetCharacter:SetPrimaryPartCFrame(skyCFrame)
							targetRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							targetRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						end
					end
				end
				task.wait(0.1)
			end
		end)
		
		-- =======================================================
		-- STEP 4: REDUCED DELAY WAITING FOR KICK EMERGENCE
		-- =======================================================
		print("[PHASE 4] Drop executed. Waiting 15 seconds to observe server departures...")
		task.wait(15) -- Updated to exactly 15 seconds
		
		-- Kill the current background velocity lock thread before checking the remaining headcount
		keepLocked = false
		task.wait(0.5)
	end
	
	print("[SYSTEM] Completed maximum of 3 attempts or pool fully emptied.")
end

runMultiAttemptFreezeCycle()

	end
})

Kicks:AddToggle({
	Name = "Destroy Gucci",
	Default = false,
	Callback = function(Value)
		Settings.BlobmanBeta.destroyGucciActive = Value
		if Value then
			task.spawn(function()
				BlobmanBetaFeature.StartDestroyGucciLoop()
			end)
		end
	end
})

ConfigTab:AddToggle({
	Name = "Ignore Friends",
	Default = false,
	Callback = function(Value) Settings.BlobmanBeta.ignoreFriends = Value end
})

ConfigTab:AddToggle({
	Name = "Unsafe Blobman",
	Default = false,
	Callback = function(Value) Settings.BlobmanBeta.unsafeBlobman = Value end
})

ConfigTab:AddSlider({
	Name = "Float Amount",
	Min = 1, Max = 50, Default = 16, Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "studs",
	Callback = function(Value) Settings.BlobmanBeta.FloatAmount = Value end
})

ConfigTab:AddSlider({
	Name = "Kick Delay",
	Min = 0.01, Max = 1, Default = 0.18, Color = Color3.fromRGB(255,255,255), Increment = 0.01, ValueName = "s",
	Callback = function(Value) Settings.BlobmanBeta.KickDelay = Value end
})

local TpWalkSpeed = 16

-- Configuration & Anti-Grab Systems
_G.SETTINGS_ANTI_GRAB = false
local GHOST_SPEED = 16
local SYNC_TIMEOUT = 0.8
local CLEANUP_DELAY = 0.5

local characterEventsFolder = ReplicatedStorage:WaitForChild("CharacterEvents", 30)
local setNetworkOwnerEvent = grabEventsFolder:WaitForChild("SetNetworkOwner", 5)
local destroyGrabLineEvent = grabEventsFolder:WaitForChild("DestroyGrabLine", 5)
local ragdollRemoteEvent = characterEventsFolder:WaitForChild("RagdollRemote", 5)
local struggleEvent = characterEventsFolder:WaitForChild("Struggle", 5)
local isHeldValue = LocalPlayer:WaitForChild("IsHeld", 30)

local currentVisualClone = nil
local renderConnection = nil
local escapeConnection = nil
local teleportSpamConnection = nil
local jumpConnection = nil
local cleanupThread = nil

local MasterControl = nil
pcall(function()
	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule"))
	MasterControl = PlayerModule:GetControls()
end)

local function stripPartVisibilityAndQuery(part)
	if part:IsA("BasePart") then
		part.Transparency = 1
		part.LocalTransparencyModifier = 1
		part.CanQuery = false
		part.CastShadow = false
	elseif part:IsA("Decal") or part:IsA("Texture") then
		part.Transparency = 1
		part.LocalTransparencyModifier = 1
	end
end

local function applyPermanentStealth(character)
	if not character then return end
	for _, desc in ipairs(character:GetDescendants()) do
		stripPartVisibilityAndQuery(desc)
	end
	character.DescendantAdded:Connect(stripPartVisibilityAndQuery)
end

RunService.RenderStepped:Connect(function()
	local character = LocalPlayer.Character
	if character then
		for _, desc in ipairs(character:GetDescendants()) do
			if desc:IsA("BasePart") or desc:IsA("Decal") then
				desc.LocalTransparencyModifier = 1
				if desc:IsA("BasePart") then desc.CanQuery = false end
			end
		end
	end
	if currentVisualClone then
		for _, desc in ipairs(currentVisualClone:GetDescendants()) do
			if desc:IsA("BasePart") or desc:IsA("Decal") then
				desc.LocalTransparencyModifier = 1
				if desc:IsA("BasePart") then desc.CanQuery = false end
			end
		end
	end
end)

local function setMobileJumpButtonEnabled(enabled)
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end
	local touchGui = playerGui:FindFirstChild("TouchGui")
	if touchGui then
		local touchControlFrame = touchGui:FindFirstChild("TouchControlFrame")
		if touchControlFrame then
			local jumpButton = touchControlFrame:FindFirstChild("JumpButton")
			if jumpButton then
				jumpButton.Visible = enabled
				jumpButton.Active = enabled
			end
		end
	end
end

local function cleanupClone()
	if renderConnection then renderConnection:Disconnect() renderConnection = nil end
	if escapeConnection then escapeConnection:Disconnect() escapeConnection = nil end
	if teleportSpamConnection then teleportSpamConnection:Disconnect() teleportSpamConnection = nil end
	if jumpConnection then jumpConnection:Disconnect() jumpConnection = nil end

	if currentVisualClone then
		currentVisualClone:Destroy()
		currentVisualClone = nil
	end

	local camera = workspace.CurrentCamera
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and camera then camera.CameraSubject = humanoid end
end

local function verifyAndSyncPosition(realHrp, targetCFrame, timeout)
	local startTime = os.clock()
	while (os.clock() - startTime) < timeout do
		if not realHrp or not realHrp.Parent then break end
		realHrp.Velocity = Vector3.zero
		realHrp.RotVelocity = Vector3.zero
		realHrp.CFrame = targetCFrame
		if (realHrp.Position - targetCFrame.Position).Magnitude < 0.5 then return true end
		task.wait()
	end
	return false
end

local function handleTerminationAndCleanup()
	if cleanupThread then task.cancel(cleanupThread) cleanupThread = nil end
	local character = LocalPlayer.Character
	local realHrp = character and character:FindFirstChild("HumanoidRootPart")

	if realHrp and currentVisualClone then
		local cloneHrp = currentVisualClone:FindFirstChild("HumanoidRootPart")
		if cloneHrp then
			if teleportSpamConnection then teleportSpamConnection:Disconnect() teleportSpamConnection = nil end
			if escapeConnection then escapeConnection:Disconnect() escapeConnection = nil end
			verifyAndSyncPosition(realHrp, cloneHrp.CFrame, SYNC_TIMEOUT)
		end
	end

	cleanupThread = task.spawn(function()
		task.wait(CLEANUP_DELAY)
		cleanupClone()
		cleanupThread = nil
	end)
end

local function AttemptNetworkShip(part)
	if not part or not part.Parent then return false end
	local partOwner = part:FindFirstChild("PartOwner")
	if partOwner and partOwner.Value == LocalPlayer.Name then return true end
	for _ = 1, 5 do
		task.wait()
		local po = part:FindFirstChild("PartOwner")
		if po and po.Value == LocalPlayer.Name then return true end
	end
	return false
end

local function bindEscapeHooks(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	if not escapeConnection then
		escapeConnection = RunService.Heartbeat:Connect(function()
			if not isHeldValue.Value then return end
			hrp.AssemblyLinearVelocity = Vector3.zero
			if struggleEvent then pcall(function() struggleEvent:FireServer(LocalPlayer) end) end
			if ragdollRemoteEvent then pcall(function() ragdollRemoteEvent:FireServer(hrp, 0) end) end
		end)
	end

	if not teleportSpamConnection then
		teleportSpamConnection = RunService.Heartbeat:Connect(function()
			if not isHeldValue.Value then return end
			if currentVisualClone then
				local cloneHrpPart = currentVisualClone:FindFirstChild("HumanoidRootPart")
				if cloneHrpPart then
					hrp.Anchored = false
					if (hrp.Position - cloneHrpPart.Position).Magnitude > 0.02 then
						hrp.CFrame = cloneHrpPart.CFrame
					end
				end
			end
		end)
	end
end

local function createVisualClone(character)
	if cleanupThread and currentVisualClone then
		task.cancel(cleanupThread)
		cleanupThread = nil
		bindEscapeHooks(character)
		return
	end

	if currentVisualClone then cleanupClone() end
	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = false

	local cloneHrp = clone:FindFirstChild("HumanoidRootPart")
	local cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")
	local realHrp = character:FindFirstChild("HumanoidRootPart")

	if cloneHrp and realHrp then
		cloneHrp.CFrame = realHrp.CFrame
		cloneHrp.AssemblyLinearVelocity = Vector3.zero
		cloneHrp.AssemblyAngularVelocity = Vector3.zero
	end

	for _, desc in ipairs(clone:GetDescendants()) do
		if desc:IsA("LuaSourceContainer") or desc:IsA("Sound") then
			desc:Destroy()
		else
			stripPartVisibilityAndQuery(desc)
			if desc:IsA("BasePart") then
				desc.CanTouch = false
				desc.CanQuery = false
				desc.CanCollide = (desc == cloneHrp)
			end
		end
	end

	for _, realPart in ipairs(character:GetDescendants()) do
		if realPart:IsA("BasePart") then
			for _, ghostPart in ipairs(clone:GetDescendants()) do
				if ghostPart:IsA("BasePart") then
					local noCollide = Instance.new("NoCollisionConstraint")
					noCollide.Part0 = realPart
					noCollide.Part1 = ghostPart
					noCollide.Parent = ghostPart
				end
			end
		end
	end

	if cloneHumanoid then
		-- Safely uses your file variable directly
		cloneHumanoid.WalkSpeed = TpWalkSpeed
		cloneHumanoid.AutoRotate = true
		cloneHumanoid.PlatformStand = false
		cloneHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		cloneHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		cloneHumanoid:ChangeState(Enum.HumanoidStateType.Running)
	end

	clone.Parent = workspace
	currentVisualClone = clone

	local camera = workspace.CurrentCamera
	if cloneHumanoid and camera then camera.CameraSubject = cloneHumanoid end

	setMobileJumpButtonEnabled(true)

	jumpConnection = UserInputService.JumpRequest:Connect(function()
		if cloneHumanoid and cloneHumanoid.Health > 0 then
			cloneHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	renderConnection = RunService.RenderStepped:Connect(function()
		if not cloneHrp or not cloneHumanoid then return end
		
		-- Live Sync: Directly matches your real-time slider value instantly
		cloneHumanoid.WalkSpeed = TpWalkSpeed

		local rawMoveVector = Vector3.zero
		if MasterControl and MasterControl.GetMoveVector then rawMoveVector = MasterControl:GetMoveVector() end

		if MasterControl and MasterControl.GetActiveController then
			local activeCtrl = MasterControl:GetActiveController()
			if activeCtrl and (activeCtrl.IsJumping or (activeCtrl.GetIsJumping and activeCtrl:GetIsJumping())) then
				cloneHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end

		if rawMoveVector.Magnitude > 0 then
			local cameraCFrame = camera.CFrame
			local forward = Vector3.new(cameraCFrame.LookVector.X, 0, cameraCFrame.LookVector.Z).Unit
			local right = Vector3.new(cameraCFrame.RightVector.X, 0, cameraCFrame.RightVector.Z).Unit
			local worldMoveVector = (forward * -rawMoveVector.Z) + (right * rawMoveVector.X)
			if worldMoveVector.Magnitude > 0 then cloneHumanoid:Move(worldMoveVector.Unit, false) else cloneHumanoid:Move(Vector3.zero, false) end
		else
			cloneHumanoid:Move(Vector3.zero, false)
		end
	end)



	bindEscapeHooks(character)
end

local function setupPartOwnerListener(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	character.DescendantAdded:Connect(function(child)
		if not _G.SETTINGS_ANTI_GRAB then return end
		if not (child:IsA("StringValue") and child.Name == "PartOwner" and child.Value) then return end
		if child.Value == LocalPlayer.Name then return end

		local grabbedPart = child.Parent
		if not grabbedPart or not grabbedPart:IsA("BasePart") then return end

		AttemptNetworkShip(hrp)
		if destroyGrabLineEvent then pcall(function() destroyGrabLineEvent:FireServer(grabbedPart) end) end
	end)
end

local function onCharacterAdded(character)
	applyPermanentStealth(character)
	setupPartOwnerListener(character)
end

if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

isHeldValue.Changed:Connect(function(isBeingHeld)
	if isBeingHeld and _G.SETTINGS_ANTI_GRAB then
		local character = LocalPlayer.Character
		if character then createVisualClone(character) end
	else
		handleTerminationAndCleanup()
	end
end)

-- Camera Dynamics & Scriptable Projections
local camera = Workspace.CurrentCamera
local isCustomCameraEnabled = false
local renderConnectionCam = nil
local inputConnection = nil
local touchConnection = nil

local MIN_ZOOM = 0
local MAX_ZOOM = 100
local currentZoom = 20
local pitch = -15
local yaw = 0
local heightOffset = Vector3.new(0, 2, 0)

local function updateCamera()
	local character = LocalPlayer.Character
	if not character then return end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	if camera.CameraType ~= Enum.CameraType.Scriptable then camera.CameraType = Enum.CameraType.Scriptable end

	local targetPosition = humanoidRootPart.Position + heightOffset
	local cameraRotation = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
	local cameraPosition = targetPosition + cameraRotation * Vector3.new(0, 0, currentZoom)
	camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition)
end

local function setupMobileDragging()
	return UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not isCustomCameraEnabled then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			local activeTouchId = input.Identifier
			local moveConnection
			local endedConnection
			local lastPosition = input.Position

			moveConnection = UserInputService.InputChanged:Connect(function(moveInput, moveProcessed)
				if not isCustomCameraEnabled then moveConnection:Disconnect() return end
				if moveInput.Identifier == activeTouchId and moveInput.UserInputType == Enum.UserInputType.Touch and moveInput.Position then
					local delta = moveInput.Position - lastPosition
					lastPosition = moveInput.Position
					yaw = yaw - (delta.X * 0.4)
					pitch = math.clamp(pitch - (delta.Y * 0.4), -75, 75)
				end
			end)

			endedConnection = UserInputService.InputEnded:Connect(function(endInput)
				if endInput.Identifier == activeTouchId then
					if moveConnection then moveConnection:Disconnect() end
					if endedConnection then endedConnection:Disconnect() end
				end
			end)
		end
	end)
end

local function setupZoomHandling()
	return UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed or not isCustomCameraEnabled then return end
		if input.UserInputType == Enum.UserInputType.Gesture then
			if input.Delta.Z ~= 0 then currentZoom = math.clamp(currentZoom - (input.Delta.Z * 5), MIN_ZOOM, MAX_ZOOM) end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			currentZoom = math.clamp(currentZoom - (input.Delta.Y * 2), MIN_ZOOM, MAX_ZOOM)
		end
	end)
end

local function toggleCustomCamera(enable)
	if enable == nil then enable = not isCustomCameraEnabled end
	isCustomCameraEnabled = enable

	if isCustomCameraEnabled then
		camera.CameraType = Enum.CameraType.Scriptable
		renderConnectionCam = RunService.RenderStepped:Connect(updateCamera)
		touchConnection = setupMobileDragging()
		inputConnection = setupZoomHandling()
		print("Custom camera system: ENABLED")
	else
		if renderConnectionCam then renderConnectionCam:Disconnect() end
		if touchConnection then touchConnection:Disconnect() end
		if inputConnection then inputConnection:Disconnect() end
		camera.CameraType = Enum.CameraType.Custom
		print("Custom camera system: DISABLED")
	end
end

LocalPlayer.Chatted:Connect(function(message)
	if message:lower() == "/toggle" then toggleCustomCamera() end
end)

local highlightEnabled = false
local function updateHighlights()
	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:FindFirstChild("OwnershipHighlight") then part.OwnershipHighlight:Destroy() end
	end
	if not highlightEnabled then return end
	local Character = LocalPlayer.Character
	if not Character then return end

	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(Character) then
			if part.ReceiveAge == 0 or (part:GetRootPart() and part:GetRootPart().ReceiveAge == 0) then
				local isPlayer = false
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer and p.Character and part:IsDescendantOf(p.Character) then isPlayer = true break end
				end
				local highlight = Instance.new("SelectionBox")
				highlight.Name = "OwnershipHighlight"
				highlight.Adornee = part
				highlight.Color3 = isPlayer and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
				highlight.LineThickness = 0.05
				highlight.Parent = part
			end
		end
	end
end

_G.SetOwnershipHighlight = function(state)
	highlightEnabled = state
	updateHighlights()
end

task.spawn(function()
	while task.wait(0.5) do if highlightEnabled then updateHighlights() end end
end)

local scriptObj = LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("CharacterAndBeamMove")
local function setAntiLag(on) if scriptObj then scriptObj.Disabled = on end end
setAntiLag(false)

LocalPlayer.CharacterAdded:Connect(function()
	task.defer(function()
		scriptObj = LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("CharacterAndBeamMove")
		if scriptObj then scriptObj.Disabled = true end
	end)
end)

_G.Cam = _G.Cam or {}
_G.Cam.ThirdP = { Enabled = false, MinZoom = 0, MaxZoom = 100, Offset = Vector3.new(0, 2, 8) }

RunService.RenderStepped:Connect(function(deltaTime)
	local config = _G.Cam.ThirdP
	if not config or not config.Enabled then return end
	LocalPlayer.CameraMinZoomDistance = config.MinZoom
	LocalPlayer.CameraMaxZoomDistance = config.MaxZoom

	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart
		camera.CameraType = Enum.CameraType.Scriptable
		local zoomOffset = config.Offset
		local targetCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(camera.CFrame.Rotation.Y), 0) * CFrame.new(zoomOffset.X, zoomOffset.Y, zoomOffset.Z)
		camera.CFrame = CFrame.lookAt(targetCFrame.Position, rootPart.Position + Vector3.new(0, 2, 0))
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end)

local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
local CreateLine = GrabEvents and GrabEvents:FindFirstChild("CreateGrabLine")
shared.LagSettings = { MonsterLagEnabled = false }
local maxRange = 9e9
local distanceModifier = 1.0

local function getSpawnLocation() return Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) end
local function getRandomOffset()
	local currentMax = maxRange * distanceModifier
	return ((math.random() * 2) - 1) * currentMax, ((math.random() * 2) - 1) * currentMax
end

task.spawn(function()
	while CreateLine do
		if shared.LagSettings.MonsterLagEnabled then
			local spawnLocation = getSpawnLocation()
			if spawnLocation then
				local offsetX, offsetZ = getRandomOffset()
				CreateLine:FireServer(spawnLocation, CFrame.new(offsetX, 0, offsetZ))
			end
		end
		task.wait()
	end
end)

local AntiGrabEnabled = false
local antiExplosionConnection = nil
local antiExplosionCharConn = nil

local function setupAntiExplosion(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not hrp then return end
	if antiExplosionConnection then antiExplosionConnection:Disconnect() end

	antiExplosionConnection = Workspace.ChildAdded:Connect(function(model)
		if not Settings.AntiExplosion then return end
		local char = LocalPlayer.Character
		local h = char and char:FindFirstChild("Humanoid")
		local r = char and char:FindFirstChild("HumanoidRootPart")
		if not h or not r then return end
		if model:IsA("BasePart") and (model.Position - r.Position).Magnitude <= 20 then
			if h.SeatPart ~= nil then
				r.Anchored = true task.wait(0.03) r.AssemblyLinearVelocity = Vector3.zero r.Anchored = false
			else
				r.Anchored = true task.wait() h:ChangeState(Enum.HumanoidStateType.Running) r.Anchored = false h.AutoRotate = true
			end
		end
	end)
end

local antiKillConnection = nil
local function enableAntiKill()
	if antiKillConnection then antiKillConnection:Disconnect() end
	local toggle = false
	local lastSpawnAttempt = 0
	antiKillConnection = RunService.Heartbeat:Connect(function()
		if not Settings.AntiKillHamburger then return end
		local character = LocalPlayer.Character
		if not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then return end
		local spawnedFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
		local hamburger = spawnedFolder and spawnedFolder:FindFirstChild("FoodHamburger")
		if not hamburger or not hamburger:FindFirstChild("HoldPart") then
			if tick() - lastSpawnAttempt > 1 then
				lastSpawnAttempt = tick()
				pcall(function() SpawnToyRF:InvokeServer("FoodHamburger", CFrame.new(0, 300, 0), Vector3.zero) end)
			end
			toggle = false return
		end
		toggle = not toggle
		if toggle then pcall(function() hamburger.HoldPart.HoldItemRemoteFunction:InvokeServer(hamburger, character) end) else pcall(function() hamburger.HoldPart.DropItemRemoteFunction:InvokeServer(hamburger, CFrame.new(0, 300, 0), Vector3.zero) end) end
	end)
end

local function disableAntiKill()
	if antiKillConnection then antiKillConnection:Disconnect() antiKillConnection = nil end
	local spawnedFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
	if spawnedFolder then
		for _, hb in ipairs(spawnedFolder:GetChildren()) do
			if hb.Name == "FoodHamburger" and hb:FindFirstChild("HoldPart") then pcall(function() hb.HoldPart.DropItemRemoteFunction:InvokeServer(hb, CFrame.new(0, 300, 0), Vector3.zero) end) end
		end
		task.wait(0.1)
		for _, hb in ipairs(spawnedFolder:GetChildren()) do if hb.Name == "FoodHamburger" then pcall(function() DeleteToyRE:FireServer(hb) end) end end
	end
end

local antiBlobmanKillConnection = nil
local function enableAntiBlobmanKill()
	if antiBlobmanKillConnection then antiBlobmanKillConnection:Disconnect() end
	local lastUpdate = 0
	antiBlobmanKillConnection = RunService.Heartbeat:Connect(function()
		if not Settings.AntiBlobmanKill then return end
		if tick() - lastUpdate < 0.033 then return end
		lastUpdate = tick()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp or hum.Health <= 0 then return end
		hum.Sit = true
		hum:ChangeState(Enum.HumanoidStateType.Running)
		if camera then
			local lookVec = camera.CFrame.LookVector
			hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(lookVec.X, 0, lookVec.Z))
		end
	end)
end

local kickAllV1Thread = nil
local function startKickAllV1()
	if kickAllV1Thread then task.cancel(kickAllV1Thread) end
	kickAllV1Thread = task.spawn(function()
		local blob = BlobmanBetaFeature.getBlobman() or BlobmanBetaFeature.findAnyBlobman() or BlobmanBetaFeature.spawnBlobman()
		if not blob or not blob:FindFirstChild("VehicleSeat") then Settings.KickAllV1 = false return end
		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
		if not myHRP or not myHum then Settings.KickAllV1 = false return end

		while Settings.KickAllV1 do
			local targets = {}
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then table.insert(targets, {plr = plr, root = plr.Character.HumanoidRootPart}) end
			end
			for _, t in ipairs(targets) do
				if not Settings.KickAllV1 then break end
				if myHRP and t.root then
					myHRP.CFrame = t.root.CFrame task.wait(0.03)
					BlobmanBetaFeature.blobKick(blob, t.root, Settings.currentSide) task.wait(0.03)
					BlobmanBetaFeature.ungrab(myHRP) task.wait(0.03)
				end
			end
			task.wait(0.05)
		end
	end)
end

local function setBarrierNoclip()
	local Plots = Workspace:FindFirstChild("Plots")
	if not Plots then return end
	for i = 1, 5 do
		local plot = Plots:FindFirstChild("Plot" .. i)
		if plot and plot:FindFirstChild("Barrier") then
			for _, b in ipairs(plot.Barrier:GetChildren()) do if b:IsA("BasePart") then b.CanCollide = false end end
		end
	end
end

local function UnlockBarrier()
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local orig = LocalPlayer.Character.HumanoidRootPart.CFrame
	pcall(function() SpawnToyRF:InvokeServer("InstrumentWoodwindOcarina", CFrame.new(184.14, -5.54, 498.13), Vector3.new(0, 34, 0)) end)
	task.wait(0.3)
	local ocarina = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys"):FindFirstChild("InstrumentWoodwindOcarina")
	if ocarina and ocarina:FindFirstChild("HoldPart") then ocarina.HoldPart.HoldItemRemoteFunction:InvokeServer(ocarina, Workspace[LocalPlayer.Name]) end
	task.wait(0.3)
	LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(304.06, 25.77, 488.54) task.wait(0.15)
	if ocarina then pcall(function() DeleteToyRE:FireServer(ocarina) end) end task.wait(0.15)
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = orig end
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local setNetworkOwnerEvent = ReplicatedStorage:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")

-- Function wrapped and optimized for task.spawn
local function claimPlotAndLoadHouse()
    -- Wait 4 seconds before starting the process
    task.wait()

    -- Run your predefined function in the background
    task.spawn(UnlockBarrier)
    task.wait(4)

    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local targetPlot = nil
    
    -- Loop through plots 1 to 5 to find an unowned one
    for i = 1, 5 do
        local plotName = "Plot" .. i
        local plot = Workspace:WaitForChild("Plots"):WaitForChild(plotName)
        local ownersFolder = plot:WaitForChild("PlotSign"):WaitForChild("ThisPlotsOwners")
        
        -- Check if the owners folder has any values/children
        if #ownersFolder:GetChildren() == 0 then
            targetPlot = plot
            break
        end
    end
    
    -- If all 5 plots are owned, give up
    if not targetPlot then
        warn("All 5 plots checked, but all are owned. Giving up.")
        return
    end
    
    -- Step 1: Teleport to the chosen unowned plot base
    rootPart.CFrame = targetPlot:GetPivot()
    task.wait(1)
    
    -- Step 2: Teleport to the "Plus" part (index 8 child inside PlotSign)
    local plotSign = targetPlot:WaitForChild("PlotSign")
    local children = plotSign:GetChildren()
    local targetChild = children[8]
    
    if targetChild and targetChild:FindFirstChild("Plus") then
        local plusPart = targetChild.Plus
        rootPart.CFrame = plusPart.CFrame
        
        -- Step 3: Fire the Network Owner event for the Plus part
        setNetworkOwnerEvent:FireServer(plusPart, plusPart.CFrame)
    else
        warn("Could not find the Plus part at index 8 of PlotSign.")
        return
    end
    
    task.wait(1)
    
    -- Step 4: Fire the Network Owner event for the HouseLoadButton
    local houseLoadButton = targetPlot:WaitForChild("PlotSign")
        :WaitForChild("PlotOptionsSign")
        :WaitForChild("HouseLoadModel")
        :WaitForChild("HouseLoadButton")
        
    setNetworkOwnerEvent:FireServer(houseLoadButton)
    
    print("Finished")
end

-- Execute using task.spawn




local function Disconnecthrp()
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp then for _, obj in ipairs(hrp:GetChildren()) do if obj:IsA("Motor6D") or obj:IsA("Weld") then obj:Destroy() end end end
end

-- Screen Overlay Toggle Button Configuration
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "OrionToggleDot"
ToggleGui.ResetOnSpawn = false
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ToggleGui.Parent = game:GetService("CoreGui") end)
if not ToggleGui.Parent then ToggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local BlackDot = Instance.new("TextButton")
BlackDot.Name = "OpenButton"
BlackDot.Size = UDim2.new(0, 32, 0, 32)
BlackDot.Position = UDim2.new(0, 20, 0, 140)
BlackDot.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
BlackDot.Text = "UI"
BlackDot.TextColor3 = Color3.fromRGB(255, 255, 255)
BlackDot.Font = Enum.Font.SourceSansBold
BlackDot.TextSize = 14
BlackDot.Parent = ToggleGui
BlackDot.Visible = false

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = BlackDot


BlackDot.MouseButton1Click:Connect(function() if OrionLib and OrionLib.ToggleUI then OrionLib:ToggleUI() end end)

-- ============================================================================
-- CONNECT REMAINING INTERFACE TABS (SECURELY ATTACHED TO _G.Window)
-- ============================================================================

local infoTab = _G.Window:MakeTab({ Name = "Infoℹ️", Icon = "", PremiumOnly = false })
infoTab:AddLabel("Made by ai simp")
infoTab:AddLabel("HUGE thanks to TSBH_Adrenaline for making the attacks")

-- Tab 1: Player
local PlayerTab = _G.Window:MakeTab({
	Name = "Player🚹",
	Icon = "",
	PremiumOnly = false
})

local PlayerSection = PlayerTab:AddSection({
	Name = "Movement & Physics Toggles"
})

-- State tracking variables for custom physics overrides
_G.UseCustomWalkspeed = false
_G.UseCustomJump = false

PlayerSection:AddToggle({
	Name = "Toggle Custom Walkspeed",
	Default = false,
	Callback = function(Value)
		_G.UseCustomWalkspeed = Value
		-- Instantly revert character to normal speed if toggled off
		if not Value then
			pcall(function()
				game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
			end)
		end
	end
})

PlayerSection:AddToggle({
	Name = "Toggle Custom Jump",
	Default = false,
	Callback = function(Value)
		_G.UseCustomJump = Value
		-- Instantly revert character to normal jump power if toggled off
		if not Value then
			pcall(function()
				game.Players.LocalPlayer.Character.Humanoid.JumpPower = 50
			end)
		end
	end
})

local SliderSection = PlayerTab:AddSection({
	Name = "Movement & Physics Modifiers"
})

-- TP Walk configuration variables
local RunService = game:GetService("RunService")

local TpWalkConnection = nil

SliderSection:AddSlider({
	Name = "Walkspeed",
	Min = 16,
	Max = 500,
	Default = 16,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	Callback = function(Value)
		TpWalkSpeed = Value
		
		-- Reset normal character walkspeed to default so they don't stack
		pcall(function()
			game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
		end)
		
		-- Start the TP Walk loop if it isn't already running
		if not TpWalkConnection then
			TpWalkConnection = RunService.Heartbeat:Connect(function(deltaTime)
				pcall(function()
					-- ONLY execute if the toggle is actively turned ON
					if _G.UseCustomWalkspeed then
						local character = game.Players.LocalPlayer.Character
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						local rootPart = character:FindFirstChild("HumanoidRootPart")
						
						-- Only TP walk if the player is actively moving their stick/keys
						if humanoid and rootPart and humanoid.MoveDirection.Magnitude > 0 then
							-- Calculate next position based on move direction, custom speed, and frame time
							local targetVelocity = humanoid.MoveDirection * (TpWalkSpeed - 16)
							rootPart.CFrame = rootPart.CFrame + (targetVelocity * deltaTime)
						end
					end
				end)
			end)
		end
	end    
})

SliderSection:AddSlider({
	Name = "Jump Height",
	Min = 50,
	Max = 500,
	Default = 50,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	Callback = function(Value)
		-- ONLY apply value changes if the toggle is actively turned ON
		if _G.UseCustomJump then
			pcall(function()
				game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
			end)
		end
	end    
})

SliderSection:AddSlider({
	Name = "Gravity",
	Min = 0,
	Max = 196.2,
	Default = 196.2,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	Callback = function(Value)
		game.Workspace.Gravity = Value
	end    
})

SliderSection:AddToggle({
	Name = "Infinite Jump",
	Default = false,
	Callback = function(Value)
		_G.InfJump = Value
		game:GetService("UserInputService").JumpRequest:Connect(function()
			if _G.InfJump then
				game.Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid'):ChangeState("Jumping")
			end
		end)
	end
})

local ProtectionSection = PlayerTab:AddSection({
	Name = "Client Protection"
})

-- Store the service reference outside the hook to prevent recursive namecalls
local PlayersService = game:GetService("Players")
local oldHook

ProtectionSection:AddToggle({
	Name = "Anti-Local Kick",
	Default = false,
	Callback = function(Value)
		_G.AntiKick = Value
		
		if not oldHook then
			oldHook = hookmetamethod(game, "__namecall", function(self, ...)
				local method = getnamecallmethod()
				
				-- Fixed: Uses the pre-defined PlayersService variable instead of calling game:GetService inside the loop
				if _G.AntiKick and self == PlayersService.LocalPlayer and (method == "Kick" or method == "kick") then
					return nil 
				end
				
				return oldHook(self, ...)
			end)
		end
	end
})



-- Tab 2: Servers
local ServerTab = _G.Window:MakeTab({
	Name = "Servers💾",
	Icon = "",
	PremiumOnly = false
})

local ServerSection = ServerTab:AddSection({
	Name = "Server Management"
})

ServerSection:AddButton({
	Name = "Rejoin Server",
	Callback = function()
		local ts = game:GetService("TeleportService")
		local p = game.Players.LocalPlayer
		ts:Teleport(game.PlaceId, p)
	end
})

ServerSection:AddButton({
	Name = "Server Hop",
	Callback = function()
		local HttpService = game:GetService("HttpService")
		local TeleportService = game:GetService("TeleportService")
		
		-- Changed sortOrder=Asc to sortOrder=Desc to get the largest servers first
		local targetUrl = "https://roblox.com" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
		local success, result = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(targetUrl))
		end)
		
		if success and result and result.data then
			-- We loop backwards from the end of the data list to find a stable, 
			-- highly populated server that isn't completely full or your current one.
			for i = #result.data, 1, -1 do
				local server = result.data[i]
				if server.playing and server.maxPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then
					-- Leave 1 or 2 slots free so you don't get stuck on a "Server is full" loading loop
					if (server.maxPlayers - server.playing) >= 2 then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, game.Players.LocalPlayer)
						break
					end
				end
			end
		end
	end
})

ServerSection:AddToggle({
	Name = "Mobile Anti-AFK",
	Default = false,
	Callback = function(Value)
		_G.AntiAFK = Value
		if Value then
			task.spawn(function()
				local localPlayer = game:GetService("Players").LocalPlayer
				localPlayer.Idled:Connect(function()
					if _G.AntiAFK then
						local camera = workspace.CurrentCamera
						if camera then
							camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(1), 0)
							task.wait(0.1)
							camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(-1), 0)
						end
					end
				end)
			end)
		end
	end
})


local AntisTab = _G.Window:MakeTab({ Name = "Antis🛡", Icon = "", PremiumOnly = false })
local BarrierTab = _G.Window:MakeTab({ Name = "Barrier❌️", Icon = "", PremiumOnly = false })
local ScriptStuff = _G.Window:MakeTab({ Name = "Script helpers💻", Icon = "", PremiumOnly = false })
local CustomProtectTab = _G.Window:MakeTab({ Name = "Protect🔰", Icon = "", PremiumOnly = false })

-- Ensure OrionLib is already initialized in your main script before this block runs
-- Make sure you have a reference to your tab, e.g., local CustomProtectTab = OrionLib:MakeTab(...)

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Configuration Remotes
local GRAB_EVENTS = ReplicatedStorage:WaitForChild("GrabEvents")
local SET_NETWORK_OWNER = GRAB_EVENTS:WaitForChild("SetNetworkOwner")
local DESTROY_GRAB_LINE = GRAB_EVENTS:WaitForChild("DestroyGrabLine")

local LocalPlayer = Players.LocalPlayer

-- Custom Tracking Cache Table
local manualTargets = {}

-- =======================================================
-- HELPER FUNCTIONS FOR INTERFACE & LOGIC
-- =======================================================

-- Helper to generate the exact "Display Name (Username)" formatting string list
local function getPlayerDropdownList()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(list, player.DisplayName .. " (@" .. player.Name .. ")")
		end
	end
	return list
end

-- Helper to extract the actual Player object from the formatting string selection
local function getPlayerFromSelection(selectionString)
	if not selectionString then return nil end
	local username = string.match(selectionString, "@([%w_]+)%)$")
	if username then
		return Players:FindFirstChild(username)
	end
	return nil
end

-- Fast Rescue Execution Routine (Velocity-Zeroed Position Reset)
local function executeRescueSequence(targetPlayer)
	local myCharacter = LocalPlayer.Character
	local myRootPart = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
	local targetCharacter = targetPlayer.Character
	local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
	
	if not myRootPart or not targetRoot or not targetRoot.Parent then return end
	
	-- CHECK PROPERTY: targetRoot.Parent is the Character Model
	local partOwner = targetCharacter:FindFirstChild("PartOwner")
	
	-- IF I AM THE OWNER: Skip teleport, only fire DestroyGrabLine
	if partOwner and (partOwner:IsA("StringValue") or partOwner:IsA("ValueBase")) and partOwner.Value == LocalPlayer.Name then
		DESTROY_GRAB_LINE:FireServer(targetRoot)
		return
	end
	
	-- IF SOMEONE ELSE IS THE OWNER: Perform full rescue sequence
	local savedTargetCFrame = targetRoot.CFrame
	local originalPlayerCFrame = myRootPart.CFrame
	
	-- 1. Freeze Client Camera Context
	local camera = Workspace.CurrentCamera
	local originalCameraType = camera.CameraType
	local originalCameraCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- 2. Teleport to target player with a sharp 0.1s sync delay
	myRootPart.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
	task.wait(0.1) 
	
	-- 3. Grab ownership & instantly wipe out momentum forces
	for i = 1, 5 do
		SET_NETWORK_OWNER:FireServer(targetRoot, savedTargetCFrame)
	end
	
	targetRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	targetRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	
	-- 4. Snap target straight back to their saved spot and un-grab
	targetCharacter:SetPrimaryPartCFrame(savedTargetCFrame)
	DESTROY_GRAB_LINE:FireServer(targetRoot)
	
	-- 5. Return to your original coordinates accurately
	myRootPart.CFrame = originalPlayerCFrame
	
	-- 6. Restore camera focus smoothly
	camera.CFrame = originalCameraCFrame
	camera.CameraType = originalCameraType
end

-- =======================================================
-- ORIONLIB INTERFACE INTEGRATION ELEMENTS
-- =======================================================

local selectedDropdownValue = nil

-- 1. Create the Player Selector Dropdown UI
local PlayerDropdown = CustomProtectTab:AddDropdown({
	Name = "Select Targeted Player",
	Default = "None",
	Options = getPlayerDropdownList(),
	Callback = function(Value)
		selectedDropdownValue = Value
	end
})

-- Refresh the listing dynamically when players join or leave the server instance
Players.PlayerAdded:Connect(function()
	PlayerDropdown:Refresh(getPlayerDropdownList(), true)
end)
Players.PlayerRemoving:Connect(function(player)
	local index = table.find(manualTargets, player)
	if index then
		table.remove(manualTargets, index)
	end
	PlayerDropdown:Refresh(getPlayerDropdownList(), true)
end)

-- 2. Add Target Button UI element
CustomProtectTab:AddButton({
	Name = "Add Target to Rescue Queue",
	Callback = function()
		local playerInstance = getPlayerFromSelection(selectedDropdownValue)
		if playerInstance then
			if not table.find(manualTargets, playerInstance) then
				table.insert(manualTargets, playerInstance)
				OrionLib:MakeNotification({
					Name = "Target Added",
					Content = "Now tracking: " .. playerInstance.DisplayName,
					Time = 3
				})
			end
		else
			OrionLib:MakeNotification({
				Name = "Error",
				Content = "Please select a valid player from the dropdown first.",
				Time = 3
			})
		end
	end
})

-- 3. Remove Target Button UI element
CustomProtectTab:AddButton({
	Name = "Remove Target from Queue",
	Callback = function()
		local playerInstance = getPlayerFromSelection(selectedDropdownValue)
		if playerInstance then
			local index = table.find(manualTargets, playerInstance)
			if index then
				table.remove(manualTargets, index)
				OrionLib:MakeNotification({
					Name = "Target Removed",
					Content = "Stopped tracking: " .. playerInstance.DisplayName,
					Time = 3
				})
			else
				OrionLib:MakeNotification({
					Name = "Status Check",
					Content = playerInstance.DisplayName .. " was not in your tracking queue.",
					Time = 3
				})
			end
		end
	end
})

-- =======================================================
-- BACKGROUND PATROL PROCESS DEPLOYMENT
-- =======================================================

task.spawn(function()
	while true do
		for _, targetPlayer in ipairs(manualTargets) do
			if targetPlayer and targetPlayer.Parent == Players then
				
				-- Look for active instance state condition flag 'IsHeld'
				local isHeldVal = targetPlayer:FindFirstChild("IsHeld")
				if isHeldVal and (isHeldVal:IsA("BoolValue") or isHeldVal:IsA("ValueBase")) and isHeldVal.Value == true then
					
					pcall(function()
						executeRescueSequence(targetPlayer)
					end)
					
					-- Small sequence delay cycle between multiple grabbed items to let network packets leave cleanly
					task.wait(0.1)
				end
			end
		end
		task.wait()
	end
end)

-- Ensure OrionLib is already initialized in your main script before this block runs
-- Example: local OrionLib = loadstring(game:HttpGet(('https://githubusercontent.com')))()
-- Example: local Window = OrionLib:MakeWindow({Name = "Visual Controls", HidePremium = false, SaveConfig = true, ConfigFolder = "OrionTest"})

-- Services
local Lighting = game:GetService("Lighting")

-- Create the new Tab
local VisualsTab = _G.Window:MakeTab({
	Name = "Shaders & Skyboxes🌃",
	Icon = "",
	PremiumOnly = false
})

-- =======================================================
-- SHADER CONFIGURATIONS & COMPONENT MANAGER
-- =======================================================

-- Ensure core post-processing objects exist in Lighting
local function getOrCreateEffect(className, name)
	local effect = Lighting:FindFirstChild(name)
	if not effect then
		effect = Instance.new(className)
		effect.Name = name
		effect.Parent = Lighting
	end
	return effect
end

local colorCorrection = getOrCreateEffect("ColorCorrectionEffect", "CustomColorCorrection")
local bloom = getOrCreateEffect("BloomEffect", "CustomBloom")
local sunRays = getOrCreateEffect("SunRaysEffect", "CustomSunRays")

-- Set standard default balances (Disabled initially)
colorCorrection.Enabled = false
colorCorrection.Brightness = 0.1
colorCorrection.Contrast = 0.15
colorCorrection.Saturation = 0.2

bloom.Enabled = false
bloom.Intensity = 1
bloom.Size = 24
bloom.Threshold = 0.9

sunRays.Enabled = false
sunRays.Intensity = 0.1
sunRays.Spread = 1

-- =======================================================
-- SKYBOX ASSET DICTIONARY
-- =======================================================

local skyboxPresets = {
	["Default"] = {
		SkyboxBk = "rbxassetid://164344078", SkyboxDn = "rbxassetid://164344053", SkyboxFt = "rbxassetid://164344026",
		SkyboxLf = "rbxassetid://164344007", SkyboxRt = "rbxassetid://164343940", SkyboxUp = "rbxassetid://164344093"
	},
	["Cyberpunk Neon"] = {
		SkyboxBk = "rbxassetid://2312683072", SkyboxDn = "rbxassetid://2312683226", SkyboxFt = "rbxassetid://2312683397",
		SkyboxLf = "rbxassetid://2312683574", SkyboxRt = "rbxassetid://2312683713", SkyboxUp = "rbxassetid://2312683884"
	},
	["Deep Space"] = {
		SkyboxBk = "rbxassetid://154449886", SkyboxDn = "rbxassetid://154449911", SkyboxFt = "rbxassetid://154449931",
		SkyboxLf = "rbxassetid://154449955", SkyboxRt = "rbxassetid://154449975", SkyboxUp = "rbxassetid://154449993"
	},
	["Aesthetic Purple Pastel"] = {
		SkyboxBk = "rbxassetid://5854483733", SkyboxDn = "rbxassetid://5854483569", SkyboxFt = "rbxassetid://5854483321",
		SkyboxLf = "rbxassetid://5854483103", SkyboxRt = "rbxassetid://5854482811", SkyboxUp = "rbxassetid://5854482559"
	},
	["Realistic Sunset"] = {
		SkyboxBk = "rbxassetid://265320577", SkyboxDn = "rbxassetid://265321345", SkyboxFt = "rbxassetid://265321528",
		SkyboxLf = "rbxassetid://265321856", SkyboxRt = "rbxassetid://265322129", SkyboxUp = "rbxassetid://265322409"
	}
}

local function applySkybox(presetName)
	local assets = skyboxPresets[presetName]
	if not assets then return end
	
	-- Clean existing Skybox objects to avoid stacking overlays
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end
	
	local newSky = Instance.new("Sky")
	newSky.Name = "CustomSkyboxEffect"
	newSky.SkyboxBk = assets.SkyboxBk
	newSky.SkyboxDn = assets.SkyboxDn
	newSky.SkyboxFt = assets.SkyboxFt
	newSky.SkyboxLf = assets.SkyboxLf
	newSky.SkyboxRt = assets.SkyboxRt
	newSky.SkyboxUp = assets.SkyboxUp
	
	-- Extra atmospheric tuning to match look profiles
	if presetName == "Deep Space" then
		Lighting.TimeOfDay = "00:00:00"
		Lighting.Ambient = Color3.fromRGB(10, 10, 20)
	elseif presetName == "Realistic Sunset" then
		Lighting.TimeOfDay = "17:30:00"
		Lighting.Ambient = Color3.fromRGB(130, 90, 60)
	else
		Lighting.TimeOfDay = "14:00:00"
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
	end
	
	newSky.Parent = Lighting
end

-- =======================================================
-- ORIONLIB INTERFACE INTEGRATION ELEMENTS
-- =======================================================

VisualsTab:AddSection({
	Name = "Post-Processing Shaders"
})

-- 1. Color Correction Toggle
VisualsTab:AddToggle({
	Name = "Vibrant Color Correction",
	Default = false,
	Callback = function(Value)
		colorCorrection.Enabled = Value
	end
})

-- 2. Bloom Glare Toggle
VisualsTab:AddToggle({
	Name = "High Bloom Contrast (Glow)",
	Default = false,
	Callback = function(Value)
		bloom.Enabled = Value
	end
})

-- 3. Sun Rays Volume Toggle
VisualsTab:AddToggle({
	Name = "Volumetric Sun Rays",
	Default = false,
	Callback = function(Value)
		sunRays.Enabled = Value
	end
})

VisualsTab:AddSection({
	Name = "Atmospheric Skyboxes"
})

-- Extract keys from skyboxPresets array for drop list construction
local dropdownOptions = {}
for name, _ in pairs(skyboxPresets) do
	table.insert(dropdownOptions, name)
end
table.sort(dropdownOptions) -- Keep it sorted alphabetically

-- 4. Skybox Selector Dropdown
VisualsTab:AddDropdown({
	Name = "Change Atmosphere/Skybox",
	Default = "Default",
	Options = dropdownOptions,
	Callback = function(Value)
		pcall(function()
			applySkybox(Value)
		end)
	end
})


AntisTab:AddToggle({ Name = "Iso anti V5", Default = false, Callback = function(Value) _G.SETTINGS_ANTI_GRAB = Value end })
AntisTab:AddToggle({ Name = "Antigrab by TSBH", Default = false, Callback = function(Value) AntiGrabEnabled = Value end })
AntisTab:AddToggle({ Name = "Anti Explosion", Default = false, Callback = function(Value) Settings.AntiExplosion = Value setupAntiExplosion(LocalPlayer.Character) end })
AntisTab:AddToggle({ Name = "Anti Kill (Hamburger)", Default = false, Callback = function(Value) Settings.AntiKillHamburger = Value if Value then enableAntiKill() else disableAntiKill() end end })
AntisTab:AddToggle({ Name = "Anti Lag", Default = false, Callback = function(Value) setAntiLag(Value) end })
AntisTab:AddToggle({ Name = "Anti Blobman Kill", Default = false, Callback = function(Value) Settings.AntiBlobmanKill = Value enableAntiBlobmanKill() end })

BarrierTab:AddButton({ Name = "Unlock Barrier (V1)", Callback = function() task.spawn(UnlockBarrier) end })
BarrierTab:AddToggle({ Name = "Barrier Noclip", Default = false, Callback = function(Value) Settings.BarrierNoclip = Value setBarrierNoclip() end })

ScriptStuff:AddToggle({ Name = "Enable void", Default = true, Callback = function(Value) Workspace.FallHeightEnabled = Value end })
ScriptStuff:AddButton({ Name = "Tsunami", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/2015xavier123-star/Bjsjsjs/refs/heads/main/tsunami.lua"))() end })
ScriptStuff:AddButton({ Name = "Disconnect hrp", Callback = function() task.spawn(Disconnecthrp) end })

-- Ensure ScriptStuff tab is defined above this block in your script:
-- local ScriptStuff = Window:MakeTab({Name = "ScriptStuff", Icon = "rbxassetid://4483362458", Premium = false})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local state = {
    plotName = "Plot3",
    autoTP = false,
    ownerOnly = true,
    hasTriggered = false,
    lastCFrame = nil,
    timeValue = nil,
}

local function OrionNotify(title, msg)
    OrionLib:MakeNotification({
        Name = title,
        Content = msg,
        Image = "rbxassetid://4483362458",
        Time = 3
    })
end

local function CheckPlotOwner(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false, "Plots missing" end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false, plotName .. " missing" end
    local ownerName = ""
    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local ownersFolder = plotSign:FindFirstChild("ThisPlotsOwners")
        if ownersFolder then
            for _, child in ipairs(ownersFolder:GetChildren()) do
                if child:IsA("StringValue") or child:IsA("ObjectValue") then
                    local v = tostring(child.Value)
                    if v ~= "" then ownerName = v break end
                end
                if child.Name == "Value" then
                    ownerName = tostring(child.Value)
                    break
                end
            end
            local valObj = ownersFolder:FindFirstChild("Value")
            if valObj then ownerName = tostring(valObj.Value) end
        end
    end
    if ownerName == "" then
        for _, desc in ipairs(plot:GetDescendants()) do
            if (desc.Name == "Value" or desc.Name == "Owner") and (desc:IsA("StringValue") or desc:IsA("ObjectValue")) then
                ownerName = tostring(desc.Value)
                if ownerName ~= "" then break end
            end
        end
    end
    if ownerName == LocalPlayer.Name or ownerName == "VyzenAlt" or ownerName == "VYZEN_NN" then
        return true, ownerName
    end
    return false, ownerName ~= "" and ownerName or "None"
end

local function FindTimeRemaining(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        local plot = plots:FindFirstChild(plotName or "Plot3")
        if plot then
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc.Name == "TimeRemainingNum" and (desc:IsA("IntValue") or desc:IsA("NumberValue")) then
                    return desc
                end
            end
        end
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "TimeRemainingNum" and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v
        end
    end
    return nil
end

local function TeleportToPlotHouse(plotName)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local plots = workspace:FindFirstChild("Plots")
    local plot = plots and plots:FindFirstChild(plotName or "Plot3")
    if not plot then
        OrionNotify("Teleport Error", (plotName or "Plot3") .. " not found")
        return
    end
    local house = plot:FindFirstChild("House", true)
    if not house then
        OrionNotify("Teleport Error", "House not found")
        return
    end
    local targets = {"BigFatTree", "BigSkinTree", "FireLog", "Deck", "Chimney", "Chimney2", "BottomTrim"}
    local targetPart = nil
    for _, name in ipairs(targets) do
        local obj = house:FindFirstChild(name, true)
        if obj then
            if obj:IsA("BasePart") then targetPart = obj break end
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then targetPart = part break end
        end
    end
    if not targetPart then
        targetPart = house:FindFirstChildWhichIsA("BasePart", true)
    end
    if targetPart then
        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 8, 0)
        OrionNotify("Teleported", "Landed on " .. targetPart.Name)
    else
        hrp.CFrame = house:GetPivot() + Vector3.new(0, 10, 0)
        OrionNotify("Teleported", "Used House pivot")
    end
    task.delay(2, function()
        if state.lastCFrame and character and character.Parent and hrp and hrp.Parent then
            hrp.CFrame = state.lastCFrame
            OrionNotify("Returned", "Returned to original position")
        end
    end)
end

local function CheckAndTeleport()
    if not state.timeValue or not state.timeValue.Parent then
        state.timeValue = FindTimeRemaining(state.plotName)
    end
    local isOwner = CheckPlotOwner(state.plotName)
    if state.timeValue then
        local val = state.timeValue.Value
        if val > 9 then
            state.hasTriggered = false
        end
        if val == 8 and not state.hasTriggered then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then state.lastCFrame = hrp.CFrame end
        end
        if val <= 6 and not state.hasTriggered then
            if (not state.ownerOnly) or isOwner then
                state.hasTriggered = true
                OrionNotify("Auto TP Triggered", "Timer: " .. tostring(val) .. "s - TPing to house")
                TeleportToPlotHouse(state.plotName)
                return true
            end
        end
    end
    return false
end

-- UI elements loaded directly under the ScriptStuff tab
local StatusLabel = ScriptStuff:AddLabel(state.plotName .. " | Timer: N/A | Owner: ...")

ScriptStuff:AddDropdown({
    Name = "Select Plot Target",
    Default = state.plotName,
    Options = {"Plot1", "Plot2", "Plot3", "Plot4", "Plot5"},
    Callback = function(Option)
        state.plotName = Option
        state.timeValue = nil
        state.hasTriggered = false
        OrionNotify("Plot Changed", "Selected " .. Option)
    end,
})

ScriptStuff:AddToggle({
    Name = "Auto TP (Timer <= 6s)",
    Default = state.autoTP,
    Callback = function(Value)
        state.autoTP = Value
        state.hasTriggered = false
        state.timeValue = FindTimeRemaining(state.plotName)
        OrionNotify("Auto TP", Value and ("Watching " .. state.plotName) or "Auto TP Disabled")
    end,
})

ScriptStuff:AddToggle({
    Name = "Only When I Own Plot",
    Default = state.ownerOnly,
    Callback = function(Value)
        state.ownerOnly = Value
    end,
})

ScriptStuff:AddButton({
    Name = "Force TP To House Now",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then state.lastCFrame = hrp.CFrame end
        TeleportToPlotHouse(state.plotName)
    end,
})

task.spawn(function()
    local lastStatusUpdate = 0
    while true do
        if state.autoTP then
            CheckAndTeleport()
        else
            if not state.timeValue or not state.timeValue.Parent then
                state.timeValue = FindTimeRemaining(state.plotName)
            end
        end
        local now = tick()
        if now - lastStatusUpdate > 0.5 then
            lastStatusUpdate = now
            local isOwner, ownerInfo = CheckPlotOwner(state.plotName)
            local val = (state.timeValue and state.timeValue.Parent) and state.timeValue.Value or "N/A"
            
            StatusLabel:Set(state.plotName .. " | Timer: " .. tostring(val) .. "s | Owner: " .. tostring(ownerInfo))
        end
        task.wait(0.15)
    end
end)


ServerTab:AddToggle({ Name = "Lag server", Default = false, Callback = function(Value) shared.LagSettings.MonsterLagEnabled = Value end })

PlayerTab:AddButton({ Name = "Multicolor&FurtherReach", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-Multicolor-and-FurtherReach-224379"))()
 end })
ScriptStuff:AddButton({ Name = "Inf Yield", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
 end })
ScriptStuff:AddButton({ Name = "Dex++", Callback = function() loadstring(game:HttpGet("https://scriptblox.com/raw/Universal-Script-Dex-PlusPlus-Decompiler-Fix-206651"))()
 end })
ScriptStuff:AddButton({ Name = "Cobalt", Callback = function() --[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
loadstring(game:HttpGet("https://raw.githubusercontent.com/Wortexios/CobaltSpy/refs/heads/main/Cobalt"))()
 end })

local ToyMod = _G.Window:MakeTab({ Name = "Toy mod🎩", Icon = "", PremiumOnly = false })

local hsection = ToyMod:AddSection({
    Name = "House plots"
})
ToyMod:AddButton({
	Name = "Setup ToyMod",
	Callback = function()
		task.spawn(claimPlotAndLoadHouse)
	end
})
local msection = ToyMod:AddSection({
    Name = "Midi"
})

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local displayText = "HELLO 123"
local isEnabled = false
local currentSpeedSetting = 10
local ON_HEAD = true
local HEAD_HEIGHT = 8
local MAKER_SPACING = 7.5
local ROTATION_STEP = -09

local frameDuration = 0.35 - currentSpeedSetting * 0.03
local scrollOffset, lastUpdate = 0, 0
local GrabEvents, SetNetworkOwner, ToyFolder
local MidiMakers = {}
local rows = {"A","B","C","D","E","F","G","H"}
local grid, canvas = {}, {}

local rawFont = {
A="00111100/01100110/01100110/01111110/01100110/01100110/01100110/00000000",
B="01111100/01100110/01100110/01111100/01100110/01100110/01111100/00000000",
C="00111100/01100110/01100000/01100000/01100000/01100110/00111100/00000000",
D="01111000/01101100/01100110/01100110/01100110/01101100/01111000/00000000",
E="01111110/01100000/01100000/01111100/01100000/01100000/01111110/00000000",
F="01111110/01100000/01100000/01111100/01100000/01100000/01100000/00000000",
G="00111100/01100110/01100000/01101110/01100110/01100110/00111100/00000000",
H="01100110/01100110/01100110/01111110/01100110/01100110/01100110/00000000",
I="00111000/00010000/00010000/00010000/00010000/00010000/00111000/00000000",
J="00001110/00000110/00000110/00000110/00000110/01100110/00111100/00000000",
K="01100110/01101100/01111000/01110000/01111000/01101100/01100110/00000000",
L="01100000/01100000/01100000/01100000/01100000/01100000/01111110/00000000",
M="01100011/01110111/01111111/01101011/01100011/01100011/01100011/00000000",
N="01100110/01110110/01111110/01101110/01100110/01100110/01100110/00000000",
O="00111100/01100110/01100110/01100110/01100110/01100110/00111100/00000000",
P="01111100/01100110/01100110/01111100/01100000/01100000/01100000/00000000",
Q="00111100/01100110/01100110/01100110/01101110/01100110/00111111/00000011",
R="01111100/01100110/01100110/01111100/01111000/01101100/01100110/00000000",
S="00111100/01100110/00110000/00011100/00011000/01100110/00111100/00000000",
T="01111110/00011000/00011000/00011000/00011000/00011000/00011000/00000000",
U="01100110/01100110/01100110/01100110/01100110/01100110/00111100/00000000",
V="01100110/01100110/01100110/01100110/00111100/00111100/00011000/00000000",
W="01100011/01100011/01100011/01101011/01111111/00110110/00110110/00000000",
X="01100110/01100110/00111100/00011000/00111100/01100110/01100110/00000000",
Y="01100110/01100110/01100110/00111100/00011000/00011000/00011000/00000000",
Z="01111110/00000110/00001100/00011000/00110000/01100000/01111110/00000000",
["0"]="00111100/01100110/01101110/01111110/01110110/01100110/00111100/00000000",
["1"]="00011000/00111000/01011000/00011000/00011000/00011000/01111110/00000000",
["2"]="00111000/01100110/00000110/00011100/00110000/01100000/01111110/00000000",
["3"]="00111100/01100110/00000110/00111100/00000110/01100110/00111100/00000000",
["4"]="00001100/00011100/00110100/01100100/01111110/00000100/00000100/00000000",
["5"]="01111110/01100000/01111100/00000110/00000110/01100110/00111100/00000000",
["6"]="00111100/01100000/01100000/01111100/01100110/01100110/00111100/00000000",
["7"]="01111110/00000110/00001100/00011000/00110000/00110000/00110000/00000000",
["8"]="00111100/01100110/01100110/00111100/01100110/01100110/00111100/00000000",
["9"]="00111100/01100110/01100110/00111110/00000110/00000110/00111100/00000000",
["!"]="00011000/00011000/00011000/00011000/00000000/00011000/00011000/00000000",
["?"]="00111000/01100110/00000110/00011100/00011000/00000000/00011000/00000000",
["_"]="00000000/00000000/00000000/00000000/00000000/00000000/01111110/00000000",
["%"]="01100110/01100100/00001100/00011000/00110000/01001110/01001100/00000000",
["^"]="00011000/00111100/01100110/00000000/00000000/00000000/00000000/00000000",
["#"]="00101000/00101000/01111100/00101000/01111100/00101000/00101000/00000000",
["@"]="00111100/01100110/01111110/01101110/01101110/01100000/00111110/00000000"
}

local font = {}
for ch, encoded in pairs(rawFont) do
    font[ch] = {}
    for line in encoded:gmatch("[^/]+") do
        local row = {}
        for i = 1, #line do
            row[i] = tonumber(line:sub(i, i))
        end
        table.insert(font[ch], row)
    end
end

local blank = {}
for r = 1, 8 do
    blank[r] = {0,0,0,0,0,0,0,0}
end

local function refreshObjects()
    GrabEvents = RS:FindFirstChild("GrabEvents")
    SetNetworkOwner = GrabEvents and GrabEvents:FindFirstChild("SetNetworkOwner")
    ToyFolder = workspace:FindFirstChild(`{LocalPlayer.Name}SpawnedInToys`)

    local found = {}
    if ToyFolder then
        for _, obj in ipairs(ToyFolder:GetChildren()) do
            if obj.Name == "MidiMaker" then
                table.insert(found, obj)
            end
        end
    end

    MidiMakers = found
    return SetNetworkOwner ~= nil and #MidiMakers > 0
end

local function rebuildGrid()
    grid = {}
    for i, _ in ipairs(MidiMakers) do
        grid[i] = {}
        for _, r in ipairs(rows) do
            grid[i][r] = {0,0,0,0,0,0,0,0}
        end
    end
end

local function layoutMakers()
    if not ON_HEAD then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local count = #MidiMakers
    if count == 0 then return end

    local dynamicSpacing = tonumber(MAKER_SPACES) or 8
    local firstMaker = MidiMakers[1]
    if firstMaker then
        if firstMaker:IsA("Model") then
            dynamicSpacing = firstMaker:GetExtentsSize().X
        elseif firstMaker:IsA("BasePart") then
            dynamicSpacing = firstMaker.Size.X
        end
    end

    local hrpCFrame = hrp.CFrame
    local flatLook = Vector3.new(hrpCFrame.LookVector.X, 0, hrpCFrame.LookVector.Z).Unit
    local flatRight = Vector3.new(hrpCFrame.RightVector.X, 0, hrpCFrame.RightVector.Z).Unit
    local flatCFrame = CFrame.fromMatrix(hrpCFrame.Position, flatRight, Vector3.new(0, 1, 0), -flatLook)

    for i, maker in ipairs(MidiMakers) do
        if maker and maker.Parent then
            local offsetMultiplier = (i - (count + 1) / 2)
            local relativeOffset = Vector3.new(offsetMultiplier * dynamicSpacing, HEAD_HEIGHT, 0)
            local cf = flatCFrame * CFrame.new(relativeOffset) * CFrame.Angles(math.rad(-90), 0, 0)

            if maker:IsA("Model") then
                maker:PivotTo(cf)
            elseif maker:IsA("BasePart") then
                maker.CFrame = cf
            end
        end
    end
end

local function buildCanvas(text)
    local result = {}
    for r = 1, 8 do
        result[r] = {}
        for _ = 1, 8 do
            table.insert(result[r], 0)
        end
    end

    for i = 1, #text do
        local ch = text:sub(i, i)
        local glyph = font[ch] or blank

        for r = 1, 8 do
            for c = 1, 8 do
                table.insert(result[r], glyph[r][c] or 0)
            end
        end

        local gap = ch == " " and 2 or 1
        if ch == "!" or ch == "?" or ch == "_" or ch == "%" or ch == "^" or ch == "#" or ch == "@" then
            gap = 0
        end
        for r = 1, 8 do
            for _ = 1, gap do
                table.insert(result[r], 0)
            end
        end
    end

    for r = 1, 8 do
        for _ = 1, 8 do
            table.insert(result[r], 0)
        end
    end

    canvas = result
    scrollOffset = 0
end

local function getFrame(offset)
    local frame = {}
    local width = #MidiMakers * 8
    local total = #canvas[1]
    if total == 0 then return frame end

    for r = 1, 8 do
        frame[r] = {}
        for c = 1, width do
            local index = ((offset + c - 1) % total) + 1
            frame[r][c] = canvas[r][index] or 0
        end
    end
    return frame
end

local function drawFrame(frame)
    if not SetNetworkOwner or not SetNetworkOwner.Parent then
        return false
    end

    if #grid ~= #MidiMakers then
        rebuildGrid()
    end

    local totalMakers = #MidiMakers

    for i, maker in ipairs(MidiMakers) do
        if not maker or not maker.Parent then return false end

        local displayOrderIndex = (totalMakers - i)

        for r, rowName in ipairs(rows) do
            for c = 1, 8 do
                local pixel = frame[r] and frame[r][(displayOrderIndex * 8) + c] or 0
                local old = grid[i][rowName][c]

                if pixel ~= old then
                    local part = maker:FindFirstChild(rowName .. c)
                    if part and part:IsA("BasePart") then
                        -- FIX: Toggle visual transparency states instead of applying physical CFrame movement steps
                        part.LocalTransparencyModifier = (pixel == 1) and 0 or 1
                        
                        SetNetworkOwner:FireServer(part, part.CFrame)
                        grid[i][rowName][c] = pixel
                    end
                end
            end
        end
    end

    return true
end


    return true
end

buildCanvas(displayText:upper())
refreshObjects()
rebuildGrid()

RunService.Heartbeat:Connect(function()
    if ON_HEAD then
        layoutMakers()
    end

    if not isEnabled then return end
    
    local calculatedDuration = 0.35 - (math.clamp(tonumber(currentSpeedSetting) or 8, 1, 11) * 0.03)
    if os.clock() - lastUpdate < calculatedDuration then return end
    lastUpdate = os.clock()

    local oldCount = #MidiMakers
    refreshObjects()
    if oldCount ~= #MidiMakers then rebuildGrid() end
    if #MidiMakers == 0 then return end

    drawFrame(getFrame(scrollOffset))
    scrollOffset = (scrollOffset + 1) % #canvas[1]
end)




msection:AddToggle({
    Name = "Enable Drawer",
    Default = false,
    Callback = function(Value)
        isEnabled = Value
    end    
})

msection:AddToggle({
    Name = "Ontop head",
    Default = false,
    Callback = function(Value)
        ON_HEAD = Value
    end    
})

msection:AddTextbox({
    Name = "Input",
    Default = "Hello123",
    TextDisappear = false,
    Callback = function(Value)
        displayText =Value
    end	  
})

msection:AddTextbox({
    Name = "Scrollspeed",
    Default = "8",
    TextDisappear = false,
    Callback = function(Value)
        currentSpeedSetting =Value
    end	  
})

msection:AddTextbox({
    Name = "Spaces",
    Default = "8",
    TextDisappear = false,
    Callback = function(Value)
        MAKER_SPACES = Value
    end	  
})


local osection = ToyMod:AddSection({
    Name = "Objects"
})
local rsection = ToyMod:AddSection({
    Name = "Miscallenious"
})

-- Local variables to keep track of the code and loop state
local currentLuauCode = ""
local isSpamming = false

-- Add the TextBox to input Luau code
ScriptStuff:AddTextbox({
	Name = "Enter Luau Code",
	Default = "",
	TextDisappear = false,
	Callback = function(Value)
		currentLuauCode = Value
	end	
})

-- Add the Toggle to spam the code safely
ScriptStuff:AddToggle({
	Name = "Spam Script (No Delay / Safe)",
	Default = false,
	Callback = function(Value)
		isSpamming = Value
		
		-- Start the execution loop when toggled on
		if isSpamming then
			task.spawn(function()
				while isSpamming do
					if currentLuauCode ~= "" then
						-- pcall prevents bad input code from breaking the spam loop
						pcall(function()
							local func, err = loadstring(currentLuauCode)
							if func then
								func()
							else
								warn("Luau Compile Error: " .. tostring(err))
							end
						end)
					end
					-- task.wait() ensures maximum per-frame speed without freezing the client
					task.wait() 
				end
			end)
		end
	end
})


-- Execution Finalization
OrionLib:Init()
autoSendChat("|--🌌Aether 4.2 loaded🌌--|")
