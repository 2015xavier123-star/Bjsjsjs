local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Global configuration namespace
_G.Cam = _G.Cam or {}

-- Third-person configuration dictionary
_G.Cam.ThirdP = {
    Enabled = false
    MinZoom = 0,
    MaxZoom = 100,
    Offset = Vector3.new(0, 2, 8) -- Custom detachment offset (X, Y, Z distance)
}

local currentZoom = (_G.Cam.ThirdP.MinZoom + _G.Cam.ThirdP.MaxZoom) / 2

-- Bind to RenderStepped to override camera behaviour and force third person
RunService.RenderStepped:Connect(function(deltaTime)
    local config = _G.Cam.ThirdP
    if not config or not config.Enabled then return end
    
    -- Dynamically ensure player properties respect zoom constraints
    player.CameraMinZoomDistance = config.MinZoom
    player.CameraMaxZoomDistance = config.MaxZoom
    
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        
        -- Detach and manually position camera to guarantee third-person perspective
        camera.CameraType = Enum.CameraType.Scriptable
        
        -- Calculate distance based on camera zoom state or fallback to offset
        local zoomOffset = config.Offset
        local targetCFrame = CFrame.new(rootPart.Position) 
            * CFrame.Angles(0, math.rad(camera.CFrame.Rotation.Y), 0) -- Match horizontal rotation
            * CFrame.new(zoomOffset.X, zoomOffset.Y, zoomOffset.Z)
        
        -- Smoothly interpolate or snap camera position
        camera.CFrame = CFrame.lookAt(targetCFrame.Position, rootPart.Position + Vector3.new(0, 2, 0))
    else
        -- Fallback to default behavior if character is missing/spawning
        camera.CameraType = Enum.CameraType.Custom
    end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
local CreateLine = GrabEvents and GrabEvents:FindFirstChild("CreateGrabLine")

if not CreateLine then 
    GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents", 10) 
    CreateLine = GrabEvents and GrabEvents:FindFirstChild("CreateGrabLine")
end

if not CreateLine then 
    warn("[Lag Tool] CreateGrabLine not found in ReplicatedStorage.GrabEvents") 
    return
end

shared.LagSettings = {
    MonsterLagEnabled = false
}

local maxRange = 9e9 
local distanceModifier = 1.0 

local function getSpawnLocation() 
    local LP = Players.LocalPlayer 
    return Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
end

local function getRandomOffset() 
    local currentMax = maxRange * distanceModifier 
    local randomMultiplierX = (math.random() * 2) - 1 
    local randomMultiplierZ = (math.random() * 2) - 1 
    return randomMultiplierX * currentMax, randomMultiplierZ * currentMax
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


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

--// ==================== SETTINGS ====================

local AntiGrabEnabled = false
_G.AntiGrab = false

--// ==================== REMOTES ====================

local grabEventsFolder = ReplicatedStorage:WaitForChild("GrabEvents", 30)
local characterEventsFolder = ReplicatedStorage:WaitForChild("CharacterEvents", 30)

local setNetworkOwnerEvent =
	grabEventsFolder and grabEventsFolder:WaitForChild("SetNetworkOwner", 5)

local destroyGrabLineEvent =
	grabEventsFolder and grabEventsFolder:WaitForChild("DestroyGrabLine", 5)

local ragdollRemoteEvent =
	characterEventsFolder and characterEventsFolder:WaitForChild("RagdollRemote", 5)

local struggleEvent =
	characterEventsFolder and characterEventsFolder:WaitForChild("Struggle", 5)

local isHeldValue = LocalPlayer:WaitForChild("IsHeld", 30)

--// ==================== NETWORK OWNERSHIP ====================

local function AttemptNetworkShip(part)
	if not part or not part.Parent then
		return false
	end

	local partOwner = part:FindFirstChild("PartOwner")

	if partOwner and partOwner.Value == LocalPlayer.Name then
		return true
	end

	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return false
	end

	if setNetworkOwnerEvent then
		pcall(function()
			setNetworkOwnerEvent:FireServer(
				part,
				CFrame.lookAt(root.Position, part.Position)
			)
		end)
	end

	for _ = 1, 5 do
		task.wait()

		local owner = part:FindFirstChild("PartOwner")

		if owner and owner.Value == LocalPlayer.Name then
			return true
		end
	end

	return false
end

--// ==================== ANTI-GRAB CONTROLLER ====================

local AntiGrab = {}
AntiGrab.__index = AntiGrab

function AntiGrab.new()
	local self = setmetatable({
		anti_grab = true,
		conns = {},
	}, AntiGrab)

	self:HookPlayer()

	return self
end

function AntiGrab:AntiGrabPlayer(character)
	if self.anti_grab_conn then
		self.anti_grab_conn:Disconnect()
		self.anti_grab_conn = nil
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 5)

	if not hrp then
		return
	end

	self.anti_grab_conn = character.DescendantAdded:Connect(function(child)
		if not self.anti_grab then
			return
		end

		if not (
			child:IsA("StringValue")
			and child.Name == "PartOwner"
			and child.Value
		) then
			return
		end

		if child.Value == LocalPlayer.Name then
			return
		end

		local grabbedPart = child.Parent

		if not grabbedPart or not grabbedPart:IsA("BasePart") then
			return
		end

		

		if destroyGrabLineEvent then
			pcall(function()
				destroyGrabLineEvent:FireServer(grabbedPart)
			end)
		end
	end)

	table.insert(self.conns, self.anti_grab_conn)
