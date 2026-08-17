-- Client HUD, Dynamic Lobby vs. Game Island UI, Sound FX, Inventory, Modals & Treatment Minigames
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SocialService = game:GetService("SocialService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Events = ReplicatedStorage:WaitForChild("Events")
local CallNextPatientEvent = Events:WaitForChild("CallNextPatient")
local TakePictureEvent = Events:WaitForChild("TakePicture")
local PrintDocumentEvent = Events:WaitForChild("PrintDocument")
local OpenLogbookEvent = Events:WaitForChild("OpenLogbook")
local SubmitDecisionEvent = Events:WaitForChild("SubmitDecision")
local ShowNotificationEvent = Events:WaitForChild("ShowNotification")
local UpdateInventoryEvent = Events:WaitForChild("UpdateInventory")
local UpdatePlayerStateEvent = Events:WaitForChild("UpdatePlayerState")
local SelectClassEvent = Events:WaitForChild("SelectClass")
local DrinkCoffeeEvent = Events:WaitForChild("DrinkCoffee")
local StartMinigameEvent = Events:WaitForChild("StartMinigame")
local CompleteMinigameEvent = Events:WaitForChild("CompleteMinigame")

local ClassTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClassTypes"))
local ShopTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopTypes"))

-- Create Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PirateHospitalHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

---------------------------------------------------------
-- 0. VERIFIED AUDIO SOUND FX
---------------------------------------------------------
local SOUNDS = {
	Bell = "rbxassetid://9114223170",       -- Brass Desk Bell
	Camera = "rbxassetid://130972023",      -- Classic Camera Shutter
	Printer = "rbxassetid://2865227271",    -- Mechanical Typewriter Print
	Admit = "rbxassetid://9069609200",      -- Verified Notification Ding
	Quarantine = "rbxassetid://9069609054", -- Alarm Buzzer
	BookFlip = "rbxassetid://9114221199",   -- Parchment Page Flip
	ItemEquip = "rbxassetid://6518811702",  -- UI Chime
	DrinkCoffee = "rbxassetid://10722059"   -- Drinking sound
}

local function playSound(soundId, volume, pitch)
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = soundId
		s.Volume = volume or 1
		s.PlaybackSpeed = pitch or 1
		s.Parent = SoundService
		s:Play()
		s.Ended:Connect(function() s:Destroy() end)
	end)
end

---------------------------------------------------------
-- 1. TOP HEADER: SCHICHT & OBJECTIVE (Game Island Only)
---------------------------------------------------------
local gameTopHeader = Instance.new("Frame", screenGui)
gameTopHeader.Name = "GameTopHeader"
gameTopHeader.Size = UDim2.new(1, 0, 0, 60)
gameTopHeader.BackgroundTransparency = 1
gameTopHeader.Visible = false

local shiftBanner = Instance.new("Frame", gameTopHeader)
shiftBanner.Size = UDim2.new(0, 220, 0, 38)
shiftBanner.Position = UDim2.new(0.5, -110, 0, 8)
shiftBanner.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
shiftBanner.BackgroundTransparency = 0.25
local sCorner = Instance.new("UICorner", shiftBanner)
sCorner.CornerRadius = UDim.new(0, 8)

local shiftLabel = Instance.new("TextLabel", shiftBanner)
shiftLabel.Size = UDim2.new(1, 0, 1, 0)
shiftLabel.BackgroundTransparency = 1
shiftLabel.Text = "Schicht 1"
shiftLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
shiftLabel.TextScaled = true
shiftLabel.Font = Enum.Font.Antique

local objLabel = Instance.new("TextLabel", gameTopHeader)
objLabel.Size = UDim2.new(0, 380, 0, 38)
objLabel.Position = UDim2.new(1, -400, 0, 8)
objLabel.BackgroundTransparency = 1
objLabel.Text = "Warten Sie auf Besucher."
objLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
objLabel.TextSize = 20
objLabel.Font = Enum.Font.Antique
objLabel.TextXAlignment = Enum.TextXAlignment.Right

