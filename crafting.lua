-----------------------
-- Crafting Recipes --
-----------------------
------- Ver 2.0 -------

local glass = "group:glass"
local stick = "group:stick"
local wood = "group:wood"
local tree = "group:tree"
local string_item = "group:string"

local empty_bucket = minetest.registered_items["bucket:bucket_empty"] and "bucket:bucket_empty" or (minetest.registered_items["mcl_buckets:bucket_empty"] and "mcl_buckets:bucket_empty" or "group:food_vessel")
local water_bucket = minetest.registered_items["bucket:bucket_water"] and "bucket:bucket_water" or (minetest.registered_items["mcl_buckets:bucket_water"] and "mcl_buckets:bucket_water" or "group:water_bucket")
local steel_block = minetest.registered_items["default:steelblock"] and "default:steelblock" or (minetest.registered_items["mcl_core:iron_block"] and "mcl_core:iron_block" or "group:steelblock")
local steel_ingot = minetest.registered_items["default:steel_ingot"] and "default:steel_ingot" or (minetest.registered_items["mcl_core:iron_ingot"] and "mcl_core:iron_ingot" or "group:ingot_iron")
local copper_ingot = minetest.registered_items["default:copper_ingot"] and "default:copper_ingot" or (minetest.registered_items["mcl_copper:copper_ingot"] and "mcl_copper:copper_ingot" or steel_ingot)
local bronze_ingot = minetest.registered_items["default:bronze_ingot"] and "default:bronze_ingot" or (minetest.registered_items["mcl_core:gold_ingot"] and "mcl_core:gold_ingot" or steel_ingot)
local book_item = minetest.registered_items["default:book"] and "default:book" or (minetest.registered_items["mcl_books:book"] and "mcl_books:book" or "group:book")
local wool_white = minetest.registered_items["wool:white"] and "wool:white" or (minetest.registered_items["mcl_wool:white"] and "mcl_wool:white" or "group:color_white")
local wool_pink = minetest.registered_items["wool:pink"] and "wool:pink" or (minetest.registered_items["mcl_wool:pink"] and "mcl_wool:pink" or "group:color_pink")
local cotton_item = minetest.registered_items["farming:cotton"] and "farming:cotton" or string_item

minetest.register_craft({
	output = "paleotest:feeder_carnivore",
	recipe = {
		{"group:color_red", glass, "group:color_red"},
		{"", empty_bucket, ""},
		{"", steel_block, ""},
	}
})

minetest.register_craft({
	output = "paleotest:feeder_piscivore",
	recipe = {
		{"group:color_blue", glass, "group:color_blue"},
		{"", empty_bucket, ""},
		{"", steel_block, ""},
	}
})

minetest.register_craft({
	output = "paleotest:feeder_herbivore",
	recipe = {
		{"group:color_green", glass, "group:color_green"},
		{"", empty_bucket, ""},
		{"", steel_block, ""},
	}
})

minetest.register_craft({
	output = "paleotest:field_guide",
	recipe = {
		{"", "", ""},
		{"group:fossil", "", ""},
		{book_item, "group:color_blue", ""},
	}
})

minetest.register_craft({
	output = "paleotest:whip",
	recipe = {
		{"", "", cotton_item},
		{"", stick, cotton_item},
		{stick, "", cotton_item},
	}
})

minetest.register_craft({
	output = "paleotest:pursuit_ball",
	recipe = {
		{string_item, wool_pink, string_item},
		{wool_pink, cotton_item, wool_pink},
		{string_item, wool_pink, string_item},
	}
})

minetest.register_craft({
	output = "paleotest:scratching_post",
	recipe = {
		{wool_white, wood, wool_white},
		{wool_white, wood, wool_white},
		{tree, tree, tree},
	}
})

minetest.register_craft({
    output = "paleotest:dna_cultivator",
    recipe = {
        {steel_ingot, steel_ingot, steel_ingot},
        {glass, water_bucket, glass},
        {steel_ingot, bronze_ingot, steel_ingot}
    }
})

minetest.register_craft({
    output = "paleotest:fossil_analyzer",
    recipe = {
        {steel_ingot, steel_ingot, steel_ingot},
        {steel_ingot, copper_ingot, steel_ingot},
        {bronze_ingot, bronze_ingot, bronze_ingot}
    }
})

minetest.register_craft({
	type = "cooking",
	output = "paleotest:dinosaur_meat_cooked",
	recipe = "paleotest:dinosaur_meat_raw",
	cooktime = 5
})

minetest.register_craft({
	type = "cooking",
	output = "paleotest:mammal_meat_cooked",
	recipe = "paleotest:mammal_meat_raw",
	cooktime = 5
})

minetest.register_craft({
	type = "cooking",
	output = "paleotest:reptile_meat_cooked",
	recipe = "paleotest:reptile_meat_raw",
	cooktime = 5
})

minetest.register_craft({
	type = "cooking",
	output = "paleotest:fish_meat_cooked",
	recipe = "paleotest:fish_meat_raw",
	cooktime = 5
})
