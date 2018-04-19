-- Scans crystals for their contents

local fmspecelems = {
	["earth"] = {2, 0.3},
	["water"] = {0, 1.25},
	["air"]   = {4, 1.25},
	["fire"]  = {2, 5.1},
	["light"] = {0, 4.25},
	["dark"]  = {4, 4.25}
}

local function create_formspec(elements, desc)
	local spec   = ""
	local labels = ""

	if not elements then
		elements = {}
	end

	for name, pos in pairs(fmspecelems) do
		local cp = ""
		local y = -0.4

		if not elements[name] then
			cp = "^[colorize:#2f2f2f:200"
		elseif elements[name] and elements[name][1] == 0 then
			cp = "^[colorize:#2f2f2f:128"
		end

		if pos[2] > 2.5 then
			y = 0.85
		end

		spec = spec .. "image["..pos[1]..","..pos[2]..";1,1;magicalities_symbol_"..name..".png"..cp.."]"

		if elements[name] then
			labels = labels .. "label["..(pos[1] + 0.3)..","..(pos[2] + y)..";"..elements[name][1].."]"
		end
	end

	return "size[5,6]"..
		default.gui_bg..
		default.gui_bg_img..
		"label[0,0;"..desc.."]"..
		"image[0,0.55;6,6;magicalities_symbol_hexagram.png]"..
		spec..
		labels
end

local function show_spec(i, placer, pointed_thing)
	local pos  = pointed_thing.under
	local node = minetest.get_node(pos)
	
	if not node or minetest.get_item_group(node.name, "crystal_cluster") == 0 then
		return i
	end

	local meta     = minetest.get_meta(pos)
	local nodedef  = minetest.registered_nodes[node.name]
	local contents = minetest.deserialize(meta:get_string("contents"))
	if not contents then
		contents = magicalities.crystals.generate_crystal_buffer(pos)
		meta:set_string("contents", minetest.serialize(contents))
	end

	minetest.show_formspec(placer:get_player_name(), "magicalities:crystal_scanner", create_formspec(contents, nodedef.description))
	return i
end

minetest.register_craftitem("magicalities:element_ring", {
	description = "Elemental Ring\nShows contents of crystals",
	inventory_image = "magicalities_element_ring.png",
	on_place = show_spec,
	stack_max = 1,
})