end

function AntiGrab:OnDied(character)
	local humanoid = character:WaitForChild("Humanoid", 5)

	if not humanoid then
		return
	end

	self.died_conn = humanoid.Died:Once(function()
		if self.anti_grab_conn then
			self.anti_grab_conn:Disconnect()
			self.anti_grab_conn = nil
		end
	end)

	table.insert(self.conns, self.died_conn)
end

function AntiGrab:SetUp(character)
	if not character then
		return
	end

	self:OnDied(character)
	self:AntiGrabPlayer(character)
end

function AntiGrab:HookPlayer()
	local character = LocalPlayer.Character

	if character then
		self:SetUp(character)
	end

	self.root_conn = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
		self:SetUp(newCharacter)
	end)

	table.insert(self.conns, self.root_conn)
end

--// ==================== ISHELD HANDLING ====================

local heldHeartbeatConnection = nil

local function stopHeldHeartbeat()
	if heldHeartbeatConnection then
		heldHeartbeatConnection:Disconnect()
		heldHeartbeatConnection = nil
	end

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if hrp then
		hrp.Velocity = Vector3.zero
		hrp.Anchored = false
	end
end

local function setupIsHeld()
	if not isHeldValue then
		return
	end

	isHeldValue.Changed:Connect(function(isBeingHeld)
		if isBeingHeld ~= true or not AntiGrabEnabled then
			stopHeldHeartbeat()
			return
		end

		local char = LocalPlayer.Character
			or LocalPlayer.CharacterAdded:Wait()

		local hrp = char:WaitForChild("HumanoidRootPart", 5)

		if not hrp then
			return
		end

		if isHeldValue.Value then
			stopHeldHeartbeat()

			heldHeartbeatConnection = RunService.Heartbeat:Connect(function()
				if not AntiGrabEnabled then
					stopHeldHeartbeat()
					return
				end

				if not isHeldValue.Value then
					stopHeldHeartbeat()
					return
				end

				hrp.Velocity = Vector3.zero
				hrp.Anchored = true

				if struggleEvent then
					pcall(function()
						struggleEvent:FireServer(LocalPlayer)
					end)
				end

				if ragdollRemoteEvent then
					pcall(function()
						ragdollRemoteEvent:FireServer(hrp, 0)
					end)
				end
			end)
		end
	end)
