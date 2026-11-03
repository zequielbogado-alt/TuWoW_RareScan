--[[****************************************************************************
  * _NPCScan by Saiket                                                         *
  * _NPCScan.Button.lua - Displays a button to target found NPCs.              *
  ****************************************************************************]]


local _NPCScan = select( 2, ... );
local me = CreateFrame( "Button", "TuWoW_RareScanButton", UIParent, "SecureActionButtonTemplate,SecureHandlerShowHideTemplate" );
_G[ "_NPCScanButton" ] = me;
_NPCScan.Button = me;

me.Drag = me:CreateTitleRegion();
me.Model = CreateFrame( "PlayerModel", nil, me );
me.Pedestal = me:CreateTexture( nil, "BACKGROUND" );
me.Portrait = me:CreateTexture( nil, "ARTWORK" );
me.Flash = CreateFrame( "Frame" );
me.Flash.LoopCountMax = 3;

me.PendingName, me.PendingID = nil;

me.RotationRate = math.pi / 4;
me.RaidTargetIcon = 4; -- Green triangle

me.ModelDefaultScale = 0.75;
--- @description Key is lowercase, value = "[Scale]|[X]|[Y]|[Z]", where any parameter can be left empty
me.ModelCameras = {
	[ [[creature\spectraltigerferal\spectraltigerferal.m2]] ] = "||-.25|1"; -- Gondria
	[ [[creature\abyssaloutland\abyssal_outland.m2]] ] = "|.3|1|-8"; -- Kraator
	[ [[creature\ancientofarcane\ancientofarcane.m2]] ] = "1.25"; -- Old Crystalbark
	[ [[creature\arcanegolem\arcanegolem.m2]] ] = ".6|.25"; -- Ever-Core the Punisher
	[ [[creature\bonegolem\bonegolem.m2]] ] = "|.4|.6"; -- Crippler
	[ [[creature\bonespider\bonespider.m2]] ] = "||-1"; -- Terror Spinner
	[ [[creature\crocodile\crocodile.m2]] ] = ".7||-.5"; -- Goretooth
	[ [[creature\dragon\northrenddragon.m2]] ] = ".5||20|-14"; -- Hemathion, Vyragosa
	[ [[creature\fungalmonster\fungalmonster.m2]] ] = ".5|.2|1"; -- Bog Lurker
	[ [[creature\mammoth\mammoth.m2]] ] = ".35|.9|2.7"; -- Tukemuth
	[ [[creature\mountaingiantoutland\mountaingiant_bladesedge.m2]] ] = ".19|-.2|1.2"; -- Morcrush
	[ [[creature\northrendfleshgiant\northrendfleshgiant.m2]] ] = "||2"; -- Putridus the Ancient
	[ [[creature\protodragon\protodragon.m2]] ] = "1.3||-3"; -- Time-Lost Proto Drake
	[ [[creature\satyr\satyr.m2]] ] = ".7|.3|.5"; -- Ambassador Jerrikar
	[ [[creature\wight\wight.m2]] ] = ".7"; -- Griegen
	[ [[creature\zuldrakgolem\zuldrakgolem.m2]] ] = ".45|.1|1.3"; -- Zul'drak Sentinel
};




local muteTimerFrame = CreateFrame( "Frame" );
local function UnmuteTemporarily ( duration )
	local needsRestore = false;
	if ( not GetCVarBool( "Sound_EnableAllSound" ) ) then
		SetCVar( "Sound_EnableAllSound", 1 );
		needsRestore = true;
	end
	if ( not GetCVarBool( "Sound_EnableSFX" ) ) then
		SetCVar( "Sound_EnableSFX", 1 );
	end
	local mVol = tonumber( GetCVar( "Sound_MasterVolume" ) or "0" ) or 0;
	if ( mVol < 0.25 ) then
		SetCVar( "Sound_MasterVolume", "0.8" );
	end
	if ( needsRestore ) then
		muteTimerFrame.elapsed = 0;
		muteTimerFrame.duration = duration or 4.0;
		muteTimerFrame:SetScript( "OnUpdate", function ( self, dt )
			self.elapsed = self.elapsed + dt;
			if ( self.elapsed >= self.duration ) then
				self:SetScript( "OnUpdate", nil );
				if ( _NPCScan.Options and _NPCScan.Options.AlertSoundUnmute ) then
					SetCVar( "Sound_EnableAllSound", 0 );
				end
			end
		end );
	end
