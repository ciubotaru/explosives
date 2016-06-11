--File name: init.lua
--Project name: explosives, a Mod for Minetest
--License: General Public License, version 3 or later
--Copyright (C) 2016 Vitalie Ciubotaru <vitalie at ciubotaru dot tk>

minetest.log('action', 'MOD: Explosives loading...')
local explosives_version = '0.0.1'

explosives = rawget(_G, "explosives") or {}
--internationalization
if minetest.get_modpath("intllib") then
	explosives.i18n = intllib.Getter()
else
	explosives.i18n = function(s,a,...)
		a={a,...}
		local v = s:gsub("@(%d+)", function(n)
			return a[tonumber(n)]
		end)
		return v
	end
end
local i18n = explosives.i18n

local radius = tonumber(minetest.setting_get("tnt_radius") or 3)
local singleplayer = minetest.is_singleplayer()
local setting = minetest.setting_getbool("enable_tnt")
if (not singleplayer and setting ~= true) or
		(singleplayer and setting == false) then
	minetest.log('action', 'MOD: Landmine can not load (enable TNT).')
	return
end
local enable_mesh = minetest.setting_getbool("enable_explomesh")

local function formspec(pos)
	local timer = minetest.get_node_timer(pos)
	local formspec =
		'size[8,2]'..
--a dirty hack to pass node coords to player_receive_fields
		'field[0,0;0,0;x;;' .. pos.x .. ']'..
		'field[0,0;0,0;y;;' .. pos.y .. ']'..
		'field[0,0;0,0;z;;' .. pos.z .. ']'
	if timer:is_started() then
		formspec = formspec ..
		'label[0,0;' .. i18n('You have @1 seconds to disarm the mine', timer:get_timeout() - timer:get_elapsed()) .. ']' ..
		'button_exit[0,1;8,1;stop;' .. i18n('Disarm the mine') .. ']'
		return formspec
	else
		formspec = formspec ..
		'label[0,0;' .. i18n('You will have 30 seconds to run away') .. ']' ..
		'button_exit[0,1;8,1;start;' .. i18n('Arm the mine') .. ']'
		return formspec
	end
end

explosives.on_rightclick = function(pos, node, clicker, itemstack)
	minetest.show_formspec(
		clicker:get_player_name(),
		'explosives',
		formspec(pos)
	)
	return itemstack
end

local on_rightclick = explosives.on_rightclick

explosives.boom = function(pos)
	local node = minetest.get_node(pos)
	local def = {
		name = node.name,
		radius = radius,
		damage_radius = radius * 2,
	}
	tnt.boom(pos, def)
end

local boom = explosives.boom

explosives.detonate = function(pos, node, player, pointed_thing)
	local timer = minetest.get_node_timer(pos)
	if not timer:is_started() then
		minetest.sound_play("landmine_lock.ogg", {pos = pos})
		local delay = math.random(0,3)
		if delay == 0 then
			boom(pos)
		else
			timer:start(delay)
			minetest.set_node(pos, {name = "explosives:landmine_armed"})
		end
	end
end
local detonate = explosives.detonate

local function dig_up(pos, node, digger)
	local pos_up = {x = pos.x, y = pos.y + 1, z = pos.z}
	local node_up = minetest.get_node(pos_up)
	if node_up.name == node.name then
		--this recursively calls after_dig_node
		minetest.node_dig(pos_up, node_up, digger)
	end
end

local function dig_down(pos, node, digger)
	local pos_down = {x = pos.x, y = pos.y - 1, z = pos.z}
	local node_down = minetest.get_node(pos_down)
	if node_down.name == node.name then
		--this recursively calls after_dig_node
		minetest.node_dig(pos_down, node_down, digger)
	end
end

local function after_dig_node(pos, node, metadata, digger)
	dig_up(pos, node, digger)
	dig_down(pos, node, digger)
end

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
if enable_mesh == true then
	dofile(modpath .. "/mines-mesh.lua")
else
	dofile(modpath .. "/mines-nodebox.lua")
end

minetest.register_node("explosives:landmine_dirt", {
	description = i18n('Land mine in dirt'),
	tiles = {"default_dirt.png"},
	groups = {
		dig_immediate = 3,
		explody = 1,
	},
	sounds = default.node_sound_dirt_defaults(),
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			boom(pos)
		end
	end,
	on_rightclick = on_rightclick,
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
		minetest.place_node(pos, {name = 'explosives:landmine_dirt_armed'})
	end,
	on_blast = boom,
})

minetest.register_node("explosives:landmine_dirt_armed", {
	description = i18n('Land mine in dirt (armed)'),
	tiles = {"default_dirt.png"},
	groups = {
		landmine = 1,
		not_in_creative_inventory = 1
	},
	sounds = default.node_sound_dirt_defaults(),
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			boom(pos)
		else
			detonate(pos)
		end
	end,
	on_blast = boom,
})

