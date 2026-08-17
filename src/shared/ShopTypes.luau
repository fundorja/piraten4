-- Definition of Shop Items, Upgrades, and Cosmetics
local ShopTypes = {
	Items = {
		["CoffeeMachine_Upgrade"] = {
			Id = "CoffeeMachine_Upgrade",
			Name = "☕ Turbo-Kaffeemaschine",
			Price = 120,
			Icon = "☕",
			Description = "Kaffee brüht doppelt so schnell und stellt sofort +40% Vernunft her."
		},
		["Flashlight_Upgrade"] = {
			Id = "Flashlight_Upgrade",
			Name = "🔍 Fluch-Detektor-Lupe",
			Price = 200,
			Icon = "🔍",
			Description = "Erleichtert das Entdecken von Geisterspuren und gefälschten Siegeln."
		},
		["GoldBadge_Upgrade"] = {
			Id = "GoldBadge_Upgrade",
			Name = "🪙 Goldene Inspektoren-Marke",
			Price = 350,
			Icon = "🪙",
			Description = "Dauerhafter +20% Bonus auf alle Gold-Einnahmen pro Schicht."
		},
		["FastShoes_Upgrade"] = {
			Id = "FastShoes_Upgrade",
			Name = "👢 Seemanns-Schnellstiefel",
			Price = 180,
			Icon = "👢",
			Description = "Erhöht deine permanente Laufgeschwindigkeit um +15%."
		}
	}
}

return ShopTypes