---------------------------------------------------------
-- 2. BOTTOM LEFT STATUS: SANITY BRAIN, GOLD & CLASS (Game Island Only)
---------------------------------------------------------
local gameStatusHUD = Instance.new("Frame", screenGui)
gameStatusHUD.Name = "GameStatusHUD"
gameStatusHUD.Size = UDim2.new(0, 240, 0, 95)
gameStatusHUD.Position = UDim2.new(0, 20, 1, -105)
gameStatusHUD.BackgroundTransparency = 1
gameStatusHUD.Visible = false

local brainBadge = Instance.new("Frame", gameStatusHUD)
brainBadge.Size = UDim2.new(0, 70, 0, 56)
brainBadge.Position = UDim2.new(0, 0, 0, 0)
brainBadge.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
brainBadge.BackgroundTransparency = 0.2
local bCorner = Instance.new("UICorner", brainBadge)
bCorner.CornerRadius = UDim.new(0, 8)
local bStroke = Instance.new("UIStroke", brainBadge)
bStroke.Color = Color3.fromRGB(180, 240, 100)
bStroke.Thickness = 2

local brainIcon = Instance.new("TextLabel", brainBadge)
brainIcon.Size = UDim2.new(0.45, 0, 0.9, 0)
brainIcon.Position = UDim2.new(0.05, 0, 0.05, 0)
brainIcon.BackgroundTransparency = 1
brainIcon.Text = "🧠"
brainIcon.TextScaled = true

local sanityPercent = Instance.new("TextLabel", brainBadge)
sanityPercent.Size = UDim2.new(0.5, 0, 0.9, 0)
sanityPercent.Position = UDim2.new(0.45, 0, 0.05, 0)
sanityPercent.BackgroundTransparency = 1
sanityPercent.Text = "100%"
sanityPercent.TextColor3 = Color3.fromRGB(180, 240, 100)
sanityPercent.TextScaled = true
sanityPercent.Font = Enum.Font.GothamBlack

local sanityTag = Instance.new("TextLabel", gameStatusHUD)
sanityTag.Size = UDim2.new(0, 70, 0, 18)
sanityTag.Position = UDim2.new(0, 0, 0, 58)
sanityTag.BackgroundTransparency = 1
sanityTag.Text = "Vernunft"
sanityTag.TextColor3 = Color3.fromRGB(200, 205, 215)
sanityTag.TextScaled = true
sanityTag.Font = Enum.Font.GothamMedium

local goldText = Instance.new("TextLabel", gameStatusHUD)
goldText.Size = UDim2.new(0, 150, 0, 28)
goldText.Position = UDim2.new(0, 80, 0, 5)
goldText.BackgroundTransparency = 1
goldText.Text = "🪙 50 Gold"
goldText.TextColor3 = Color3.fromRGB(255, 235, 100)
goldText.TextScaled = true
goldText.Font = Enum.Font.GothamBlack
goldText.TextXAlignment = Enum.TextXAlignment.Left

local classText = Instance.new("TextLabel", gameStatusHUD)
classText.Size = UDim2.new(0, 150, 0, 22)
classText.Position = UDim2.new(0, 80, 0, 35)
classText.BackgroundTransparency = 1
classText.Text = "Krankenschwester"
classText.TextColor3 = Color3.fromRGB(245, 245, 245)
classText.TextScaled = true
classText.Font = Enum.Font.Antique
classText.TextXAlignment = Enum.TextXAlignment.Left

---------------------------------------------------------
-- 3. LEFT SIDEBAR MENU (Lobby Island Only)
---------------------------------------------------------
local lobbySidebar = Instance.new("Frame", screenGui)
lobbySidebar.Name = "LobbySidebar"
lobbySidebar.Size = UDim2.new(0, 135, 0, 220)
lobbySidebar.Position = UDim2.new(0, 20, 0.35, 0)
lobbySidebar.BackgroundTransparency = 1

