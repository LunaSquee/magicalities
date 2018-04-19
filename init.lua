-- Magicalities
magicalities = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
magicalities.modpath = modpath

magicalities.elements = {
	-- Base Elements
	["water"] = {color = "#003cff", description = "Water", inheritance = nil},
	["earth"] = {color = "#00a213", description = "Earth", inheritance = nil},
	["light"] = {color = "#ffffff", description = "Light", inheritance = nil},
	["fire"]  = {color = "#ff2424", description = "Fire",  inheritance = nil},
	["dark"]  = {color = "#232323", description = "Dark",  inheritance = nil},
	["air"]   = {color = "#ffff00", description = "Air",   inheritance = nil},

	-- Inherited Elements
}

-- Crystals
dofile(modpath.."/crystals.lua")

-- Wands
dofile(modpath.."/wands.lua")

-- Wand focuses
dofile(modpath.."/focuses.lua")

-- Tables
dofile(modpath.."/table.lua")

-- Items
dofile(modpath.."/craftitems.lua")

-- Scanner
dofile(modpath.."/scanner.lua")

-- Register
dofile(modpath.."/register.lua")
