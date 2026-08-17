-- Main Server Entry Point (Rojo Synchronized)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

print("🏴‍☠️ [Piraten4] Initializing Pirate Hospital Server...")

-- 1. Initialize Shifts, Sanity & Class Badges
local ShiftManager = require(script:WaitForChild("ShiftManager"))
ShiftManager.Init()

-- 2. Initialize Lobby & Party Matchmaking
local LobbyManager = require(script:WaitForChild("LobbyManager"))
LobbyManager.Init()

-- 3. Initialize Medicine & Inventory Manager
local MedicineManager = require(script:WaitForChild("MedicineManager"))
MedicineManager.Init()

-- 4. Initialize Hospital 8 Rooms & Scenic Walkway
local HospitalRoomsManager = require(script:WaitForChild("HospitalRoomsManager"))
HospitalRoomsManager.SetMedicineManager(MedicineManager)
HospitalRoomsManager.BuildRooms()

-- 5. Initialize Ship Arrival & Patient Systems
local ShipArrivalManager = require(script:WaitForChild("ShipArrivalManager"))
local CheckInManager = require(script:WaitForChild("CheckInManager"))
local PiratePatientManager = require(script:WaitForChild("PiratePatientManager"))

PiratePatientManager.SetCheckInManager(CheckInManager)
PiratePatientManager.SetShipArrivalManager(ShipArrivalManager)
PiratePatientManager.SetHospitalRoomsManager(HospitalRoomsManager)

CheckInManager.Init(PiratePatientManager)

print("✅ [Piraten4] All Server Systems (Shifts + Classes + Lobby + Ships + 8 Rooms + Medicine + Inventory) initialized successfully!")
