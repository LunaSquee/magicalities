-- Wand Focuses

minetest.register_craftitem("magicalities:focus_teleport", {
	description = "Wand Focus of Teleportation",
	groups = {wand_focus = 1},
	inventory_image = "magicalities_focus_teleport.png",
	stack_max = 1,
	_wand_requirements = {
		["air"] = 1
	},
	_wand_use = function (itemstack, user, pointed_thing)
		local dir  = user:get_look_dir()
		local dest = vector.multiply(dir, 20)
		dest = vector.add(dest, user:get_pos())

		local pos = user:get_pos()
		pos.x = pos.x + (dir.x * 2)
		pos.y = pos.y + (dir.y * 2) + 1.5
		pos.z = pos.z + (dir.z * 2)

		local ray  = Raycast(pos, dest, true, false)
		local targ = ray:next()
		local can_go = targ == nil

		if targ and targ.type == "node" then
			local abv = minetest.get_node(targ.above)
			if not abv or abv.name == "air" then
				dest = targ.above
				can_go = true
			end
		end

		if can_go then
			itemstack = magicalities.wands.wand_take_contents(itemstack, {air = 1})
			magicalities.wands.update_wand_desc(itemstack)
			user:set_pos(dest)
		end

		return itemstack
	end
})
