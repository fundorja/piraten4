-- Definition of Player Classes, Perks, and Titles
local ClassTypes = {
	Classes = {
		["Praktikant"] = {
			Id = "Praktikant",
			Name = "Praktikant",
			Title = "Praktikant",
			Icon = "📋",
			Color = Color3.fromRGB(245, 220, 80),
			Description = "Standard-Einsteigerklasse auf der Pirateninsel.\n• +15% Laufgeschwindigkeit\n• Solide Grundausbildung",
			SpeedBoost = 1.15,
			SanityDrainMultiplier = 1.0,
			GoldMultiplier = 1.0,
			UnlockCost = 0
		},
		["Krankenschwester"] = {
			Id = "Krankenschwester",
			Name = "Schiffsarzt / Krankenschwester",
			Title = "Krankenschwester",
			Icon = "💉",
			Color = Color3.fromRGB(100, 220, 255),
			Description = "Experte für Wundversorgung und Medikamente.\n• Medizin heilt Patienten 50% schneller\n• +25% Gold für geheilte Patienten",
			SpeedBoost = 1.0,
			SanityDrainMultiplier = 0.8,
			GoldMultiplier = 1.25,
			UnlockCost = 150
		},
		["Voodoo_Schamane"] = {
			Id = "Voodoo_Schamane",
			Name = "Voodoo-Schamane",
			Title = "Schamane",
			Icon = "🔮",
			Color = Color3.fromRGB(180, 80, 255),
			Description = "Erkennt Flüche und Geisteranomalien sofort.\n• +50% Vernunft-Resistenz gegen Spuk\n• Flüche leuchten für dich violett",
			SpeedBoost = 1.0,
			SanityDrainMultiplier = 0.5,
			GoldMultiplier = 1.2,
			UnlockCost = 300
		},
		["Geheimagent"] = {
			Id = "Geheimagent",
			Name = "Insel-Geheimagent",
			Title = "Geheimagent",
			Icon = "🕵️",
			Color = Color3.fromRGB(255, 180, 40),
			Description = "Enttarnt gefälschte Papiere und verbotene Schiffe.\n• Falsche Schiffssiegel werden sofort markiert\n• +35% Gold für Enttarnungen",
			SpeedBoost = 1.1,
			SanityDrainMultiplier = 0.7,
			GoldMultiplier = 1.35,
			UnlockCost = 500
		},
		["Quarantaene_Waechter"] = {
			Id = "Quarantaene_Waechter",
			Name = "Quarantäne-Wächter",
			Title = "Wächter",
			Icon = "🔒",
			Color = Color3.fromRGB(255, 80, 80),
			Description = "Spezialist für gefährliche Fluch-Eindämmung.\n• +50 Gold für jede Quarantäne-Einweisung\n• Keine Vernunft-Einbußen bei Geisterausbrüchen",
			SpeedBoost = 1.05,
			SanityDrainMultiplier = 0.6,
			GoldMultiplier = 1.5,
			UnlockCost = 750
		}
	}
}

return ClassTypes
