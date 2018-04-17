-- Magicalities Wands

magicalities.wands = {}

local transform_recipes = {
	["mg_table"] = {result = "magicalities:arcane_table", requires = {["earth"] = 5, ["light"] = 5}}
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

	for elem, amount in pairs(data_table) do
		local dataelem = magicalities.elements[elem]
		if amount > 0 then
			strbld = strbld.."\n"
			strbld = strbld..minetest.colorize(dataelem.color, dataelem.description.." ")
			strbld = strbld..align(longest_desc * 2 - #dataelem.description)
			strbld = strbld..amount.."/"..capcontents
		end
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

-- Initialize wand metadata
local function initialize_wand(stack)
	local data_table = {}

	for name, data in pairs(magicalities.elements) do
		if not data.inheritance then
			data_table[name] = 10
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

	local to_replace = nil
	for grp, result in pairs(transform_recipes) do
		if minetest.get_item_group(node.name, grp) > 0 then
			to_replace = result
			break
		end
	end

	if not to_replace then return itemstack end
	if to_replace.requires then
		if not magicalities.wands.wand_has_contents(itemstack, to_replace.requires) then return itemstack end
		itemstack = magicalities.wands.wand_take_contents(itemstack, to_replace.requires)
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

	if not magicalities.wands.wand_has_contents(itemstack, {water = 5}) then
		return itemstack
	end

	--itemstack = magicalities.wands.wand_take_contents(itemstack, {water = 5})

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

	for i = 1, 8 do
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
		groups = {wand = 1}
	})
end

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