end

--- Plays an alert sound, temporarily enabling sound if necessary.
-- @param AlertSound  A LibSharedMedia sound key, or file path, or nil to play default.
function me.PlaySound ( AlertSound )
	if ( _NPCScan.Options and _NPCScan.Options.AlertSoundUnmute ) then
		UnmuteTemporarily( 4.0 );
	end
	if ( AlertSound == nil ) then -- Default
		PlaySoundFile( [[Sound\Event Sounds\Event_wardrum_ogre.wav]], "Master" );
		PlaySoundFile( [[Sound\Events\scourge_horn.wav]], "Master" );
	elseif ( AlertSound == "Raid Warning" ) then
		PlaySoundFile( [[Sound\Interface\RaidWarning.wav]], "Master" );
	elseif ( AlertSound == "Bell Toll" ) then
		PlaySoundFile( [[Sound\Interface\AuctionWindowOpen.wav]], "Master" );
	elseif ( AlertSound == "Level Up" ) then
		PlaySoundFile( [[Sound\Interface\LevelUp.wav]], "Master" );
	else
		local LSM = LibStub and LibStub( "LibSharedMedia-3.0", true );
		local path = LSM and LSM:Fetch( LSM.MediaType.SOUND, AlertSound );
		if ( path ) then
			PlaySoundFile( path, "Master" );
		elseif ( type( AlertSound ) == "string" and ( AlertSound:find( "\\" ) or AlertSound:find( "/" ) ) ) then
			local ok = pcall( PlaySoundFile, AlertSound, "Master" );
			if ( not ok ) then pcall( PlaySoundFile, AlertSound ); end
		else
			PlaySoundFile( [[Sound\Event Sounds\Event_wardrum_ogre.wav]], "Master" );
			PlaySoundFile( [[Sound\Events\scourge_horn.wav]], "Master" );
		end
	end
end


--- Plays alerts and sets the targetting button if not in combat.
-- If in combat, queues the button to appear when combat ends.
-- @param ID  A numeric NpcID or string UnitID.
-- @param Name  Localized name of the unit.
-- @param customSound  Optional path to sound file.
-- @param prefer2D  If true, displays 2D portrait on pedestal and hides 3D model. If false/nil, displays 3D model only.
-- @see me:Update
function me:SetNPC ( ID, Name, customSound, prefer2D )
	if ( tonumber( ID ) ) then
		ID = tonumber( ID );
		_NPCScan.Overlays.Add( ID );
		_NPCScan.Overlays.Found( ID );
	end

	self.PlaySound( customSound or _NPCScan.Options.AlertSound );
	if ( GetCVarBool( "screenEdgeFlash" ) ) then
		self.Flash:Show();
		self.Flash.Fade:Pause(); -- Forces OnPlay to fire again if it was already playing
		self.Flash.Fade:Play();
	end

	if ( InCombatLockdown() ) then
		if ( type( self.PendingID ) == "number" ) then -- Remove old pending NPC
			_NPCScan.Overlays.Remove( self.PendingID );
		end
		self.PendingID, self.PendingName, self.PendingPrefer2D = ID, Name, prefer2D;
	else
		self:Update( ID, Name, prefer2D );
	end