end

--// ==================== START ====================

setupIsHeld()

local AntiGrabController = AntiGrab.new()


local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local DeleteToyRE = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("DestroyToy")
local SpawnToyRF = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")
local setNetworkOwnerEvent = ReplicatedStorage:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")
local destroyGrabLineEvent = ReplicatedStorage:WaitForChild("GrabEvents"):WaitForChild("DestroyGrabLine")

local Settings = {
	ProtectFriends = false,
	KickAllV1 = false,
	AntiExplosion = false,
	AntiKillHamburger = false,
	AntiBlobmanKill = false,
	BarrierNoclip = false,
	FloatAmount = 16,
	currentSide = "Left",
}

local function isFriend(plr)
	local ok, result = pcall(function()
		return LocalPlayer:IsFriendsWith(plr.UserId)
	end)
	return ok and result
end

local function getToysFolder()
	return Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
end

local function getLocalRoot()
	local c = LocalPlayer.Character
	return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end

local function getLocalHum()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getBlobman()
	local hum = getLocalHum()
	if hum and hum.Sit and hum.SeatPart and hum.SeatPart.Parent then
		if hum.SeatPart.Parent.Name == "CreatureBlobman" then
			return hum.SeatPart.Parent
		end
	end
	local inv = getToysFolder()
	if inv then
		local v = inv:FindFirstChild("CreatureBlobman")
		if v and v.ClassName == "Model" and v:FindFirstChild("VehicleSeat") then return v end
	end
	return nil
end

local function findAnyBlobman()
	local myRoot = getLocalRoot()
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
	checkFolder(getToysFolder())
	if not closest then
		for _, obj in ipairs(Workspace:GetChildren()) do
			if obj.Name == "CreatureBlobman" and obj:IsA("Model") and obj:FindFirstChild("VehicleSeat") then
				local dist = myRoot and (obj:GetPivot().Position - myRoot.Position).Magnitude or 0
				if dist < 100000 and dist < closestDist then
					closestDist = dist
					closest = obj
				end
			end
		end
	end
	return closest
end

local function spawnBlobman()
	local myRoot = getLocalRoot()
	if not myRoot then return nil end
	local existing = getBlobman()
	if existing then return existing end
	local anyBlob = findAnyBlobman()
	if anyBlob then return anyBlob end
	pcall(function()
		SpawnToyRF:InvokeServer("CreatureBlobman", myRoot.CFrame * CFrame.new(3, 0, 0), Vector3.zero)
	end)
	task.wait(0.8)
	return getBlobman() or findAnyBlobman()
end

local function isSittingOnBlobman()
	local hum = getLocalHum()
	return hum and hum.Sit and hum.SeatPart and hum.SeatPart.Parent and hum.SeatPart.Parent.Name == "CreatureBlobman"
end

local function SetNetworkOwner(part)
	local root = getLocalRoot()
	if root then
		pcall(function() setNetworkOwnerEvent:FireServer(part, root.CFrame) end)
	end
end

local function ungrab(part)
	pcall(function() destroyGrabLineEvent:FireServer(part) end)
end

local function blobGrab(blob, target, side)
	if not blob then return end
	local detector = blob:FindFirstChild(side .. "Detector")
	if not detector then return end
	local weld = detector:FindFirstChild(side .. "Weld")
	if not weld then return end
	local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript", true)
	if not script then return end
	local remote = script:FindFirstChild("CreatureGrab")
	if remote then pcall(function() remote:FireServer(detector, target, weld) end) end
end

local function blobDrop(blob, target, side)
	if not blob then return end
	local detector = blob:FindFirstChild(side .. "Detector")
	if not detector then return end
	local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript", true)
	if not script then return end
	local remote = script:FindFirstChild("CreatureDrop")
	if remote then pcall(function() remote:FireServer(detector, target) end) end