minetest.register_node("explosives:landmine_dirt_with_grass", {
	description = i18n('Land mine in dirt with grass'),
	tiles = {
		"default_grass.png",
		"default_dirt.png",
		{
			name = "default_dirt.png^default_grass_side.png",
			tileable_vertical = false
		}
	},
	groups = {
		dig_immediate = 3,
		explody = 1,
	},
	sounds = default.node_sound_dirt_defaults({
		footstep = {
			name="default_grass_footstep",
			gain=0.25
		},
	}),
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			boom(pos)
		end
	end,
	on_rightclick = on_rightclick,
	on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
		minetest.place_node(pos, {name = 'explosives:landmine_dirt_with_grass_armed'})
	end,
	on_blast = boom,
})

minetest.register_node("explosives:landmine_dirt_with_grass_armed", {
	description = i18n('Land mine in dirt with grass (armed)'),
	tiles = {
		"default_grass.png",
		"default_dirt.png",
		{
			name = "default_dirt.png^default_grass_side.png",
			tileable_vertical = false
		}
	},
	groups = {
		landmine = 1,
		not_in_creative_inventory = 1
	},
	sounds = default.node_sound_dirt_defaults({
		footstep = {
			name="default_grass_footstep",
			gain=0.25
		},
	}),
	on_punch = function(pos, node, puncher)
		if puncher:get_wielded_item():get_name() == "default:torch" then
			boom(pos)
		else
			detonate(pos)
		end
	end,
	on_blast = boom,
})

minetest.register_node("explosives:minefield_sign", {
	description = i18n('Minefield sign'),
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png^minefield_sign.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.25, -0.0625, 0.4375, 0.375, 0},
			{-0.0625, -0.5, -0.0625, 0.0625, -0.1875, 0},
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.4375, -0.5, -0.0625, 0.4375, 0.375, 0}
	},
	groups = {choppy = 2, flammable = 2, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string('infotext', i18n('Danger\nMines'))
	end,
})

minetest.register_node("explosives:navalmine_cable", {
	description = i18n('Naval mine cable'),
	tiles = {
		"navalmine_cable.png",
		"navalmine_cable.png^[transform2",
	},
	walkable = false,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	drop = {max_items = 0},
	tile_images = {"navalmine_cable.png"},
	drawtype = "plantlike",
	groups = {
		cracky=3,
		not_in_creative_inventory = 1, --only cable reels, not fragments of cable
	},
	sounds =  default.node_sound_stone_defaults(),
	after_dig_node = after_dig_node,
})

if minetest.get_modpath('dye') ~= nil then
	minetest.register_craft({
		type = "shapeless",
		recipe = {'dye:black', 'dye:orange', 'dye:red', 'default:sign_wall_wood'},
		output = 'explosives:minefield_sign',
	})
end

minetest.register_craftitem("explosives:fuze", {
	description = "Land mine fuze",
	inventory_image = "landmine_fuze.png",
})

minetest.register_craftitem("explosives:cable_reel", {
	description = "Naval mine cable (reel)",
	inventory_image = "navalmine_cable_reel.png",
})

minetest.register_craft({
	output = 'explosives:fuze 10',
	recipe = {
		{"", "default:steel_ingot",""},
		{"", "tnt:gunpowder",""},
		{"", "default:steel_ingot",""},
	}
})

minetest.register_craft({
	type = "shapeless",
	recipe = {"explosives:fuze", "tnt:tnt"},
	output = 'explosives:landmine',
})

minetest.register_craft({
	type = "shapeless",
	recipe = {"default:dirt", "explosives:landmine"},
	output = 'explosives:landmine_dirt',
})

minetest.register_craft({
	type = "shapeless",
	recipe = {"default:grass_1", "explosives:landmine_dirt"},
	output = 'explosives:landmine_dirt_with_grass',
})

minetest.register_craft({
	type = "shapeless",
	recipe = {"default:dirt", "default:grass_1", "explosives:landmine"},
	output = 'explosives:landmine_dirt_with_grass',
})

if minetest.get_modpath('vessels') ~= nil then
	minetest.register_craft({
		output = 'explosives:cable_reel',
		recipe = {
			{"default:steel_ingot", "default:steel_ingot","default:steel_ingot"},
			{"default:steel_ingot", "group:wood","default:steel_ingot"},
			{"default:steel_ingot", "default:steel_ingot","default:steel_ingot"},
		}
	})
	minetest.register_craft({
		type = "shapeless",
		recipe = {'group:vessel', 'explosives:landmine', 'explosives:cable_reel'},
		output = 'explosives:navalmine',
	})
end

minetest.register_abm({
	nodenames = {"group:landmine"},
	interval = 1.0,
	chance = 1,
	catch_up = false,
	action = function(pos, _, _, _)
		--detonate if something is placed above
		if minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z}).name ~= "air" then
			detonate(pos)
			return
		end
		--detonate if someone walks upon the mine
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y + 0.3, z = pos.z}, 0.6)
		for k, player in pairs(objs) do
			if player:get_player_name() ~= "" then
				detonate(pos)
				return
			end
		end
	end
})