end
--- Updates the button out of combat to target a given unit.
-- @param ID  A numeric NpcID or string UnitID.
-- @param Name  Localized name of the unit.  If ID is an NpcID, Name is used in the targetting macro.
-- @param prefer2D  Boolean indicating 2D portrait mode vs 3D creature model mode.
function me:Update ( ID, Name, prefer2D )
	if ( type( self.ID ) == "number" ) then -- Remove last overlay
		_NPCScan.Overlays.Remove( self.ID );
	end
	self.ID = ID;

	self:SetText( Name );
	local Model = self.Model;
	Model:Reset();
	
	if ( prefer2D ) then
		-- Modo 2D exclusivo (pruebas manuales desde explorador o simulador de cazador)
		-- Ocultamos el modelo 3D para que jamas colisionen
		Model:Hide();
		if ( self.Portrait ) then
			local numID = tonumber( ID );
			if ( numID ) then
				self.Portrait:SetTexture( "Interface\\AddOns\\TuWoW_RareScan\\Assets\\Portraits\\" .. numID .. ".tga" );
				if ( not self.Portrait:GetTexture() ) then
					local pet = _NPCScan.GetHunterPet and _NPCScan:GetHunterPet( numID );
					if ( pet and pet.icon ) then
						self.Portrait:SetTexture( pet.icon );
					end
				end
				self.Portrait:Show();
				if ( self.Pedestal ) then
					local pet = _NPCScan.GetHunterPet and _NPCScan:GetHunterPet( numID );
					if ( pet ) then
						self.Pedestal:SetTexture( "Interface\\AddOns\\TuWoW_RareScan\\Assets\\PedestalHunter.tga" );
					else
						self.Pedestal:SetTexture( "Interface\\AddOns\\TuWoW_RareScan\\Assets\\Pedestal.tga" );
					end
					self.Pedestal:Show();
				end
			elseif ( ID == "player" or UnitIsPlayer( ID ) ) then
				SetPortraitTexture( self.Portrait, "player" );
				self.Portrait:Show();
				if ( self.Pedestal ) then
					self.Pedestal:SetTexture( "Interface\\AddOns\\TuWoW_RareScan\\Assets\\Pedestal.tga" );
					self.Pedestal:Show();
				end
			else
				self.Portrait:Hide();
				if ( self.Pedestal ) then self.Pedestal:Hide(); end
			end
		end
	else
		-- Modo 3D exclusivo (deteccion real en vivo por avistamiento o prueba de personaje del minimapa)
		-- Ocultamos retrato 2D y pedestal para que se vea unicamente la figura 3D limpia
		if ( self.Portrait ) then self.Portrait:Hide(); end
		if ( self.Pedestal ) then self.Pedestal:Hide(); end
		Model:Show();
		if ( type( ID ) == "number" ) then -- ID is NPC ID
			Model.UnitID = nil;
			pcall( function() Model:SetCreature( ID ); end );
			self:UnregisterEvent( "UNIT_MODEL_CHANGED" );
		else -- ID is UnitID
			Model.UnitID = ID;
			pcall( function() Model:SetUnit( ID ); end );
			self:RegisterEvent( "UNIT_MODEL_CHANGED" );
		end
	end

	local targetMacroParam = (type(ID) == "string" and ID == "player") and "player" or Name;
	self:SetAttribute( "macrotext", "/cleartarget\n/targetexact " .. tostring(targetMacroParam) );
	self:PLAYER_TARGET_CHANGED(); -- Updates the target icon

	self:Show();
	self:StopAnimating();
	self.Glow:Play();
	self.Shine:Play();
end
--- Enables or disables dragging the button.
-- Not a secure function; Can be run in combat.
function me:EnableDrag ( Enable )
	local Drag = self.Drag;
	Drag:ClearAllPoints();
	if ( Enable ) then
		Drag:SetAllPoints();
	else -- Position offscreen
		Drag:SetPoint( "TOP", UIParent, 0, math.huge );
	end
end


--- Starts dragging or waits for drag key when shown.
function me:OnShow ()
	self:RegisterEvent( "MODIFIER_STATE_CHANGED" );
	self:RegisterEvent( "PLAYER_TARGET_CHANGED" );
	self:EnableDrag( IsModifiedClick( "_NPCSCAN_BUTTONDRAG" ) );
end
--- Stops listening for events when hidden.
function me:OnHide ()
	self:UnregisterEvent( "MODIFIER_STATE_CHANGED" );
	self:UnregisterEvent( "PLAYER_TARGET_CHANGED" );
	self:UnregisterEvent( "UNIT_MODEL_CHANGED" );
	self:EnableDrag( false );

	if ( type( self.ID ) == "number" ) then -- Remove current overlay
		_NPCScan.Overlays.Remove( self.ID );
	end
