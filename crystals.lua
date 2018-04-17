-- Magicalities crystals

local randbuff = PcgRandom(os.clock())

local function generate_crystal_buffer(pos)
	local final    = {}
	local node     = minetest.get_node(pos)
	local nodedef  = minetest.registered_nodes[node.name]
	local self_cnt = randbuff:next(10, 60)

	for name, data in pairs(magicalities.elements) do
		if #final > 5 then break end
		if not data.inheritance then
			if name == nodedef["_element"] then
				final[name] = {self_cnt, self_cnt}
			else
				if randbuff:next(0, 5) == 0 then
					local cnt = randbuff:next(0, math.floor(self_cnt / 4))
					final[name] = {cnt, cnt}
				end
			end
		else
			if randbuff:next(0, 15) == 0 then
				local cnt = randbuff:next(0, math.floor(self_cnt / 8))
				final[name] = {cnt, cnt}
			end
		end
	end

	return final
end

local function crystal_rightclick(pos, node, clicker, itemstack, pointed_thing)
	local output = generate_crystal_buffer(pos)
	local meta   = minetest.get_meta(pos)

	-- Add contents to the crystal
	local contents = minetest.deserialize(meta:get_string("contents"))
	if not contents then
		contents = generate_crystal_buffer(pos)
		meta:set_string("contents", minetest.serialize(contents))
	end

	-- Check for wand
	if minetest.get_item_group(itemstack:get_name(), "wand") == 0 then
		return itemstack
	end

	local one_of_each = {}
	for name, count in pairs(contents) do
		if count[1] > 0 then
			one_of_each[name] = 1
		end
	end

	local can_put = magicalities.wands.wand_insertable_contents(itemstack, one_of_each)
	for name, count in pairs(can_put) do
		if count > 0 then
			contents[name][1] = contents[name][1] - count
		end
	end

	itemstack = magicalities.wands.wand_insert_contents(itemstack, can_put)
	magicalities.wands.update_wand_desc(itemstack)
	meta:set_string("contents", minetest.serialize(contents))

	return itemstack
end

function magicalities.register_crystal(element, description, color)
	-- Crystal Item
	minetest.register_craftitem("magicalities:crystal_"..element, {
		description = description.." Crystal Shard",
		inventory_image = "magicalities_crystal_shard.png^[multiply:"..color,
		_element = element,
		groups = {crystal = 1, ["elemental_"..element] = 1}
	})

	-- Crystal Cluster
	minetest.register_node("magicalities:crystal_cluster_"..element, {
		description = description.." Crystal Cluster",
		use_texture_alpha = true,
		mesh = "crystal.obj",
		paramtype = "light",
		drawtype = "mesh",
		light_source = 4,
		_element = element,
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.4375, -0.5000, -0.4375, 0.4375, 0.3750, 0.4375}
			}
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.4375, -0.5000, -0.4375, 0.4375, 0.3750, 0.4375}
			}
		},
		tiles = {
			{
				name = "magicalities_crystal.png^[multiply:"..color,
				backface_culling = true
			}
		},
		drop = {
            max_items = 1,
            items = {
                {
                    items = {"magicalities:crystal_"..element.." 4"},
                    rarity = 1,
                },
                {
                    items = {"magicalities:crystal_"..element.." 5"},
                    rarity = 5,
                },
            },
		},
		groups = {cracky = 3, oddly_breakable_by_hand = 3, crystal_cluster = 1, ["elemental_"..element] = 1},
		sunlight_propagates = true,
		is_ground_content = false,
		sounds = default.node_sound_glass_defaults(),

		on_rightclick = crystal_rightclick,
	})

	-- Crystal Block
	minetest.register_node("magicalities:crystal_block_"..element, {
		description = description.." Crystal Block",
		use_texture_alpha = true,
		paramtype = "light",
		drawtype = "glasslike",
		tiles = {
			{
				name = "magicalities_crystal.png^[multiply:"..color
			}
		},
		groups = {cracky = 3, oddly_breakable_by_hand = 3, crystal_block = 1, ["elemental_"..element] = 1},
		sunlight_propagates = true,
		is_ground_content = false,
		_element = element,
		sounds = default.node_sound_glass_defaults(),
	})

	-- Crystal clusters as ores
	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "magicalities:crystal_cluster_"..element,
		wherein        = "default:stone",
		clust_scarcity = 19 * 19 * 19,
		clust_num_ores = 1,
		clust_size     = 1,
		y_max          = -30,
		y_min          = -31000,
	})

	minetest.register_craft({
		type = "shapeless",
		output = "magicalities:crystal_block_"..element,
		recipe = {
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element
		},
	})

	minetest.register_craft({
		type = "shapeless",
		output = "magicalities:crystal_"..element.." 9",
		recipe = {
			"magicalities:crystal_block_"..element
		},
	})
end

-- Register refill ABMs
minetest.register_abm({
	label     = "Crystal Elements Refill",
	nodenames = {"group:crystal_cluster"},
	interval  = 60.0,
	chance    = 10,
	action    = function (pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		local contents = meta:get_string("contents")
		if contents ~= "" then
			-- Regenerate some elements
			contents = minetest.deserialize(contents)
			local count = 0
			for _, v in pairs(contents) do
				count = count + 1
			end

			local mcnt    = randbuff:next(1, count)
			local cnt     = 0
			for name, data in pairs(contents) do
				if cnt == mcnt then break end
				if type(data) ~= 'table' then break end

				if data[1] < data[2] then
					data[1] = data[1] + 1
					cnt = cnt + 1
				end
			end

			if cnt == 0 then return end

			meta:set_string("contents", minetest.serialize(contents))
		end 
	end
})
