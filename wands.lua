-- Magicalities Wands

magicalities.wands = {}

local transform_recipes = {
	["mg_table"] = {result = "magicalities:arcane_table", requirements = nil}
}

local wandcaps = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {},
	damage_groups = {fleshy = 2},
}

local randparticles = PcgRandom(os.clock())

local function align(len)
	local str = ""
	for i = 1, len do
		str = str.."\t"
	end
	return str
end

function magicalities.wands.get_wand_focus(stack)
	local meta = stack:get_meta()
	if meta:get_string("focus") == "" then
		return nil
	end

	local focus   = meta:get_string("focus")
	local itemdef = minetest.registered_items[focus]
	if not itemdef then return nil end

	return focus, itemdef
end

local function focus_requirements(stack, fdef)
	if fdef["_wand_requirements"] then
		return magicalities.wands.wand_has_contents(stack, fdef["_wand_requirements"])
	end
	
	return true
end

local function focuses_formspec(available, focusname)
	local x   = 0
	local fsp = ""
	for focus in pairs(available) do
		fsp = fsp .. "item_image_button["..x..",2.8;1,1;"..focus..";"..focus..";]"
		x = x + 1
	end

	local current = ""
	if not focusname then
		current = "label[2,1;No Focus]"
	else
		current = "item_image_button[2,0.5;1,1;"..focusname..";remove;Remove]"..
				  "label[0,1.5;Current: "..minetest.registered_items[focusname].description.."]"
	end

	return "size[5,3.5]"..
		default.gui_bg..
		default.gui_bg_img..
		"label[0,0;Wand Focuses]"..
		current..
		"label[0,2.4;Available]"..
		fsp
end

-- Update wand's description
function magicalities.wands.update_wand_desc(stack)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))

	local wanddata    = minetest.registered_items[stack:get_name()]
	local description = wanddata.description
	local capcontents = wanddata["_cap_max"] or 15
	local strbld      = description.."\n"

	local longest_desc = 0
	for _,data in pairs(magicalities.elements) do
		if not data.inheritance then
			local len = #data.description
			if len > longest_desc then
				longest_desc = len
			end
		end
	end

	local elems = {}
	for elem, amount in pairs(data_table) do
		local dataelem = magicalities.elements[elem]
		if amount > 0 then
			elems[#elems + 1] = minetest.colorize(dataelem.color, dataelem.description.." ")..
								align(longest_desc * 2 - #dataelem.description)..
								amount.."/"..capcontents
		end
	end

	local focus, def = magicalities.wands.get_wand_focus(stack)
	local focusstr = "No Wand Focus"
	if focus then
		focusstr = def.description
	end

	strbld = strbld .. focusstr
	if #elems > 0 then
		table.sort(elems)
		strbld = strbld .. "\n" .. table.concat(elems, "\n")
	end

	meta:set_string("description", strbld)
end

-- Ensure wand has contents
function magicalities.wands.wand_has_contents(stack, requirements)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))
	
	if not data_table then return false end

	for name, count in pairs(requirements) do
		if not data_table[name] or data_table[name] < count then
			return false
		end
	end
	
	return true
end

-- Take wand contents
function magicalities.wands.wand_take_contents(stack, to_take)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))

	for name, count in pairs(to_take) do
		if not data_table[name] or data_table[name] - count < 0 then
			return nil
		end

		data_table[name] = data_table[name] - count
	end
	
	local data_res = minetest.serialize(data_table)
	meta:set_string("contents", data_res)

	return stack
end

-- Add wand contents
function magicalities.wands.wand_insert_contents(stack, to_put)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))
	local cap = minetest.registered_items[stack:get_name()]["_cap_max"]
	local leftover = {}

	for name, count in pairs(to_put) do
		if data_table[name] then
			if data_table[name] + count > cap then
				data_table[name] = cap
				leftover[name] = (data_table[name] + count) - cap
			else
				data_table[name] = data_table[name] + count
			end
		end
	end
	
	local data_res = minetest.serialize(data_table)
	meta:set_string("contents", data_res)

	return stack, leftover
end

-- Can add wand contents
function magicalities.wands.wand_insertable_contents(stack, to_put)
	local meta = stack:get_meta()
	local data_table = minetest.deserialize(meta:get_string("contents"))
	local cap = minetest.registered_items[stack:get_name()]["_cap_max"]
	local insertable = {}

	for name, count in pairs(to_put) do
		if data_table[name] then
			if data_table[name] + count < cap + 1 then
				insertable[name] = count
			end
		end
	end

	return insertable
end

-- Initialize wand metadata
local function initialize_wand(stack)
	local data_table = {}

	for name, data in pairs(magicalities.elements) do
		if not data.inheritance then
			data_table[name] = 0
		end
	end

	local meta = stack:get_meta()
	meta:set_string("contents", minetest.serialize(data_table))
end

