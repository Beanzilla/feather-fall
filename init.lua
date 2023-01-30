
local ff = {}
local current_y = 0
local current_gravity = 1
local gravity_reset_timer = -1
local use_gravity_calls = minetest.settings:get_bool("feather_fall.use_gravity_calls", true) -- a switch to disable change gravity calls
local falling_speed = math.max(math.abs(tonumber(minetest.settings:get("feather_fall.falling_speed")) or 6)*-1,1)
local holding_requirement = minetest.settings:get("feather_fall.holding_requirement") or "hotbar"
local hotbar_slots = tonumber(minetest.settings:get("feather_fall.hotbar_slots")) or 8

ff.VERSION = "1.0.2"

-- Attempt to detect what gamemode/game these folks are running on
function ff.game_mode()
    local reported = false -- Have we send a report
    local game_mode = "???" -- let's even return that
    if (minetest.get_modpath("default") or false) and not reported then
        reported = true
        game_mode = "MTG"
    end
    if (minetest.get_modpath("mcl_core") or false) and not reported then
        reported = true
        game_mode = "MCL"
    end
    return game_mode
end

function ff.set_speed(user)
	local last_y = current_y
    current_y = user:get_velocity()["y"] -- returns float
    -- If we aren't going negative floating isn't needed
    if current_y > 0 then return end
	if (current_y < 0 and use_gravity_calls == true) then gravity_reset_timer = 2 end
    if current_y < falling_speed then
        user:add_velocity({x=0, y=current_y*-0.2, z=0}) -- Reduce speed by X percent (it appears don't go past 0.50)
		if use_gravity_calls == true then user:set_physics_override({gravity=0}) end
		current_gravity = 0
    end
end

function ff.find_stack(inv, listname, find_stack)
	local max_size = inv:get_size(listname)
	local RETURN_ME = -1
	for i = 0, max_size do
		local stack = inv:get_stack(listname, i)
		i = i+1
		if stack:get_name() == find_stack then
			RETURN_ME = i-1
			i = max_size
		end
	end
	return RETURN_ME
end

minetest.register_globalstep(function (dtime)
	if gravity_reset_timer > -1 then gravity_reset_timer = gravity_reset_timer-1 end
    for _, player in ipairs(minetest.get_connected_players()) do
		local inv = player:get_inventory()
		if holding_requirement == "hotbar" then
			local seek_stack = ff.find_stack(inv, "main", "feather_fall:feather")
			if (seek_stack <= hotbar_slots and seek_stack ~= -1) then
				local location = inv:get_location()
				ff.set_speed(player)
			end
		elseif holding_requirement == "inventory" then
			if inv:contains_item("main", "feather_fall:feather") then
				local location = inv:get_location()
				ff.set_speed(player)
			end
		elseif holding_requirement == "hand" then
			local hand = player:get_wielded_item()
			if hand ~= nil then -- Only run if we obtained the player's hand
				-- Check if the player has this mod's feather in their hand
				if hand:get_name() == "feather_fall:feather" then
					ff.set_speed(player)
				end
			end
		end 
		if (gravity_reset_timer == 0 or (current_gravity == 0 and math.abs(current_y) < 0.8)) then
			player:set_physics_override({gravity=1})
			current_gravity = 1
		end
    end
end)

minetest.register_craftitem("feather_fall:feather", {
    short_description = "Falling Feather",
    description = "Falling Feather\n(Hold in hand to float down great heights)",
    inventory_image = "feather_fall_feather.png"
})

local craftable = minetest.settings:get_bool("feather_fall.craftable")

if craftable == nil then
    craftable = false
    minetest.settings:set_bool("feather_fall.craftable", false)
end

if craftable == true then
    local gm = ff.game_mode()
    local empty = ""
    local iron = ""
    local gold = ""
    local mese = ""
    if gm == "MTG" then
        iron = "default:steel_ingot"
        gold = "default:gold_ingot"
        mese = "default:mese_crystal"
    elseif gm == "MCL" then
        iron = "mcl_core:iron_ingot"
        gold = "mcl_core:gold_ingot"
        mese = "mesecons:redstone"
    end

    minetest.register_craft({
        output = "feather_fall:feather",
        recipe = {
            {mese, iron, mese},
            {gold, mese, iron},
            {mese, gold, mese}
        }
    })
end

minetest.log("action", "[feather_fall] Version: "..ff.VERSION)
minetest.log("action", "[feather_fall] Gamemode is "..ff.game_mode())
minetest.log("action", "[feather_fall] Ready")
