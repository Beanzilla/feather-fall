
local ff = {}

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
    local current_y = user:get_velocity()["y"]
    -- If we aren't going negative floating isn't needed
    if current_y >= 0 then return end
    -- Ok we are negative
    --minetest.chat_send_player(user:get_player_name(), "Y: "..tostring(current_y))
    current_y = math.abs(current_y) -- Flip it so we can use it sanely
    if current_y > 3 then -- Only activate if greater than -2
        user:add_velocity({x=0, y=current_y*0.20, z=0}) -- Reduce speed by X percent (it appears don't go past 0.50)
    end
end

minetest.register_globalstep(function (dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local hand = player:get_wielded_item()
        if hand ~= nil then -- Only run if we obtained the player's hand
            -- Check if the player has this mod's feather in their hand
            if hand:get_name() == "feather_fall:feather" then
                ff.set_speed(player)
            end
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
