-- ShipArrivalManager: Full 3D Ghost Pirate Galleon Sailing Animation, Banners & Fog Effects
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local ShipArrivalManager = {}
local currentActiveShip = nil

local function createPart(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.WoodPlanks
	if shape then p.Shape = shape end
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeWedge(name, size, cf, color, material, parent)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = material or Enum.Material.WoodPlanks
	w.Anchored = true
	w.CanCollide = false
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent
	return w
end

-- Constructs Full 3D Ghost Pirate Galleon (209 Parts: 3 Masts, Tattered Sails, Skull Figurehead, 14 Cannons)
local function buildDetailedGalleon(shipData, baseCF)
	local ship = Instance.new("Model")
	ship.Name = "SailingPirateShip"

	local isCursed = (shipData.Curse ~= nil or shipData.Name:match("DUTCHMAN") or shipData.Name:match("GEISTER"))

	-- Colors
	local WOOD_DARK   = isCursed and Color3.fromRGB(28, 22, 25) or Color3.fromRGB(45, 30, 20)
	local WOOD_MED    = isCursed and Color3.fromRGB(45, 38, 40) or Color3.fromRGB(75, 50, 32)
	local WOOD_LIGHT  = isCursed and Color3.fromRGB(60, 52, 55) or Color3.fromRGB(105, 72, 45)
	local WOOD_ROT    = isCursed and Color3.fromRGB(38, 48, 38) or Color3.fromRGB(65, 45, 28)
	local SAIL_TORN   = isCursed and Color3.fromRGB(35, 40, 38) or Color3.fromRGB(235, 225, 205)
	local SAIL_COLOR  = isCursed and Color3.fromRGB(18, 20, 22) or Color3.fromRGB(245, 240, 225)
	local METAL_RUST  = Color3.fromRGB(55, 40, 35)
	local BONE_WHITE  = Color3.fromRGB(220, 215, 200)
	local ROPE_COLOR  = Color3.fromRGB(70, 55, 40)

	local HULL_LENGTH = 70
	local HULL_WIDTH  = 18
	local HULL_HEIGHT = 12
	local DECK_Y      = HULL_HEIGHT - 2

	-- Hull
	local hullFolder = Instance.new("Folder", ship)
	hullFolder.Name = "Hull"

	local keel = createPart(hullFolder, "Keel", Vector3.new(2, 2, HULL_LENGTH), baseCF * CFrame.new(0, 1, 0), WOOD_DARK, Enum.Material.Wood)
	ship.PrimaryPart = keel

	local numSegments = 10
	for i = 0, numSegments do
		local progress = i / numSegments
		local zPos = -HULL_LENGTH / 2 + progress * HULL_LENGTH
		local widthFactor = math.sin(progress * math.pi)
		local currentWidth = math.max(HULL_WIDTH * widthFactor, 4)

		createPart(hullFolder, "HullSegment_" .. i, Vector3.new(currentWidth, HULL_HEIGHT, HULL_LENGTH / numSegments + 0.2),
			baseCF * CFrame.new(0, HULL_HEIGHT / 2, zPos),
			i % 2 == 0 and WOOD_DARK or WOOD_MED, Enum.Material.WoodPlanks)

		for _, side in ipairs({-1, 1}) do
			createPart(hullFolder, "PlankRow_" .. side .. "_" .. i, Vector3.new(0.6, HULL_HEIGHT, HULL_LENGTH / numSegments + 0.2),
				baseCF * CFrame.new(side * (currentWidth / 2), HULL_HEIGHT / 2, zPos),
				WOOD_LIGHT, Enum.Material.WoodPlanks)
		end
	end

	-- Bow Wedges
	makeWedge("BowWedge_L", Vector3.new(HULL_WIDTH / 2, HULL_HEIGHT, 14),
		baseCF * CFrame.new(-HULL_WIDTH / 4, HULL_HEIGHT / 2, -HULL_LENGTH / 2 - 7) * CFrame.Angles(0, math.rad(180), 0),
		WOOD_DARK, Enum.Material.Wood, hullFolder)
	makeWedge("BowWedge_R", Vector3.new(HULL_WIDTH / 2, HULL_HEIGHT, 14),
		baseCF * CFrame.new(HULL_WIDTH / 4, HULL_HEIGHT / 2, -HULL_LENGTH / 2 - 7) * CFrame.Angles(0, math.rad(180), 0),
		WOOD_DARK, Enum.Material.Wood, hullFolder)

	-- Stern Castle
	local sternFolder = Instance.new("Folder", ship)
	sternFolder.Name = "Stern"
	local sternBaseCF = baseCF * CFrame.new(0, HULL_HEIGHT, HULL_LENGTH / 2 - 6)
	createPart(sternFolder, "SternCastle_Floor", Vector3.new(HULL_WIDTH * 0.85, 1, 16), sternBaseCF, WOOD_DARK, Enum.Material.WoodPlanks)
	createPart(sternFolder, "SternCastle_Wall_L", Vector3.new(1, 8, 16), sternBaseCF * CFrame.new(-HULL_WIDTH * 0.42, 4, 0), WOOD_MED, Enum.Material.WoodPlanks)
	createPart(sternFolder, "SternCastle_Wall_R", Vector3.new(1, 8, 16), sternBaseCF * CFrame.new(HULL_WIDTH * 0.42, 4, 0), WOOD_MED, Enum.Material.WoodPlanks)
	createPart(sternFolder, "SternCastle_Back", Vector3.new(HULL_WIDTH * 0.85, 8, 1), sternBaseCF * CFrame.new(0, 4, 8), WOOD_DARK, Enum.Material.WoodPlanks)
	createPart(sternFolder, "SternCastle_Roof", Vector3.new(HULL_WIDTH * 0.9, 1, 17), sternBaseCF * CFrame.new(0, 8.5, 0), WOOD_DARK, Enum.Material.WoodPlanks)

	-- Main Deck & Railing
	local deckFolder = Instance.new("Folder", ship)
	deckFolder.Name = "Deck"
	createPart(deckFolder, "MainDeck", Vector3.new(HULL_WIDTH - 1, 1, HULL_LENGTH - 4), baseCF * CFrame.new(0, DECK_Y / 2, 0), WOOD_ROT, Enum.Material.WoodPlanks)

	for _, side in ipairs({-1, 1}) do
		for i = 0, 14 do
			local zPos = -HULL_LENGTH / 2 + 6 + i * ((HULL_LENGTH - 12) / 14)
			createPart(deckFolder, "RailPost_" .. side .. "_" .. i, Vector3.new(0.6, 3, 0.6),
				baseCF * CFrame.new(side * (HULL_WIDTH / 2 - 0.5), DECK_Y + 1.5, zPos),
				WOOD_DARK, Enum.Material.Wood)
		end
		createPart(deckFolder, "RailTop_" .. side, Vector3.new(0.6, 0.6, HULL_LENGTH - 12),
			baseCF * CFrame.new(side * (HULL_WIDTH / 2 - 0.5), DECK_Y + 3, 0),
			WOOD_DARK, Enum.Material.Wood)
	end

	-- 3 Masts, Yards & Sails
	local mastFolder = Instance.new("Folder", ship)
	mastFolder.Name = "Masts"
	local mastData = {
		{ name = "Foremast", zOffset = -HULL_LENGTH * 0.28, height = 45, sailWidth = 16 },
		{ name = "Mainmast", zOffset = 2, height = 55, sailWidth = 20 },
		{ name = "Mizzenmast", zOffset = HULL_LENGTH * 0.3, height = 35, sailWidth = 12 },
	}

	for _, mData in ipairs(mastData) do
		local mBase = baseCF * CFrame.new(0, DECK_Y, mData.zOffset)
		createPart(mastFolder, mData.name .. "_Pole", Vector3.new(1.4, mData.height, 1.4), mBase * CFrame.new(0, mData.height / 2, 0), WOOD_DARK, Enum.Material.Wood)
		createPart(mastFolder, mData.name .. "_CrowsNest", Vector3.new(3, 1.5, 3), mBase * CFrame.new(0, mData.height * 0.85, 0), WOOD_MED, Enum.Material.Wood)

		for level = 1, 2 do
			local yardY = mData.height * (level == 1 and 0.4 or 0.65)
			local yardWidth = mData.sailWidth
			createPart(mastFolder, mData.name .. "_Yard" .. level, Vector3.new(yardWidth, 0.6, 0.6), mBase * CFrame.new(0, yardY, 0), WOOD_MED, Enum.Material.Wood)

			-- Tattered or billowed sails
			local strips = 6
			for s = 0, strips - 1 do
				local stripWidth = (yardWidth - 1) / strips
				local hVar = (mData.height * 0.32) * (0.75 + math.random() * 0.25)
				local xOff = -(yardWidth - 1) / 2 + stripWidth * (s + 0.5)
				createPart(mastFolder, mData.name .. "_Sail_" .. level .. "_" .. s, Vector3.new(stripWidth - 0.2, hVar, 0.15),
					mBase * CFrame.new(xOff, yardY - mData.height * 0.18, 0.3),
					(s % 2 == 0) and SAIL_COLOR or SAIL_TORN, Enum.Material.Fabric)
			end
		end
	end

	-- Giant Figurehead Skull on Bowsprit
	local bowFolder = Instance.new("Folder", ship)
	bowFolder.Name = "Bowsprit"
	local bowspritCF = baseCF * CFrame.new(0, DECK_Y - 1, -HULL_LENGTH / 2 - 8)
	createPart(bowFolder, "BowspritPole", Vector3.new(1, 1, 16), bowspritCF * CFrame.new(0, 0, 8) * CFrame.Angles(math.rad(-15), 0, 0), WOOD_DARK, Enum.Material.Wood)

	local skullCF = bowspritCF * CFrame.new(0, -1, 16)
	createPart(bowFolder, "FigureheadSkull", Vector3.new(4, 4, 4), skullCF, BONE_WHITE, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	createPart(bowFolder, "FigureheadJaw", Vector3.new(3, 1.4, 3.2), skullCF * CFrame.new(0, -2.2, 0.2), BONE_WHITE, Enum.Material.SmoothPlastic)

	-- 14 Cannons (7 per side)
	local cannonFolder = Instance.new("Folder", ship)
	cannonFolder.Name = "Cannons"
	for _, side in ipairs({-1, 1}) do
		for i = 0, 6 do
			local zPos = -HULL_LENGTH / 2 + 10 + i * ((HULL_LENGTH - 20) / 6)
			local cannonCF = baseCF * CFrame.new(side * (HULL_WIDTH / 2 - 0.5), 2, zPos) * CFrame.Angles(0, 0, math.rad(90) * side)
			createPart(cannonFolder, "Cannon_" .. side .. "_" .. i, Vector3.new(1.2, 1.2, 5), cannonCF, Color3.fromRGB(25, 25, 28), Enum.Material.Metal, Enum.PartType.Cylinder)
		end
	end

	-- Top Mast Name Banner (Visible from Reception Window!)
	local bannerPart = createPart(ship, "ShipNameBannerPart", Vector3.new(0.5, 3.5, 18), baseCF * CFrame.new(0, DECK_Y + 58, 2), Color3.fromRGB(20, 22, 28), Enum.Material.SmoothPlastic)
	local bb = Instance.new("BillboardGui", bannerPart)
	bb.Size = UDim2.new(16, 0, 4, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 350
	local nameLabel = Instance.new("TextLabel", bb)
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 0.2
	nameLabel.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
	nameLabel.Text = (shipData.Flag or "⛵") .. "  " .. string.upper(shipData.Name)
	nameLabel.TextColor3 = isCursed and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 225, 100)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Antique

	local uiCorner = Instance.new("UICorner", nameLabel)
	uiCorner.CornerRadius = UDim.new(0, 10)
	local uiStroke = Instance.new("UIStroke", nameLabel)
	uiStroke.Color = isCursed and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 215, 60)
	uiStroke.Thickness = 3

	-- Spooky Green Ghost Fire / Torches for Cursed Ships
	if isCursed then
		local ghostGlow = createPart(ship, "GhostAura", Vector3.new(6, 6, 6), baseCF * CFrame.new(0, DECK_Y + 10, 0), Color3.fromRGB(80, 255, 120), Enum.Material.Neon, Enum.PartType.Ball)
		ghostGlow.Transparency = 0.6
		local pl = Instance.new("PointLight", ghostGlow)
		pl.Color = Color3.fromRGB(80, 255, 120)
		pl.Brightness = 3
		pl.Range = 40
	end

	ship.Parent = workspace
	return ship
end

function ShipArrivalManager.SailShipToHarbor(shipData, onDockedCallback)
	if currentActiveShip and currentActiveShip.Parent then
		currentActiveShip:Destroy()
	end

	local spawnCF = CFrame.new(Constants.SHIP_OCEAN_SPAWN) * CFrame.Angles(0, math.rad(-90), 0)
	local dockCF = CFrame.new(Constants.SHIP_DOCK_POSITION) * CFrame.Angles(0, math.rad(-90), 0)

	local shipModel = buildDetailedGalleon(shipData, spawnCF)
	currentActiveShip = shipModel

	print("[ShipArrivalManager] Ship '" .. shipData.Name .. "' setting sail from ocean towards harbor...")

	-- Smooth Sailing Tween
	local travelTime = 7.5
	local startTime = os.clock()

	task.spawn(function()
		while (os.clock() - startTime) < travelTime do
			local dt = task.wait()
			local elapsed = os.clock() - startTime
			local alpha = math.clamp(elapsed / travelTime, 0, 1)

			local currentPos = Constants.SHIP_OCEAN_SPAWN:Lerp(Constants.SHIP_DOCK_POSITION, alpha)
			local bobbingY = math.sin(elapsed * 2.5) * 0.8
			local rollAngle = math.sin(elapsed * 2.0) * math.rad(2.5)

			local newCF = CFrame.new(currentPos + Vector3.new(0, bobbingY, 0)) * CFrame.Angles(0, math.rad(-90), rollAngle)
			if shipModel and shipModel.PrimaryPart then
				shipModel:PivotTo(newCF)
			end
		end

		if shipModel and shipModel.PrimaryPart then
			shipModel:PivotTo(dockCF)
		end

		print("[ShipArrivalManager] Ship '" .. shipData.Name .. "' successfully docked at the pier!")
		if onDockedCallback then
			onDockedCallback()
		end
	end)

	return shipModel
end

function ShipArrivalManager.DepartShip()
	if not currentActiveShip or not currentActiveShip.Parent then return end
	local shipModel = currentActiveShip
	local startCF = shipModel:GetPivot()
	local endPos = Constants.SHIP_OCEAN_SPAWN

	task.spawn(function()
		local startTime = os.clock()
		local travelTime = 6.0
		while (os.clock() - startTime) < travelTime do
			task.wait()
			local elapsed = os.clock() - startTime
			local alpha = math.clamp(elapsed / travelTime, 0, 1)
			local curPos = startCF.Position:Lerp(endPos, alpha)
			if shipModel and shipModel.PrimaryPart then
				shipModel:PivotTo(CFrame.new(curPos) * CFrame.Angles(0, math.rad(90), 0))
			end
		end
		if shipModel and shipModel.Parent then
			shipModel:Destroy()
		end
	end)
end

return ShipArrivalManager
