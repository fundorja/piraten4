-- Definition of Pirate Patients, Ships, Curses, and Medicines
local PirateTypes = {}

PirateTypes.Ships = {
	Allowed = {
		{ Name = "Die Schwarze Perle", Flag = "⛵", Color = Color3.fromRGB(40, 40, 45) },
		{ Name = "Wandernde Moewe", Flag = "🕊️", Color = Color3.fromRGB(220, 215, 200) },
		{ Name = "Koenigliche Galeone", Flag = "👑", Color = Color3.fromRGB(50, 90, 160) },
		{ Name = "Seeteufel", Flag = "⚓", Color = Color3.fromRGB(130, 80, 50) },
		{ Name = "Klabautermann", Flag = "🍻", Color = Color3.fromRGB(160, 110, 60) },
	},
	Banned = {
		{ Name = "Flying Dutchman", Flag = "🏴‍☠️", Color = Color3.fromRGB(30, 70, 50), Curse = "Davy_Jones_Curse" },
		{ Name = "Geisterschiff Der Verdammten", Flag = "👻", Color = Color3.fromRGB(100, 190, 160), Curse = "Ghost_Curse" },
		{ Name = "Voodoo-Wrack", Flag = "🧟", Color = Color3.fromRGB(80, 50, 90), Curse = "Voodoo_Curse" },
		{ Name = "Azteken-Flotte", Flag = "💀", Color = Color3.fromRGB(180, 140, 40), Curse = "Skeleton_Curse" }
	}
}

PirateTypes.Medicines = {
	["Lemon_Tonic"] = {
		Id = "Lemon_Tonic",
		Name = "Zitronen-Tonikum",
		Icon = "🍋",
		Color = Color3.fromRGB(245, 220, 40),
		Description = "Reicher Zitrusextrakt gegen Vitaminmangel und Skorbut.",
		TargetIllness = "Skorbut"
	},
	["PegLeg_Splint"] = {
		Id = "PegLeg_Splint",
		Name = "Holzbein-Schiene",
		Icon = "🪵",
		Color = Color3.fromRGB(140, 95, 55),
		Description = "Massive Eichenholzschiene mit Lederriemen für gebrochene Beine.",
		TargetIllness = "Holzbein-Bruch"
	},
	["Parrot_Antidote"] = {
		Id = "Parrot_Antidote",
		Name = "Gegenmittel-Elixier",
		Icon = "🧪",
		Color = Color3.fromRGB(60, 220, 120),
		Description = "Gebrautes Gegengift gegen Papageienbisse und Dschungelfieber.",
		TargetIllness = "Papageien-Biss"
	},
	["Herbal_Rum"] = {
		Id = "Herbal_Rum",
		Name = "Beruhigungs-Rum",
		Icon = "☕",
		Color = Color3.fromRGB(190, 120, 50),
		Description = "Heißer Kräuter-Rum mit Minze gegen schwere Seekrankheit.",
		TargetIllness = "Seekrankheit"
	},
	["Holy_Water"] = {
		Id = "Holy_Water",
		Name = "Weihwasser-Essenz",
		Icon = "🔮",
		Color = Color3.fromRGB(100, 220, 255),
		Description = "Gesegnetes Quellwasser zur Austreibung böser Voodoo-Geister.",
		TargetIllness = "Fluch-Austreibung"
	}
}

