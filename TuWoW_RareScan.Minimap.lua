--[[****************************************************************************
  * _NPCScan by Saiket - Adapted for TuWoW (ForeverUI)                         *
  * _NPCScan.Minimap.lua - Minimap button compatible with ForeverUI & Classic. *
  ****************************************************************************]]

local _NPCScan = select( 2, ... );
local L = _NPCScan.L;

local me = CreateFrame( "Button", "TuWoW_RareScanMinimapButton", Minimap );
_G[ "_NPCScanMinimapButton" ] = me;
_NPCScan.MinimapButton = me;

me:SetSize( 31, 31 );
me:SetFrameStrata( "MEDIUM" );
me:SetFrameLevel( 9 );
me:RegisterForClicks( "anyUp" );
me:RegisterForDrag( "LeftButton" );
me:SetHighlightTexture( [[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]] );

-- Background texture
local Background = me:CreateTexture( nil, "BACKGROUND" );
Background:SetSize( 20, 20 );
Background:SetTexture( [[Interface\Minimap\UI-Minimap-Background]] );
Background:SetPoint( "TOPLEFT", 6, -5 );
me.Background = Background;

-- Icon texture (ForeverGM gold emblem)
local Icon = me:CreateTexture( nil, "ARTWORK" );
Icon:SetSize( 30, 30 );
Icon:SetTexture( [[Interface\AddOns\TuWoW_RareScan\Assets\ForeverGM-Minimap-v2]] );
Icon:SetTexCoord( 0, 1, 0, 1 );
Icon:SetPoint( "CENTER", 0, 0 );
me.Icon = Icon;

-- Circular border
local Border = me:CreateTexture( nil, "OVERLAY" );
Border:SetSize( 52, 52 );
Border:SetTexture( [[Interface\Minimap\MiniMap-TrackingBorder]] );
Border:SetPoint( "TOPLEFT", -2, 2 );
me.Border = Border;

--- Positions the button around the perimeter of the minimap.
-- Compensates for ForeverUI's 1.414x scale and custom circular mask.
function me:UpdatePosition ( Position )
	if ( _NPCScan.Options and _NPCScan.Options.MinimapHide ) then
		self:Hide();
		return;
	else
		self:Show();
	end

	local Angle = math.rad( Position or ( _NPCScan.Options and _NPCScan.Options.MinimapPos ) or 215 );
	local MapScale = ( ForeverUI and ForeverUI.Minimap and Minimap and Minimap:GetScale() ) or 1;
	
	if ( MapScale ~= 1 ) then
		self:SetScale( 1 / MapScale );
	else
		self:SetScale( 1 );
	end
	
	local RadiusOffset = ( MapScale ~= 1 ) and 1 or 2;
	local Width = ( Minimap:GetWidth() * MapScale / 2 ) + RadiusOffset;
	local Height = ( Minimap:GetHeight() * MapScale / 2 ) + RadiusOffset;
	local X = math.cos( Angle ) * Width;
	local Y = math.sin( Angle ) * Height;
	
	self:ClearAllPoints();
	self:SetPoint( "CENTER", Minimap, "CENTER", X, Y );
end

-- Drag handling
me:SetScript( "OnDragStart", function ( self )
	self.IsDragging = true;
	self:SetScript( "OnUpdate", function ()
		local CenterX, CenterY = Minimap:GetCenter();
		local CursorX, CursorY = GetCursorPosition();
		local Scale = Minimap:GetEffectiveScale();
		CursorX, CursorY = CursorX / Scale, CursorY / Scale;
		
		local Pos = math.deg( math.atan2( CursorY - CenterY, CursorX - CenterX ) ) % 360;
		if ( _NPCScan.Options ) then
			_NPCScan.Options.MinimapPos = Pos;
		end
		self:UpdatePosition( Pos );
	end );
end );

me:SetScript( "OnDragStop", function ( self )
	self.IsDragging = false;
	self:SetScript( "OnUpdate", nil );
end );