local menuButtons = {
	{ Name = "Geschäft", Icon = "🛍️", Color = Color3.fromRGB(40, 150, 210), Key = "Shop" },
	{ Name = "Invite", Icon = "👥", Color = Color3.fromRGB(85, 75, 180), Key = "Invite" },
	{ Name = "Klassen", Icon = "🎭", Color = Color3.fromRGB(65, 110, 210), Key = "Classes" },
	{ Name = "Tagebuch", Icon = "📖", Color = Color3.fromRGB(75, 100, 190), Key = "Logbook" },
}

local function makeMenuButton(bData, index)
	local btn = Instance.new("TextButton", lobbySidebar)
	btn.Name = bData.Key .. "Btn"
	btn.Size = UDim2.new(1, 0, 0, 46)
	btn.Position = UDim2.new(0, 0, 0, (index - 1) * 54)
	btn.BackgroundColor3 = bData.Color
	btn.Text = bData.Name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.Antique

	local bCorner = Instance.new("UICorner", btn)
	bCorner.CornerRadius = UDim.new(0, 10)
	local bStroke = Instance.new("UIStroke", btn)
	bStroke.Color = Color3.fromRGB(255, 255, 255)
	bStroke.Thickness = 2
	bStroke.Transparency = 0.4
	return btn
end

local shopBtn = makeMenuButton(menuButtons[1], 1)
local inviteBtn = makeMenuButton(menuButtons[2], 2)
local classBtn = makeMenuButton(menuButtons[3], 3)
local logbookBtn = makeMenuButton(menuButtons[4], 4)

---------------------------------------------------------
-- 4. 5-SLOT INVENTORY BAR (Game Island Only)
---------------------------------------------------------
local invBar = Instance.new("Frame", screenGui)
invBar.Name = "InventoryBar"
invBar.Size = UDim2.new(0, 360, 0, 68)
invBar.Position = UDim2.new(0.5, -180, 1, -75)
invBar.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
invBar.BackgroundTransparency = 0.2
invBar.Visible = false
local iCorner = Instance.new("UICorner", invBar)
iCorner.CornerRadius = UDim.new(0, 10)
local iStroke = Instance.new("UIStroke", invBar)
iStroke.Color = Color3.fromRGB(140, 100, 60)
iStroke.Thickness = 2.5

local slotFrames = {}
local selectedSlot = 1
for i = 1, 5 do
	local slot = Instance.new("TextButton", invBar)
	slot.Size = UDim2.new(0, 56, 0, 56)
	slot.Position = UDim2.new(0, 10 + ((i - 1) * 68), 0, 6)
	slot.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
	slot.Text = ""
	local sCorner = Instance.new("UICorner", slot)
	sCorner.CornerRadius = UDim.new(0, 8)
	local sStroke = Instance.new("UIStroke", slot)
	sStroke.Color = (i == selectedSlot) and Color3.fromRGB(255, 215, 60) or Color3.fromRGB(70, 75, 90)
	sStroke.Thickness = (i == selectedSlot) and 3 or 1.5

	local numTag = Instance.new("TextLabel", slot)
	numTag.Size = UDim2.new(0, 16, 0, 16)
	numTag.Position = UDim2.new(0, 4, 0, 4)
	numTag.BackgroundTransparency = 1
	numTag.Text = tostring(i)
	numTag.TextColor3 = Color3.fromRGB(180, 185, 200)
	numTag.TextScaled = true
	numTag.Font = Enum.Font.GothamBold

	local iconLabel = Instance.new("TextLabel", slot)
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, -8, 1, -8)
	iconLabel.Position = UDim2.new(0, 4, 0, 4)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = ""
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold

	slotFrames[i] = { Button = slot, Stroke = sStroke, Icon = iconLabel }
	slot.MouseButton1Click:Connect(function()
		selectedSlot = i
		playSound(SOUNDS.ItemEquip, 0.7, 1.2)
		for sIdx, sData in ipairs(slotFrames) do
			sData.Stroke.Color = (sIdx == selectedSlot) and Color3.fromRGB(255, 215, 60) or Color3.fromRGB(70, 75, 90)
			sData.Stroke.Thickness = (sIdx == selectedSlot) and 3 or 1.5
		end
	end)