end

local function blobKick(blob, target, side)
	if not blob or not target then return end
	blobGrab(blob, getLocalRoot(), side)
	task.wait(0.02)
	SetNetworkOwner(target)
	task.wait(0.02)
	target.CFrame = target.CFrame + Vector3.new(0, Settings.FloatAmount, 0)
	task.wait(0.02)
	ungrab(target)
	task.wait(0.02)
	blobGrab(blob, target, side)
	task.wait(0.02)
	blobDrop(blob, target, side)
	task.wait(0.02)
	ungrab(target)
end

local function isValidTarget(plr)
	if plr == LocalPlayer then return false end
	if Settings.ProtectFriends and isFriend(plr) then return false end
	local char = plr.Character
	if not char then return false end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	if root.Position.Y < -25 then return false end
	return true
end

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
				r.Anchored = true
				task.wait(0.03)
				r.AssemblyLinearVelocity = Vector3.zero
				r.AssemblyAngularVelocity = Vector3.zero
				r.Anchored = false
			else
				r.Anchored = true
				task.wait()
				h:ChangeState(Enum.HumanoidStateType.Running)
				r.Anchored = false
				h.AutoRotate = true
				for _, limb in ipairs(char:GetDescendants()) do
					if limb:IsA("BasePart") and limb.Name == "RagdollLimbPart" then
						limb.CanCollide = false
					end
				end
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
		local spawnedFolder = getToysFolder()
		local hamburger = spawnedFolder and spawnedFolder:FindFirstChild("FoodHamburger")
		if not hamburger or not hamburger:FindFirstChild("HoldPart") then
			if tick() - lastSpawnAttempt > 1 then
				lastSpawnAttempt = tick()
				pcall(function()
					SpawnToyRF:InvokeServer("FoodHamburger", CFrame.new(0, 300, 0), Vector3.zero)
				end)
			end
			toggle = false
			return
		end
		toggle = not toggle
		if toggle then
			pcall(function() hamburger.HoldPart.HoldItemRemoteFunction:InvokeServer(hamburger, character) end)
		else
			pcall(function()
				hamburger.HoldPart.DropItemRemoteFunction:InvokeServer(hamburger, CFrame.new(0, 300, 0), Vector3.zero)
			end)
		end
	end)
end

local function disableAntiKill()
	if antiKillConnection then antiKillConnection:Disconnect() antiKillConnection = nil end
	local spawnedFolder = getToysFolder()
	if spawnedFolder then
		for _, hamburger in ipairs(spawnedFolder:GetChildren()) do
			if hamburger.Name == "FoodHamburger" and hamburger:FindFirstChild("HoldPart") then
				pcall(function()
					hamburger.HoldPart.DropItemRemoteFunction:InvokeServer(hamburger, CFrame.new(0, 300, 0), Vector3.zero)
				end)
			end
		end
		task.wait(0.1)
		for _, hamburger in ipairs(spawnedFolder:GetChildren()) do
			if hamburger.Name == "FoodHamburger" then
				pcall(function() DeleteToyRE:FireServer(hamburger) end)
			end
		end
	end
end

local antiBlobmanKillConnection = nil

