-- LobbyManager: Manages the 4 Crew Party Pads on the Lobby Island & 10s Teleport Countdown
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local LobbyManager = {}
local padStates = {}

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

-- Builds or ensures the physical Pad Model exists in workspace
local function buildPadModel(padConfig, lobbyFolder)
	local existing = lobbyFolder:FindFirstChild(padConfig.Name)
	if existing then existing:Destroy() end

	local model = Instance.new("Model")
	model.Name = padConfig.Name

	local pos = padConfig.Pos

	-- 1. Main Wooden Deck Platform
	local base = createPart(model, "PadBase", Vector3.new(16, 0.8, 16), CFrame.new(pos + Vector3.new(0, 0.4, 0)), Color3.fromRGB(95, 65, 35), Enum.Material.WoodPlanks, Enum.PartType.Cylinder)
	base.CFrame = base.CFrame * CFrame.Angles(0, 0, math.rad(90))
	model.PrimaryPart = base

	-- 2. Glowing Neon Trim Ring in Crew Color
	local ring = createPart(model, "PadRing", Vector3.new(16.4, 0.3, 16.4), CFrame.new(pos + Vector3.new(0, 0.85, 0)), padConfig.Color, Enum.Material.Neon, Enum.PartType.Cylinder)
	ring.CFrame = ring.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.CanCollide = false

	-- 3. Center Crest
	local crest = createPart(model, "Crest", Vector3.new(5.5, 0.3, 5.5), CFrame.new(pos + Vector3.new(0, 0.95, 0)), Color3.fromRGB(35, 35, 40), Enum.Material.Metal, Enum.PartType.Cylinder)
	crest.CFrame = crest.CFrame * CFrame.Angles(0, 0, math.rad(90))
	crest.CanCollide = false

	-- 4. 4 Tiki Torches around the Pad
	for t = 1, 4 do
		local ta = (t / 4) * math.pi * 2
		local tx = math.cos(ta) * 9.5
		local tz = math.sin(ta) * 9.5
		local tPos = pos + Vector3.new(tx, 0, tz)

		local pole = createPart(model, "TorchPole", Vector3.new(0.5, 7, 0.5), CFrame.new(tPos + Vector3.new(0, 3.5, 0)), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
		local head = createPart(model, "FlameHead", Vector3.new(0.8, 0.8, 0.8), CFrame.new(tPos + Vector3.new(0, 7.2, 0)), padConfig.Color, Enum.Material.Neon, Enum.PartType.Ball)
		head.CanCollide = false

		local pl = Instance.new("PointLight", head)
		pl.Color = padConfig.Color
		pl.Brightness = 2.5
		pl.Range = 16
	end

	-- 5. Overhead BillboardUI (Integrated Countdown & Player Count)
	local bb = Instance.new("BillboardGui")
	bb.Name = "CrewBillboard"
	bb.Size = UDim2.new(9, 0, 4.2, 0)
	bb.StudsOffset = Vector3.new(0, 8, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 150
	bb.Parent = base

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = bb

	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = padConfig.Color
	stroke.Thickness = 3.5

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.42, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.05, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = padConfig.Label
	titleLabel.TextColor3 = Color3.fromRGB(255, 245, 220)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.Antique
	titleLabel.Parent = frame

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 0.3, 0)
	timerLabel.Position = UDim2.new(0, 0, 0.45, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "Tritt auf die Plattform"
	timerLabel.TextColor3 = Color3.fromRGB(200, 205, 215)
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Parent = frame

	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "CountLabel"
	countLabel.Size = UDim2.new(1, 0, 0.22, 0)
	countLabel.Position = UDim2.new(0, 0, 0.74, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = "0 / " .. Constants.MAX_PLAYERS_PER_PAD .. " Spieler"
	countLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamMedium
	countLabel.Parent = frame

	model.Parent = lobbyFolder
	return model
end

local function updatePadUI(padName)
	local state = padStates[padName]
	if not state or not state.Model then return end

	local base = state.Model:FindFirstChild("PadBase")
	if not base then return end

	local bb = base:FindFirstChild("CrewBillboard")
	if not bb then return end

	local frame = bb:FindFirstChild("Frame")
	if not frame then return end

	local timerLabel = frame:FindFirstChild("TimerLabel")
	local countLabel = frame:FindFirstChild("CountLabel")

	local pCount = #state.Players
	if pCount == 0 then
		if timerLabel then
			timerLabel.Text = "Tritt auf die Plattform"
			timerLabel.TextColor3 = Color3.fromRGB(200, 205, 215)
		end
		if countLabel then
			countLabel.Text = "0 / " .. Constants.MAX_PLAYERS_PER_PAD .. " Spieler"
			countLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
		end
	elseif state.Active then
		if timerLabel then
			timerLabel.Text = "⏳ START IN " .. state.Timer .. " SEKUNDEN!"
			timerLabel.TextColor3 = Color3.fromRGB(255, 225, 40)
		end
		if countLabel then
			countLabel.Text = pCount .. " / " .. Constants.MAX_PLAYERS_PER_PAD .. " Spieler (Bereit)"
			countLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
		end
	else
		if timerLabel then
			timerLabel.Text = "Warte auf Spieler..."
			timerLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
		end
		if countLabel then
			countLabel.Text = pCount .. " / " .. Constants.MAX_PLAYERS_PER_PAD .. " Spieler"
			countLabel.TextColor3 = Color3.fromRGB(150, 255, 170)
		end
	end
end

local function teleportPartyToGame(partyPlayers, padName)
	print("[LobbyManager] Teleporting " .. #partyPlayers .. " player(s) from " .. padName .. " to Island...")

	if Constants.GAME_PLACE_ID > 0 then
		local success, err = pcall(function()
			local options = Instance.new("TeleportOptions")
			options.ShouldReserveServer = true
			TeleportService:TeleportAsync(Constants.GAME_PLACE_ID, partyPlayers, options)
		end)
		if success then
			print("[LobbyManager] Successfully dispatched party to Place ID: " .. Constants.GAME_PLACE_ID)
			return
		else
			warn("[LobbyManager] TeleportService error: " .. tostring(err) .. ". Falling back to local teleport.")
		end
	end

	-- Local Island Teleport to Harbor Check-In Counter (Directly behind desk)
	for _, player in ipairs(partyPlayers) do
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = CFrame.new(Constants.MAIN_ISLAND_SPAWN) * CFrame.Angles(0, math.rad(-90), 0)
				print("[LobbyManager] Teleported " .. player.Name .. " behind Check-In Counter!")
			end
		end
	end
end

local function startCountdown(padName)
	local state = padStates[padName]
	if state.Active then return end
	state.Active = true
	state.Timer = Constants.COUNTDOWN_DURATION

	state.Coroutine = task.spawn(function()
		while state.Timer > 0 and #state.Players > 0 do
			updatePadUI(padName)
			task.wait(1)
			state.Timer = state.Timer - 1
		end

		if #state.Players > 0 then
			updatePadUI(padName)
			local playersToPort = {}
			for _, p in ipairs(state.Players) do
				if p and p.Parent then
					table.insert(playersToPort, p)
				end
			end

			state.Players = {}
			state.Active = false
			updatePadUI(padName)

			teleportPartyToGame(playersToPort, padName)
		else
			state.Active = false
			state.Timer = 0
			updatePadUI(padName)
		end
	end)
end

function LobbyManager.Init()
	print("[LobbyManager] Initializing 4 Crew Matchmaking Pads on Lobby Island...")

	local lobbyFolder = workspace:FindFirstChild("LobbyAssets")
	if not lobbyFolder then
		lobbyFolder = Instance.new("Folder", workspace)
		lobbyFolder.Name = "LobbyAssets"
	end

	for _, padConfig in ipairs(Constants.PAD_CONFIGS) do
		local model = buildPadModel(padConfig, lobbyFolder)
		padStates[padConfig.Name] = {
			Config = padConfig,
			Model = model,
			Players = {},
			Timer = 0,
			Active = false,
			Coroutine = nil,
		}
	end

	-- Continuous Player Detection Loop (Generous 10-stud radius)
	task.spawn(function()
		while true do
			task.wait(0.3)

			for padName, state in pairs(padStates) do
				local currentPlayers = {}
				local base = state.Model and state.Model:FindFirstChild("PadBase")
				local padPos = base and base.Position or state.Config.Pos

				for _, p in ipairs(Players:GetPlayers()) do
					local char = p.Character
					if char then
						local root = char:FindFirstChild("HumanoidRootPart")
						if root then
							local dist2D = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(padPos.X, padPos.Z)).Magnitude
							local distY = math.abs(root.Position.Y - padPos.Y)

							-- Generous 9.5-stud radius to reliably capture players on pad
							if dist2D <= 9.5 and distY <= 6 then
								if #currentPlayers < Constants.MAX_PLAYERS_PER_PAD then
									table.insert(currentPlayers, p)
								end
							end
						end
					end
				end

				local countChanged = (#currentPlayers ~= #state.Players)
				state.Players = currentPlayers

				if #state.Players > 0 and not state.Active then
					startCountdown(padName)
				elseif #state.Players == 0 and state.Active then
					if state.Coroutine then task.cancel(state.Coroutine) end
					state.Active = false
					state.Timer = 0
					updatePadUI(padName)
				elseif countChanged then
					updatePadUI(padName)
				end
			end
		end
	end)

	-- Chat command for returning to lobby
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(msg)
			if msg == "/lobby" or msg == "/spawn" or msg == "/hub" then
				local char = player.Character
				if char then
					local root = char:FindFirstChild("HumanoidRootPart")
					if root then
						root.CFrame = CFrame.new(Constants.LOBBY_SPAWN)
					end
				end
			end
		end)
	end)
end

return LobbyManager