end

---------------------------------------------------------
-- 5. LOCATION DETECTION: SWITCH UI AUTOMATICALLY
---------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.3)
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local isLobby = (root.Position.X < -150)
				lobbySidebar.Visible = isLobby
				gameTopHeader.Visible = not isLobby
				gameStatusHUD.Visible = not isLobby
				invBar.Visible = not isLobby
			end
		end
	end
end)

---------------------------------------------------------
-- 5.5 CUSTOM BACKGROUND MUSIC
---------------------------------------------------------
local bgMusic = SoundService:FindFirstChild("GhostPirateBGM")
if not bgMusic then
	bgMusic = Instance.new("Sound")
	bgMusic.Name = "GhostPirateBGM"
	bgMusic.SoundId = "rbxassetid://78492837776019"
	bgMusic.Volume = 0.25
	bgMusic.Looped = true
	bgMusic.Parent = SoundService
	bgMusic:Play()
end

---------------------------------------------------------
-- 6. INTERACTIVE TREATMENT MINIGAME MODAL (Animal Hospital Style)
---------------------------------------------------------
local minigameModal = Instance.new("Frame", screenGui)
minigameModal.Name = "TreatmentMinigameModal"
minigameModal.Size = UDim2.new(0, 680, 0, 480)
minigameModal.Position = UDim2.new(0.5, -340, 0.5, -240)
minigameModal.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
minigameModal.BorderSizePixel = 0
minigameModal.Active = true
minigameModal.Visible = false

local mCorner = Instance.new("UICorner", minigameModal)
mCorner.CornerRadius = UDim.new(0, 14)
local mStroke = Instance.new("UIStroke", minigameModal)
mStroke.Color = Color3.fromRGB(80, 220, 140)
mStroke.Thickness = 4

local mgHeader = Instance.new("TextLabel", minigameModal)
mgHeader.Size = UDim2.new(1, -100, 0, 45)
mgHeader.Position = UDim2.new(0, 25, 0, 15)
mgHeader.BackgroundTransparency = 1
mgHeader.Text = "💉 BEHANDLUNG: PATIENT"
mgHeader.TextColor3 = Color3.fromRGB(255, 235, 120)
mgHeader.TextScaled = true
mgHeader.Font = Enum.Font.Antique

local mgSub = Instance.new("TextLabel", minigameModal)
mgSub.Size = UDim2.new(1, -50, 0, 28)
mgSub.Position = UDim2.new(0, 25, 0, 60)
mgSub.BackgroundTransparency = 1
mgSub.Text = "Aufgabe: Drücke im richtigen Moment!"
mgSub.TextColor3 = Color3.fromRGB(190, 200, 220)
mgSub.TextScaled = true
mgSub.Font = Enum.Font.GothamMedium

local mgContent = Instance.new("Frame", minigameModal)
mgContent.Size = UDim2.new(1, -50, 1, -120)
mgContent.Position = UDim2.new(0, 25, 0, 95)
mgContent.BackgroundTransparency = 1

local mgCloseBtn = Instance.new("TextButton", minigameModal)
mgCloseBtn.Size = UDim2.new(0, 40, 0, 40)
mgCloseBtn.Position = UDim2.new(1, -50, 0, 15)
mgCloseBtn.BackgroundColor3 = Color3.fromRGB(190, 50, 40)
mgCloseBtn.Text = "X"
mgCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mgCloseBtn.TextScaled = true
mgCloseBtn.Font = Enum.Font.GothamBlack
local mgCCorner = Instance.new("UICorner", mgCloseBtn)
mgCCorner.CornerRadius = UDim.new(0, 8)
mgCloseBtn.MouseButton1Click:Connect(function() minigameModal.Visible = false end)

local minigameConn = nil

