-- CheckInManager: Handles the Animal Hospital Anomaly Reception Desk Tools & Logic
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PirateTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PirateTypes"))

local CheckInManager = {}

local currentPatient = nil
local patientData = nil
local hasTakenPhoto = false
local hasPrintedDoc = false

-- Ensure Events folder and RemoteEvents exist
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder", ReplicatedStorage)
	eventsFolder.Name = "Events"
end

local function getOrCreateRemote(name, class)
	class = class or "RemoteEvent"
	local r = eventsFolder:FindFirstChild(name)
	if not r then
		r = Instance.new(class, eventsFolder)
		r.Name = name
	end
	return r
end

local CallNextPatientEvent = getOrCreateRemote("CallNextPatient")
local TakePictureEvent = getOrCreateRemote("TakePicture")
local PrintDocumentEvent = getOrCreateRemote("PrintDocument")
local OpenLogbookEvent = getOrCreateRemote("OpenLogbook")
local SubmitDecisionEvent = getOrCreateRemote("SubmitDecision")
local UpdateDisplayEvent = getOrCreateRemote("UpdateDisplay")
local ShowNotificationEvent = getOrCreateRemote("ShowNotification")

-- Update Desktop Screen in Office
local function updateScreenText(title, status, color)
	local office = workspace:FindFirstChild("MainIslandAssets") and workspace.MainIslandAssets:FindFirstChild("HarborAdmissionOffice")
	if not office then return end

	local screen = office:FindFirstChild("StatusMonitor")
	if not screen then return end

	local gui = screen:FindFirstChildOfClass("SurfaceGui")
	if not gui then return end

	local label = gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = title .. "\n" .. status
		if color then label.TextColor3 = color end
	end
end

function CheckInManager.SetCurrentPatient(patientModel, data)
	currentPatient = patientModel
	patientData = data
	hasTakenPhoto = false
	hasPrintedDoc = false

	print("[CheckInManager] New patient at counter: " .. data.Name .. " (" .. data.Type .. ")")
	updateScreenText("PATIENT AM SCHALTER", data.Name .. " • " .. data.Ship, Color3.fromRGB(255, 230, 80))

	UpdateDisplayEvent:FireAllClients({
		HasPatient = true,
		Name = data.Name,
		Ship = data.Ship,
		Illness = data.Illness,
		HasTakenPhoto = false,
		HasPrintedDoc = false
	})
end

function CheckInManager.GetCurrentPatient()
	return currentPatient, patientData
end

