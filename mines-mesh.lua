local i18n = explosives.i18n
local on_rightclick = explosives.on_rightclick
local boom = explosives.boom
local detonate = explosives.detonate

minetest.register_node("explosives:landmine", {
	description = i18n('Land mine'),
	paramtype = "light",
	paramtype2 = "facedir", --optional
	tiles = {"explosives_landmine.png"},
	drawtype = "mesh",
	mesh = "landmine.obj",
	groups = {
		dig_immediate = 3,
		explody = 1,
	},
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			boom(pos)
		end
	end,
	on_rightclick = on_rightclick,
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
		minetest.place_node(pos, {name = 'explosives:landmine_armed'})
	end,
	on_blast = boom,
})

minetest.register_node("explosives:landmine_armed", {
	description = i18n('Land mine (armed)'),
	paramtype = "light",
	paramtype2 = "facedir", --optional
	tiles = {"explosives_landmine.png"},
	drawtype = "mesh",
	mesh = "landmine.obj",
	groups = {
		landmine = 1,
		not_in_creative_inventory = 1,
	},
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			boom(pos)
		else
			detonate(pos)
		end
	end,
	on_timer = boom,
	on_blast = boom,
})

minetest.register_node("explosives:navalmine", {
	description = i18n('Naval mine'),
	paramtype = "light",
	paramtype2 = "facedir", --optional
	tiles = {"explosives_navalmine.png"},
	drawtype = "mesh",
	mesh = "navalmine.obj",
	groups = {
		dig_immediate = 3,
		explody = 1,
	},
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			boom(pos)
		end
	end,
	on_rightclick = on_rightclick,
	on_timer = function(pos, elapsed)
		--make sure it didn't move
		if minetest.get_node(pos).name == "explosives:navalmine" then
			minetest.set_node(pos, {name = 'explosives:navalmine_armed'})
			minetest.get_meta(pos):set_int("drifting", 0)
		end
	end,
	on_blast = boom,
})

minetest.register_node("explosives:navalmine_armed", {
	description = i18n('Naval mine (armed)'),
	paramtype = "light",
	paramtype2 = "facedir", --optional
	tiles = {"explosives_navalmine.png"},
	drawtype = "mesh",
	mesh = "navalmine.obj",
	groups = {
		dig_immediate = 3,
		explody = 1,
		navalmine = 1,
		not_in_creative_inventory = 1
	},
	drop = "explosives:navalmine", --shouldn't happen
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			boom(pos)
		end
	end,
	on_blast = boom,
})

