---------------------------
-- Register all crystals --
---------------------------

for name, data in pairs(magicalities.elements) do
	if not data.inheritance then
		magicalities.register_crystal(name, data.description, data.color)
	end
end

-----------------------------
-- Arcane crafting recipes --
-----------------------------

local recipes = {
	{
		input = {
			{"default:gold_ingot", "default:glass", "default:gold_ingot"},
			{"default:glass",      "",              "default:glass"},
			{"default:gold_ingot", "default:glass", "default:gold_ingot"},
		},
		output = "magicalities:element_ring",
		requirements = {
			["water"] = 15,
			["earth"] = 15,
			["light"] = 15,
			["fire"]  = 15,
			["dark"]  = 15,
			["air"]   = 15,
		}
	},
	{
		input = {
			{"",              "",                       "magicalities:cap_gold"},
			{"",              "magicalities:wand_core", ""},
			{"group:crystal", "",                       ""}
		},
		output = "magicalities:wand_gold",
		requirements = {
			["water"] = 25,
			["earth"] = 25,
			["light"] = 25,
			["fire"]  = 25,
			["dark"]  = 25,
			["air"]   = 25,
		}
	}
}

for _, recipe in pairs(recipes) do
	magicalities.arcane.register_recipe(recipe)
end

-----------
-- Wands --
-----------

-- Iron
magicalities.wands.register_wand("steel", {
	description = "Steel-Capped Wand",
	image       = "magicalities_wand_iron.png",
	wand_cap    = 25,
})

-- Gold
magicalities.wands.register_wand("gold", {
	description = "Gold-Capped Wand",
	image       = "magicalities_wand_gold.png",
	wand_cap    = 50,
})

--------------------
-- Basic Crafting --
--------------------

minetest.register_craft({
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "",                    "default:steel_ingot"},
	},
	output = "magicalities:cap_steel",
})

minetest.register_craft({
	recipe = {
		{"",              "default:stick"},
		{"default:stick", ""},
	},
	output = "magicalities:wand_core",
})

minetest.register_craft({
	recipe = {
		{"",              "",                       "magicalities:cap_steel"},
		{"",              "magicalities:wand_core", ""},
		{"group:crystal", "",                       ""}
	},
	output = "magicalities:wand_steel",
})