local function enableAntiBlobmanKill()
	if antiBlobmanKillConnection then antiBlobmanKillConnection:Disconnect() end
	local lastUpdate = 0
	antiBlobmanKillConnection = RunService.Heartbeat:Connect(function()
		if not Settings.AntiBlobmanKill then return end
		local now = tick()
		if now - lastUpdate < 0.033 then return end
		lastUpdate = now
		local char = LocalPlayer.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp or hum.Health <= 0 then return end
		hum.Sit = true
		hum:ChangeState(Enum.HumanoidStateType.Running)
		local camera = Workspace.CurrentCamera
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
		local blob = getBlobman() or findAnyBlobman() or spawnBlobman()
		if not blob or not blob:FindFirstChild("VehicleSeat") then
			Settings.KickAllV1 = false
			return
		end

		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
		if not myHRP or not myHum then
			Settings.KickAllV1 = false
			return
		end

		local seat = blob.VehicleSeat
		if not myHum.Sit or myHum.SeatPart ~= seat then
			if seat.Occupant and seat.Occupant ~= myHum then
				pcall(function() seat.Occupant.Jump = true end)
				task.wait(0.1)
			end
			local sitStart = tick()
			while tick() - sitStart < 0.5 do
				if not blob or not blob.Parent then break end
				myHRP.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
				task.wait(0.03)
				seat:Sit(myHum)
				task.wait(0.05)
				if myHum.Sit and myHum.SeatPart == seat then break end
			end
		end

		while Settings.KickAllV1 do
			if not isSittingOnBlobman() then
				local s = blob and blob:FindFirstChild("VehicleSeat")
				if not s then task.wait(0.1) continue end
				local r = getLocalRoot()
				local h = getLocalHum()
				if r and h then
					if s.Occupant and s.Occupant ~= h then
						pcall(function() s.Occupant.Jump = true end)
						task.wait(0.1)
					end
					r.CFrame = s.CFrame + Vector3.new(0, 2, 0)
					task.wait(0.05)
					s:Sit(h)
					task.wait(0.1)
				end
				if not isSittingOnBlobman() then
					task.wait(0.1)
					continue
				end
			end

			local targets = {}
			for _, plr in ipairs(Players:GetPlayers()) do
				if not isValidTarget(plr) then continue end
				local char = plr.Character
				if not char then continue end
				local root = char:FindFirstChild("HumanoidRootPart")
				if not root then continue end
				table.insert(targets, {plr = plr, root = root})
			end

			local blobPos = blob.VehicleSeat.Position
			table.sort(targets, function(a, b)
				return (a.root.Position - blobPos).Magnitude < (b.root.Position - blobPos).Magnitude
			end)

			for _, t in ipairs(targets) do
				if not Settings.KickAllV1 then break end
				if not isSittingOnBlobman() then
					local seat2 = blob and blob:FindFirstChild("VehicleSeat")
					if not seat2 then break end
					local myRoot = getLocalRoot()
					local hum = getLocalHum()
					if myRoot and hum then
						myRoot.CFrame = seat2.CFrame + Vector3.new(0, 2, 0)
						task.wait(0.05)
						seat2:Sit(hum)
						task.wait(0.1)
					end
					if not isSittingOnBlobman() then break end
				end

				local myRoot = getLocalRoot()
				if myRoot and t.root then
					if (t.root.Position - myRoot.Position).Magnitude > 500000 then continue end
					myRoot.CFrame = t.root.CFrame
					task.wait(0.03)
					blobKick(blob, t.root, Settings.currentSide)
					task.wait(0.03)
					ungrab(myRoot)
					task.wait(0.03)
					myRoot.CFrame = blob.VehicleSeat.CFrame + Vector3.new(0, 2, 0)
					task.wait(0.03)
					local hum = getLocalHum()
					if hum and blob:FindFirstChild("VehicleSeat") then
						blob.VehicleSeat:Sit(hum)
						task.wait(0.05)
					end
				end
			end
			task.wait(0.05)
		end
	end)
end

local function stopKickAllV1()
	Settings.KickAllV1 = false
	if kickAllV1Thread then task.cancel(kickAllV1Thread) kickAllV1Thread = nil end
end

local barrierNoclipConn = nil

local function setBarrierNoclip()
	if not Settings.BarrierNoclip then return end
	local Plots = Workspace:FindFirstChild("Plots")
	if not Plots then return end
	for i = 1, 5 do
		local plot = Plots:FindFirstChild("Plot" .. i)
		if plot and plot:FindFirstChild("Barrier") then
			for _, barrier in ipairs(plot.Barrier:GetChildren()) do
				if barrier:IsA("BasePart") then
					barrier.CanCollide = false
				end
			end
		end
	end
