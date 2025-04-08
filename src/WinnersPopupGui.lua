RollFor = RollFor or {}
local m = RollFor

local getn = m.getn

if m.WinnersPopupGui then return end

---@class WinnersPopupGui
---@field headers fun( parent: Frame, on_click: function ): Frame
---@field winner fun( parent: Frame): Frame
---@field create_dropdown fun( parent: Frame, award_filters: table, populate: function ): Frame
---@field create_checkbox_entry fun( parent: Frame, text: string, setting: string, on_change: function ): Frame
---@field create_scroll_frame fun( parent: Frame, name: string ): Frame

local M = {}

function M.headers( parent, on_click )
  local frame = m.api.CreateFrame( "Frame", nil, parent )
  frame:SetWidth( 250 )
  frame:SetHeight( 14 )
  frame:SetFrameStrata( "DIALOG" )
  frame:SetFrameLevel( parent:GetFrameLevel() + 1 )
  frame:EnableMouse( true )

  ---@diagnostic disable-next-line: undefined-global
  local font_file = pfUI and pfUI.version and pfUI.font_default or "FONTS\\ARIALN.TTF"
  local font_size = 11

  local headers = {
    { text = "Player", name = "player_name",  width = 74 },
    { text = "Item",   name = "item_id",      width = 150 },
    { text = "Roll",   name = "winning_roll", width = 25 },
    { text = "Type",   name = "roll_type",    width = 25 }
  }

  for _, v in pairs( headers ) do
    local header = m.GuiElements.create_text_in_container( "Button", frame, v.width, nil, v.text )
    header.inner:SetFont( font_file, font_size )
    header.sort = v.name
    header:SetHeight( 14 )
    header.inner:SetPoint( v.name == "winning_roll" and "RIGHT" or "LEFT", v.name == "winning_roll" and -5 or 2, 0 )
    header:SetBackdrop( {
      bgFile = "Interface/Buttons/WHITE8x8",
      tile = true,
      tileSize = 22,
    } )
    header:SetBackdropColor( 0.125, 0.624, 0.976, 0.4 )
    header:SetScript( "OnClick", function()
      on_click( header )
    end )
    frame[ v.name .. "_header" ] = header
  end

  frame.player_name_header:SetPoint( "LEFT", 0, 0 )
  frame.roll_type_header:SetPoint( "RIGHT", 0, 0 )
  frame.winning_roll_header:SetPoint( "RIGHT", frame.roll_type_header, "LEFT", -1, 0 )
  frame.item_id_header:SetPoint( "LEFT", frame.player_name_header, "RIGHT", 1, 0 )
  frame.item_id_header:SetPoint( "RIGHT", frame.winning_roll_header, "LEFT", -1, 0 )

  return frame
end

function M.roll_type_dropdown()
  if not M.roll_type_dropdown_frame then
    M.roll_type_dropdown_frame = m.api.CreateFrame( "Frame", "RollForRollTypeDropdown" )
    M.roll_type_dropdown_frame.displayMode = "MENU"
  end

  if M.roll_type_dropdown_frame.initialize ~= M.roll_type_dropdown_menu then
    m.api.CloseDropDownMenus()
    M.roll_type_dropdown_frame.initialize = M.roll_type_dropdown_menu
  end

  M.roll_type_dropdown_frame.value = this.inner.value
  M.roll_type_dropdown_frame.on_update_item = this.inner.on_update_item

  local row = this:GetParent()
  m.api.ToggleDropDownMenu( 1, nil, M.roll_type_dropdown_frame, row:GetName(), row:GetWidth() - 57, 0 )
end

function M.roll_type_dropdown_menu()
  local info = {}

  for roll_type in pairs( m.Types.RollType ) do
    info.text = m.roll_type_color( roll_type, m.roll_type_abbrev( roll_type ) )
    info.checked = M.roll_type_dropdown_frame.value == roll_type
    info.arg1 = roll_type
    info.func = function( rt )
      if M.roll_type_dropdown_frame.on_update_item then
        M.roll_type_dropdown_frame.on_update_item( rt )
      end
    end
    m.api.UIDropDownMenu_AddButton( info, 1 )
  end
end

