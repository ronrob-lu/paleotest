--------------------
-- PaleoTest Ores --
--------------------
------ Ver 2.0 -----


--------------------
-- Ore Definition --
--------------------

-- Fossil Block --

local stone_wherein = {"default:stone", "mcl_core:stone", "mcl_deepslate:deepslate"}
local permafrost_wherein = {"default:permafrost_with_stones", "default:permafrost", "mcl_core:dirt", "mcl_core:coarse_dirt"}

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "paleotest:fossil_block",
	wherein        = stone_wherein,
	clust_scarcity = 64 * 64 * 64,
	clust_num_ores = 5,
	clust_size     = 3,
	y_max          = 64,
	y_min          = -32,
})

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "paleotest:fossil_block",
	wherein        = stone_wherein,
	clust_scarcity = 32 * 32 * 32,
	clust_num_ores = 4,
	clust_size     = 3,
	y_max          = -32,
	y_min          = -128,
})

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "paleotest:fossil_block",
	wherein        = stone_wherein,
	clust_scarcity = 16 * 16 * 16,
	clust_num_ores = 5,
	clust_size     = 3,
	y_max          = -128,
	y_min          = -31000,
})

-- Suspicious Permafrost --

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "paleotest:suspicious_permafrost",
	wherein        = permafrost_wherein,
	clust_scarcity = 32 * 32 * 32,
	clust_num_ores = 5,
	clust_size     = 3,
	y_max          = 256,
	y_min          = -256,
})