end

local function UnlockBarrier()
	local player = LocalPlayer
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	local originalPosition = player.Character.HumanoidRootPart.CFrame

	pcall(function()
		SpawnToyRF:InvokeServer("InstrumentWoodwindOcarina",
			CFrame.new(184.148834, -5.54824972, 498.136749),
			Vector3.new(0, 34, 0)
		)
	end)
	task.wait(0.3)

	local toyFolder = getToysFolder()
	if not toyFolder then return end
	local ocarina = toyFolder:FindFirstChild("InstrumentWoodwindOcarina")
	if not ocarina then return end
	local holdPart = ocarina:FindFirstChild("HoldPart")
	if not holdPart then return end

	holdPart.HoldItemRemoteFunction:InvokeServer(ocarina, Workspace[player.Name])
	task.wait(0.3)

	player.Character.HumanoidRootPart.CFrame = CFrame.new(304.06, 25.77, 488.54)
	task.wait(0.15)
	if ocarina and ocarina.Parent then pcall(function() DeleteToyRE:FireServer(ocarina) end) end
	task.wait(0.15)

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = originalPosition
	end

	local Plots = Workspace:FindFirstChild("Plots")
	if Plots then
		for _, v in ipairs(Plots:GetChildren()) do
			local barrier = v:FindFirstChild("Barrier")
			if barrier then
				for _, p in ipairs(barrier:GetChildren()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end
	end
end

local function UnlockBarrierV2()
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local inv = getToysFolder()
	local plot1 = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild("Plot1")
	local metal = plot1 and plot1:FindFirstChild("TeslaCoil") and plot1.TeslaCoil:FindFirstChild("Metal")
	if not metal then return end

	local TP = metal.CFrame
	local OCF = hrp.CFrame

	task.spawn(function()
		pcall(function() SpawnToyRF:InvokeServer("FoodBread", hrp.CFrame, Vector3.zero) end)
	end)
	task.wait(0.2)

	local foodBread = inv and inv:FindFirstChild("FoodBread")
	if foodBread then
		local holdPart = foodBread:FindFirstChild("HoldPart")
		if holdPart then
			local holdRemote = holdPart:FindFirstChild("HoldItemRemoteFunction")
			if holdRemote then pcall(function() holdRemote:InvokeServer(foodBread, char) end) end
		end
	end
	task.wait(0.1)
	hrp.CFrame = TP
	task.wait(0.17)
	if foodBread then pcall(function() DeleteToyRE:FireServer(foodBread) end) end
	hrp.CFrame = OCF
end

local Window = OrionLib:MakeWindow({
	Name = "Main script | AI SIMP",
	HidePremium = false,
	SaveConfig = true,
	ConfigFolder = "OrionTest"
})

local infoTab = Window:MakeTab({
    Name = "Info",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

infoTab:AddLabel("Made by ai simp")
infoTab:AddLabel("HUGE thanks to TSBH_Adrenaline for making the attacks♡")
infoTab:AddLabel("This script is very weak for now.")
infoTab:AddLabel("Updates soon ig")


local AntisTab = Window:MakeTab({
	Name = "Antis",
	Icon = "rbxassetid://111176085924966",
	PremiumOnly = false
})

local KickTab = Window:MakeTab({
	Name = "Kicks",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local BarrierTab = Window:MakeTab({
	Name = "Barrier",
	Icon = "rbxassetid://6031094678",
	PremiumOnly = false
})

local Rndm = Window:MakeTab({
	Name = "Essentials",
	Icon = "rbxassetid://5009915812",
	PremiumOnly = false
})

local atk = Window:MakeTab({
	Name = "Attacks",
	Icon = "rbxassetid://6031094678",
	PremiumOnly = false
})

AntisTab:AddToggle({
	Name = "Antigrab by TSBH",
	Default = false,
	Callback = function(Value)
		AntiGrabEnabled = Value
	end
})

AntisTab:AddToggle({
	Name = "Anti Explosion",
	Default = false,
	Callback = function(Value)
		Settings.AntiExplosion = Value
		if Value then
			if LocalPlayer.Character then setupAntiExplosion(LocalPlayer.Character) end
			if antiExplosionCharConn then antiExplosionCharConn:Disconnect() end
			antiExplosionCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
				if antiExplosionConnection then antiExplosionConnection:Disconnect() end
				setupAntiExplosion(char)
			end)
		else
			if antiExplosionConnection then antiExplosionConnection:Disconnect() antiExplosionConnection = nil end
			if antiExplosionCharConn then antiExplosionCharConn:Disconnect() antiExplosionCharConn = nil end
		end
	end
})

AntisTab:AddToggle({
	Name = "Anti Kill (Hamburger)",
	Default = false,
	Callback = function(Value)
		Settings.AntiKillHamburger = Value
		if Value then enableAntiKill() else disableAntiKill() end
	end
})

AntisTab:AddToggle({
	Name = "Anti Blobman Kill",
	Default = false,
	Callback = function(Value)
		Settings.AntiBlobmanKill = Value
		if Value then
			enableAntiBlobmanKill()
		else
			if antiBlobmanKillConnection then
				antiBlobmanKillConnection:Disconnect()
				antiBlobmanKillConnection = nil
			end
		end
	end
})

KickTab:AddToggle({
	Name = "Protect Friends",
	Default = false,
	Callback = function(Value)
		Settings.ProtectFriends = Value
	end
})

KickTab:AddToggle({
	Name = "Kick All V1",
	Default = false,
	Callback = function(Value)
		Settings.KickAllV1 = Value
		if Value then startKickAllV1() else stopKickAllV1() end
	end
})

BarrierTab:AddButton({
	Name = "Unlock Barrier (V1)",
	Callback = function()
		task.spawn(UnlockBarrier)
	end
})

BarrierTab:AddButton({
	Name = "Unlock Barrier V2 (Fast)",
	Callback = function()
		task.spawn(UnlockBarrierV2)
	end
})

BarrierTab:AddToggle({
	Name = "Barrier Noclip",
	Default = false,
	Callback = function(Value)
		Settings.BarrierNoclip = Value
		if Value then
			setBarrierNoclip()
			if barrierNoclipConn then barrierNoclipConn:Disconnect() end
			barrierNoclipConn = Workspace.DescendantAdded:Connect(function(obj)
				if Settings.BarrierNoclip and (obj.Name == "Barrier" or (obj.Parent and obj.Parent.Name == "Barrier")) then
					task.wait(0.1)
					setBarrierNoclip()
				end
			end)
		else
			if barrierNoclipConn then barrierNoclipConn:Disconnect() barrierNoclipConn = nil end
		end
	end
})

Rndm:AddToggle({
	Name = "Enable void",
	Default = true,
	Callback = function(Value)
		game.Workspace.FallHeightEnabled = Value
	end
})

Rndm:AddButton({
	Name = "Tsunami",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/2015xavier123-star/Bjsjsjs/refs/heads/main/tsunami.lua"))()
	end
})

atk:AddToggle({
	Name = "Lag server (Can kick players)",
   Default = false
	Callback = function()
        shared.LagSettings.MonsterLagEnabled = Value
	end
})

Rndm:AddButton({
	Name = "Grab all",
	Callback = function()	loadstring(game:HttpGet("https://raw.githubusercontent.com/2015xavier123-star/Bjsjsjs/refs/heads/main/Test.lua"))()
	end
})

Rndm:AddToggle({
	Name = "3rd person enabled",
	Default = true,
	Callback = function(Value)
		_G.Cam.ThirdP = Value
	end
})

OrionLib:Init()