function M.winner( parent )
  M.winner_rows = M.winner_rows and M.winner_rows + 1 or 1
  local frame = m.api.CreateFrame( "Button", "RollForWinnerRow" .. M.winner_rows, parent )
  frame:SetHeight( 14 )
  frame:SetPoint( "LEFT", parent, "LEFT", 0, 0 )
  frame:SetPoint( "RIGHT", parent, "RIGHT", 0, 0 )
  frame:SetFrameStrata( "DIALOG" )
  frame:SetFrameLevel( parent:GetFrameLevel() + 1 )
  frame:SetBackdrop( {
    bgFile = "Interface/Buttons/WHITE8x8",
    tile = true,
    tileSize = 22,
  } )

  local function blue_hover( a )
    frame:SetBackdropColor( 0.125, 0.624, 0.976, a )
  end

  blue_hover( 0 )
  frame:SetScript( "OnEnter", function() blue_hover( .2 ) end )
  frame:SetScript( "OnLeave", function() blue_hover( 0 ) end )

  ---@diagnostic disable-next-line: undefined-global
  local font_file = pfUI and pfUI.version and pfUI.font_default or "FONTS\\ARIALN.TTF"
  local font_size = 11

  local player_name = m.GuiElements.create_text_in_container( "Frame", frame, 74, "LEFT", "dummy" )
  player_name.inner:SetFont( font_file, font_size )
  player_name.inner:SetJustifyH( "LEFT" )
  player_name:SetPoint( "LEFT", frame, "LEFT", 2, 0 )
  player_name:SetHeight( 14 )
  frame.player_name = player_name.inner

  local roll_type = m.GuiElements.create_text_in_container( "Frame", frame, 25, nil, "dummy" )
  roll_type.inner:SetFont( font_file, font_size )
  roll_type.inner:SetJustifyH( "LEFT" )
  roll_type.inner:SetPoint( "LEFT", 5, 0 )
  roll_type:SetPoint( "RIGHT", 0, 0 )
  roll_type:SetHeight( 14 )
  roll_type:EnableMouse()
  roll_type:SetScript( "onMouseUp", function()
    if arg1 == "RightButton" then
      M.roll_type_dropdown()
    end
  end )
  frame.roll_type = roll_type.inner

  local winning_roll = m.GuiElements.create_text_in_container( "Frame", frame, 25, nil, "dummy" )
  winning_roll.inner:SetFont( font_file, font_size )
  winning_roll.inner:SetJustifyH( "RIGHT" )
  winning_roll.inner:SetPoint( "RIGHT", -5, 0 )
  winning_roll:SetPoint( "RIGHT", roll_type, "LEFT", -1, 0 )
  winning_roll:SetHeight( 14 )
  frame.winning_roll = winning_roll.inner

  local item_link = m.GuiElements.create_text_in_container( "Button", frame, 1, "LEFT", "dummy" )
  item_link.inner:SetFont( font_file, font_size )
  item_link.inner:SetJustifyH( "LEFT" )
  item_link.inner:SetPoint( "LEFT", 0, 0 )
  item_link.inner:SetPoint( "RIGHT", 0, 0 )
  item_link.inner:SetHeight( 14 )
  item_link:SetPoint( "LEFT", player_name, "RIGHT", 1, 0 )
  item_link:SetPoint( "RIGHT", winning_roll, "LEFT", -1, 0 )
  item_link:SetHeight( 14 )
  frame.item_link = item_link

  frame.SetItem = function( _, item_link_text )
    item_link.inner:SetText( item_link_text )

    local tooltip_link = m.ItemUtils.get_tooltip_link( item_link_text )

    item_link:SetScript( "OnEnter", function()
      blue_hover( 0.2 )
    end )

    item_link:SetScript( "OnLeave", function()
      blue_hover( 0 )
    end )

    item_link:SetScript( "OnClick", function()
      if not tooltip_link then return end

      if m.is_ctrl_key_down() then
        m.api.DressUpItemLink( item_link_text )
      elseif m.is_shift_key_down() then
        m.link_item_in_chat( item_link_text )
      else
        m.api.SetItemRef( tooltip_link, tooltip_link, "LeftButton" )
      end
    end )
  end

  return frame
end

function M.create_dropdown( parent, award_filters, populate )
  if not parent:GetParent().dropdowns then parent:GetParent().dropdowns = {} end

  local dropdown = m.api.CreateFrame( "Frame", nil, parent )
  dropdown:SetFrameStrata( "TOOLTIP" )
  dropdown:SetPoint( "TOPLEFT", parent, "BOTTOMLEFT", 0, 0 )
  dropdown:SetBackdrop( {
    bgFile = "Interface/Buttons/WHITE8x8",
    edgeFile = "Interface/Buttons/WHITE8x8",
    tile = false,
    tileSize = 0,
    edgeSize = 0.5,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  } )
  dropdown:SetBackdropColor( 0, 0, 0, 1 )
  dropdown:SetBackdropBorderColor( .2, .2, .2, 1 )
  dropdown:EnableMouse( true )
  dropdown:Hide()
  table.insert( parent:GetParent().dropdowns, dropdown )

  dropdown:SetScript( "OnLeave", function()
    if m.api.MouseIsOver( dropdown ) then
      return
    end
    dropdown:Hide()
  end )

  parent:SetScript( "OnMouseDown", function()
    if arg1 == "RightButton" then
      local visible = dropdown:IsVisible()
      for v in ipairs( parent:GetParent().dropdowns ) do
        parent:GetParent().dropdowns[ v ]:Hide()
      end
      if not visible then dropdown:Show() end
    end
  end )

  if populate then
    dropdown:SetScript( "OnShow", function()
      local self = dropdown
      if not self.setup then
        self.setup = true
        populate( self )
      end
      for _, v in ipairs( self.checkboxes ) do
        if v.filter and v.setting then
          v.checkbox:SetChecked( award_filters[ v.filter ][ v.setting ] )
        end
      end
    end )
  end

  return dropdown