end
--- Highlights the button's border when moused over.
function me:OnEnter ()
	self:SetBackdropBorderColor( 1, 0.92, 0.3 ); -- Brilliant gold
end
--- Removes border highlights when mousing out.
function me:OnLeave ()
	self:SetBackdropBorderColor( 0.78, 0.62, 0.18 ); -- ForeverUI antique gold
end


--- Shows the button queued by me:SetNPC when combat ends.
function me:PLAYER_REGEN_ENABLED ()
	-- Update button after leaving combat
	if ( self.PendingName and self.PendingID ) then
		self:Update( self.PendingID, self.PendingName );
		self.PendingID, self.PendingName = nil;
	end
end
--- Enables or disables dragging when the drag modifier is held.
function me:MODIFIER_STATE_CHANGED ()
	self:EnableDrag( IsModifiedClick( "_NPCSCAN_BUTTONDRAG" ) );
end
do
	--- @param ID  A numeric NpcID or string UnitID.
	-- @return True if the given ID represents the current target.
	local function TargetIsFoundRare ( ID ) -- Returns true if the button targetted its rare
		if ( type( ID ) == "number" ) then
			local GUID = UnitGUID( "target" );
			if ( GUID and ID == tonumber( GUID:sub( 8, 12 ), 16 ) ) then
				return true;
			end
		else -- UnitID
			return UnitIsUnit( ID, "target" );
		end
	end
	--- Raid marks the rare when it's targetted.
	function me:PLAYER_TARGET_CHANGED ()
		local ID = self.ID;
		local markIcon = (_NPCScan.Options and _NPCScan.Options.RaidTargetIcon ~= nil) and _NPCScan.Options.RaidTargetIcon or self.RaidTargetIcon;
		if ( TargetIsFoundRare( ID ) ) then
			if ( markIcon > 0 and GetRaidTargetIndex( "target" ) ~= markIcon -- Wrong mark
				and ( GetNumRaidMembers() == 0 or IsRaidOfficer() ) -- Player can mark
			) then
				SetRaidTarget( "target", markIcon );
			end

			if ( type( ID ) == "number" ) then -- Update model with more accurate visual
				self.Model.UnitID = "target";
				self:RegisterEvent( "UNIT_MODEL_CHANGED" );
				self:UNIT_MODEL_CHANGED( nil, "target" );
			end
		elseif ( self.Model.UnitID and type( ID ) == "number" ) then -- Quit updating model for creature ID
			self.Model.UnitID = nil;
			self:UnregisterEvent( "UNIT_MODEL_CHANGED" );
		end
	end
end
--- Updates the 3D preview display if the targetted rare changes appearance.
function me:UNIT_MODEL_CHANGED ( _, UnitID )
	if ( UnitIsUnit( UnitID, self.Model.UnitID ) ) then
		self.Model:Reset( true ); -- Don't reset rotation
		self.Model:SetUnit( UnitID );
	end
end


--- Stops the animation after a number of loops.
function me.Flash:OnLoop ( Direction )
	if ( Direction == "FORWARD" ) then
		self.LoopCount = self.LoopCount + 1;
		local Flash = self:GetParent();
		if ( self.LoopCount >= Flash.LoopCountMax ) then
			self:Stop();
			Flash:Hide();
		end
	end
end
--- Resets the loop count when resumed/restarted.
function me.Flash:OnPlay ()
	self.LoopCount = 0;
end


