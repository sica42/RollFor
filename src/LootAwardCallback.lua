RollFor = RollFor or {}
local m = RollFor

if m.LootAwardCallback then return end

local getn = m.getn
local RollType = m.Types.RollType

local M = m.Module.new( "LootAwardCallback" )

---@class LootAwardCallback
---@field on_loot_awarded fun( item_id: number, item_link: string, player_name: string, player_class: string?, is_trade: boolean? )

---@param awarded_loot AwardedLoot
---@param roll_controller RollController
---@param winner_tracker WinnerTracker
---@param group_roster GroupRoster
---@param softres GroupAwareSoftRes
---@param confirm_popup ConfirmPopup
---@param config Config
function M.new( awarded_loot, roll_controller, winner_tracker, group_roster, softres, confirm_popup, config )
  ---@param item_id number
  ---@param item_link string
  ---@param player_name string
  ---@param player_class PlayerClass?
  local function on_loot_awarded( item_id, item_link, player_name, player_class, is_trade )
    M.debug.add( string.format( "on_loot_awarded( %s, %s, %s, %s )", item_id, item_link, player_name, player_class or "nil" ) )
    local roll_tracker = roll_controller.get_roll_tracker( item_id )
    local _, current_iteration = roll_tracker.get()
    local roll_data = m.find( player_name, current_iteration.rolls, 'player_name' )
    local sr_players = softres.get( item_id )
    local sr_player = m.find( player_name, sr_players, 'name' )
    local rolling_strategy
    local class

    if roll_data then
      rolling_strategy = current_iteration.rolling_strategy
    else
      local winners = winner_tracker.find_winners( item_link )
      local winner = m.find( player_name, winners, 'winner_name' )
      rolling_strategy = winner and winner.rolling_strategy
    end

    if not player_class then
      local player = group_roster.find_player( player_name )
      class = player and player.class or nil
    end

      awarded_loot.award(
        player_name,
        item_id,
        roll_data,
        rolling_strategy,
        item_link,
        player_class or class,
        sr_player and sr_player.sr_plus,
        false
      )
  
    if is_trade then return end

    if player_class then
      roll_controller.loot_awarded( item_id, item_link, player_name, player_class )
    else
      roll_controller.loot_awarded( item_id, item_link, player_name, class )
    end

    winner_tracker.untrack( player_name, item_link )

    local function on_confirm_plus_one(plus_one)
      awarded_loot.update_item(getn(awarded_loot.get_winners()), { plus_one = plus_one })
    end

    if config.handle_plus_ones() and roll_data ~= nil and roll_data.roll_type == RollType.MainSpec then
      if config.plus_one_prompt() then
        local colorized_player_name = m.colorize_player_by_class(player_name, player_class or class) or m.colors.grey( player_name )
        confirm_popup.show( { "Should " .. colorized_player_name .. " get a +1 for " .. item_link .. "?" }, on_confirm_plus_one)
      else
        on_confirm_plus_one(true)
      end
    else
      on_confirm_plus_one(false)
    end
  end
  ---@type LootAwardCallback
  return {
    on_loot_awarded = on_loot_awarded,
  }
end

m.LootAwardCallback = M
return M


