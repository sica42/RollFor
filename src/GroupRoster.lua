RollFor = RollFor or {}
local m = RollFor

if m.GroupRoster then return end

local M = {}

---@type MakePlayerFn
local make_player = m.Types.make_player

---@class GroupRosterApi
---@field IsInParty fun(): number?
---@field IsInRaid fun(): number?
---@field IsInGroup fun(): number?
---@field UnitName fun( unit: string ): string?
---@field UnitClass fun( unit: string ): string?
---@field UnitIsConnected fun( unit: string ): number?
---@field GetRaidRosterInfo fun( index: number ): string?, string, number, number, PlayerClass, string, string

---@class GroupRoster
---@field get_all_players_in_my_group fun( f: (fun( player: Player ): boolean)? ): Player[]
---@field is_player_in_my_group fun( player_name: string ): boolean
---@field am_i_in_group fun(): boolean
---@field am_i_in_party fun(): boolean
---@field am_i_in_raid fun(): boolean
---@field find_player fun( player_name: string ): Player?

---@param api GroupRosterApi
---@param player_info PlayerInfo
function M.new( api, player_info )
  -- PERF (local change): the roster used to be rebuilt (40 tables + a sort) on every
  -- call, and find_player / is_player_in_my_group are called once per soft-res entry
  -- and once per roll. The list is now built once and reused until a group event
  -- invalidates it (see EventHandler), with a max age as a safety net.
  local CACHE_MAX_AGE = 10 -- seconds
  local m_cache ---@type Player[]|nil
  local m_by_name ---@type table<string, Player>|nil
  local m_cache_time = 0
  local m_names_buffer = {}
  local m_names_buffer_size = 0

  local function sort( candidates )
    table.sort( candidates, function( lhs, rhs )
      if lhs.class < rhs.class then
        return true
      elseif lhs.class > rhs.class then
        return false
      end

      return lhs.name < rhs.name
    end )
  end

  local function build_group_players()
    local result = {}

    if api.IsInRaid() then
      for i = 1, 40 do
        local name, _, _, _, class, _, location = api.GetRaidRosterInfo( i )

        if name then
          table.insert( result, { name = name, class = class, online = location ~= "Offline" and true or false } )
        end
      end

      sort( result )
      return result
    end

    local party = { "player", "party1", "party2", "party3", "party4" }

    for _, v in ipairs( party ) do
      local name = api.UnitName( v )
      local class = api.UnitClass( v )
      local online = api.UnitIsConnected( v ) and true or false
      local player = name and class and make_player( name, class, online )
      if player then table.insert( result, player ) end
    end

    sort( result )
    return result
  end

  local function solo_player()
    return { name = player_info.get_name(), class = api.UnitClass( "player" ) }
  end

  -- Returns the cached group (and name index), or nil when not in a group.
  local function get_group()
    if not api.IsInGroup() then return nil end

    local now = m.lua.time()

    if not m_cache or now - m_cache_time >= CACHE_MAX_AGE then
      m_cache = build_group_players()
      m_by_name = {}

      for _, player in ipairs( m_cache ) do
        m_by_name[ string.lower( player.name ) ] = player
      end

      m_cache_time = now
    end

    return m_cache
  end

  local function invalidate()
    m_cache = nil
    m_by_name = nil
  end

  local function get_all_players_in_my_group( f )
    local group = get_group()
    local result = {}

    if not group then
      table.insert( result, solo_player() )
      return result
    end

    for _, player in ipairs( group ) do
      if not f or f( player ) then table.insert( result, player ) end
    end

    return result
  end

  local function find_player( player_name )
    if not player_name then return nil end

    if not get_group() then
      local player = solo_player()
      if player.name and string.lower( player.name ) == string.lower( player_name ) then return player end
      return nil
    end

    return m_by_name[ string.lower( player_name ) ]
  end

  local function is_player_in_my_group( player_name )
    return find_player( player_name ) ~= nil
  end

  local function am_i_in_group()
    return api.IsInGroup()
  end

  local function am_i_in_party()
    return api.IsInGroup() and not api.IsInRaid()
  end

  local function am_i_in_raid()
    return api.IsInGroup() and api.IsInRaid()
  end

  -- Order-independent signature of the names in the group. Reuses one buffer, so
  -- it can be called for every PARTY_MEMBERS_CHANGED without building the roster.
  local function get_names_signature()
    if not api.IsInGroup() then return player_info.get_name() or "" end

    local n = 0

    if api.IsInRaid() then
      for i = 1, 40 do
        local name = api.GetRaidRosterInfo( i )

        if name then
          n = n + 1
          m_names_buffer[ n ] = name
        end
      end
    else
      for _, v in ipairs( { "player", "party1", "party2", "party3", "party4" } ) do
        local name = api.UnitName( v )

        if name then
          n = n + 1
          m_names_buffer[ n ] = name
        end
      end
    end

    for i = n + 1, m_names_buffer_size do
      m_names_buffer[ i ] = nil
    end

    m_names_buffer_size = n
    table.sort( m_names_buffer )

    return table.concat( m_names_buffer, "," )
  end

  ---@type GroupRoster
  return {
    get_all_players_in_my_group = get_all_players_in_my_group,
    is_player_in_my_group = is_player_in_my_group,
    am_i_in_group = am_i_in_group,
    am_i_in_party = am_i_in_party,
    am_i_in_raid = am_i_in_raid,
    find_player = find_player,
    invalidate = invalidate,
    get_names_signature = get_names_signature
  }
end

m.GroupRoster = M
return M