do
	--- Fires one frame after the 3D model is loaded, at which point it can safely be manipulated.
	local function OnUpdate ( self )
		local Path = self:GetModel();
		if ( type( Path ) == "string" ) then
			-- Restore normal rotation
			self:SetScript( "OnUpdate", self.OnUpdate );

			local ID = self:GetParent().ID;
			if ( type( ID ) == "number" or not UnitIsPlayer( ID ) ) then -- Creature
				local Scale, X, Y, Z = ( "|" ):split( me.ModelCameras[ Path:lower() ] or "" );
				self:SetModelScale( me.ModelDefaultScale * ( tonumber( Scale ) or 1 ) );
				self:SetPosition( tonumber( Z ) or 0, tonumber( X ) or 0, tonumber( Y ) or 0 );
			else -- Player
				self:SetModelScale( me.ModelDefaultScale );
			end
		end
	end
	--- Fires when the 3D model mesh loads and is ready to display.
	local function OnUpdateModel ( self )
		-- Mesh is loaded; Wait one more frame
		self:SetScript( "OnUpdateModel", nil );
		self:SetScript( "OnUpdate", OnUpdate );
	end
	--- Clears the model and readies it for a SetCreature/Unit call.
	function me.Model:Reset ( KeepFacing )
		self:ClearModel();
		self:SetModelScale( 1 );
		self:SetPosition( 0, 0, 0 );
		if ( not KeepFacing ) then
			self:SetFacing( 0 );
		end

		-- Wait a frame after model changes, or else the current model scale will
		--   display as 100% with later calls scaling relative to it.
		self:SetScript( "OnUpdate", nil );
		self:SetScript( "OnUpdateModel", OnUpdateModel );
	end
end
--- Slowly rotates the 3D model preview.
function me.Model:OnUpdate ( Elapsed )
	self:SetFacing( self:GetFacing() + Elapsed * me.RotationRate );
end




me:SetScale( 1.25 );
me:SetSize( 150, 42 );
me:SetPoint( "BOTTOM", UIParent, 0, 135 );
me:SetMovable( true );
me:SetUserPlaced( true );
me:SetClampedToScreen( true );
me:SetFrameStrata( "FULLSCREEN_DIALOG" );

-- ForeverUI Dark Slate / Gold Theme
me:SetBackdrop( {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]];
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]];
	tile = true; tileSize = 16; edgeSize = 14;
	insets = { left = 3, right = 3, top = 3, bottom = 3 };
} );
me:SetBackdropColor( 0.04, 0.04, 0.06, 0.94 );
me:OnLeave(); -- Set gold border

me:SetAttribute( "_onshow", "self:Enable();" );
me:SetAttribute( "_onhide", "self:Disable();" );
me:Hide();

local TitleBackground = me:CreateTexture( nil, "BORDER" );
TitleBackground:SetTexture( 0.12, 0.10, 0.05, 0.75 );
TitleBackground:SetPoint( "TOPRIGHT", -5, -5 );
TitleBackground:SetPoint( "LEFT", 5, 0 );
TitleBackground:SetHeight( 18 );

local Title = me:CreateFontString( nil, "OVERLAY", "GameFontHighlightMedium" );
Title:SetPoint( "TOPLEFT", TitleBackground, "TOPLEFT", 4, 0 );
Title:SetPoint( "RIGHT", TitleBackground, -4, 0 );
Title:SetTextColor( 1.0, 0.82, 0.0 ); -- ForeverUI Gold text
me:SetFontString( Title );

local SubTitle = me:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
SubTitle:SetPoint( "TOPLEFT", Title, "BOTTOMLEFT", 0, -3 );
SubTitle:SetPoint( "RIGHT", Title );
SubTitle:SetTextColor( 0.25, 1.0, 0.35 ); -- Crisp green
SubTitle:SetText( _NPCScan.L.BUTTON_FOUND );

-- Close button
local Close = CreateFrame( "Button", nil, me, "UIPanelCloseButton" );
Close:SetPoint( "TOPRIGHT", 1, 1 );
Close:SetSize( 26, 26 );
Close:SetScale( 0.85 );

-- Model view
local Model = me.Model;
Model:SetPoint( "BOTTOMLEFT", me, "TOPLEFT", 0, -4 );
Model:SetPoint( "RIGHT" );
Model:SetHeight( me:GetWidth() * 0.65 );
me:SetClampRectInsets( 0, 0, Model:GetHeight() + 20, 0 ); -- Allow room for model