--sticking cable disappears; hanging cable extends down
minetest.register_abm({
	nodenames = {"explosives:navalmine_cable"},
	interval = 600, --once in 10 mins
	chance = 1,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		--disappear if air or water above
		local node_up = minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
		if node_up.name == "air" or minetest.get_item_group(node_up, "water") > 0 then
			minetest.remove_node(pos)
		end
		--add cable down if water below
		local node_down = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
		if minetest.get_item_group(node_down, "water") > 0 then
			minetest.set_node({x = pos.x, y = pos.y - 1, z = pos.z}, {name="explosives:navalmine_cable"})
		end
	end
})

--naval mines floating up/down and extending/shringking their cable
minetest.register_abm({
	nodenames = {"group:navalmine"},
	interval = 60, --every minute
	chance = 1,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local pos_up = {x = pos.x, y = pos.y + 1, z = pos.z}
		local node_up = minetest.get_node(pos_up)
		local node_down = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
		--move up if water above
		if minetest.get_item_group(node_up.name, "water") ~= 0 then
			minetest.set_node(pos_up, {name = node.name})
			minetest.set_node(pos, {name = "explosives:navalmine_cable"})
			return
		else
		end
		--move down if no water above and around, but water/cable below
		if minetest.get_item_group(node_up.name, "water") == 0
			and minetest.get_item_group(minetest.get_node({x = pos.x + 1, y = pos.y, z = pos.z}).name, "water") == 0
			and minetest.get_item_group(minetest.get_node({x = pos.x - 1, y = pos.y, z = pos.z}).name, "water") == 0
			and minetest.get_item_group(minetest.get_node({x = pos.x, y = pos.y, z = pos.z + 1}).name, "water") == 0
			and minetest.get_item_group(minetest.get_node({x = pos.x, y = pos.y, z = pos.z - 1}).name, "water") == 0
			and ( minetest.get_item_group(node_down, "water") > 0 or minetest.get_node(node_down).name == "explosives:navalmine_cable")
			then
			minetest.remove_node(pos)
			minetest.set_node(pos_down, {name = node.name})
			return
		end
		--if no cable beneath and no need to move down, mark the mine as drifting
		if node_down.name ~= "explosives:navalmine_cable" then
			local meta = minetest.get_meta(pos)
			if meta:get_int("drifting") ~= 1 then
				meta:set_int("drifting", 1)
			else
			end
		end
	end
})

--naval mines watch out for players
minetest.register_abm({
	nodenames = {"group:navalmine"},
	interval = 1.0,
	chance = 1,
	catch_up = false,
	action = function(pos, _, _, _)
		--detonate if a player approaches the mine
		local objs = minetest.get_objects_inside_radius(pos, radius * 2)
		for k, player in pairs(objs) do
			if player:get_player_name() ~= "" then
				boom(pos)
				return
			end
		end
	end
})

--drifting
minetest.register_abm({
	nodenames = {"group:navalmine"},
	interval = 600, --once in 10 mins
	chance = 1,
	catch_up = false,
	action = function(pos, _, _, _)
		--only drifting mines
		if minetest.get_meta(pos):get_int("drifting") ~= 1 then
			return
		end
		local directions = {}
		if minetest.get_item_group(minetest.get_node({x = pos.x + 1, y = pos.y, z = pos.z}).name, "water") > 0 then
			table.insert(directions, {x = pos.x + 1, y = pos.y, z = pos.z})
		end
		if minetest.get_item_group(minetest.get_node({x = pos.x - 1, y = pos.y, z = pos.z}).name, "water") > 0 then
			table.insert(directions, {x = pos.x - 1, y = pos.y, z = pos.z})
		end
		if minetest.get_item_group(minetest.get_node({x = pos.x, y = pos.y, z = pos.z + 1}).name, "water") > 0 then
			table.insert(directions, {x = pos.x, y = pos.y, z = pos.z + 1})
		end
		if minetest.get_item_group(minetest.get_node({x = pos.x, y = pos.y, z = pos.z - 1}).name, "water") > 0 then
			table.insert(directions, {x = pos.x, y = pos.y, z = pos.z - 1})
		end
		if #directions > 0 then
			local rnd = math.random(#directions)
			minetest.set_node(pos, {name = "default:water_source"})
			minetest.set_node(directions[rnd], {name = "explosives:navalmine_armed"})
			minetest.get_meta(directions[rnd]):set_int("drifting", 1)
		end
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "explosives" then return end
	local timer = minetest.get_node_timer({x = fields.x, y = fields.y, z = fields.z})
	if fields.start then
		timer:start(30)
		return
	end
	if fields.stop then
		timer:stop()
		return
	end
end)

minetest.log('action', 'MOD: Explosives version ' .. explosives_version .. ' loaded.')