end

function M.create_checkbox_entry( parent, text, setting, on_change )
  if not parent.checkboxes then parent.checkboxes = {} end
  local p = string.find( setting, ".", 1, true ) or 0
  local cb_filter = string.sub( setting, 1, p - 1 )
  local cb_setting = string.sub( setting, p + 1 )

  local cb = m.GuiElements.checkbox( parent, text, function( value )
    if on_change then on_change( cb_filter, cb_setting, value ) end
  end )

  cb:SetPoint( "TOP", 0, -((getn( parent.checkboxes )) * 17) - 7 )
  cb.filter = cb_filter
  cb.setting = cb_setting

  if cb:GetWidth() > parent:GetWidth() - 15 then
    parent:SetWidth( cb:GetWidth() + 15 )
  end

  table.insert( parent.checkboxes, cb )
  parent:SetHeight( getn( parent.checkboxes ) * 17 + 11 )

  return cb
end

function M.create_scroll_frame( parent, name )
  local f = m.api.CreateFrame( "ScrollFrame", name, parent, "FauxScrollFrameTemplate" )

  if m.classic then
    local scroll_bar = _G[ name .. "ScrollBar" ]
    scroll_bar:SetPoint( "TOPLEFT", name, "TOPRIGHT", 1, -16 )
  else
    local scroll_bar = _G[ name .. "ScrollBar" ]
    scroll_bar:SetWidth( 12 )
    scroll_bar:SetBackdrop( {
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      tile = false,
      tileSize = 0,
      edgeSize = 0.5,
      insets = { left = 0, right = 0, top = 0, bottom = 0 }
    } )
    scroll_bar:SetBackdropColor( 0, 0, 0, 0.8 )
    scroll_bar:SetBackdropBorderColor( .2, .2, .2, 1 )
    scroll_bar:SetPoint( "TOPLEFT", name, "TOPRIGHT", 3, -13.5 )
    scroll_bar:SetPoint( "BOTTOMLEFT", name, "BOTTOMRIGHT", 6, 14)

    local thumb = _G[ name .. "ScrollBarThumbTexture" ]
    thumb:SetTexture( "Interface\\Buttons\\WHITE8X8" )
    thumb:SetVertexColor( .8, .8, .8, .8 )
    thumb:SetWidth( 12 )
    thumb:SetHeight( 10 )

    for i, button in { _G[ name .. "ScrollBarScrollUpButton" ], _G[ name .. "ScrollBarScrollDownButton" ] } do

      for _, tex in { "Normal", "Highlight", "Pushed", "Disabled" } do
        local texture = button[ "Get" .. tex .. "Texture" ]( button )
        texture:SetTexture( "Interface\\AddOns\\RollFor\\assets\\arrow-" .. (i == 1 and "up" or "down") .. ".tga" )
        texture:SetTexCoord( 0, 1, 0, 1 )
        texture:SetVertexColor( .8, .8, .8, .8 )
        texture:SetAlpha( .8 )
        texture:SetPoint( "TOPLEFT", 2, -1 )
        texture:SetPoint( "BOTTOMRIGHT", -2, 1 )
      end

      button:SetWidth( 12 )
      button:SetHeight( 12 )
      button:SetBackdrop( {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 0.5,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
      } )
      button:SetBackdropColor( 0, 0, 0, 1 )
      button:SetBackdropBorderColor( .2, .2, .2, 1 )
      button:GetDisabledTexture():SetAlpha( 0.4 )

      if i == 1 then
        button:SetPoint("BOTTOM", scroll_bar, "TOP", 0, 2 )
      else
        button:SetPoint("TOP", scroll_bar, "BOTTOM", 0, -2 )
      end

      button:SetScript( "OnEnter", function()
        this:SetBackdropBorderColor( .125, .624, .976, .5 )
      end )
      button:SetScript( "OnLeave", function()
        this:SetBackdropBorderColor( .2, .2, .2, 1 )
      end )
    end
  end

  return f
end

m.WinnersPopupGui = M
return M
