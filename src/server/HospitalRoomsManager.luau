-- HospitalRoomsManager: Bright Modern Hospital Architecture, Interactive 3D Doors, and Treatment Stations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PirateTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PirateTypes"))

local HospitalRoomsManager = {}
local MedicineManagerRef = nil

local Events = ReplicatedStorage:FindFirstChild("Events")
if not Events then
	Events = Instance.new("Folder", ReplicatedStorage)
	Events.Name = "Events"
end

local function getOrCreateRemote(name, class)
	class = class or "RemoteEvent"
	local r = Events:FindFirstChild(name)
	if not r then
		r = Instance.new(class, Events)
		r.Name = name
	end
	return r
end

local StartMinigameEvent = getOrCreateRemote("StartMinigame")
local CompleteMinigameEvent = getOrCreateRemote("CompleteMinigame")
local ShowNotificationEvent = getOrCreateRemote("ShowNotification")

local activePatients = {} -- [patientModel] = { Data = patientData, Room = roomKey }

local function createPart(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.WoodPlanks
	if shape then p.Shape = shape end
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Interactive 3D Swinging Door Helper with [E] and NPC Auto-Open
local function createInteractiveDoor(parent, name, cf, width, height, isDouble)
	local doorModel = Instance.new("Model", parent)
	doorModel.Name = name

	local frameColor = Color3.fromRGB(80, 50, 25)
	local doorWoodColor = Color3.fromRGB(130, 85, 45)

	-- Door frame posts
	local postL = createPart(doorModel, "FrameL", Vector3.new(1.2, height, 1.2), cf * CFrame.new(-width/2 - 0.6, height/2, 0), frameColor, Enum.Material.Wood)
	local postR = createPart(doorModel, "FrameR", Vector3.new(1.2, height, 1.2), cf * CFrame.new(width/2 + 0.6, height/2, 0), frameColor, Enum.Material.Wood)
	local lintel = createPart(doorModel, "Lintel", Vector3.new(width + 2.4, 1.4, 1.4), cf * CFrame.new(0, height + 0.7, 0), frameColor, Enum.Material.Wood)

	-- Door leaf (hinged)
	local leafWidth = isDouble and (width / 2) or width
	local doorLeaf = createPart(doorModel, "DoorLeaf", Vector3.new(leafWidth - 0.2, height - 0.4, 0.6), cf * CFrame.new(-width/2 + (leafWidth/2), height/2, 0), doorWoodColor, Enum.Material.WoodPlanks)
	
	-- Door handle
	local handle = createPart(doorModel, "Handle", Vector3.new(0.3, 1.2, 0.4), cf * CFrame.new(-width/2 + leafWidth - 0.6, height/2, 0.4), Color3.fromRGB(240, 200, 80), Enum.Material.Metal)

	local isOpen = false
	local closedCF = doorLeaf.CFrame
	local openCF = cf * CFrame.new(-width/2, height/2, 0) * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(leafWidth/2, 0, 0)

	local prompt = Instance.new("ProximityPrompt", doorLeaf)
	prompt.ActionText = "Tür öffnen"
	prompt.ObjectText = "Tür"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12

	local function toggleDoor(open)
		if open == nil then open = not isOpen end
		isOpen = open
		prompt.ActionText = isOpen and "Tür schließen" or "Tür öffnen"

		local targetCF = isOpen and openCF or closedCF
		TweenService:Create(doorLeaf, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = targetCF }):Play()
		TweenService:Create(handle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = targetCF * CFrame.new(leafWidth/2 - 0.6, 0, 0.4) }):Play()
	end

	prompt.Triggered:Connect(function()
		toggleDoor()
	end)

	-- NPC Auto-Proximity Trigger
	task.spawn(function()
		while doorModel.Parent do
			task.wait(0.5)
			local shouldOpen = false
			for pModel, _ in pairs(activePatients) do
				if pModel and pModel.Parent then
					local root = pModel:FindFirstChild("HumanoidRootPart")
					if root and (root.Position - cf.Position).Magnitude < 10 then
						shouldOpen = true
						break
					end
				end
			end
			if shouldOpen and not isOpen then
				toggleDoor(true)
			elseif not shouldOpen and isOpen then
				task.wait(2.5)
				toggleDoor(false)
			end
		end
	end)

	return doorModel
end