local function wand_action(itemstack, placer, pointed_thing)
	if not pointed_thing.type == "node" then return itemstack end
	local node = minetest.get_node(pointed_thing.under)
	local imeta = itemstack:get_meta()

	-- Initialize wand metadata
	if imeta:get_string("contents") == nil or imeta:get_string("contents") == "" then
		initialize_wand(itemstack)
		magicalities.wands.update_wand_desc(itemstack)
	end

	-- Replacement
	local to_replace = nil
	for grp, result in pairs(transform_recipes) do
		if minetest.get_item_group(node.name, grp) > 0 then
			to_replace = result
			break
		end
	end

	-- Call rightclick on the wand focus
	local focus, fdef = magicalities.wands.get_wand_focus(itemstack)
	if focus then
		if fdef["_wand_node"] and focus_requirements(itemstack, fdef) then
			itemstack = fdef["_wand_node"](pointed_thing.under, node, placer, itemstack, pointed_thing)

			return itemstack
		end
	end

	-- Call on_rightclick on the node instead if it cannot be replaced
	if not to_replace then
		local nodedef = minetest.registered_nodes[node.name]
		
		if nodedef.on_rightclick then
			itemstack = nodedef.on_rightclick(pointed_thing.under, node, placer, itemstack, pointed_thing)
		end

		return itemstack
	end
	
	if to_replace.requirements then
		if not magicalities.wands.wand_has_contents(itemstack, to_replace.requirements) then return itemstack end
		itemstack = magicalities.wands.wand_take_contents(itemstack, to_replace.requirements)
		magicalities.wands.update_wand_desc(itemstack)
	end

	minetest.swap_node(pointed_thing.under, {name = to_replace.result, param1 = node.param1, param2 = node.param2})
	
	local spec = minetest.registered_nodes[to_replace.result]
	if spec.on_construct then
		spec.on_construct(pointed_thing.under)
	end

	return itemstack
end

local function use_wand(itemstack, user, pointed_thing)
	local imeta = itemstack:get_meta()

	-- Initialize wand metadata
	if imeta:get_string("contents") == nil or imeta:get_string("contents") == "" then
		initialize_wand(itemstack)
		magicalities.wands.update_wand_desc(itemstack)
	end

	-- Call use on the wand focus
	local focus, fdef = magicalities.wands.get_wand_focus(itemstack)
	if focus then
		if fdef["_wand_use"] and focus_requirements(itemstack, fdef) then
			itemstack = fdef["_wand_use"](itemstack, user, pointed_thing)

			return itemstack
		end
	end

	-- Calculate velocity
	local dir = user:get_look_dir()
	local vel = {x=0,y=0,z=0}
	vel.x = dir.x * 16
	vel.y = dir.y * 16
	vel.z = dir.z * 16

	-- Calculate position
	local pos = user:get_pos()
	pos.x = pos.x + (dir.x * 2)
	pos.y = pos.y + (dir.y * 2) + 1.5
	pos.z = pos.z + (dir.z * 2)

	for i = 1, 16 do
		-- Deviation
		local relvel = {x=0,y=0,z=0}
		relvel.x = vel.x + (randparticles:next((-i/2.5) * 1000, (i/2.5) * 1000) / 1000)
		relvel.y = vel.y + (randparticles:next((-i/2.5) * 1000, (i/2.5) * 1000) / 1000)
		relvel.z = vel.z + (randparticles:next((-i/2.5) * 1000, (i/2.5) * 1000) / 1000)
		minetest.add_particle({
			pos = pos,
			velocity = relvel,
			acceleration = relvel,
			expirationtime = 1,
			size = 4,
			collisiondetection = true,
			collision_removal = true,
			texture = "magicalities_spark.png",
		--	animation = {Tile Animation definition},
			glow = 2
		})
	end

	magicalities.wands.update_wand_desc(itemstack)
	return itemstack
end

local function wand_focuses(itemstack, user, pointed_thing)
	local focuses_found = {}
	local inv  = user:get_inventory()
	local list = inv:get_list("main")

	local focusname, focusdef = magicalities.wands.get_wand_focus(itemstack)
	local meta = itemstack:get_meta()

	for _, stack in pairs(list) do
		if minetest.get_item_group(stack:get_name(), "wand_focus") > 0 then
			focuses_found[stack:get_name()] = true
		end
	end

	minetest.show_formspec(user:get_player_name(), "magicalities:wand_focuses", focuses_formspec(focuses_found, focusname))
	minetest.register_on_player_receive_fields(function (player, formname, fields)
		if formname ~= "magicalities:wand_focuses" then
			return false
		end

		-- Make sure field is a valid item
		local f = ""
		if not fields["quit"] then
			if fields["remove"] then
				f = nil
			else
				for v in pairs(fields) do
					if minetest.registered_items[v] then
						f = v
						break
					end
				end
			end
		else
			return true
		end

		local was

		was = meta:get_string("focus")
		if was == "" and not f then
			return true
		elseif was ~= "" then
			was = ItemStack(was)
			if not inv:room_for_item("main", was) then
				return true
			end
		end

		minetest.close_formspec(player:get_player_name(), "magicalities:wand_focuses")

		local removed_focus = false
		local set = false

		-- Update itemstack
		for i, stack in pairs(list) do
			if set and (removed_focus or not f) then break end
			if not removed_focus and stack:get_name() == f then
				inv:set_stack("main", i, ItemStack(nil))
				removed_focus = true -- Make sure to only remove one
			end
			
			if stack:get_name() == itemstack:get_name() and stack:get_meta() == itemstack:get_meta() and not set then
				if not f then
					meta:set_string("focus", "")
					magicalities.wands.update_wand_desc(itemstack)
				elseif f ~= "" then
					meta:set_string("focus", f)
					magicalities.wands.update_wand_desc(itemstack)
				end

				inv:set_stack("main", i, itemstack)
				set = true
			end
		end

		-- Give the removed focus back
		if was then
			inv:add_item("main", was)
		end

		return true
	end)

	return itemstack
end

function magicalities.wands.register_wand(name, data)
	local mod = minetest.get_current_modname()
	minetest.register_tool(mod..":wand_"..name, {
		description = data.description,
		inventory_image = data.image,
		tool_capabilities = wandcaps,
		stack_max = 1,
		_cap_max = data.wand_cap,
		on_use = use_wand,
		on_place = wand_action,
		on_secondary_use = wand_focuses,
		groups = {wand = 1}
	})
end
