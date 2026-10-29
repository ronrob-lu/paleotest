paleotest = {}

-- Provide fallback stubs if mobkit or mob_core are missing
if not mobkit then
    mobkit = {
        statfunc = function() end,
        actfunc = function() end,
        stepfunc = function() end,
        recall = function(self, key) return self and self[key] end,
        remember = function(self, key, val) if self then self[key] = val end return val end,
        is_alive = function(self) return self and self.object and self.object:get_hp() > 0 end,
        timer = function(self, s) return false end,
        get_stand_pos = function(self) return self.object and self.object:get_pos() or {x=0,y=0,z=0} end,
        clear_queue_high = function() end,
        clear_queue_low = function() end,
        queue_high = function() end,
        queue_low = function() end,
        animate = function() end,
        make_sound = function() end,
        heal = function() end,
        hurt = function() end,
        hq_follow = function() end,
        get_queue_priority = function() return 0 end,
        get_nearby_player = function() return nil end,
        is_queue_empty_high = function() return true end,
        is_queue_empty_low = function() return true end,
        get_closest_entity = function() return nil end,
        lq_idle = function() end,
        lq_turn2pos = function() end,
        lq_fallover = function() end,
    }
end

if not mob_core then
    mob_core = {
        get_name_proper = function(name)
            if not name then return "" end
            local parts = name:split(":")
            local mob_name = parts[2] or parts[1]
            return (mob_name:gsub("_", " "):gsub("^%l", string.upper))
        end,
        on_activate = function() end,
        collision_detection = function() end,
        vitals = function() end,
        random_sound = function() end,
        growth = function() end,
        protect = function() end,
        nametag = function() end,
        on_punch_basic = function() end,
        on_punch_retaliate = function() end,
        on_punch_runaway = function() end,
        on_die = function(self) if self.object then self.object:remove() end end,
        register_spawn_egg = function() end,
        set_scale = function() end,
        set_textures = function() end,
        spawn_child = function(pos, mob) return minetest.add_entity(pos, mob) end,
        hq_roam = function() end,
        hq_liquid_recovery = function() end,
        logic_attack_mob = function() end,
        logic_attack_mobs = function() end,
        logic_attack_player = function() end,
        hq_follow_holding = function() end,
        follow_holding = function() return false end,
        set_owner = function(self, name) if self then self.owner = name end end,
        mount = function() end,
        detach = function() end,
        is_mobkit_mob = function() return false end,
        logic_aqua_attack_mobs = function() end,
        logic_aqua_attack_player = function() end,
        logic_aqua_attack_mob = function() end,
        hq_aqua_roam = function() end,
        hq_aqua_follow_holding = function() end,
        hq_takeoff = function() end,
        hq_land = function() end,
        hq_aerial_roam = function() end,
        hq_mount_logic = function() end,
        punch_timer = function() end,
        goto_next_waypoint = function() end,
        swim_to_next_waypoint = function() end,
        fly_to_next_waypoint = function() end,
    }
end

-- Sound abstraction helpers
function paleotest.node_sound_stone_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_stone_defaults then
		return default.node_sound_stone_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_stone_defaults then
		return mcl_sounds.node_sound_stone_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_dirt_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_dirt_defaults then
		return default.node_sound_dirt_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_dirt_defaults then
		return mcl_sounds.node_sound_dirt_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_sand_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_sand_defaults then
		return default.node_sound_sand_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_sand_defaults then
		return mcl_sounds.node_sound_sand_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_wood_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_wood_defaults then
		return default.node_sound_wood_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_wood_defaults then
		return mcl_sounds.node_sound_wood_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_leaves_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_leaves_defaults then
		return default.node_sound_leaves_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_leaves_defaults then
		return mcl_sounds.node_sound_leaves_defaults(table)
	end
	return table or {}
end

function paleotest.node_sound_metal_defaults(table)
	if minetest.get_modpath("default") and default.node_sound_metal_defaults then
		return default.node_sound_metal_defaults(table)
	elseif minetest.get_modpath("mcl_sounds") and mcl_sounds.node_sound_metal_defaults then
		return mcl_sounds.node_sound_metal_defaults(table)
	end
	return table or {}
end

-- Node & Tree Growth Abstractions
function paleotest.can_grow(pos)
	if minetest.get_modpath("default") and default.can_grow then
		return default.can_grow(pos)
	end
	local node_above = minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
	local light = minetest.get_node_light(pos)
	return (light and light >= 13) and (node_above.name == "air" or minetest.registered_nodes[node_above.name].buildable_to)
end

function paleotest.sapling_on_place(itemstack, placer, pointed_thing, sapling_name, minp, maxp, interval)
	if minetest.get_modpath("default") and default.sapling_on_place then
		return default.sapling_on_place(itemstack, placer, pointed_thing, sapling_name, minp, maxp, interval)
	end
	return minetest.item_place(itemstack, placer, pointed_thing)
end