local function launchTreatmentMinigame(data)
	minigameModal.Visible = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	mgContent:ClearAllChildren()
	if minigameConn then minigameConn:Disconnect() minigameConn = nil end

	mgHeader.Text = "💉 BEHANDLUNG: " .. data.PatientName
	local successScore = 0
	local targetScore = 3

	-- A. TIMING BAR MINIGAME (Skorbut & Ward Lemon Juice Press)
	if data.Medicine == "Lemon_Tonic" or data.RoomType == "Ward" then
		mgSub.Text = "🍋 Zitronen-Presse: Drücke [ LEERTASTE ] oder Klicke im GRÜNEN Bereich! (" .. successScore .. "/" .. targetScore .. ")"

		local barBg = Instance.new("Frame", mgContent)
		barBg.Size = UDim2.new(0.85, 0, 0, 50)
		barBg.Position = UDim2.new(0.075, 0, 0.35, 0)
		barBg.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
		local bC = Instance.new("UICorner", barBg)
		bC.CornerRadius = UDim.new(0, 10)

		-- Green Sweet Spot in Center
		local greenZone = Instance.new("Frame", barBg)
		greenZone.Size = UDim2.new(0.3, 0, 1, 0)
		greenZone.Position = UDim2.new(0.35, 0, 0, 0)
		greenZone.BackgroundColor3 = Color3.fromRGB(50, 220, 90)
		local gC = Instance.new("UICorner", greenZone)
		gC.CornerRadius = UDim.new(0, 8)

		-- Moving Cursor Indicator
		local cursor = Instance.new("Frame", barBg)
		cursor.Size = UDim2.new(0, 18, 1, 8)
		cursor.Position = UDim2.new(0, 0, 0, -4)
		cursor.BackgroundColor3 = Color3.fromRGB(255, 235, 50)
		local cC = Instance.new("UICorner", cursor)
		cC.CornerRadius = UDim.new(0, 4)

		local pressBtn = Instance.new("TextButton", mgContent)
		pressBtn.Size = UDim2.new(0.5, 0, 0, 54)
		pressBtn.Position = UDim2.new(0.25, 0, 0.65, 0)
		pressBtn.BackgroundColor3 = Color3.fromRGB(240, 190, 40)
		pressBtn.Text = "🍋 JETZT PRESSEN!"
		pressBtn.TextColor3 = Color3.fromRGB(30, 20, 10)
		pressBtn.TextScaled = true
		pressBtn.Font = Enum.Font.GothamBlack
		local pC = Instance.new("UICorner", pressBtn)
		pC.CornerRadius = UDim.new(0, 10)

		local cursorPos = 0
		local speed = 2.2
		local dir = 1

		minigameConn = RunService.RenderStepped:Connect(function(dt)
			cursorPos = cursorPos + (dir * speed * dt)
			if cursorPos > 0.95 then cursorPos = 0.95 dir = -1 end
			if cursorPos < 0.0 then cursorPos = 0.0 dir = 1 end
			cursor.Position = UDim2.new(cursorPos, 0, 0, -4)
		end)

		local function handleAction()
			if cursorPos >= 0.35 and cursorPos <= 0.65 then
				successScore = successScore + 1
				playSound(SOUNDS.ItemEquip, 1, 1.4)
				mgSub.Text = "✅ Perfekt! (" .. successScore .. "/" .. targetScore .. ")"
				if successScore >= targetScore then
					if minigameConn then minigameConn:Disconnect() end
					playSound(SOUNDS.Admit, 1)
					CompleteMinigameEvent:FireServer(true, data.PatientName)
					minigameModal.Visible = false
				end
			else
				playSound(SOUNDS.Quarantine, 0.8, 1.5)
				mgSub.Text = "❌ Daneben! Versuch es noch einmal!"
			end
		end

		pressBtn.MouseButton1Click:Connect(handleAction)
		UserInputService.InputBegan:Connect(function(inp, gp)
			if minigameModal.Visible and not gp and inp.KeyCode == Enum.KeyCode.Space then
				handleAction()
			end
		end)

	-- B. 3-STEP SURGERY / DISINFECTION MINIGAME
	else
		mgSub.Text = "🧪 Klicke die 3 infizierten Stellen zur Behandlung an!"
		local clicked = 0
		local spots = {
			{ X = 0.25, Y = 0.3 },
			{ X = 0.5, Y = 0.5 },
			{ X = 0.75, Y = 0.35 }
		}

		for sIdx, sPos in ipairs(spots) do
			local spotBtn = Instance.new("TextButton", mgContent)
			spotBtn.Size = UDim2.new(0, 70, 0, 70)
			spotBtn.Position = UDim2.new(sPos.X, -35, sPos.Y, -35)
			spotBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 50)
			spotBtn.Text = "🩹"
			spotBtn.TextScaled = true
			local sC = Instance.new("UICorner", spotBtn)
			sC.CornerRadius = UDim.new(1, 0)

			spotBtn.MouseButton1Click:Connect(function()
				spotBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 90)
				spotBtn.Text = "✨"
				spotBtn.AutoButtonColor = false
				clicked = clicked + 1
				playSound(SOUNDS.ItemEquip, 1, 1.3)
				if clicked >= #spots then
					playSound(SOUNDS.Admit, 1)
					CompleteMinigameEvent:FireServer(true, data.PatientName)
					minigameModal.Visible = false
				end
			end)
		end
	end
