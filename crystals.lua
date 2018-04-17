-- Magicalities crystals

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

	-- Crafting between clusters, shards and blocks
	minetest.register_craft({
		type = "shapeless",
		output = "magicalities:crystal_cluster_"..element,
		recipe = {
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element,
			"magicalities:crystal_"..element
		},
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

-- Register all crystals
for name, data in pairs(magicalities.elements) do
	if not data.inheritance then
		magicalities.register_crystal(name, data.description, data.color)
	end
end