function CheckInManager.Init(patientSpawnerModule)
	print("[CheckInManager] Initializing Check-In Tools & Events...")

	-- 1. 🔔 BELL TRIGGER (Call Next Patient)
	CallNextPatientEvent.OnServerEvent:Connect(function(player)
		if currentPatient and currentPatient.Parent then
			ShowNotificationEvent:FireClient(player, "⚠️ Es steht bereits ein Patient am Schalter!", Color3.fromRGB(255, 160, 40))
			return
		end

		print("[CheckInManager] Bell rung by " .. player.Name .. ". Calling next pirate patient...")
		updateScreenText("GLOCKE GELÄUTET", "Patient nähert sich...", Color3.fromRGB(80, 220, 255))
		
		-- Ringing sound broadcast
		ShowNotificationEvent:FireAllClients("🔔 *DING-DONG!* Nächster Patient nähert sich über den Steg!", Color3.fromRGB(255, 240, 100))

		if patientSpawnerModule then
			patientSpawnerModule.SpawnPatient()
		end
	end)

	-- 2. 📷 CAMERA TRIGGER (g-cam Photo)
	TakePictureEvent.OnServerEvent:Connect(function(player)
		if not currentPatient or not patientData then
			ShowNotificationEvent:FireClient(player, "❌ Kein Patient vor der Kamera!", Color3.fromRGB(255, 80, 80))
			return
		end

		hasTakenPhoto = true
		print("[CheckInManager] Photo taken of " .. patientData.Name .. " by " .. player.Name)
		
		-- Flash camera flash part
		local office = workspace.MainIslandAssets:FindFirstChild("HarborAdmissionOffice")
		local flashPart = office and office:FindFirstChild("CameraFlash")
		if flashPart then
			local pl = flashPart:FindFirstChildOfClass("PointLight") or Instance.new("PointLight", flashPart)
			pl.Brightness = 8
			pl.Range = 30
			pl.Color = Color3.fromRGB(255, 255, 255)
			task.delay(0.2, function() pl.Brightness = 0 end)
		end

		ShowNotificationEvent:FireAllClients("📸 *KLICK-BLITZ!* Foto von " .. patientData.Name .. " aufgenommen!", Color3.fromRGB(200, 100, 255))
		
		UpdateDisplayEvent:FireAllClients({
			HasPatient = true,
			Name = patientData.Name,
			Ship = patientData.Ship,
			Illness = patientData.Illness,
			HasTakenPhoto = true,
			HasPrintedDoc = hasPrintedDoc,
			CurseVisual = patientData.CurseVisual
		})
	end)

	-- 3. 🖨️ PRINTER TRIGGER (Print Admission Certificate)
	PrintDocumentEvent.OnServerEvent:Connect(function(player)
		if not currentPatient or not patientData then
			ShowNotificationEvent:FireClient(player, "❌ Keine Patientendaten zum Drucken!", Color3.fromRGB(255, 80, 80))
			return
		end

		hasPrintedDoc = true
		print("[CheckInManager] Document printed for " .. patientData.Name .. " by " .. player.Name)
		ShowNotificationEvent:FireAllClients("🖨️ *RATTER-SURR!* Einlass-Bescheinigung für " .. patientData.Name .. " gedruckt!", Color3.fromRGB(80, 220, 120))

		UpdateDisplayEvent:FireAllClients({
			HasPatient = true,
			Name = patientData.Name,
			Ship = patientData.Ship,
			Illness = patientData.Illness,
			HasTakenPhoto = hasTakenPhoto,
			HasPrintedDoc = true,
			Symptoms = patientData.Symptoms,
			SealValid = patientData.SealValid
		})
	end)

	-- 4. 📋 CLIPBOARD / LOGBOOK TRIGGER
	OpenLogbookEvent.OnServerEvent:Connect(function(player)
		OpenLogbookEvent:FireClient(player, {
			AllowedShips = PirateTypes.Ships.Allowed,
			BannedShips = PirateTypes.Ships.Banned,
			KnownCurses = PirateTypes.Curses,
			CurrentPatient = patientData
		})
	end)

	-- 5. 🟢 / 🔴 DECISION TRIGGER (Admit vs Quarantine)
	SubmitDecisionEvent.OnServerEvent:Connect(function(player, decision)
		if not currentPatient or not patientData then
			ShowNotificationEvent:FireClient(player, "❌ Kein Patient am Schalter zur Entscheidung!", Color3.fromRGB(255, 80, 80))
			return
		end

		local isCursed = (patientData.Type == "Cursed")
		local expected = isCursed and "Quarantine" or "Admit"

		if decision == "Admit" then
			if not isCursed then
				-- CORRECT: Healthy Patient admitted!
				print("[CheckInManager] SUCCESS: " .. player.Name .. " admitted healthy patient " .. patientData.Name)
				ShowNotificationEvent:FireAllClients("🟢 ZUGELASSEN: " .. patientData.Name .. " ist gesund und betritt das Hospital! (+50 Gold)", Color3.fromRGB(50, 255, 80))
				updateScreenText("PATIENT ZUGELASSEN", "✅ Gesund • Ins Bett geleitet", Color3.fromRGB(50, 255, 80))

				if patientSpawnerModule then
					patientSpawnerModule.SendToHospitalBed(currentPatient, patientData)
				end
			else
				-- ERROR: Cursed Pirate admitted!
				print("[CheckInManager] CRITICAL ERROR: " .. player.Name .. " admitted cursed pirate " .. patientData.Name .. "!")
				ShowNotificationEvent:FireAllClients("⚠️ ALARM! FLUCH-AUSBRUCH! Ein verfluchter Pirat wurde ins Hospital gelassen! (-100 Gold)", Color3.fromRGB(255, 40, 40))
				updateScreenText("⚠️ FLUCH-AUSBRUCH!", "Krankenhaus infiziert!", Color3.fromRGB(255, 40, 40))

				if patientSpawnerModule then
					patientSpawnerModule.TriggerCurseOutbreak(currentPatient, patientData)
				end
			end
		elseif decision == "Quarantine" then
			if isCursed then
				-- CORRECT: Cursed Pirate quarantined!
				print("[CheckInManager] PERFECT: " .. player.Name .. " quarantined cursed pirate " .. patientData.Name .. "!")
				ShowNotificationEvent:FireAllClients("🔴 GEBANNT! " .. patientData.Name .. " (" .. (patientData.CurseName or "Fluch") .. ") wurde sicher in die Quarantänezelle gesperrt! (+100 Gold)", Color3.fromRGB(255, 180, 0))
				updateScreenText("FLUCH GEBANNT!", "🔒 In Quarantänezelle gesichert", Color3.fromRGB(255, 180, 0))

				if patientSpawnerModule then
					patientSpawnerModule.SendToQuarantine(currentPatient)
				end
			else
				-- ERROR: Healthy Pirate wrongly quarantined!
				print("[CheckInManager] MISTAKE: " .. player.Name .. " wrongly quarantined healthy patient " .. patientData.Name .. "!")
				ShowNotificationEvent:FireAllClients("❌ FEHLER: " .. patientData.Name .. " war gar nicht verflucht! (-30 Gold Beschwerde)", Color3.fromRGB(255, 100, 100))
				updateScreenText("FALSCHE DIAGNOSE", "Unschuldiger Pirat eingesperrt", Color3.fromRGB(255, 100, 100))

				if patientSpawnerModule then
					patientSpawnerModule.DismissPatient(currentPatient)
				end
			end
		end

		currentPatient = nil
		patientData = nil
		hasTakenPhoto = false
		hasPrintedDoc = false

		task.delay(4, function()
			if not currentPatient then
				updateScreenText("HAFEN EINLASS", "STATUS: BEREIT\n[GLOCKE DRÜCKEN]", Color3.fromRGB(80, 255, 120))
			end
		end)
	end)
end

return CheckInManager