end

StartMinigameEvent.OnClientEvent:Connect(launchTreatmentMinigame)

---------------------------------------------------------
-- 7. GENERAL EVENT LISTENERS & MODALS
---------------------------------------------------------
local function makeGenericModal(titleText)
	local modal = Instance.new("Frame", screenGui)
	modal.Size = UDim2.new(0, 700, 0, 500)
	modal.Position = UDim2.new(0.5, -350, 0.5, -250)
	modal.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
	modal.BorderSizePixel = 0
	modal.Active = true
	modal.Visible = false

	local mC = Instance.new("UICorner", modal)
	mC.CornerRadius = UDim.new(0, 14)
	local mSt = Instance.new("UIStroke", modal)
	mSt.Color = Color3.fromRGB(245, 195, 60)
	mSt.Thickness = 3.5

	local h = Instance.new("TextLabel", modal)
	h.Size = UDim2.new(1, -120, 0, 50)
	h.Position = UDim2.new(0, 25, 0, 12)
	h.BackgroundTransparency = 1
	h.Text = titleText
	h.TextColor3 = Color3.fromRGB(255, 235, 160)
	h.TextScaled = true
	h.Font = Enum.Font.Antique

	local closeBtn = Instance.new("TextButton", modal)
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -52, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(190, 50, 40)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextScaled = true
	closeBtn.Font = Enum.Font.GothamBlack
	local cCorn = Instance.new("UICorner", closeBtn)
	cCorn.CornerRadius = UDim.new(0, 8)
	closeBtn.MouseButton1Click:Connect(function() modal.Visible = false end)

	return modal
end

local shopModal = makeGenericModal("🛍️ INSEL-GESCHÄFT & UPGRADES")
local classModal = makeGenericModal("🎭 KLASSEN-AUSWAHL")

shopBtn.MouseButton1Click:Connect(function()
	shopModal.Visible = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	playSound(SOUNDS.BookFlip, 0.8)
end)

inviteBtn.MouseButton1Click:Connect(function()
	pcall(function() SocialService:PromptGameInvite(player) end)
end)

classBtn.MouseButton1Click:Connect(function()
	classModal.Visible = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	playSound(SOUNDS.BookFlip, 0.8)
end)

logbookBtn.MouseButton1Click:Connect(function()
	OpenLogbookEvent:FireServer()
end)

UpdatePlayerStateEvent.OnClientEvent:Connect(function(state)
	shiftLabel.Text = "Schicht " .. tostring(state.CurrentShift)
	sanityPercent.Text = tostring(math.floor(state.Sanity)) .. "%"
	if state.ClassInfo then
		classText.Text = state.ClassInfo.Title
		classText.TextColor3 = state.ClassInfo.Color
	end
end)

