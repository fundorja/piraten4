-- PiratePatientManager: Spawns Sailing Ships, Cursed/Healthy Pirate Patients, and Routes them to Hospital Rooms
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PirateTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PirateTypes"))

local PiratePatientManager = {}
local CheckInManagerRef = nil
local ShipArrivalManagerRef = nil
local HospitalRoomsManagerRef = nil

local COUNTER_STOP = Vector3.new(169, 7.6, 80) -- Right in front of Check-In Window

local function createPirateDummy(position, data)
	local dummy = Instance.new("Model")
	dummy.Name = data.Name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = position + Vector3.new(0, 3, 0)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = false
	root.Parent = dummy
	dummy.PrimaryPart = root

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = position + Vector3.new(0, 3, 0)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = data.TorsoColor or Color3.fromRGB(110, 50, 45)
	torso.Anchored = false
	torso.CanCollide = true
	torso.Transparency = data.Transparency or 0
	torso.Parent = dummy

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Position = position + Vector3.new(0, 4.6, 0)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = data.HeadColor or Color3.fromRGB(220, 180, 140)
	head.Anchored = false
	head.CanCollide = true
	head.Transparency = data.Transparency or 0
	head.Parent = dummy

	-- Glowing Eyes if cursed
	if data.EyeColor then
		for _, eyeSide in ipairs({-0.3, 0.3}) do
			local eye = Instance.new("Part")
			eye.Name = "CurseEye"
			eye.Size = Vector3.new(0.2, 0.2, 0.2)
			eye.CFrame = head.CFrame * CFrame.new(eyeSide, 0.2, -0.6)
			eye.Color = data.EyeColor
			eye.Material = Enum.Material.Neon
			eye.CanCollide = false
			eye.Anchored = false
			eye.Parent = dummy

			local weld = Instance.new("Weld", head)
			weld.Part0 = head
			weld.Part1 = eye
			weld.C0 = CFrame.new(eyeSide, 0.2, -0.6)
		end
	end

	-- Ghost / Curse Aura Particles
	if data.CurseKey == "Ghost_Curse" then
		local pe = Instance.new("ParticleEmitter", torso)
		pe.Rate = 15
		pe.Speed = NumberRange.new(0.5, 2)
		pe.Lifetime = NumberRange.new(1, 2)
		pe.Size = NumberSequence.new(0.8, 0)
		pe.Color = ColorSequence.new(Color3.fromRGB(100, 255, 200))
		pe.Transparency = NumberSequence.new(0.4, 1)
		pe.LightEmission = 1
	elseif data.CurseKey == "Skeleton_Curse" then
		local pe = Instance.new("ParticleEmitter", torso)
		pe.Rate = 8
		pe.Speed = NumberRange.new(0.2, 1)
		pe.Lifetime = NumberRange.new(0.5, 1.2)
		pe.Size = NumberSequence.new(0.4, 0)
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 60, 0))
		pe.LightEmission = 1
	end

	-- Limbs
	local function makeLimb(name, size, offset, color)
		local limb = Instance.new("Part")
		limb.Name = name
		limb.Size = size
		limb.Position = position + offset
		limb.Color = color or Color3.fromRGB(100, 70, 45)
		limb.Material = Enum.Material.SmoothPlastic
		limb.Transparency = data.Transparency or 0
		limb.Parent = dummy

		local weld = Instance.new("Weld", torso)
		weld.Part0 = torso
		weld.Part1 = limb
		weld.C0 = CFrame.new(offset.X, offset.Y - 3, offset.Z)
		return limb
	end

	makeLimb("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), data.HeadColor)
	makeLimb("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), data.HeadColor)
	makeLimb("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), Color3.fromRGB(40, 45, 60))
	makeLimb("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), Color3.fromRGB(40, 45, 60))

	local humanoid = Instance.new("Humanoid", dummy)
	humanoid.WalkSpeed = 11

	local rootWeld = Instance.new("Weld", root)
	rootWeld.Part0 = root
	rootWeld.Part1 = torso

	local headWeld = Instance.new("Weld", torso)
	headWeld.Part0 = torso
	headWeld.Part1 = head
	headWeld.C0 = CFrame.new(0, 1.6, 0)

	dummy.Parent = workspace
	return dummy
end

local function walkNPC(dummy, destination, onReached)
	local humanoid = dummy:FindFirstChild("Humanoid")
	if not humanoid then return end

	humanoid:MoveTo(destination)
	local conn
	conn = humanoid.MoveToFinished:Connect(function()
		conn:Disconnect()
		if onReached then onReached() end
	end)
end

function PiratePatientManager.SpawnPatient()
	local name = PirateTypes.Names[math.random(1, #PirateTypes.Names)]
	local isCursed = (math.random(1, 100) <= 40)

	local pData = {
		Name = name,
		Type = isCursed and "Cursed" or "Healthy",
		HasPrintedDoc = false,
		HasTakenPhoto = false,
	}

	local selectedShip = nil

	if isCursed then
		local curseKeys = { "Skeleton_Curse", "Davy_Jones_Curse", "Ghost_Curse", "Voodoo_Curse" }
		local cKey = curseKeys[math.random(1, #curseKeys)]
		local curseInfo = PirateTypes.Curses[cKey]

		pData.CurseKey = cKey
		pData.CurseName = curseInfo.Name
		pData.CurseHint = curseInfo.Hint
		pData.Ship = curseInfo.Ship
		pData.Illness = "Verdacht auf: " .. curseInfo.Name
		pData.Symptoms = curseInfo.Symptoms
		pData.HeadColor = curseInfo.HeadColor
		pData.TorsoColor = curseInfo.TorsoColor
		pData.EyeColor = curseInfo.EyeColor
		pData.Transparency = curseInfo.Transparency
		pData.SealValid = false
		pData.AssignedRoom = curseInfo.AssignedRoom
		pData.RequiredMedicine = "Holy_Water"

		-- Find matching ship
		for _, bShip in ipairs(PirateTypes.Ships.Banned) do
			if bShip.Curse == cKey or bShip.Name == curseInfo.Ship then
				selectedShip = bShip
				break
			end
		end
		if not selectedShip then selectedShip = PirateTypes.Ships.Banned[1] end
	else
		local illness = PirateTypes.NormalIllnesses[math.random(1, #PirateTypes.NormalIllnesses)]
		selectedShip = PirateTypes.Ships.Allowed[math.random(1, #PirateTypes.Ships.Allowed)]

		pData.Ship = selectedShip.Name
		pData.Illness = illness.Name
		pData.Symptoms = illness.Symptoms
		pData.HeadColor = Color3.fromRGB(225, 185, 145)
		pData.TorsoColor = Color3.fromRGB(120, 60, 45)
		pData.SealValid = true
		pData.AssignedRoom = illness.AssignedRoom
		pData.RequiredMedicine = illness.RequiredMedicine
	end

	-- Sail the ship into the harbor dock!
	if ShipArrivalManagerRef then
		ShipArrivalManagerRef.SailShipToHarbor(selectedShip, function()
			-- When ship docks, step pirate patient off onto pier!
			local dummy = createPirateDummy(Constants.PIER_ARRIVAL_POINT, pData)

			walkNPC(dummy, COUNTER_STOP, function()
				print("[PiratePatientManager] Pirate " .. name .. " arrived at Check-In Desk!")
				if CheckInManagerRef then
					CheckInManagerRef.SetCurrentPatient(dummy, pData)
				end
			end)
		end)
	end
end

function PiratePatientManager.SendToHospitalBed(patientModel, pData)
	if HospitalRoomsManagerRef and pData then
		HospitalRoomsManagerRef.AssignPatientToRoom(patientModel, pData)
	else
		local bedPos = Vector3.new(-65, 8.0, -160)
		walkNPC(patientModel, bedPos, function()
			patientModel:PivotTo(CFrame.new(bedPos + Vector3.new(0, 1.8, 0)) * CFrame.Angles(math.rad(-90), 0, 0))
		end)
	end
end

function PiratePatientManager.SendToQuarantine(patientModel)
	local cellPos = Vector3.new(85, 8.0, -110)
	patientModel:PivotTo(CFrame.new(cellPos + Vector3.new(0, 3, 0)))
	task.delay(8, function()
		if patientModel and patientModel.Parent then
			patientModel:Destroy()
		end
	end)
end

function PiratePatientManager.TriggerCurseOutbreak(patientModel, data)
	local root = patientModel:FindFirstChild("HumanoidRootPart")
	if root then
		local ex = Instance.new("Explosion", workspace)
		ex.Position = root.Position
		ex.BlastPressure = 0
		ex.BlastRadius = 12
	end
	task.delay(4, function()
		if patientModel and patientModel.Parent then
			patientModel:Destroy()
		end
	end)
end

function PiratePatientManager.DismissPatient(patientModel)
	walkNPC(patientModel, Constants.PIER_ARRIVAL_POINT, function()
		if patientModel and patientModel.Parent then
			patientModel:Destroy()
		end
	end)
end

function PiratePatientManager.SetCheckInManager(manager)
	CheckInManagerRef = manager
end

function PiratePatientManager.SetShipArrivalManager(manager)
	ShipArrivalManagerRef = manager
end

function PiratePatientManager.SetHospitalRoomsManager(manager)
	HospitalRoomsManagerRef = manager
end

return PiratePatientManager