function HospitalRoomsManager.BuildRooms()
	local hospZone = workspace:FindFirstChild("Hospital_Zone")
	if not hospZone then
		hospZone = Instance.new("Folder", workspace)
		hospZone.Name = "Hospital_Zone"
	end
	hospZone:ClearAllChildren()

	local hospComplex = Instance.new("Model", hospZone)
	hospComplex.Name = "HospitalComplex8Rooms"

	-- BRIGHT, CLEAN HOSPITAL FLOOR (Warm Polished Oak)
	local mainFloor = createPart(hospComplex, "HospitalFloor", Vector3.new(200, 1.6, 120), CFrame.new(10, 7.5, -135), Color3.fromRGB(155, 120, 80), Enum.Material.WoodPlanks)
	hospComplex.PrimaryPart = mainFloor

	-- BRIGHT WALL COLORS (Friendly light cream / plaster - no pitch dark gloom!)
	local wallColor = Color3.fromRGB(235, 230, 218)
	local exteriorTrim = Color3.fromRGB(100, 65, 35)

	-- Exterior Walls
	createPart(hospComplex, "WallNorth", Vector3.new(202, 16, 1.5), CFrame.new(10, 15.5, -195), wallColor, Enum.Material.SmoothPlastic)
	createPart(hospComplex, "WallWest", Vector3.new(1.5, 16, 120), CFrame.new(-91, 15.5, -135), wallColor, Enum.Material.SmoothPlastic)
	createPart(hospComplex, "WallEast", Vector3.new(1.5, 16, 120), CFrame.new(111, 15.5, -135), wallColor, Enum.Material.SmoothPlastic)
	createPart(hospComplex, "Roof", Vector3.new(204, 1.5, 124), CFrame.new(10, 23.5, -135), Color3.fromRGB(85, 55, 30), Enum.Material.WoodPlanks)

	-- South Entrance Wall with Grand Doorway at X = 2..18
	createPart(hospComplex, "WallSouth_West", Vector3.new(93, 16, 1.5), CFrame.new(-44.5, 15.5, -75), wallColor, Enum.Material.SmoothPlastic)
	createPart(hospComplex, "WallSouth_East", Vector3.new(93, 16, 1.5), CFrame.new(64.5, 15.5, -75), wallColor, Enum.Material.SmoothPlastic)

	-- Interactive Main Entrance Door
	createInteractiveDoor(hospComplex, "HospitalMainDoor", CFrame.new(10, 7.5, -75), 14, 13, true)

	-- Grand Entrance Signboard
	local hospSign = createPart(hospComplex, "HospMainEntranceSign", Vector3.new(18, 3.2, 0.6), CFrame.new(10, 21.5, -73.8), Color3.fromRGB(30, 28, 35), Enum.Material.SmoothPlastic)
	local hGui = Instance.new("SurfaceGui", hospSign)
	hGui.Face = Enum.NormalId.Back
	local hText = Instance.new("TextLabel", hGui)
	hText.Size = UDim2.new(1, 0, 1, 0)
	hText.BackgroundTransparency = 1
	hText.Text = "🏥 KRANKENHAUS & BEHANDLUNG"
	hText.TextColor3 = Color3.fromRGB(255, 230, 120)
	hText.TextScaled = true
	hText.Font = Enum.Font.Antique

	-- =========================================================
	-- BRIGHT OVERHEAD HOSPITAL LIGHTING GRID (Full Illumination)
	-- =========================================================
	local lightGridX = {-65, -15, 10, 35, 85}
	local lightGridZ = {-165, -135, -105}

	for _, lx in ipairs(lightGridX) do
		for _, lz in ipairs(lightGridZ) do
			local chandelier = createPart(hospComplex, "CeilingChandelier", Vector3.new(2.4, 0.8, 2.4), CFrame.new(lx, 22.8, lz), Color3.fromRGB(240, 235, 210), Enum.Material.Neon, Enum.PartType.Cylinder)
			chandelier.CFrame = chandelier.CFrame * CFrame.Angles(0, 0, math.rad(90))

			local sl = Instance.new("SurfaceLight", chandelier)
			sl.Face = Enum.NormalId.Bottom
			sl.Color = Color3.fromRGB(255, 245, 225)
			sl.Brightness = 2.2
			sl.Range = 36
			sl.Angle = 110

			local pl = Instance.new("PointLight", chandelier)
			pl.Color = Color3.fromRGB(255, 235, 195)
			pl.Brightness = 1.6
			pl.Range = 32
		end
	end

	-- Corridor Partitions (East and West) with Room Openings
	createPart(hospComplex, "MainCorridor_West", Vector3.new(90, 16, 1.2), CFrame.new(-45, 15.5, -135), wallColor, Enum.Material.SmoothPlastic)
	createPart(hospComplex, "MainCorridor_East", Vector3.new(90, 16, 1.2), CFrame.new(65, 15.5, -135), wallColor, Enum.Material.SmoothPlastic)

	-- Helper: Room Sign
	local function makeRoomSign(center, name, color)
		local sign = createPart(hospComplex, "RoomSign", Vector3.new(9, 2.2, 0.4), CFrame.new(center.X, 19, center.Z + (center.Z < -135 and 24.5 or -24.5)), Color3.fromRGB(32, 35, 45), Enum.Material.SmoothPlastic)
		local bb = Instance.new("BillboardGui", sign)
		bb.Size = UDim2.new(9, 0, 2.2, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 45
		local label = Instance.new("TextLabel", bb)
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = color or Color3.fromRGB(255, 225, 100)
		label.TextScaled = true
		label.Font = Enum.Font.Antique
	end

	-- ROOM 1: Station Alpha (Betten & Skorbut)
	local r1 = Constants.ROOMS.Room1_WardAlpha.Center
	makeRoomSign(r1, "🏥 STATION ALPHA", Color3.fromRGB(100, 220, 255))
	for b = 1, 2 do
		local bPos = r1 + Vector3.new((b == 1 and -8 or 8), 0, 0)
		createPart(hospComplex, "Bed_Alpha_" .. b, Vector3.new(4.5, 1.8, 8), CFrame.new(bPos + Vector3.new(0, 0.9, 0)), Color3.fromRGB(85, 55, 30), Enum.Material.WoodPlanks)
		createPart(hospComplex, "Mat_Alpha_" .. b, Vector3.new(4, 0.8, 7.4), CFrame.new(bPos + Vector3.new(0, 2, 0)), Color3.fromRGB(245, 245, 250), Enum.Material.Fabric)
	end

	-- ROOM 2: Station Beta (Intensiv)
	local r2 = Constants.ROOMS.Room2_WardBeta.Center
	makeRoomSign(r2, "💉 STATION BETA (INTENSIV)", Color3.fromRGB(255, 160, 60))
	for b = 1, 2 do
		local bPos = r2 + Vector3.new((b == 1 and -8 or 8), 0, 0)
		createPart(hospComplex, "Bed_Beta_" .. b, Vector3.new(4.5, 1.8, 8), CFrame.new(bPos + Vector3.new(0, 0.9, 0)), Color3.fromRGB(85, 55, 30), Enum.Material.WoodPlanks)
		createPart(hospComplex, "Mat_Beta_" .. b, Vector3.new(4, 0.8, 7.4), CFrame.new(bPos + Vector3.new(0, 2, 0)), Color3.fromRGB(245, 245, 250), Enum.Material.Fabric)
	end

	-- ROOM 3: Chirurgie & Verbandsraum
	local r3 = Constants.ROOMS.Room3_Surgery.Center
	makeRoomSign(r3, "🪓 CHIRURGIE & VERBÄNDE", Color3.fromRGB(255, 100, 100))
	createPart(hospComplex, "SurgeryTable", Vector3.new(5.5, 2.5, 9.5), CFrame.new(r3 + Vector3.new(0, 1.25, 0)), Color3.fromRGB(60, 65, 75), Enum.Material.Metal)

	-- ROOM 4: Erholungs-Lounge
	local r4 = Constants.ROOMS.Room4_Lounge.Center
	makeRoomSign(r4, "☕ ERHOLUNGS-LOUNGE", Color3.fromRGB(240, 200, 100))
	createPart(hospComplex, "FireHearth", Vector3.new(8, 6, 3), CFrame.new(r4 + Vector3.new(0, 3, -15)), Color3.fromRGB(70, 72, 78), Enum.Material.Cobblestone)
	local fire = createPart(hospComplex, "FireGlow", Vector3.new(3, 1, 2), CFrame.new(r4 + Vector3.new(0, 1.5, -14)), Color3.fromRGB(255, 120, 20), Enum.Material.Neon)
	local fLight = Instance.new("PointLight", fire)
	fLight.Color = Color3.fromRGB(255, 140, 40)
	fLight.Range = 25

	-- ROOM 5: Röntgen & Fluch-Scan
	local r5 = Constants.ROOMS.Room5_XRay.Center
	makeRoomSign(r5, "⚡ RÖNTGEN & FLUCH-SCAN", Color3.fromRGB(0, 255, 220))
	createPart(hospComplex, "ScanBed", Vector3.new(5, 2.2, 9), CFrame.new(r5 + Vector3.new(0, 1.1, 0)), Color3.fromRGB(50, 55, 65), Enum.Material.Metal)
	createPart(hospComplex, "ScanArch", Vector3.new(7.5, 8, 2), CFrame.new(r5 + Vector3.new(0, 4.5, 0)), Color3.fromRGB(0, 220, 200), Enum.Material.Neon)

	-- ROOM 6: Alchemie- & Medizin-Labor
	local r6 = Constants.ROOMS.Room6_Alchemy.Center
	makeRoomSign(r6, "🧪 ALCHEMIE & MEDIZIN", Color3.fromRGB(80, 255, 120))
	createPart(hospComplex, "LabTable", Vector3.new(16, 3.2, 4), CFrame.new(r6 + Vector3.new(0, 1.6, -4)), Color3.fromRGB(85, 55, 30), Enum.Material.WoodPlanks)
	createPart(hospComplex, "Cauldron", Vector3.new(3.5, 3, 3.5), CFrame.new(r6 + Vector3.new(-4, 4.5, -4)), Color3.fromRGB(35, 38, 45), Enum.Material.Metal, Enum.PartType.Ball)
	local brew = createPart(hospComplex, "BrewLiquid", Vector3.new(2.8, 0.2, 2.8), CFrame.new(r6 + Vector3.new(-4, 5.6, -4)), Color3.fromRGB(80, 240, 120), Enum.Material.Neon, Enum.PartType.Cylinder)
	brew.CFrame = brew.CFrame * CFrame.Angles(0, 0, math.rad(90))

	-- 5 Medicine Shelves inside Room 6
	local shelfCenter = r6 + Vector3.new(0, 0, 10)
	createPart(hospComplex, "MedicineCabinet", Vector3.new(22, 5, 2.5), CFrame.new(shelfCenter + Vector3.new(0, 2.5, 0)), Color3.fromRGB(85, 55, 30), Enum.Material.WoodPlanks)

	local medicinesList = {
		{ Id = "Lemon_Tonic", Name = "Zitronen-Tonikum", Icon = "🍋", XOff = -8, Color = Color3.fromRGB(245, 220, 40) },
		{ Id = "PegLeg_Splint", Name = "Holzbein-Schiene", Icon = "🪵", XOff = -4, Color = Color3.fromRGB(140, 95, 55) },
		{ Id = "Parrot_Antidote", Name = "Gegenmittel-Elixier", Icon = "🧪", XOff = 0, Color = Color3.fromRGB(60, 220, 120) },
		{ Id = "Herbal_Rum", Name = "Beruhigungs-Rum", Icon = "☕", XOff = 4, Color = Color3.fromRGB(190, 120, 50) },
		{ Id = "Holy_Water", Name = "Weihwasser-Essenz", Icon = "🔮", XOff = 8, Color = Color3.fromRGB(100, 220, 255) },
	}
	for _, m in ipairs(medicinesList) do
		local bottlePos = shelfCenter + Vector3.new(m.XOff, 5.8, 0)
		local bottle = createPart(hospComplex, "MedBottle_" .. m.Id, Vector3.new(1.2, 2, 1.2), CFrame.new(bottlePos), m.Color, Enum.Material.Glass, Enum.PartType.Cylinder)
		bottle.CFrame = bottle.CFrame * CFrame.Angles(0, 0, math.rad(90))
		createPart(hospComplex, "BottleCap", Vector3.new(0.6, 0.4, 0.6), CFrame.new(bottlePos + Vector3.new(0, 1.2, 0)), Color3.fromRGB(130, 85, 45), Enum.Material.Wood)

		local bb = Instance.new("BillboardGui", bottle)
		bb.Size = UDim2.new(5, 0, 2, 0)
		bb.StudsOffset = Vector3.new(0, 2.2, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 35
		local label = Instance.new("TextLabel", bb)
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = m.Icon .. " " .. m.Name
		label.TextColor3 = m.Color
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold

		local prompt = Instance.new("ProximityPrompt", bottle)
		prompt.ActionText = "Nehmen: " .. m.Name
		prompt.ObjectText = m.Icon .. " Medizin-Regal"
		prompt.HoldDuration = 0.3
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 12

		prompt.Triggered:Connect(function(player)
			if MedicineManagerRef then
				MedicineManagerRef.PickupMedicine(player, m.Id)
			end
		end)
	end

	-- ROOM 7: Voodoo- & Ritual-Schrein
	local r7 = Constants.ROOMS.Room7_Shrine.Center
	makeRoomSign(r7, "🔮 RITUAL- & ENFLUCHUNGS-SCHREIN", Color3.fromRGB(180, 80, 255))
	createPart(hospComplex, "ShrineAltar", Vector3.new(7, 3, 5), CFrame.new(r7 + Vector3.new(0, 1.5, 0)), Color3.fromRGB(50, 40, 60), Enum.Material.Cobblestone)
	local runeCircle = createPart(hospComplex, "RuneCircle", Vector3.new(12, 0.2, 12), CFrame.new(r7 + Vector3.new(0, 0.85, 0)), Color3.fromRGB(180, 60, 255), Enum.Material.Neon, Enum.PartType.Cylinder)
	runeCircle.CFrame = runeCircle.CFrame * CFrame.Angles(0, 0, math.rad(90))

	-- ROOM 8: Hochsicherheits-Quarantäne
	local r8 = Constants.ROOMS.Room8_Quarantine.Center
	makeRoomSign(r8, "🔒 HOCHSICHERHEITS-QUARANTÄNE", Color3.fromRGB(255, 40, 40))
	for q = 1, 2 do
		local qPos = r8 + Vector3.new((q == 1 and -7 or 7), 0, 0)
		createPart(hospComplex, "CellFloor_" .. q, Vector3.new(9, 0.8, 9), CFrame.new(qPos + Vector3.new(0, 0.4, 0)), Color3.fromRGB(50, 52, 60), Enum.Material.Metal)
		for bar = -4, 4, 1.4 do
			createPart(hospComplex, "LaserBar", Vector3.new(0.2, 12, 0.2), CFrame.new(qPos + Vector3.new(bar, 6.5, 4.2)), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
		end
	end

	-- Connect interactive door to office back exit too!
	local office = workspace:FindFirstChild("MainIslandAssets") and workspace.MainIslandAssets:FindFirstChild("HarborAdmissionOffice")
	if office then
		local oldDoor = office:FindFirstChild("OfficeBackDoor")
		if oldDoor then oldDoor:Destroy() end
		createInteractiveDoor(office, "OfficeBackDoor", CFrame.new(142, 7.2, 80) * CFrame.Angles(0, math.rad(90), 0), 8, 12, false)
	end
end

-- Routes patient along scenic walkway waypoints through both doors into assigned room
function HospitalRoomsManager.AssignPatientToRoom(patientModel, patientData)
	local roomKey = patientData.AssignedRoom or "Room1_WardAlpha"
	local roomInfo = Constants.ROOMS[roomKey]
	local targetPos = roomInfo and roomInfo.Center or Vector3.new(-65, 8.0, -160)

	activePatients[patientModel] = { Data = patientData, Room = roomKey }
	print("[HospitalRoomsManager] Routing patient " .. patientData.Name .. " to " .. (roomInfo and roomInfo.Name or roomKey))

	local humanoid = patientModel:FindFirstChild("Humanoid")
	if not humanoid then return end

	local pathWaypoints = {
		Vector3.new(178, 7.4, 80),   -- Step back from reception window
		Vector3.new(178, 7.4, 52),   -- North exterior corner bypass
		Vector3.new(135, 7.5, 52),   -- Side walkway past office
		Vector3.new(110, 7.5, 60),   -- Boardwalk waypoint 1
		Vector3.new(80, 7.5, 30),    -- Boardwalk waypoint 2
		Vector3.new(50, 7.5, -10),   -- Boardwalk waypoint 3
		Vector3.new(25, 7.5, -50),   -- Boardwalk waypoint 4
		Vector3.new(10, 7.5, -75),   -- Through hospital grand entrance door
		Vector3.new(10, 8.0, -110),  -- Hospital central hallway
		targetPos                    -- Assigned treatment room / bed
	}

	humanoid.WalkSpeed = 16

	local currentWP = 1
	local function walkToNextWaypoint()
		if currentWP > #pathWaypoints then
			-- Reached final room! Lay down or stand in station
			patientModel:PivotTo(CFrame.new(targetPos + Vector3.new(0, 1.8, 0)) * CFrame.Angles(math.rad(-90), 0, 0))

			-- Add Interactive Treatment Minigame ProximityPrompt
			local torso = patientModel:FindFirstChild("Torso")
			if torso then
				local reqMed = patientData.RequiredMedicine or "Lemon_Tonic"
				local medInfo = PirateTypes.Medicines[reqMed] or { Name = "Medizin", Icon = "💊" }

				local prompt = Instance.new("ProximityPrompt", torso)
				prompt.ActionText = "Behandlung starten (" .. medInfo.Icon .. " " .. (patientData.Illness or "Krank") .. ")"
				prompt.ObjectText = patientData.Name
				prompt.HoldDuration = 0.5
				prompt.RequiresLineOfSight = false
				prompt.MaxActivationDistance = 14

				prompt.Triggered:Connect(function(player)
					-- Check if player has the required medicine first
					if MedicineManagerRef then
						local hasMed, slotIdx = MedicineManagerRef.HasMedicine(player, reqMed)
						if not hasMed then
							ShowNotificationEvent:FireClient(player, "❌ Du benötigst zuerst: " .. medInfo.Icon .. " " .. medInfo.Name .. "! (Raum 6)", Color3.fromRGB(255, 80, 80))
							return
						end
					end

					-- Launch specialized Minigame for this room/illness!
					StartMinigameEvent:FireClient(player, {
						PatientName = patientData.Name,
						Illness = patientData.Illness or "Krankheit",
						RoomType = roomInfo and roomInfo.Type or "Ward",
						Medicine = reqMed
					})
				end)
			end
			return
		end

		local wp = pathWaypoints[currentWP]
		currentWP = currentWP + 1
		humanoid:MoveTo(wp)

		local finished = false
		local conn
		conn = humanoid.MoveToFinished:Connect(function()
			if not finished then
				finished = true
				conn:Disconnect()
				walkToNextWaypoint()
			end
		end)

		-- Anti-Stuck Timeout: If NPC doesn't reach waypoint within 3.5s, auto advance!
		task.delay(3.5, function()
			if not finished and patientModel and patientModel.Parent then
				finished = true
				if conn then conn:Disconnect() end
				patientModel:PivotTo(CFrame.new(wp + Vector3.new(0, 1.5, 0)))
				walkToNextWaypoint()
			end
		end)
	end

	walkToNextWaypoint()
end

-- Handle Minigame Completion from Client (Only on active Server)
local RunService = game:GetService("RunService")
if RunService:IsServer() then
	CompleteMinigameEvent.OnServerEvent:Connect(function(player, success, patientName)
		if not success then return end

		for patientModel, pInfo in pairs(activePatients) do
			if pInfo.Data.Name == patientName and patientModel.Parent then
				local torso = patientModel:FindFirstChild("Torso")
				if torso then
					local reqMed = pInfo.Data.RequiredMedicine or "Lemon_Tonic"
					if MedicineManagerRef then
						local hasMed, slotIdx = MedicineManagerRef.HasMedicine(player, reqMed)
						if hasMed then
							MedicineManagerRef.RemoveItem(player, slotIdx)
						end
						MedicineManagerRef.AwardGold(player, 120)
					end

					local prompt = torso:FindFirstChildOfClass("ProximityPrompt")
					if prompt then prompt:Destroy() end

					-- Sparkling cure effect
					local pe = Instance.new("ParticleEmitter", torso)
					pe.Rate = 35
					pe.Speed = NumberRange.new(2, 4)
					pe.Color = ColorSequence.new(Color3.fromRGB(255, 230, 80))
					pe.Size = NumberSequence.new(0.7, 0)
					pe.Lifetime = NumberRange.new(1, 1.5)

					patientModel:PivotTo(CFrame.new(patientModel:GetPivot().Position + Vector3.new(0, 1.2, 0)))
					ShowNotificationEvent:FireAllClients("✨ GEHEILT! " .. patientName .. " erfolgreich behandelt! (+120 Gold)", Color3.fromRGB(80, 255, 120))

					activePatients[patientModel] = nil
					task.delay(4, function()
						if patientModel and patientModel.Parent then
							patientModel:Destroy()
						end
					end)
				end
				break
			end
		end
	end)
end

function HospitalRoomsManager.SetMedicineManager(medManager)
	MedicineManagerRef = medManager
end

return HospitalRoomsManager