function paleotest.get_inventory_drops(pos, listname, drops)
	if minetest.get_modpath("default") and default.get_inventory_drops then
		return default.get_inventory_drops(pos, listname, drops)
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if not inv then return end
	for i = 1, inv:get_size(listname) do
		local stack = inv:get_stack(listname, i)
		if not stack:is_empty() then
			table.insert(drops, stack:take_item(stack:get_count()))
		end
	end
end

paleotest.mobkit_mobs = {}
paleotest.global_walkable = {}
paleotest.global_flora = {}
paleotest.global_leaves = {}
paleotest.global_plants = {}
paleotest.global_liquid = {}

minetest.register_on_mods_loaded(function()
	-- Entities
    for name in pairs(minetest.registered_entities) do
        local mob = minetest.registered_entities[name]
        if mob.get_staticdata == mobkit.statfunc
        and (mob.logic or mob.brainfunc) then
            table.insert(paleotest.mobkit_mobs, name)
        end
	end
	-- Nodes
	for name, def in pairs(minetest.registered_nodes) do
		if name ~= "air" and name ~= "ignore" then
			if def.walkable then
				table.insert(paleotest.global_walkable, name)
			end
			if def.groups and (def.groups.flora or def.groups.flower or def.groups.plant) then
				table.insert(paleotest.global_flora, name)
				table.insert(paleotest.global_plants, name)
			end
			if def.groups and (def.groups.leaves or def.groups.leafdecay) then
				table.insert(paleotest.global_leaves, name)
				table.insert(paleotest.global_plants, name)
			end
			if def.drawtype == "liquid" or (def.groups and def.groups.liquid) then
				table.insert(paleotest.global_liquid, name)
			end
		end
	end
end)

paleotest.global_meat = {}

local common_meat_names = {
	"beef",
	"chicken",
	"mutton",
	"porkchop",
	"meat"
}

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_items) do
		local added = false
		if def.groups and (def.groups.food_meat_raw or def.groups.food_meat) then
			table.insert(paleotest.global_meat, name)
			added = true
		else
			for _, i in ipairs(common_meat_names) do
				if (name:match(i) and (name:match("raw") or name:match("uncooked"))) then
					table.insert(paleotest.global_meat, name)
					added = true
					break
				end
			end
		end
	end
end)

paleotest.global_fish = {}

local common_fish_names = {
	"fish",
	"cod",
	"bass",
	"tuna",
	"salmon"
}

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_items) do
		if def.groups and (def.groups.food_fish_raw or def.groups.food_fish) then
			table.insert(paleotest.global_fish, name)
		else
			for _, i in ipairs(common_fish_names) do
				if name:find(i)
				and (name:find("raw")
				or name:find("uncooked")
				or name:find("cooked")) then
					table.insert(paleotest.global_fish, name)
					break
				end
			end
		end
	end
end)

function paleotest.remove_string(tbl, val)
    for i, v in ipairs(tbl) do
		if v == val then
			return table.remove(tbl, i)
        end
    end
end

function paleotest.find_string(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

local path = minetest.get_modpath("paleotest")

-- API
dofile(path.."/api/api.lua")
dofile(path.."/api/hq_lq.lua")
dofile(path.."/api/register.lua")
if minetest.settings:get_bool("legacy_convert") then
	dofile(path.."/legacy_convert.lua")
end

-- Items
dofile(path.."/nodes.lua")
dofile(path.."/craftitems.lua")
dofile(path.."/crafting.lua")
dofile(path.."/ores.lua")
dofile(path.."/fossil_analyzer.lua")
dofile(path.."/dna_cultivator.lua")
dofile(path.."/feeders.lua")


-- Dinosaurs

dofile(path.."/mobs/brachiosaurus.lua")
dofile(path.."/mobs/carnotaurus.lua")
dofile(path.."/mobs/stegosaurus.lua")
dofile(path.."/mobs/spinosaurus.lua")
dofile(path.."/mobs/triceratops.lua")
dofile(path.."/mobs/tyrannosaurus.lua")
dofile(path.."/mobs/velociraptor.lua")

-- Reptiles
dofile(path.."/mobs/pteranodon.lua")
dofile(path.."/mobs/quetzalcoatlus.lua")
dofile(path.."/mobs/sarcosuchus.lua")

-- Aquatic Mobs
dofile(path.."/mobs/dunkleosteus.lua")
dofile(path.."/mobs/mosasaurus.lua")
dofile(path.."/mobs/plesiosaurus.lua")

-- Mammals
dofile(path.."/mobs/dire_wolf.lua")
dofile(path.."/mobs/elasmotherium.lua")
dofile(path.."/mobs/mammoth.lua")
dofile(path.."/mobs/procoptodon.lua")
dofile(path.."/mobs/smilodon.lua")
dofile(path.."/mobs/thylacoleo.lua")

minetest.log("action", "[MOD] PaleoTest v2.0 Dev loaded")
