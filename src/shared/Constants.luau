-- Configuration & Constants for Pirate Hospital Anomaly
local Constants = {
	-- Teleportation Settings:
	GAME_PLACE_ID = 0,
	COUNTDOWN_DURATION = 10,
	MAX_PLAYERS_PER_PAD = 4,
	MAX_INVENTORY_SLOTS = 5,
	
	-- Coordinates:
	LOBBY_SPAWN = Vector3.new(-300, 9.0, -300),
	MAIN_ISLAND_SPAWN = Vector3.new(161, 10.5, 80), -- Behind reception desk
	HARBOR_CHECKIN_COUNTER = Vector3.new(166, 11.5, 80),
	
	-- Ship Sailing Path:
	SHIP_OCEAN_SPAWN = Vector3.new(380, 0, 80),
	SHIP_DOCK_POSITION = Vector3.new(270, 0, 80),
	PIER_ARRIVAL_POINT = Vector3.new(250, 7.4, 80),
	
	-- Lobby Pads:
	PAD_CONFIGS = {
		{ Name = "GroupPad_1", Pos = Vector3.new(-325, 6.5, -325), Label = "⚔️ CREW 1", Color = Color3.fromRGB(50, 150, 255) },
		{ Name = "GroupPad_2", Pos = Vector3.new(-275, 6.5, -325), Label = "⚔️ CREW 2", Color = Color3.fromRGB(255, 75, 75) },
		{ Name = "GroupPad_3", Pos = Vector3.new(-325, 6.5, -275), Label = "⚔️ CREW 3", Color = Color3.fromRGB(50, 220, 100) },
		{ Name = "GroupPad_4", Pos = Vector3.new(-275, 6.5, -275), Label = "⚔️ CREW 4", Color = Color3.fromRGB(245, 185, 30) },
	},
	
	-- 8 Hospital Rooms Coordinates (Around Center -40, -140):
	ROOMS = {
		Room1_WardAlpha = { Name = "Station Alpha (Betten)", Center = Vector3.new(-65, 8.0, -160), Type = "Ward", BedCount = 2 },
		Room2_WardBeta = { Name = "Station Beta (Intensiv)", Center = Vector3.new(-15, 8.0, -160), Type = "Ward", BedCount = 2 },
		Room3_Surgery = { Name = "Chirurgie & Verbandsraum", Center = Vector3.new(35, 8.0, -160), Type = "Surgery", BedCount = 1 },
		Room4_Lounge = { Name = "Erholungs-Lounge", Center = Vector3.new(85, 8.0, -160), Type = "Lounge", BedCount = 2 },
		Room5_XRay = { Name = "Röntgen & Fluch-Scan", Center = Vector3.new(-65, 8.0, -110), Type = "Scan", BedCount = 1 },
		Room6_Alchemy = { Name = "Alchemie- & Medizin-Labor", Center = Vector3.new(-15, 8.0, -110), Type = "Lab", BedCount = 1 },
		Room7_Shrine = { Name = "Voodoo- & Ritual-Schrein", Center = Vector3.new(35, 8.0, -110), Type = "Shrine", BedCount = 1 },
		Room8_Quarantine = { Name = "Hochsicherheits-Quarantäne", Center = Vector3.new(85, 8.0, -110), Type = "Quarantine", BedCount = 2 }
	}
}

return Constants