PirateTypes.Curses = {
	["Skeleton_Curse"] = {
		Name = "💀 Azteken-Skelett-Fluch",
		Hint = "Knochen sichtbar, rot glühende Augen, verfluchtes Gold.",
		HeadColor = Color3.fromRGB(240, 235, 220),
		TorsoColor = Color3.fromRGB(220, 215, 200),
		EyeColor = Color3.fromRGB(255, 30, 30),
		Ship = "Azteken-Flotte",
		Symptoms = { "Schlaflosigkeit seit 200 Jahren", "Fleisch löst sich im Mondlicht auf", "Durst kann nie gestillt werden" },
		AssignedRoom = "Room8_Quarantine",
		ExpectedAction = "Quarantine"
	},
	["Davy_Jones_Curse"] = {
		Name = "🐙 Davy-Jones-Meeresfluch",
		Hint = "Grüne Algenhaut, Tentakeln/Schuppen, Schiff ist die Flying Dutchman.",
		HeadColor = Color3.fromRGB(80, 150, 120),
		TorsoColor = Color3.fromRGB(50, 110, 90),
		EyeColor = Color3.fromRGB(255, 220, 0),
		Ship = "Flying Dutchman",
		Symptoms = { "Seepocken wachsen auf der Haut", "Riecht stark nach fauligem Seetang", "Atmet Wasser statt Luft" },
		AssignedRoom = "Room8_Quarantine",
		ExpectedAction = "Quarantine"
	},
	["Ghost_Curse"] = {
		Name = "👻 Spektral-Geisterfluch",
		Hint = "Transparente grüne Geisterhaut, eisige Körpertemperatur, Geisteraura.",
		HeadColor = Color3.fromRGB(150, 230, 190),
		TorsoColor = Color3.fromRGB(130, 210, 170),
		EyeColor = Color3.fromRGB(80, 255, 220),
		Transparency = 0.5,
		Ship = "Geisterschiff Der Verdammten",
		Symptoms = { "Geisterheulen bei jedem Atemzug", "Schwebt leicht über dem Boden", "Gegenstände fallen durch Hände" },
		AssignedRoom = "Room7_Shrine",
		ExpectedAction = "Quarantine"
	},
	["Voodoo_Curse"] = {
		Name = "🧟 Voodoo-Zombie-Fluch",
		Hint = "Verfaulte grau-violette Haut, zuckende Bewegungen, Zaubersprüche.",
		HeadColor = Color3.fromRGB(120, 95, 130),
		TorsoColor = Color3.fromRGB(90, 70, 100),
		EyeColor = Color3.fromRGB(180, 0, 255),
		Ship = "Voodoo-Wrack",
		Symptoms = { "Herztakt schlägt nicht mehr", "Spricht wirre Voodoo-Zaubersprüche", "Haut fällt stellenweise ab" },
		AssignedRoom = "Room7_Shrine",
		ExpectedAction = "Quarantine"
	}
}

PirateTypes.NormalIllnesses = {
	{
		Name = "Skorbut",
		Symptoms = { "Zahnfleischbluten", "Müdigkeit nach langer Seefahrt", "Heißhunger auf Zitronen" },
		RequiredMedicine = "Lemon_Tonic",
		AssignedRoom = "Room1_WardAlpha"
	},
	{
		Name = "Holzbein-Bruch",
		Symptoms = { "Holzbein bei Sturm zerbrochen", "Kann nicht mehr geradeaus gehen", "Braucht neue Holzplanke" },
		RequiredMedicine = "PegLeg_Splint",
		AssignedRoom = "Room3_Surgery"
	},
	{
		Name = "Papageien-Biss",
		Symptoms = { "Bisswunde am linken Ohr", "Leichtes Fieber", "Papagei war verärgert" },
		RequiredMedicine = "Parrot_Antidote",
		AssignedRoom = "Room2_WardBeta"
	},
	{
		Name = "Seekrankheit",
		Symptoms = { "Übelkeit bei Wellengang", "Schwindelgefühl", "Verlangt nach Kamillentee / Rum" },
		RequiredMedicine = "Herbal_Rum",
		AssignedRoom = "Room4_Lounge"
	}
}

PirateTypes.Names = {
	"Kapitän Rotbart", "Matrose Jack", "Ein-Auge Bill", "Kanonier Morgan", 
	"Steuermann Hook", "Bootsmann Henry", "Küsten-Sammy", "Pirat Edward", 
	"Flint der Wilde", "Silber-Schwert Jack", "Schwarzbart Jim", "Klabauter-Peter"
}

return PirateTypes