UpdateInventoryEvent.OnClientEvent:Connect(function(inv, gold)
	goldText.Text = "🪙 " .. tostring(gold) .. " Gold"
	for i = 1, 5 do
		local item = inv[i]
		if item then
			slotFrames[i].Icon.Text = item.Icon or "💊"
			slotFrames[i].Button.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
		else
			slotFrames[i].Icon.Text = ""
			slotFrames[i].Button.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
		end
	end
end)

-- Notification Banner
local notifContainer = Instance.new("Frame", screenGui)
notifContainer.Size = UDim2.new(0, 540, 0, 85)
notifContainer.Position = UDim2.new(0.5, -270, 0, 20)
notifContainer.BackgroundTransparency = 1

local function showBanner(text, color)
	local banner = Instance.new("Frame", notifContainer)
	banner.Size = UDim2.new(1, 0, 1, 0)
	banner.Position = UDim2.new(0, 0, -1, 0)
	banner.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	banner.BackgroundTransparency = 0.15

	local corner = Instance.new("UICorner", banner)
	corner.CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke", banner)
	stroke.Color = color or Color3.fromRGB(255, 215, 60)
	stroke.Thickness = 2.5

	local label = Instance.new("TextLabel", banner)
	label.Size = UDim2.new(1, -20, 1, -10)
	label.Position = UDim2.new(0, 10, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold

	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()

	task.delay(3.5, function()
		local outTween = TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0, 0, -1.2, 0),
			BackgroundTransparency = 1
		})
		outTween:Play()
		outTween.Completed:Connect(function() banner:Destroy() end)
	end)
end
ShowNotificationEvent.OnClientEvent:Connect(showBanner)

UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.X or input.KeyCode == Enum.KeyCode.Escape then
		shopModal.Visible = false
		classModal.Visible = false
		minigameModal.Visible = false
	end
end)

-- Proximity Prompt Triggers
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer ~= player then return end
	local parentName = prompt.Parent and prompt.Parent.Name
	local objText = prompt.ObjectText

	if objText == "Rezeptionsglocke" or parentName == "CallBell" then
		playSound(SOUNDS.Bell, 1.2)
		CallNextPatientEvent:FireServer()
		objLabel.Text = "Schiff nähert sich. Überprüfen Sie den Namen."
	elseif objText == "Kamera (g-cam)" or parentName == "PatientCamera" then
		playSound(SOUNDS.Camera, 1.0)
		TakePictureEvent:FireServer()
		objLabel.Text = "Foto aufgenommen. Stempeln Sie das Formular."
	elseif objText == "Drucker" or parentName == "DocumentPrinter" then
		playSound(SOUNDS.Printer, 1.0)
		PrintDocumentEvent:FireServer()
		objLabel.Text = "Formular gedruckt. Treffen Sie eine Entscheidung."
	elseif objText == "Logbuch / Klemmbrett" or parentName == "Clipboard" then
		OpenLogbookEvent:FireServer()
	elseif objText == "Zulassen-Stempel" or parentName == "AdmitButton" then
		playSound(SOUNDS.Admit, 1.0)
		SubmitDecisionEvent:FireServer("Admit")
		objLabel.Text = "Warten Sie auf Besucher."
	elseif objText == "Quarantäne-Stempel" or parentName == "DenyButton" then
		playSound(SOUNDS.Quarantine, 1.2)
		SubmitDecisionEvent:FireServer("Quarantine")
		objLabel.Text = "Warten Sie auf Besucher."
	elseif parentName == "CoffeeMaker" or objText == "Kaffeemaschine" then
		playSound(SOUNDS.DrinkCoffee, 1.0)
		DrinkCoffeeEvent:FireServer()
	end
end)

print("✅ [Piraten4] Complete Animal Hospital Anomaly HUD & Treatment Minigames ready!")
