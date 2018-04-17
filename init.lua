-- Magicalities
magicalities = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
magicalities.modpath = modpath

magicalities.elements = {
	-- Base Elements
	["air"]   = {color = "#ffff00", description = "Air",   inheritance = nil},
	["water"] = {color = "#003cff", description = "Water", inheritance = nil},
	["fire"]  = {color = "#ff2424", description = "Fire",  inheritance = nil},
	["earth"] = {color = "#00a213", description = "Earth", inheritance = nil},
	["light"] = {color = "#ffffff", description = "Light", inheritance = nil},
	["dark"]  = {color = "#232323", description = "Dark",  inheritance = nil},

	-- Inherited Elements
}

-- Crystals
dofile(modpath.."/crystals.lua")

-- Wands
dofile(modpath.."/wands.lua")

-- Tables
dofile(modpath.."/table.lua")
