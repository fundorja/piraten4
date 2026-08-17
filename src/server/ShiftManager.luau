-- ShiftManager: Manages Shifts/Days Survived, Sanity Brain Meter, Player Classes, and Overhead Badges
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local ClassTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClassTypes"))
local ShopTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopTypes"))

local ShiftManager = {}

local playerData = {} 
-- [Player] = { 
--   CurrentShift = 1, TopShift = 1, Sanity = 100, Class = "Praktikant", 
--   UnlockedClasses = { Praktikant = true }, Upgrades = {} 
-- }

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

local UpdatePlayerStateEvent = getOrCreateRemote("UpdatePlayerState")
local SelectClassEvent = getOrCreateRemote("SelectClass")
local BuyShopItemEvent = getOrCreateRemote("BuyShopItem")
local ShowNotificationEvent = getOrCreateRemote("ShowNotification")
local DrinkCoffeeEvent = getOrCreateRemote("DrinkCoffee")

-- Attach Overhead BillboardUI above player's character (Matches Screenshot 1!)
local function attachPlayerOverheadUI(player, char)
	local head = char:WaitForChild("Head", 5)
	if not head then return end

	local existing = head:FindFirstChild("PlayerTopShiftBillboard")
	if existing then existing:Destroy() end

	local data = playerData[player] or { TopShift = 1, Class = "Praktikant" }
	local classInfo = ClassTypes.Classes[data.Class] or ClassTypes.Classes.Praktikant

	local bb = Instance.new("BillboardGui")
	bb.Name = "PlayerTopShiftBillboard"
	bb.Size = UDim2.new(5, 0, 2.5, 0)
	bb.StudsOffset = Vector3.new(0, 3.0, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 50
	bb.PlayerToHideFrom = player -- Hides from the player itself so it never blocks your own screen!
	bb.Parent = head

	local frame = Instance.new("Frame", bb)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1

	-- Clipboard Icon on left
	local iconLabel = Instance.new("TextLabel", frame)
	iconLabel.Size = UDim2.new(0.3, 0, 0.9, 0)
	iconLabel.Position = UDim2.new(0, 0, 0.05, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = "📋"
	iconLabel.TextScaled = true

	-- Text Container on right
	local topShiftLabel = Instance.new("TextLabel", frame)
	topShiftLabel.Name = "TopShiftLabel"
	topShiftLabel.Size = UDim2.new(0.72, 0, 0.48, 0)
	topShiftLabel.Position = UDim2.new(0.28, 0, 0, 0)
	topShiftLabel.BackgroundTransparency = 1
	topShiftLabel.Text = "Top-Schicht: " .. tostring(data.TopShift)
	topShiftLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	topShiftLabel.TextScaled = true
	topShiftLabel.Font = Enum.Font.Antique

	local classLabel = Instance.new("TextLabel", frame)
	classLabel.Name = "ClassLabel"
	classLabel.Size = UDim2.new(0.72, 0, 0.45, 0)
	classLabel.Position = UDim2.new(0.28, 0, 0.52, 0)
	classLabel.BackgroundTransparency = 1
	classLabel.Text = classInfo.Title
	classLabel.TextColor3 = Color3.fromRGB(245, 215, 60)
	classLabel.TextScaled = true
	classLabel.Font = Enum.Font.GothamBold
end

local function syncPlayerState(player)
	local data = playerData[player]
	if not data then return end

	UpdatePlayerStateEvent:FireClient(player, {
		CurrentShift = data.CurrentShift,
		TopShift = data.TopShift,
		Sanity = data.Sanity,
		Class = data.Class,
		ClassInfo = ClassTypes.Classes[data.Class],
		UnlockedClasses = data.UnlockedClasses,
		Upgrades = data.Upgrades
	})

	if player.Character then
		attachPlayerOverheadUI(player, player.Character)
	end
end

function ShiftManager.GetPlayerData(player)
	return playerData[player]
end

function ShiftManager.ModifySanity(player, delta)
	local data = playerData[player]
	if not data then return end

	local classInfo = ClassTypes.Classes[data.Class] or ClassTypes.Classes.Praktikant
	if delta < 0 then
		delta = delta * (classInfo.SanityDrainMultiplier or 1.0)
	end

	data.Sanity = math.clamp(data.Sanity + delta, 0, 100)
	syncPlayerState(player)

	if data.Sanity <= 20 then
		ShowNotificationEvent:FireClient(player, "🧠 VERNUNFT KRITISCH NIEDRIG! Trinke Kaffee im Pausenraum!", Color3.fromRGB(255, 50, 50))
	end
end

function ShiftManager.AdvanceShift(player)
	local data = playerData[player]
	if not data then return end

	data.CurrentShift = data.CurrentShift + 1
	data.TopShift = math.max(data.TopShift, data.CurrentShift)
	data.Sanity = math.min(100, data.Sanity + 20)

	ShowNotificationEvent:FireClient(player, "🎉 SCHICHT ÜBERLEBT! Willkommen in Schicht " .. data.CurrentShift .. "!", Color3.fromRGB(80, 255, 140))
	syncPlayerState(player)
end

function ShiftManager.Init()
	print("[ShiftManager] Initializing Shifts, Sanity, and Class Systems...")

	Players.PlayerAdded:Connect(function(p)
		playerData[p] = {
			CurrentShift = 1,
			TopShift = 8, -- Starter demo high score
			Sanity = 100,
			Class = "Krankenschwester",
			UnlockedClasses = { Praktikant = true, Krankenschwester = true },
			Upgrades = {}
		}

		p.CharacterAdded:Connect(function(char)
			task.wait(0.5)
			attachPlayerOverheadUI(p, char)
		end)

		syncPlayerState(p)
	end)

	for _, p in ipairs(Players:GetPlayers()) do
		playerData[p] = {
			CurrentShift = 1,
			TopShift = 8,
			Sanity = 100,
			Class = "Krankenschwester",
			UnlockedClasses = { Praktikant = true, Krankenschwester = true },
			Upgrades = {}
		}
		if p.Character then
			attachPlayerOverheadUI(p, p.Character)
		end
		syncPlayerState(p)
	end

	-- Class Change Listener
	SelectClassEvent.OnServerEvent:Connect(function(player, classId)
		local data = playerData[player]
		if not data then return end

		local classInfo = ClassTypes.Classes[classId]
		if classInfo and (data.UnlockedClasses[classId] or classInfo.UnlockCost == 0) then
			data.Class = classId
			ShowNotificationEvent:FireClient(player, "🎭 Klasse gewechselt: " .. classInfo.Name, Color3.fromRGB(100, 220, 255))
			syncPlayerState(player)
		end
	end)

	-- Coffee Machine Drink Listener
	DrinkCoffeeEvent.OnServerEvent:Connect(function(player)
		ShiftManager.ModifySanity(player, 35)
		ShowNotificationEvent:FireClient(player, "☕ *Schlürf!* Heißer Kaffee getrunken! (+35% Vernunft)", Color3.fromRGB(255, 220, 120))
	end)
end

return ShiftManager