-- 2D Pedestal & Portrait view
local Pedestal = me.Pedestal;
Pedestal:SetPoint( "BOTTOM", me, "TOP", 0, -8 );
Pedestal:SetSize( 116, 48 );
Pedestal:SetTexture( "Interface\\AddOns\\TuWoW_RareScan\\Assets\\Pedestal.tga" );
Pedestal:Hide();

local Portrait = me.Portrait;
Portrait:SetPoint( "BOTTOM", me, "TOP", 0, 6 );
Portrait:SetSize( 82, 82 );
Portrait:Hide();


-- Glow animation
local Texture = me:CreateTexture( nil, "OVERLAY" );
Texture:SetPoint( "CENTER", me );
Texture:SetSize( 400 / 300 * me:GetWidth(), 171 / 70 * me:GetHeight() );
Texture:SetTexture( [[Interface\AchievementFrame\UI-Achievement-Alert-Glow]] );
Texture:SetBlendMode( "ADD" );
Texture:SetTexCoord( 0, 0.78125, 0, 0.66796875 );
Texture:SetAlpha( 0 );
me.Glow = Texture:CreateAnimationGroup();
local FadeIn = me.Glow:CreateAnimation( "Alpha" );
FadeIn:SetChange( 1.0 );
FadeIn:SetDuration( 0.2 );
local FadeOut = me.Glow:CreateAnimation( "Alpha" );
FadeOut:SetOrder( 2 );
FadeOut:SetChange( -1.0 );
FadeOut:SetDuration( 0.5 );

-- Shine animation (reflection swipe)
local Texture = me:CreateTexture( nil, "ARTWORK" );
Texture:SetPoint( "TOPLEFT", me, 0, 8 );
Texture:SetSize( 67 / 300 * me:GetWidth(), 1.28 * me:GetHeight() );
Texture:SetTexture( [[Interface\AchievementFrame\UI-Achievement-Alert-Glow]] );
Texture:SetBlendMode( "ADD" );
Texture:SetTexCoord( 0.78125, 0.912109375, 0, 0.28125 );
Texture:SetAlpha( 0 );
me.Shine = Texture:CreateAnimationGroup();
local Show = me.Shine:CreateAnimation( "Alpha" );
Show:SetStartDelay( 0.3 );
Show:SetChange( 1.0 );
Show:SetDuration( 1e-5 ); -- Note: 0 is invalid
local Slide = me.Shine:CreateAnimation( "Translation" );
Slide:SetOrder( 2 );
Slide:SetOffset( me:GetWidth() - Texture:GetWidth() + 8, 0 );
Slide:SetDuration( 0.4 );
local FadeOut = me.Shine:CreateAnimation( "Alpha" );
FadeOut:SetOrder( 2 );
FadeOut:SetStartDelay( 0.2 );
FadeOut:SetChange( -1.0 );
FadeOut:SetDuration( 0.2 );


-- Full screen flash
local Flash = me.Flash;
Flash:Hide();
Flash:SetAllPoints();
Flash:SetAlpha( 0 );
Flash:SetFrameStrata( "FULLSCREEN_DIALOG" );

local Texture = Flash:CreateTexture();
Texture:SetBlendMode( "ADD" );
Texture:SetAllPoints();
Texture:SetTexture( [[Interface\FullScreenTextures\LowHealth]] );

Flash.Fade = Flash:CreateAnimationGroup();
Flash.Fade:SetLooping( "BOUNCE" );
Flash.Fade:SetScript( "OnLoop", Flash.OnLoop );
Flash.Fade:SetScript( "OnPlay", Flash.OnPlay );

local FadeIn = Flash.Fade:CreateAnimation( "Alpha" );
FadeIn:SetChange( 1.0 );
FadeIn:SetDuration( 0.5 );
FadeIn:SetEndDelay( 0.25 );


me:SetAttribute( "type", "macro" );

me:SetScript( "OnEnter", me.OnEnter );
me:SetScript( "OnLeave", me.OnLeave );
me:SetScript( "OnEvent", _NPCScan.Frame.OnEvent );
me:HookScript( "OnShow", me.OnShow );
me:HookScript( "OnHide", me.OnHide );
me:RegisterEvent( "PLAYER_REGEN_ENABLED" );