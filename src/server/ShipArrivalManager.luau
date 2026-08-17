-- ShipArrivalManager: Animated Sailing Ships with Visible Name Banners
local TweenService = game:GetService("TweenService")
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local ShipArrivalManager = {}
local activeShip = nil

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

-- Builds a stylized Sailing Pirate Ship
local function buildShipModel(shipData, startPos)
	local model = Instance.new("Model")
	model.Name = "DockedPirateShip"

	local shipColor = shipData.Color or Color3.fromRGB(80, 50, 28)

	-- 1. Main Hull
	local hull = createPart(model, "Hull", Vector3.new(42, 8, 16), CFrame.new(startPos + Vector3.new(0, 3, 0)), shipColor, Enum.Material.WoodPlanks)
	model.PrimaryPart = hull

	-- Bow (Front Wedge)
	local bow = Instance.new("WedgePart", model)
	bow.Name = "Bow"
	bow.Size = Vector3.new(16, 8, 12)
	bow.CFrame = CFrame.new(startPos + Vector3.new(-27, 3, 0)) * CFrame.Angles(0, math.rad(-90), 0)
	bow.Color = shipColor
	bow.Material = Enum.Material.WoodPlanks
	bow.Anchored = true

	-- Stern (Rear Cabin)
	createPart(model, "SternCabin", Vector3.new(12, 6, 14), CFrame.new(startPos + Vector3.new(15, 8, 0)), shipColor, Enum.Material.WoodPlanks)

	-- 2. Masts & Sails
	for _, mastX in ipairs({-8, 6}) do
		local mast = createPart(model, "Mast", Vector3.new(1.6, 26, 1.6), CFrame.new(startPos + Vector3.new(mastX, 15, 0)), Color3.fromRGB(65, 40, 22), Enum.Material.Wood)
		-- Sail Crossbeam & Cloth
		createPart(model, "Crossbeam", Vector3.new(1.2, 1.2, 18), CFrame.new(startPos + Vector3.new(mastX, 20, 0)), Color3.fromRGB(65, 40, 22), Enum.Material.Wood)
		local sail = createPart(model, "Sail", Vector3.new(0.4, 14, 17), CFrame.new(startPos + Vector3.new(mastX - 0.8, 16, 0)), Color3.fromRGB(240, 235, 220), Enum.Material.Fabric)
		sail.CanCollide = false
	end

	-- 3. PROMINENT GLOWING SHIP NAME BANNER (Visible from Reception Window!)
	local mainMastPos = startPos + Vector3.new(-1, 28, 0)
	local nameBoard = createPart(model, "ShipNameBoard", Vector3.new(1.2, 4.5, 22), CFrame.new(mainMastPos), Color3.fromRGB(20, 22, 28), Enum.Material.SmoothPlastic)
	nameBoard.CanCollide = false

	local bb = Instance.new("BillboardGui")
	bb.Name = "ShipNameBillboard"
	bb.Size = UDim2.new(14, 0, 4.5, 0)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 250
	bb.Parent = nameBoard

	local frame = Instance.new("Frame", bb)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 10)

	local isBanned = (shipData.Curse ~= nil)
	local strokeColor = isBanned and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 215, 60)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = strokeColor
	stroke.Thickness = 4

	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, -20, 1, -10)
	label.Position = UDim2.new(0, 10, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = (shipData.Flag or "⛵") .. " " .. shipData.Name
	label.TextColor3 = isBanned and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(255, 245, 200)
	label.TextScaled = true
	label.Font = Enum.Font.Antique

	-- 4. Water Wake Foam Particles
	local wakePart = createPart(model, "WaterWake", Vector3.new(16, 0.4, 16), CFrame.new(startPos + Vector3.new(0, 0.2, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	wakePart.Transparency = 1
	wakePart.CanCollide = false
	local pe = Instance.new("ParticleEmitter", wakePart)
	pe.Rate = 25
	pe.Speed = NumberRange.new(4, 8)
	pe.Lifetime = NumberRange.new(0.8, 1.5)
	pe.Size = NumberSequence.new(1.5, 0.2)
	pe.Color = ColorSequence.new(Color3.fromRGB(220, 245, 255))
	pe.Transparency = NumberSequence.new(0.2, 1)

	model.Parent = workspace.MainIslandAssets
	return model
end

function ShipArrivalManager.SailShipToHarbor(shipData, onDocked)
	if activeShip and activeShip.Parent then
		activeShip:Destroy()
	end

	local startPos = Constants.SHIP_OCEAN_SPAWN
	local endPos = Constants.SHIP_DOCK_POSITION

	print("[ShipArrivalManager] Spawning and sailing ship: " .. shipData.Name .. " into Harbor Pier...")
	local shipModel = buildShipModel(shipData, startPos)
	activeShip = shipModel

	-- Animate Sailing to Pier over 4.5 seconds
	local duration = 4.5
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < duration and shipModel and shipModel.Parent do
			local alpha = math.min((tick() - startTime) / duration, 1)
			-- Smooth sine ease out
			local smoothAlpha = math.sin(alpha * math.pi * 0.5)
			local currentPos = startPos:Lerp(endPos, smoothAlpha)
			
			-- Gentle water bobbing
			local bobY = math.sin(tick() * 3) * 0.4
			shipModel:PivotTo(CFrame.new(currentPos + Vector3.new(0, bobY, 0)))
			
			task.wait(0.03)
		end

		if shipModel and shipModel.Parent then
			shipModel:PivotTo(CFrame.new(endPos))
			print("[ShipArrivalManager] Ship docked at Harbor Pier: " .. shipData.Name)
			if onDocked then onDocked() end
		end
	end)

	return shipModel
end

return ShipArrivalManager
