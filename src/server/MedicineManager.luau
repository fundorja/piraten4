-- MedicineManager: Manages the 5-Slot Player Inventory, Medicine Dispensers, and Patient Treatment
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PirateTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PirateTypes"))

local MedicineManager = {}

local playerInventories = {} -- [Player] = { {Id = "...", Name = "...", Icon = "..."} }
local playerGold = {} -- [Player] = number

local Events = ReplicatedStorage:WaitForChild("Events")
local function getOrCreateRemote(name, class)
	class = class or "RemoteEvent"
	local r = Events:FindFirstChild(name)
	if not r then
		r = Instance.new(class, Events)
		r.Name = name
	end
	return r
end

local UpdateInventoryEvent = getOrCreateRemote("UpdateInventory")
local AdministerMedicineEvent = getOrCreateRemote("AdministerMedicine")
local ShowNotificationEvent = getOrCreateRemote("ShowNotification")

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

-- Syncs inventory with client HUD
local function syncPlayerInventory(player)
	local inv = playerInventories[player] or {}
	local gold = playerGold[player] or 0
	UpdateInventoryEvent:FireClient(player, inv, gold)
end

function MedicineManager.AddItem(player, medId)
	local inv = playerInventories[player]
	if not inv then
		inv = {}
		playerInventories[player] = inv
	end

	if #inv >= Constants.MAX_INVENTORY_SLOTS then
		ShowNotificationEvent:FireClient(player, "🎒 Inventar voll! (Max. 5 Gegenstände)", Color3.fromRGB(255, 160, 40))
		return false
	end

	local medData = PirateTypes.Medicines[medId]
	if not medData then return false end

	table.insert(inv, {
		Id = medData.Id,
		Name = medData.Name,
		Icon = medData.Icon,
		Color = medData.Color,
		Description = medData.Description
	})

	syncPlayerInventory(player)
	ShowNotificationEvent:FireClient(player, "🎒 " .. medData.Icon .. " " .. medData.Name .. " eingesteckt! (" .. #inv .. "/5)", Color3.fromRGB(100, 255, 140))
	return true
end

function MedicineManager.RemoveItem(player, slotIndex)
	local inv = playerInventories[player]
	if not inv or not inv[slotIndex] then return false end

	local removed = table.remove(inv, slotIndex)
	syncPlayerInventory(player)
	return removed
end

function MedicineManager.HasMedicine(player, targetIllnessOrId)
	local inv = playerInventories[player] or {}
	for idx, item in ipairs(inv) do
		local medInfo = PirateTypes.Medicines[item.Id]
		if item.Id == targetIllnessOrId or (medInfo and medInfo.TargetIllness == targetIllnessOrId) then
			return true, idx, item
		end
	end
	return false, nil, nil
end

function MedicineManager.AwardGold(player, amount)
	playerGold[player] = (playerGold[player] or 0) + amount
	syncPlayerInventory(player)
end

-- Builds the 5 Medicine Shelves in Room 6 (Alchemy Lab)
function MedicineManager.BuildMedicineDispensers(labCenter, parentFolder)
	print("[MedicineManager] Building 5 Medicine Dispensers in Alchemy Lab...")

	local shelfCenter = labCenter + Vector3.new(0, 0, 10)
	local shelfBase = createPart(parentFolder, "MedicineCabinet", Vector3.new(22, 5, 2.5), CFrame.new(shelfCenter + Vector3.new(0, 2.5, 0)), Color3.fromRGB(75, 48, 26), Enum.Material.WoodPlanks)

	local medicinesList = {
		{ Id = "Lemon_Tonic", XOff = -8, Color = Color3.fromRGB(245, 220, 40) },
		{ Id = "PegLeg_Splint", XOff = -4, Color = Color3.fromRGB(140, 95, 55) },
		{ Id = "Parrot_Antidote", XOff = 0, Color = Color3.fromRGB(60, 220, 120) },
		{ Id = "Herbal_Rum", XOff = 4, Color = Color3.fromRGB(190, 120, 50) },
		{ Id = "Holy_Water", XOff = 8, Color = Color3.fromRGB(100, 220, 255) },
	}

	for _, m in ipairs(medicinesList) do
		local medData = PirateTypes.Medicines[m.Id]
		local bottlePos = shelfCenter + Vector3.new(m.XOff, 5.8, 0)

		-- Medicine Bottle Model
		local bottle = createPart(parentFolder, "MedBottle_" .. m.Id, Vector3.new(1.2, 2, 1.2), CFrame.new(bottlePos), m.Color, Enum.Material.Glass, Enum.PartType.Cylinder)
		bottle.CFrame = bottle.CFrame * CFrame.Angles(0, 0, math.rad(90))

		local cap = createPart(parentFolder, "BottleCap", Vector3.new(0.6, 0.4, 0.6), CFrame.new(bottlePos + Vector3.new(0, 1.2, 0)), Color3.fromRGB(130, 85, 45), Enum.Material.Wood)

		-- Billboard Label
		local bb = Instance.new("BillboardGui", bottle)
		bb.Size = UDim2.new(5, 0, 2, 0)
		bb.StudsOffset = Vector3.new(0, 2.2, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 35

		local label = Instance.new("TextLabel", bb)
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = medData.Icon .. " " .. medData.Name
		label.TextColor3 = m.Color
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold

		-- ProximityPrompt to pick up
		local prompt = Instance.new("ProximityPrompt", bottle)
		prompt.ActionText = "Nehmen: " .. medData.Name
		prompt.ObjectText = medData.Icon .. " Medizin-Regal"
		prompt.HoldDuration = 0.3
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 12

		prompt.Triggered:Connect(function(triggeringPlayer)
			MedicineManager.AddItem(triggeringPlayer, m.Id)
		end)
	end
end

function MedicineManager.Init()
	Players.PlayerAdded:Connect(function(p)
		playerInventories[p] = {}
		playerGold[p] = 50 -- Starting gold
		syncPlayerInventory(p)
	end)

	for _, p in ipairs(Players:GetPlayers()) do
		playerInventories[p] = {}
		playerGold[p] = 50
		syncPlayerInventory(p)
	end
end

return MedicineManager