-- Tooltip display
me:SetScript( "OnEnter", function ( self )
	GameTooltip:SetOwner( self, "ANCHOR_LEFT" );
	GameTooltip:ClearLines();
	local title = (L and L.CONFIG_TITLE) or "|cff00ccffTuWoW|r |cffffd200RareScan|r";
	local subtitle = (L and L.MINIMAP_SUBTITLE) or "Escaner de Criaturas Raras (TuWoW)";
	GameTooltip:AddLine( title, 1.0, 0.82, 0.0 );
	GameTooltip:AddLine( subtitle, 0.8, 0.8, 0.8 );
	GameTooltip:AddLine( " " );
	GameTooltip:AddLine( "|cff66ccff" .. ((L and L.MINIMAP_CLICK_LEFT) or "Clic Izquierdo:") .. "|r " .. ((L and L.MINIMAP_CLICK_LEFT_DESC) or "Abrir explorador y radar de rares"), 1, 1, 1 );
	GameTooltip:AddLine( "|cff66ccff" .. ((L and L.MINIMAP_CLICK_RIGHT) or "Clic Derecho:") .. "|r " .. ((L and L.MINIMAP_CLICK_RIGHT_DESC) or "Probar alerta sonora y visual (Test)"), 1, 1, 1 );
	GameTooltip:AddLine( "|cff66ccff" .. ((L and L.MINIMAP_CLICK_SHIFT) or "Shift + Clic:") .. "|r " .. ((L and L.MINIMAP_CLICK_SHIFT_DESC) or "Comprobar memoria WDB en chat"), 1, 1, 1 );
	GameTooltip:AddLine( "|cff66ccff" .. ((L and L.MINIMAP_DRAG) or "Arrastrar:") .. "|r " .. ((L and L.MINIMAP_DRAG_DESC) or "Mover boton alrededor del minimapa"), 0.7, 0.7, 0.7 );
	GameTooltip:Show();
end );

me:SetScript( "OnLeave", function ()
	GameTooltip:Hide();
end );

-- Click actions
me:SetScript( "OnClick", function ( self, Button )
	if ( IsShiftKeyDown() ) then
		-- Shift + Clic: Comprobar mobs cacheados
		if ( _NPCScan and _NPCScan.CacheListPrint ) then
			if ( not _NPCScan.CacheListPrint( true, true ) ) then
				_NPCScan.Print( (L and L.CMD_CACHE_EMPTY) or "Memoria limpia: No hay criaturas en cache WDB.", GREEN_FONT_COLOR );
			end
		end
	elseif ( Button == "RightButton" ) then
		-- Clic Derecho: Alerta de prueba
		if ( _NPCScan and _NPCScan.TestAlert ) then
			_NPCScan.TestAlert();
		end
	else
		-- Clic Izquierdo: Abrir ventana de explorador
		if ( _NPCScan and _NPCScan.ToggleConfig ) then
			_NPCScan.ToggleConfig();
		elseif ( TuWoW_RareScan and TuWoW_RareScan.ToggleConfig ) then
			TuWoW_RareScan.ToggleConfig();
		end
	end
end );

-- Sincronizar posición inicial tras cargar
local Frame = CreateFrame( "Frame" );
Frame:RegisterEvent( "PLAYER_LOGIN" );
Frame:RegisterEvent( "PLAYER_ENTERING_WORLD" );
Frame:SetScript( "OnEvent", function ( self, Event )
	me:UpdatePosition( _NPCScan.Options and _NPCScan.Options.MinimapPos );
	if ( Event == "PLAYER_LOGIN" and ForeverUI and ForeverUI.Minimap and ForeverUI.Minimap.applyScale ) then
		hooksecurefunc( ForeverUI.Minimap, "applyScale", function ()
			me:UpdatePosition( _NPCScan.Options and _NPCScan.Options.MinimapPos );
		end );
	end
end );
