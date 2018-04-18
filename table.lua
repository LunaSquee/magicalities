
magicalities.arcane = {}
magicalities.arcane.recipes = {}

local fmspecelems = {
	["earth"] = {3, 0.15},
	["water"] = {1, 1},
	["air"]   = {5, 1},
	["fire"]  = {3, 4.85},
	["light"] = {1, 4},
	["dark"]  = {5, 4}
}

local function arcane_table_formspec(data)
	local spec   = ""
	local labels = ""

	if not data then
		data = {}
	end

	for name, pos in pairs(fmspecelems) do
		local cp = ""
		local y = -0.4

		if not data[name] then
			cp = "^[colorize:#2f2f2f:200"
		end

		if pos[2] > 2.5 then
			y = 0.85
		end

		spec = spec .. "image["..pos[1]..","..pos[2]..";1,1;magicalities_symbol_"..name..".png"..cp.."]"

		if data[name] then
			labels = labels .. "label["..(pos[1] + 0.3)..","..(pos[2] + y)..";"..data[name].."]"
		end
	end

	return "size[10,10.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;Arcane Crafting Table]"..
		"image[0.98,0.3;6,6;magicalities_symbol_hexagram.png]"..
		spec..
		"list[context;craft;2,1.5;3,3;]"..
		"list[context;craftres;7,2.5;1,1;]"..
		"list[context;wand;7,1;1,1;]"..
		labels..
		"image[6,2.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"list[current_player;main;1,6.25;8,1;]"..
		"list[current_player;main;1,7.5;8,3;8]"..
		"listring[context;wand]"..
		"listring[current_player;main]"..
		"listring[context;craft]"..
		"listring[current_player;main]"..
		"listring[context;craftres]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(1, 6.25)
end

function magicalities.arcane.register_recipe(data)
	table.insert(magicalities.arcane.recipes, data)
end

local function split_components(items)
	local arrays = {}
	local temp = {}
	local index = 1

	for i, k in pairs(items) do
		temp[#temp + 1] = k:get_name()
		index = index + 1
		if index == 4 then
			-- Don't add blank rows
			local blanks = 0
			for _, tmp in pairs(temp) do
				if tmp == "" then
					blanks = blanks + 1
				end
			end
			
			if blanks ~= 3 then
				arrays[#arrays + 1] = temp
			end

			temp = {}
			index = 1
		end
	end

	return arrays
end

local function compare_find(splitup)
	local found = nil

	for _,recipe in pairs(magicalities.arcane.recipes) do
		-- Don't even bother if it doesnt have the correct amount of rows
		if #splitup == #recipe.input then
			local rows = 0
			for index, row in pairs(recipe.input) do
				if not splitup[index] then break end
				if #splitup[index] ~= #row then break end

				local cells = 0
				for i, cell in pairs(row) do
					if cell:find("group:") == 1 then
						if minetest.get_item_group(splitup[index][i], cell:gsub("group:", "")) > 0 then
							cells = cells + 1
						end
					elseif splitup[index][i] == cell then
						cells = cells + 1
					end
				end

				if cells == #row then
					rows = rows + 1
				end
			end

			if rows == #recipe.input then
				found = recipe
				break
			end
		end
	end

	return found
end

function magicalities.arcane.get_recipe(items)
	local split = split_components(items)
	local recipe = compare_find(split)

	if not recipe then return nil end
	local result = {new_input = {}, output = recipe.output, requirements = recipe.requirements}
	for _,stack in pairs(items) do
		stack:take_item(1)
		result.new_input[#result.new_input + 1] = stack
	end

	return result
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if (listname == "wand" and minetest.get_item_group(stack:get_name(), "wand") == 0) or listname == "craftres" then
		return 0
	end

	return stack:get_count()
end

local function allow_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	if from_list == "craftres" and to_list == "craft" then return 0 end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)

	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function set_output(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	-- Check for possible result
	local result = magicalities.arcane.get_recipe(inv:get_list("craft"))
	if not result then return nil end

	-- Check for wand
	local wand = inv:get_stack("wand", 1)
	if not wand or wand:is_empty() then
		return nil, result.requirements
	end

	-- Check requirements
	local requirements = result.requirements
	if not magicalities.wands.wand_has_contents(wand, requirements) then
		return nil, result.requirements
	end

	-- Output fits
	local output = ItemStack(result.output)
	if not inv:room_for_item("craftres", output) then
		return inv:get_stack("craftres", 1), result.requirements
	end

	-- Set output
	return output, result.requirements
end

local function update_craft(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local out, reqs = set_output(pos)

	if reqs then
		meta:set_string("formspec", arcane_table_formspec(reqs))
	else
		meta:set_string("formspec", arcane_table_formspec({}))
	end

	inv:set_list("craftres", { out })
end

-- Arcane Crafting Table
minetest.register_node("magicalities:arcane_table", {
	description = "Arcane Crafting Table",
	tiles = {
		"magicalities_table_arcane_top.png", "magicalities_table_arcane.png", "magicalities_table_arcane.png",
		"magicalities_table_arcane.png", "magicalities_table_arcane.png", "magicalities_table_arcane.png",
	},
	on_construct = function(pos) 
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", arcane_table_formspec())

		local inv = meta:get_inventory()
		inv:set_size("craft", 9)
		inv:set_size("craftres", 1)
		inv:set_size("wand", 1)
	end,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if listname == "craftres" then
			local res = magicalities.arcane.get_recipe(inv:get_list("craft"))
			if res then
				inv:set_list("craft", res.new_input)

				-- Take from wand
				local wand = inv:get_stack("wand", 1)
				wand = magicalities.wands.wand_take_contents(wand, res.requirements)
				magicalities.wands.update_wand_desc(wand)
				inv:set_list("wand", {wand})
			end
		end
		
		update_craft(pos)
	end,
	on_metadata_inventory_put = update_craft,
	on_metadata_inventory_move = update_craft,

	groups = {choppy = 2, oddly_breakable_by_hand = 1, arcane_table = 1}
})

-- Base Table
minetest.register_node("magicalities:table", {
	description = "Table",
	drawtype = "nodebox",
	tiles = {
		"magicalities_table_wood_top.png", "magicalities_table_wood.png", "magicalities_table_wood.png",
		"magicalities_table_wood.png", "magicalities_table_wood.png", "magicalities_table_wood.png",
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.2500, -0.5000, -0.2500, 0.2500, -0.3750, 0.2500},
			{-0.1250, -0.3750, -0.1250, 0.1250, 0.3750, 0.1250},
			{-0.5000, 0.3750, -0.5000, 0.5000, 0.5000, 0.5000}
		}
	},
	groups = {choppy = 2, oddly_breakable_by_hand = 1, mg_table = 1}
})
