RollFor = RollFor or {}
local m = RollFor

if m.OptionsPopup then return end

local info = m.pretty_print
local blue = m.colors.blue

---@class OptionsGuiElements
local e = m.OptionsGuiElements

---@class OptionsPopup
---@field show fun( area: string )
---@field hide fun()
---@field toggle fun()

local M = m.Module.new( "OptionsPopup" )

M.center_point = { point = "CENTER", relative_point = "CENTER", x = 0, y = 150 }

---@param popup_builder PopupBuilder
---@param awarded_loot AwardedLoot
---@param version_broadcast VersionBroadcast
---@param event_bus EventBus
---@param confirm_popup ConfirmPopup
---@param db table
---@param config_db table
---@param config Config
function M.new( popup_builder, awarded_loot, version_broadcast, event_bus, confirm_popup, db, config_db, config )
  ---@class Frame
  local popup
  local frames

  local function on_drag_stop()
    if not popup then return end

    if m.is_frame_out_of_bounds( popup ) then
      popup:position( db.point or M.center_point )
      return
    end

    local anchor = popup:get_anchor_point()
    db.point = { point = anchor.point, relative_point = anchor.relative_point, x = anchor.x, y = anchor.y }
  end

  local function create_popup()
    M.debug.add( "Create popup" )

    local function notify()
      if this:GetObjectType() == "CheckButton" then
        config.notify_subscribers( this:GetParent().config, this:GetChecked() )
      else
        config.notify_subscribers( this:GetParent().config )
      end
    end

    local frame = popup_builder
        :name( "RollForOptionsFrame" )
        :width( 400 )
        :height( 350 )
        :bg_file( "Interface/Buttons/WHITE8x8" )
        :sound()
        :movable()
        :on_drag_stop( on_drag_stop )
        :esc()
        :self_centered_anchor()
        :build()

    if not m.classic then
      frame:backdrop_color( 0, 0, 0, .85 )
      frame:border_color( .2, .2, .2, 1 )
    end

    local title_bar = m.GuiElements.titlebar( frame, blue( "RollFor" ) )
    title_bar.title:SetJustifyH( "LEFT" )

    local help_btn = m.GuiElements.tiny_button( frame, "?", "Click this icon and then hover over a field for more information.", "#E6CC40" )
    help_btn:SetPoint( "RIGHT", title_bar.close_btn, "LEFT", m.classic and -4 or -5, 0 )
    help_btn:SetScript( "OnClick", function()
      this.active = not this.active
      if m.classic then
        if this.active then
          this:LockHighlight()
        else
          this:UnlockHighlight()
        end
      end
      this:GetParent().show_help = this.active
    end )

    frames = {}
    frames.tab_area = m.api.CreateFrame( "Frame", "area", frame )
    frames.tab_area:SetPoint( "TOPLEFT", title_bar, "BOTTOMLEFT", 7, m.classic and 4 or 0 )
    frames.tab_area:SetPoint( "BOTTOMRIGHT", -7, m.classic and 9 or 7 )
    frames.tab_area.config_db = config_db
    e.create_backdrop( frames.tab_area )

    e.create_gui_entry( "About", frames, function()
      this.title = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.title:SetFont( "FONTS\\FRIZQT__.TTF", 18 )
      this.title:SetPoint( "TOPLEFT", 0, -50 )
      this.title:SetPoint( "RIGHT", this.parent, "RIGHT", 0, 0 )
      this.title:SetJustifyH( "CENTER" )
      this.title:SetText( blue( "RollFor" ) )

      this.versionc = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.versionc:SetPoint( "TOPLEFT", 140, -80 )
      this.versionc:SetWidth( 100 )
      this.versionc:SetJustifyH( "LEFT" )
      this.versionc:SetText( "Version:" )

      this.version = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.version:SetPoint( "TOPRIGHT", 240, -80 )
      this.version:SetWidth( 100 )
      this.version:SetJustifyH( "RIGHT" )
      this.version:SetText( m.get_addon_version().str )

      local new_version = version_broadcast.new_version_available()
      if new_version and m.is_new_version( m.get_addon_version().str, new_version ) then
        this.newversion = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
        this.newversion:SetPoint( "TOPLEFT", 0, -100 )
        this.newversion:SetPoint( "RIGHT", this.parent, "RIGHT", 0, 0 )
        this.newversion:SetJustifyH( "CENTER" )
        this.newversion:SetText( string.format( "New version (%s) is available!", m.colors.highlight( string.format( "v%s", new_version ) ) ) )
      end

      this.info = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.info:SetPoint( "TOPLEFT", 0, new_version and -140 or -120 )
      this.info:SetPoint( "RIGHT", this.parent, "RIGHT", 0, 0 )
      this.info:SetJustifyH( "CENTER" )
      this.info:SetText( "Check the minimap icon for new commands.\n\nBe a responsible Master Looter.\n\nHappy rolling! o7" )
    end )

    e.create_gui_entry( "General", frames, function()
      e.create_config( "General settings", nil, "header" )
      e.create_config( "Classic look", "classic_look", "checkbox", "Toggle classic look. Requires /reload", function()
        event_bus.notify( "config_change_requires_ui_reload", { key = "classic_look" } )
      end )
      e.create_config( "Master loot warning", "show_ml_warning", "checkbox", "Show a warning if no master looter is set when targeting a boss.", notify )
      e.create_config( "Auto raid-roll", "auto_raid_roll", "checkbox", "Automatically do a raid-roll if noone rolls for an item", notify )
      e.create_config( "Auto group loot", "auto_group_loot", "checkbox", "Automatically sets loot mode back to group loot after boss is looted", notify )
      e.create_config( "Auto master loot", "auto_master_loot", "checkbox", "Automatically sets loot mode to master looter when a boss is targeted", notify )

      e.create_config( "Minimap", "", "header" )
      e.create_config( "Hide minimap icon", "minimap_button_hidden", "checkbox", nil, notify )
      e.create_config( "Lock minimap icon", "minimap_button_locked", "checkbox", nil, notify )

      e.create_config( "Awards data", nil, "header" )
      e.create_config( "Always keep awards data", "keep_award_data", "checkbox", "Prevents the addon from clearing award data on disconnects" )
      e.create_config( "Reset awards data", nil, "button", "Clears all the award data", function()
        if confirm_popup.is_visible() then
          confirm_popup.hide()
          return
        end

        confirm_popup.show( { "This will clear the current winners data.", "Are you sure?" }, function( value )
          if value then
            awarded_loot.clear( true )
          end
        end )
      end )
    end )

    e.create_gui_entry( "Looting", frames, function()
      e.create_config( "Loot settings", nil, "header" )
      e.create_config( "Master loot frame rows", "master_loot_frame_rows", "number|min=5|max=20", "Value must be between 5 and 20 rows", notify )
      e.create_config( "Auto-loot", "auto_loot", "checkbox", "Auto-loot items below loot thresold. BoP items will not be auto looted." )
      e.create_config( "Auto-loot coins with SuperWow", "superwow_auto_loot_coins", "checkbox", "Automatically loot coins (requires SuperWow mod)" )
      e.create_config( "Auto-loot messages", "auto_loot_messages", "checkbox", "Display auto-looted items in your private chat." )
      e.create_config( "Announce auto-looted items", "auto_loot_announce", "checkbox", "Announce auto-looted items above loot quality threshold to party/raid." )
      e.create_config( "Display loot frame at cursor", "loot_frame_cursor", "checkbox", "Display loot fram at cursor when looting.", function()
        config.notify_subscribers( 'reset_loot_frame' )
      end )
      e.create_config( "Reset loot frame position", nil, "button", nil, function()
        info( "Loot frame position has been reset." )
        config.notify_subscribers( "reset_loot_frame" )
      end )
    end )

    e.create_gui_entry( "Rolling", frames, function()
      e.create_config( "Roll settings", nil, "header" )
      e.create_config( "Default rolling time", "default_rolling_time_seconds", "number|min=4|max=15", "Value must be between 4 and 15 seconds." )
      e.create_config( "Rolling popup lock", "rolling_popup_lock", "checkbox", "Locks the rolling popup position.", notify )
      e.create_config( "Show Raid roll again button", "raid_roll_again", "checkbox", nil, notify )
      e.create_config( "MainSpec rolling threshold", "ms_roll_threshold", "number" )
      e.create_config( "OffSpec rolling threshold", "os_roll_threshold", "number" )
      e.create_config( "Enable transmog rolling", "tmog_rolling_enabled", "checkbox" )
      e.create_config( "Transmog rolling threshold", "tmog_roll_threshold", "number" )
      e.create_config( "Disable transmog roll on trash loot", "auto_tmog", "checkbox", "Automatically disable tmog roll on trash loot." )
      e.create_config( "Announce class restriction on items", "auto_class_announce", "checkbox", "Roll message will display classes that can roll on items with class restrictions." )
      e.create_config( "Reset rolling popup position", "", "button", nil, function()
        info( "Rolling popup position has been reset." )
        config.notify_subscribers( "reset_rolling_popup" )
      end )
    end )

    return frame
  end

  local function refresh()
    M.debug.add( "refresh" )
    for id, frame in pairs( frames ) do
      if type( frame ) == "table" and frame.area then
        frame.area:Hide()
        if frame.area.scroll.content.setup then
          for _, child in ipairs( { frame.area.scroll.content:GetChildren() } ) do
            if child.config and child.input then
              if child.input:GetFrameType() == "CheckButton" then
                child.input:SetChecked( config_db[ child.config ] )
              elseif child.input:GetFrameType() == "EditBox" then
                child.input:SetText( config_db[ child.config ] )
              end
            end
          end
        end
      end
    end
  end

  local function show( area )
    M.debug.add( "show" )
    if not popup then
      popup = create_popup()
    else
      refresh()
    end

    popup:Show()
    if not area or area == "" then area = "About" end
    frames[ area ].area:Show()
  end

  local function hide()
    M.debug.add( "hide" )

    if popup then
      popup:Hide()
    end
  end

  local function toggle()
    M.debug.add( "toggle" )
    if popup and popup:IsVisible() then
      hide()
    else
      show()
    end
  end

  ---@type OptionsPopup
  return {
    show = show,
    hide = hide,
    toggle = toggle
  }
end

m.OptionsPopup = M
return M
