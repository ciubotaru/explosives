--File name: init.lua
--Project name: landmine, a Mod for Minetest
--License: General Public License, version 3 or later
--Copyright (C) 2016 Vitalie Ciubotaru <vitalie at ciubotaru dot tk>

minetest.log('action', 'MOD: Landmine loading...')
landmine_version = '0.0.1'
local singleplayer = minetest.is_singleplayer()

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

local setting = minetest.setting_getbool("enable_tnt")
if (not singleplayer and setting ~= true) or
		(singleplayer and setting == false) then
if singleplayer then
minetest.log('action','singleplayer')
else
minetest.log('action','not singleplayer')
end
if (setting ~= true or setting == false) then
minetest.log('action', 'setting false')
end
minetest.log('action', 'MOD: Landmine not loaded.')
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

function boom(pos)
	minetest.set_node(pos, {name = "tnt:tnt_burning"})
	minetest.get_node_timer(pos):start(0.1) --explode immediately
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
		not_in_creative_inventory = 0,
		falling_node = 1,
	},
	on_punch = detonate,
	on_timer = boom,
	on_blast = boom,
})

minetest.register_node("landmine:landmine_dirt", {
	description = i18n('Land mine (dirt)'),
	tiles = {"default_dirt.png"},
	groups = {not_in_creative_inventory = 0},
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
	groups = {not_in_creative_inventory = 0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {
			name="default_grass_footstep",
			gain=0.25
		},
	}),
	on_punch = detonate,
	on_blast = boom,
})

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

minetest.log('action', 'MOD: Landmine version ' .. landmine_version .. ' loaded.')
