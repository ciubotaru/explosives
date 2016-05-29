--File name: init.lua
--Project name: landmine, a Mod for Minetest
--License: General Public License, version 3 or later
--Copyright (C) 2016 Vitalie Ciubotaru <vitalie at ciubotaru dot tk>

minetest.log('action', 'MOD: Landmine loading...')
local landmine_version = '0.0.1'

local i18n --internationalization
if minetest.get_modpath("intllib") then
	i18n = intllib.Getter()
else
	i18n = function(s,a,...)
		a={a,...}
		local v = s:gsub("@(%d+)", function(n)
			return a[tonumber(n)]
		end)
		return v
	end
end

local singleplayer = minetest.is_singleplayer()
local setting = minetest.setting_getbool("enable_tnt")
if (not singleplayer and setting ~= true) or
		(singleplayer and setting == false) then
	minetest.log('action', 'MOD: Landmine can not load (enable TNT).')
	return
end

local function detonate(pos, node, player, pointed_thing)
	local timer = minetest.get_node_timer(pos)
	if not timer:is_started() then
		minetest.sound_play("landmine_lock.ogg", {pos = pos})
		timer:start(3) --3 seconds to run away
	end
	minetest.set_node(pos, {name = "landmine:landmine"})
end

local function boom(pos)
	local radius = tonumber(minetest.setting_get("tnt_radius") or 3)
       local node = minetest.get_node(pos)
       local def = {
               name = node.name,
               radius = radius,
               damage_radius = radius * 2,
       }
       tnt.boom(pos, def)
end

minetest.register_node("landmine:landmine", {
	description = i18n('Land mine'),
	tiles = {
		"landmine_top.png",
		"landmine_bottom.png",
		"landmine_side.png",
		"landmine_side.png",
		"landmine_side.png",
		"landmine_side.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1875, -0.5, -0.5, 0.1875, -0.1875, 0.5}, -- NodeBox1
			{-0.5, -0.5, -0.1875, 0.5, -0.1875, 0.1875}, -- NodeBox2
			{-0.3125, -0.5, -0.4375, 0.3125, -0.1875, 0.4375}, -- NodeBox3
			{-0.4375, -0.5, -0.3125, 0.4375, -0.1875, 0.3125}, -- NodeBox4
			{-0.375, -0.5, -0.375, 0.375, -0.1875, 0.375}, -- NodeBox5
			{-0.4375, -0.1875, -0.125, 0.4375, -0.0625, 0.125}, -- NodeBox6
			{-0.125, -0.1875, -0.4375, 0.125, -0.0625, 0.4375}, -- NodeBox7
			{-0.125, -0.0625, -0.125, 0.125, 0.0625, 0.125}, -- NodeBox8
		}
	},
	groups = {
		landmine = 1,
		not_in_creative_inventory = 0,
	},
	on_punch = detonate,
	on_timer = boom,
	on_blast = boom,
})

minetest.register_node("landmine:landmine_dirt", {
	description = i18n('Land mine (dirt)'),
	tiles = {"default_dirt.png"},
	groups = {
		landmine = 1,
		not_in_creative_inventory = 0
	},
	sounds = default.node_sound_dirt_defaults(),
	on_punch = detonate,
	on_blast = boom,
})

minetest.register_node("landmine:landmine_dirt_with_grass", {
	description = i18n('Land mine (dirt with grass)'),
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
		not_in_creative_inventory = 0
	},
	sounds = default.node_sound_dirt_defaults({
		footstep = {
			name="default_grass_footstep",
			gain=0.25
		},
	}),
	on_punch = detonate,
	on_blast = boom,
})

minetest.register_node("landmine:minefield_sign", {
	description = i18n('Minefield sign'),
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png^landmine_sign.png",
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

if minetest.get_modpath('dye') ~= nil then
	minetest.register_craft({
		type = "shapeless",
		recipe = {'dye:black', 'dye:orange', 'dye:red', 'default:sign_wall_wood'},
		output = 'landmine:minefield_sign',
	})
end

minetest.register_craftitem("landmine:fuze", {
	description = "Land mine fuze",
	inventory_image = "landmine_fuze.png",
})

minetest.register_craft({
	output = 'landmine:fuze 10',
	recipe = {
		{"", "default:steel_ingot",""},
		{"", "tnt:gunpowder",""},
		{"", "default:steel_ingot",""},
	}
})

minetest.register_craft({
	type = "shapeless",
	recipe = {"landmine:fuze", "tnt:tnt"},
	output = 'landmine:landmine',
})

minetest.register_craft({
	type = "shapeless",
	recipe = {"default:dirt", "landmine:landmine"},
	output = 'landmine:landmine_dirt',
})

minetest.register_craft({
	type = "shapeless",
	recipe = {"default:grass_1", "landmine:landmine_dirt"},
	output = 'landmine:landmine_dirt_with_grass',
})

minetest.register_craft({
	type = "shapeless",
	recipe = {"default:dirt", "default:grass_1", "landmine:landmine"},
	output = 'landmine:landmine_dirt_with_grass',
})

minetest.register_abm({
	nodenames = {"group:landmine"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
--		local node_above = minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
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

minetest.log('action', 'MOD: Landmine version ' .. landmine_version .. ' loaded.')
