--[[****************************************************************************
  * TuWoW_RareScan - UI/PageHunter.lua                                          *
  * Santuario de Mascotas Exoticas para Cazadores Beastmaster                 *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
local UI = NRS.UI or {};
NRS.UI = UI;
local Theme = NRS.Theme;

UI.hunterFilterCategory = "all";
UI.hunterSearchQuery = "";
UI.NUM_HUNTER_CARDS_VISIBLE = 8;
UI.HUNTER_CARD_ROW_H = 50;

function UI:CreatePageHunter()
	local parent = self.content;
	local page = CreateFrame("Frame", nil, parent);
	page:SetAllPoints(parent);
	self.pageHunter = page;
	
	-- 1. Barra de Herramientas Superior (44px)
	local toolbar = CreateFrame("Frame", nil, page);
	toolbar:SetPoint("TOPLEFT", 6, -6);
	toolbar:SetPoint("TOPRIGHT", -6, -6);
	toolbar:SetHeight(44);
	Theme:ApplyPanel(toolbar, true);
	page.toolbar = toolbar;
	
	-- Buscador de Mascotas
	local search = Theme:CreateEditBox(toolbar, 200, 26);
	search:SetPoint("LEFT", 10, 0);
	search:SetScript("OnEscapePressed", function(e) e:ClearFocus(); end);
	search:SetScript("OnTextChanged", function(e)
		UI.hunterSearchQuery = e:GetText();
		UI:RefreshHunterList();
	end);
	
	local searchHint = Theme:CreateLabel(search, "Buscar bestia, familia o zona...", "small", Theme.colors.muted);
	searchHint:SetPoint("LEFT", 8, 0);
	search:SetScript("OnEditFocusGained", function() searchHint:Hide(); end);
	search:SetScript("OnEditFocusLost", function(e) if e:GetText() == "" then searchHint:Show(); end end);
	
	-- Botones de Filtro
	local function SetHunterFilter(cat)
		UI.hunterFilterCategory = cat;
		UI:RefreshHunterList();
	end
	
	local btnAll = Theme:CreateButton(toolbar, "Todas", 60, 26, function() SetHunterFilter("all"); end);
	btnAll:SetPoint("LEFT", search, "RIGHT", 8, 0);
	
	local btnExotic = Theme:CreateButton(toolbar, "Exóticas BM", 84, 26, function() SetHunterFilter("exotic"); end);
	btnExotic:SetPoint("LEFT", btnAll, "RIGHT", 4, 0);
	
	local btnSpirit = Theme:CreateButton(toolbar, "Espíritu", 70, 26, function() SetHunterFilter("spirit"); end);
	btnSpirit:SetPoint("LEFT", btnExotic, "RIGHT", 4, 0);
	
	local btnDino = Theme:CreateButton(toolbar, "Demosaurio", 84, 26, function() SetHunterFilter("devilsaur"); end);
	btnDino:SetPoint("LEFT", btnSpirit, "RIGHT", 4, 0);
	
	local btnClassic = Theme:CreateButton(toolbar, "Clásicas", 70, 26, function() SetHunterFilter("classic"); end);
	btnClassic:SetPoint("LEFT", btnDino, "RIGHT", 4, 0);
	
	local btnFav = Theme:CreateButton(toolbar, "Favoritas", 74, 26, function() SetHunterFilter("fav"); end);
	btnFav:SetPoint("LEFT", btnClassic, "RIGHT", 4, 0);
	
	local countHunterLabel = Theme:CreateLabel(toolbar, "", "small", Theme.colors.gold);
	countHunterLabel:SetPoint("RIGHT", -12, 0);
	self.countHunterLabel = countHunterLabel;
	
	-- 2. Columna 1: Lista de Mascotas (FauxScrollFrame)
	local listFrame = CreateFrame("Frame", nil, page);
	listFrame:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -6);
	listFrame:SetPoint("BOTTOMLEFT", 6, 6);
	listFrame:SetWidth(300);
	Theme:ApplyPanel(listFrame, true);
	page.listFrame = listFrame;
	
	local scroll = CreateFrame("ScrollFrame", "TuWoW_HunterFauxScroll", listFrame, "FauxScrollFrameTemplate");
	scroll:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -6);
	scroll:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -26, 6);
	scroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, UI.HUNTER_CARD_ROW_H, function() UI:UpdateHunterCardRows(); end);
	end);
	page.scroll = scroll;
	
	listFrame:EnableMouseWheel(true);
	listFrame:SetScript("OnMouseWheel", function(self, delta)
		local cur = FauxScrollFrame_GetOffset(scroll);
		local maxOffset = math.max(0, #UI.filteredHunterPets - UI.NUM_HUNTER_CARDS_VISIBLE);
		local newOffset = math.max(0, math.min(maxOffset, cur - delta * 2));
		local scrollBar = _G[scroll:GetName() .. "ScrollBar"];
		if scrollBar then
			scrollBar:SetValue(newOffset * UI.HUNTER_CARD_ROW_H);
		end
		UI:UpdateHunterCardRows();
	end);
	
	-- Pool de 12 tarjetas de mascotas
	page.hunterCardPool = {};
	for i = 1, 12 do
		local card = self:CreateHunterCard(i, listFrame);
		card:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 6, -6 - (i - 1) * UI.HUNTER_CARD_ROW_H);
		table.insert(page.hunterCardPool, card);
	end
	
	-- 3. Columna 2: Visor 3D con Pedestal de Cazador y Estadísticas
	local centerCol = CreateFrame("Frame", nil, page);
	centerCol:SetPoint("TOPLEFT", listFrame, "TOPRIGHT", 6, 0);
	centerCol:SetPoint("BOTTOMLEFT", listFrame, "BOTTOMRIGHT", 6, 0);
	centerCol:SetWidth(300);
	page.centerCol = centerCol;
	
	-- Escenario Grafico con Pedestal y Retrato 2D / 3D
	local stage = CreateFrame("Frame", nil, centerCol);
	stage:SetPoint("TOPLEFT", centerCol, "TOPLEFT", 0, 0);
	stage:SetPoint("TOPRIGHT", centerCol, "TOPRIGHT", 0, 0);
	stage:SetHeight(230);
	Theme:ApplyPanel(stage, true);
	page.stage = stage;
	stage.is3DMode = false;
	
	-- Etiqueta de Tipo de Mascota
	local badgeExotic = stage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	badgeExotic:SetPoint("TOPLEFT", 10, -8);
	badgeExotic:SetText("[ BESTIA EXOTICA BM ]");
	badgeExotic:SetTextColor(unpack(Theme.colors.gold));
	page.badgeExotic = badgeExotic;
	
	local badgeRotationHint = stage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	badgeRotationHint:SetPoint("BOTTOM", stage, "BOTTOM", 0, 4);
	badgeRotationHint:SetText("Arrastra para rotar | Clic der: Reiniciar");
	badgeRotationHint:SetTextColor(unpack(Theme.colors.muted));
	badgeRotationHint:Hide();
	page.badgeRotationHint = badgeRotationHint;
	
	-- Pedestal mistico de Cazador con emblema de garra verde (TGA 1024x512)
	local pedestal = stage:CreateTexture(nil, "BACKGROUND", nil, -1);
	pedestal:SetTexture("Interface\\AddOns\\TuWoW_RareScan\\Assets\\PedestalHunter.tga");
	pedestal:SetSize(280, 140);
	pedestal:SetPoint("BOTTOM", stage, "BOTTOM", 0, 2);
	pedestal:SetAlpha(1.0);
	page.pedestal = pedestal;
	
	-- Retrato 2D de alta resolucion (256x256 con transparencia perfecta)
	local portrait = stage:CreateTexture(nil, "ARTWORK", nil, 1);
	portrait:SetPoint("BOTTOM", stage, "BOTTOM", 0, 26);
	portrait:SetSize(175, 175);
	page.hunterPortrait = portrait;
	
	-- Modelo 3D (Modo alternativo)
	local model = CreateFrame("PlayerModel", nil, stage);
	model:SetPoint("TOPLEFT", 8, -24);
	model:SetPoint("BOTTOMRIGHT", -8, 12);
	model:EnableMouse(true);
	model:Hide();
	page.hunterModel = model;
	
	model.modelFacing = 0.4;
	model.isDragging = false;
	model.lastMouseX = 0;
	
	-- Control de Rotacion 360 con el Raton
	model:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self.isDragging = true;
			self.lastMouseX = select(1, GetCursorPosition());
		elseif button == "RightButton" then
			self.modelFacing = 0.4;
			pcall(function() self:SetFacing(self.modelFacing); end);
		end
	end);
	model:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then self.isDragging = false; end
	end);
	model:SetScript("OnUpdate", function(self)
		if self.isDragging then
			local curX = select(1, GetCursorPosition());
			local diff = (curX - self.lastMouseX) * 0.015;
			self.lastMouseX = curX;
			self.modelFacing = self.modelFacing + diff;
			pcall(function() self:SetFacing(self.modelFacing); end);
		end
	end);
	
	-- Boton para alternar modo 2D / 3D
	local btnToggle3D = Theme:CreateButton(stage, "3D", 38, 18, function()
		stage.is3DMode = not stage.is3DMode;
		if stage.is3DMode then
			btnToggle3D.text:SetText("2D");
			portrait:Hide();
			model:Show();
			badgeRotationHint:Show();
			if UI.selectedHunterPet then
				pcall(function()
					model:ClearModel();
					if model.SetModelScale then model:SetModelScale(1.0); end
					if model.SetPosition then model:SetPosition(0, 0, 0); end
					model:SetCreature(UI.selectedHunterPet.id);
					model:SetFacing(model.modelFacing or 0.4);
				end);
			end
		else
			btnToggle3D.text:SetText("3D");
			model:Hide();
			portrait:Show();
			badgeRotationHint:Hide();
			if UI.selectedHunterPet then
				portrait:SetTexture("Interface\\AddOns\\TuWoW_RareScan\\Assets\\Portraits\\" .. UI.selectedHunterPet.id);
			end
		end
	end);
	btnToggle3D:SetPoint("TOPRIGHT", stage, "TOPRIGHT", -6, -5);
	page.btnToggle3D = btnToggle3D;
	
	-- Banner de Nombre de la Mascota
	local titleBox = CreateFrame("Frame", nil, centerCol);
	titleBox:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -6);
	titleBox:SetPoint("TOPRIGHT", stage, "BOTTOMRIGHT", 0, -6);
	titleBox:SetHeight(44);
	Theme:ApplyPanel(titleBox, false);
	page.titleBox = titleBox;
	
	local petName = titleBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	petName:SetPoint("TOPLEFT", 10, -6);
	petName:SetPoint("TOPRIGHT", -10, -6);
	petName:SetJustifyH("LEFT");
	petName:SetText("Selecciona una mascota...");
	petName:SetTextColor(unpack(Theme.colors.gold));
	page.petName = petName;
	
	local petTitle = titleBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	petTitle:SetPoint("TOPLEFT", petName, "BOTTOMLEFT", 0, -2);
	petTitle:SetPoint("TOPRIGHT", -10, -2);
	petTitle:SetJustifyH("LEFT");
	petTitle:SetText("Familia de bestia exotica");
	petTitle:SetTextColor(unpack(Theme.colors.muted));
	page.petTitle = petTitle;
	
	-- Rejilla de Estadísticas de Combate
	local statGrid = CreateFrame("Frame", nil, centerCol);
	statGrid:SetPoint("TOPLEFT", titleBox, "BOTTOMLEFT", 0, -6);
	statGrid:SetPoint("TOPRIGHT", titleBox, "BOTTOMRIGHT", 0, -6);
	statGrid:SetHeight(56);
	page.statGrid = statGrid;
	
	local function CreateHunterStat(parent, label, iconTex, tipTitle, tipDesc)
		local f = CreateFrame("Frame", nil, parent);
		Theme:ApplyPanel(f, true);
		f:SetBackdropBorderColor(0.25, 0.22, 0.16, 0.85);
		f:SetBackdropColor(0.04, 0.045, 0.06, 0.95);
		
		local ic = f:CreateTexture(nil, "ARTWORK");
		ic:SetSize(14, 14);
		ic:SetPoint("LEFT", 5, 0);
		ic:SetTexture(iconTex);
		ic:SetTexCoord(0.08, 0.92, 0.08, 0.92);
		
		local val = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		val:SetPoint("LEFT", ic, "RIGHT", 4, 0);
		val:SetPoint("RIGHT", -4, 0);
		val:SetJustifyH("LEFT");
		val:SetText("-");
		f.val = val;
		
		f:EnableMouse(true);
		f:SetScript("OnEnter", function(self)
			self:SetBackdropBorderColor(unpack(Theme.colors.gold));
			GameTooltip:SetOwner(self, "ANCHOR_TOP");
			GameTooltip:AddLine(tipTitle or label, 0.93, 0.72, 0.25);
			if tipDesc then GameTooltip:AddLine(tipDesc, 0.85, 0.88, 0.93, true); end
			GameTooltip:Show();
		end);
		f:SetScript("OnLeave", function(self)
			self:SetBackdropBorderColor(0.25, 0.22, 0.16, 0.85);
			GameTooltip:Hide();
		end);
		return f;
	end
	
	local statVida = CreateHunterStat(statGrid, "Vida", "Interface\\Icons\\Spell_Holy_SealOfSacrifice", "Salud Estimada", "Puntos de vida base de la criatura en estado salvaje.");
	statVida:SetPoint("TOPLEFT", statGrid, "TOPLEFT", 0, 0);
	statVida:SetSize(96, 24);
	page.statVida = statVida;
	
	local statDano = CreateHunterStat(statGrid, "Dano", "Interface\\Icons\\Ability_MeleeDamage", "Poder Ofensivo", "Rango de dano cuerpo a cuerpo base.");
	statDano:SetPoint("LEFT", statVida, "RIGHT", 5, 0);
	statDano:SetSize(96, 24);
	page.statDano = statDano;
	
	local statVel = CreateHunterStat(statGrid, "Velocidad", "Interface\\Icons\\Ability_Hunter_RunningShot", "Velocidad de Ataque", "Frecuencia de golpeo basico (ej. 1.0s para Diente Roto).");
	statVel:SetPoint("LEFT", statDano, "RIGHT", 5, 0);
	statVel:SetSize(96, 24);
	page.statVel = statVel;
	
	local statDieta = CreateHunterStat(statGrid, "Dieta", "Interface\\Icons\\INV_Misc_Fish_52", "Alimentacion", "Tipos de comida que acepta para mantener su felicidad al maximo.");
	statDieta:SetPoint("TOPLEFT", statVida, "BOTTOMLEFT", 0, -4);
	statDieta:SetSize(96, 24);
	page.statDieta = statDieta;
	
	local statSkill = CreateHunterStat(statGrid, "Habilidad", "Interface\\Icons\\Ability_Hunter_Pet_Cat", "Habilidad Especial", "Poder exclusivo o habilidad exotica que aporta al cazador.");
	statSkill:SetPoint("LEFT", statDieta, "RIGHT", 5, 0);
	statSkill:SetSize(96, 24);
	page.statSkill = statSkill;
	
	local statAmenaza = CreateHunterStat(statGrid, "Amenaza", "Interface\\Icons\\Ability_Hunter_MasterMarksman", "Nivel de Peligro", "Riesgo de muerte accidental en Hardcore durante la domesticacion.");
	statAmenaza:SetPoint("LEFT", statSkill, "RIGHT", 5, 0);
	statAmenaza:SetSize(96, 24);
	page.statAmenaza = statAmenaza;
	
	-- Helper para tarjetas de informacion
	local function CreateHunterInfoCard(parent, titleText, iconTex, h)
		local card = CreateFrame("Frame", nil, parent);
		Theme:ApplyPanel(card, true);
		card:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
		card:SetBackdropColor(0.02, 0.025, 0.035, 0.95);
		card:SetHeight(h or 48);
		
		local ic = card:CreateTexture(nil, "ARTWORK");
		ic:SetSize(18, 18);
		ic:SetPoint("TOPLEFT", 6, -6);
		ic:SetTexture(iconTex);
		ic:SetTexCoord(0.08, 0.92, 0.08, 0.92);
		
		local t = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		t:SetPoint("TOPLEFT", ic, "TOPRIGHT", 6, 0);
		t:SetPoint("TOPRIGHT", -106, 0);
		t:SetJustifyH("LEFT");
		t:SetText(titleText);
		t:SetTextColor(unpack(Theme.colors.gold));
		card.title = t;
		
		local b = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		b:SetPoint("TOPLEFT", ic, "BOTTOMLEFT", 0, -3);
		b:SetPoint("BOTTOMRIGHT", -6, 4);
		b:SetJustifyH("LEFT");
		b:SetJustifyV("TOP");
		b:SetTextColor(0.85, 0.85, 0.85);
		card.body = b;
		return card;
	end
	
	-- Tarjeta: Consejo de Tameo Hardcore
	local cardAdvice = CreateHunterInfoCard(centerCol, "Consejo de Domesticacion Hardcore", "Interface\\Icons\\Ability_Hunter_TrackBeast", 54);
	cardAdvice:SetPoint("TOPLEFT", statGrid, "BOTTOMLEFT", 0, -6);
	cardAdvice:SetPoint("TOPRIGHT", statGrid, "BOTTOMRIGHT", 0, -6);
	page.cardAdvice = cardAdvice;
	
	-- Tarjeta: Macro de Domesticación
	local cardMacro = CreateHunterInfoCard(centerCol, "Macro de Tameo Seguro Recomendada", "Interface\\Icons\\Ability_Hunter_SniperShot", 70);
	cardMacro:SetPoint("TOPLEFT", cardAdvice, "BOTTOMLEFT", 0, -6);
	cardMacro:SetPoint("TOPRIGHT", cardAdvice, "BOTTOMRIGHT", 0, -6);
	page.cardMacro = cardMacro;
	
	local btnCopyMacro = Theme:CreateButton(cardMacro, "Copiar Macro", 96, 20, function()
		local pet = UI.selectedHunterPet;
		if pet and pet.macro then
			UI:ShowMacroCopyDialog(pet);
		else
			NRS:Print("Selecciona primero una mascota de la lista.");
		end
	end);
	btnCopyMacro:SetPoint("TOPRIGHT", cardMacro, "TOPRIGHT", -6, -4);
	btnCopyMacro.text:SetTextColor(unpack(Theme.colors.gold));
	page.btnCopyMacro = btnCopyMacro;
	
	-- Botones Inferiores de Acción
	local btnRoar = Theme:CreateButton(centerCol, "Escuchar Rugido", 145, 26, function()
		local pet = UI.selectedHunterPet;
		if pet and pet.soundFile then
			if NRS.Button and NRS.Button.PrepareAudioPlayback then
				NRS.Button.PrepareAudioPlayback(3.0);
			elseif GetCVar("Sound_EnableAllSound") == "0" then
				SetCVar("Sound_EnableAllSound", 1);
			end
			local ok = pcall(PlaySoundFile, pet.soundFile, "Master");
			if not ok then
				pcall(PlaySoundFile, pet.soundFile);
			end
			NRS:Print("Rugido de |cffffd200" .. pet.name .. "|r reproducido.");
		else
			NRS:Print("Selecciona primero una mascota de la lista.");
		end
	end);
	btnRoar:SetPoint("BOTTOMLEFT", centerCol, "BOTTOMLEFT", 0, 0);
	btnRoar.text:SetTextColor(unpack(Theme.colors.gold));
	page.btnRoar = btnRoar;
	
	local btnFav = Theme:CreateButton(centerCol, "Agregar Fav", 145, 26, function()
		local pet = UI.selectedHunterPet;
		if pet then
			UI:ToggleFavorite(pet.id);
			UI:UpdateHunterCardRows();
			if UI:IsFavorite(pet.id) then
				btnFav.text:SetText("Quitar Fav");
				btnFav.text:SetTextColor(1, 0.4, 0.4);
			else
				btnFav.text:SetText("Agregar Fav");
				btnFav.text:SetTextColor(unpack(Theme.colors.gold));
			end
		else
			NRS:Print("Selecciona primero una mascota de la lista.");
		end
	end);
	btnFav:SetPoint("BOTTOMRIGHT", centerCol, "BOTTOMRIGHT", 0, 0);
	page.btnFav = btnFav;
	
	-- 4. Columna 3: Mapa de Aparición y Coordenadas GPS
	local rightCol = CreateFrame("Frame", nil, page);
	rightCol:SetPoint("TOPLEFT", centerCol, "TOPRIGHT", 6, 0);
	rightCol:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -6, 6);
	page.rightCol = rightCol;
	
	-- Mapa de Zona Interactivo con pines de spawn
	local mapPreview = UI.ZoneMapPreview:Create(rightCol);
	mapPreview:SetPoint("TOPLEFT", rightCol, "TOPLEFT", 0, 0);
	mapPreview:SetPoint("TOPRIGHT", rightCol, "TOPRIGHT", 0, 0);
	mapPreview:SetHeight(230);
	page.mapPreview = mapPreview;
	
	-- Tarjetas de Localización
	local function CreateRightHunterCard(parent, titleText, iconTex, h)
		local card = CreateFrame("Frame", nil, parent);
		Theme:ApplyPanel(card, true);
		card:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
		card:SetBackdropColor(0.02, 0.025, 0.035, 0.95);
		card:SetHeight(h or 48);
		
		local ic = card:CreateTexture(nil, "ARTWORK");
		ic:SetSize(18, 18);
		ic:SetPoint("TOPLEFT", 6, -6);
		ic:SetTexture(iconTex);
		ic:SetTexCoord(0.08, 0.92, 0.08, 0.92);
		
		local t = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		t:SetPoint("TOPLEFT", ic, "TOPRIGHT", 6, 0);
		t:SetPoint("TOPRIGHT", -6, 0);
		t:SetJustifyH("LEFT");
		t:SetText(titleText);
		t:SetTextColor(unpack(Theme.colors.gold));
		card.title = t;
		
		local b = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		b:SetPoint("TOPLEFT", ic, "BOTTOMLEFT", 0, -4);
		b:SetPoint("BOTTOMRIGHT", -6, 4);
		b:SetJustifyH("LEFT");
		b:SetJustifyV("TOP");
		b:SetTextColor(0.85, 0.85, 0.85);
		card.body = b;
		return card;
	end
	
	local cardReg = CreateRightHunterCard(rightCol, "Registro y Territorio", "Interface\\Icons\\INV_Misc_EngGizmos_17", 50);
	cardReg:SetPoint("TOPLEFT", mapPreview, "BOTTOMLEFT", 0, -6);
	cardReg:SetPoint("TOPRIGHT", mapPreview, "BOTTOMRIGHT", 0, -6);
	page.cardReg = cardReg;
	
	local cardPatrol = CreateRightHunterCard(rightCol, "Puntos de Avistamiento", "Interface\\Icons\\INV_Misc_Spyglass_03", 48);
	cardPatrol:SetPoint("TOPLEFT", cardReg, "BOTTOMLEFT", 0, -6);
	cardPatrol:SetPoint("TOPRIGHT", cardReg, "BOTTOMRIGHT", 0, -6);
	page.cardPatrol = cardPatrol;
	
	local cardCoords = CreateRightHunterCard(rightCol, "Coordenadas GPS de Spawn", "Interface\\Icons\\INV_Misc_Map02", 64);
	cardCoords:SetPoint("TOPLEFT", cardPatrol, "BOTTOMLEFT", 0, -6);
	cardCoords:SetPoint("TOPRIGHT", cardPatrol, "BOTTOMRIGHT", 0, -6);
	page.cardCoords = cardCoords;
	
	local btnSimAlert = Theme:CreateButton(rightCol, "Simular Alerta de Tameo", 240, 26, function()
		local pet = UI.selectedHunterPet;
		if pet then
			NRS:TestAlert(pet.id, pet.soundFile);
		else
			NRS:Print("Selecciona primero una mascota de la lista.");
		end
	end);
	btnSimAlert:SetPoint("BOTTOM", rightCol, "BOTTOM", 0, 0);
	btnSimAlert.text:SetTextColor(unpack(Theme.colors.gold));
	page.btnSimAlert = btnSimAlert;
end

function UI:CreateHunterCard(index, parent)
	local card = CreateFrame("Button", nil, parent);
	card:SetHeight(48);
	card:SetWidth(260);
	Theme:ApplyPanel(card, false);
	card:SetBackdropBorderColor(unpack(Theme.colors.goldDim));
	card:SetBackdropColor(0.04, 0.045, 0.06, 0.95);
	
	local portrait = card:CreateTexture(nil, "ARTWORK");
	portrait:SetSize(36, 36);
	portrait:SetPoint("LEFT", 6, 0);
	portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92);
	card.portrait = portrait;
	
	local name = Theme:CreateLabel(card, "", "large", Theme.colors.text);
	name:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 8, -4);
	name:SetPoint("TOPRIGHT", -22, -4);
	name:SetHeight(16);
	name:SetJustifyH("LEFT");
	card.name = name;
	
	local sub = Theme:CreateLabel(card, "", "small", Theme.colors.muted);
	sub:SetPoint("BOTTOMLEFT", portrait, "BOTTOMRIGHT", 8, 4);
	sub:SetPoint("BOTTOMRIGHT", -22, 4);
	sub:SetHeight(14);
	sub:SetJustifyH("LEFT");
	card.sub = sub;
	
	local dot = card:CreateTexture(nil, "OVERLAY");
	dot:SetSize(6, 6);
	dot:SetPoint("RIGHT", -8, 6);
	Theme:SetSolidColor(dot, 0.3, 0.85, 0.45, 1);
	card.dot = dot;
	
	local star = card:CreateTexture(nil, "OVERLAY");
	star:SetSize(12, 12);
	star:SetPoint("RIGHT", -6, -6);
	star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1");
	star:Hide();
	card.star = star;
	
	card:SetScript("OnClick", function(self)
		if self.petData then
			UI:SelectHunterPet(self.petData);
		end
	end);
	
	card:EnableMouseWheel(true);
	card:SetScript("OnMouseWheel", function(self, delta)
		local scroll = UI.pageHunter and UI.pageHunter.scroll;
		if not scroll then return end
		local cur = FauxScrollFrame_GetOffset(scroll) or 0;
		local maxOffset = math.max(0, #(UI.filteredHunterPets or {}) - UI.NUM_HUNTER_CARDS_VISIBLE);
		local newOffset = math.max(0, math.min(maxOffset, cur - delta * 2));
		local scrollBar = _G[scroll:GetName() .. "ScrollBar"];
		if scrollBar then
			scrollBar:SetValue(newOffset * UI.HUNTER_CARD_ROW_H);
		end
		UI:UpdateHunterCardRows();
	end);
	
	card:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(unpack(Theme.colors.gold));
		self:SetBackdropColor(0.12, 0.10, 0.06, 1);
	end);
	card:SetScript("OnLeave", function(self)
		if UI.selectedHunterPet and self.petData and UI.selectedHunterPet.id == self.petData.id then
			self:SetBackdropBorderColor(unpack(Theme.colors.gold));
			self:SetBackdropColor(0.14, 0.11, 0.05, 1);
		else
			self:SetBackdropBorderColor(unpack(Theme.colors.goldDim));
			self:SetBackdropColor(0.04, 0.045, 0.06, 0.95);
		end
	end);
	
	card:Hide();
	return card;
end

function UI:SelectHunterPet(pet)
	if not pet then return end
	self.selectedHunterPet = pet;
	local page = self.pageHunter;
	if not page then return end
	
	-- 1. Modelo 3D y Retrato 2D con Pedestal
	if page.hunterPortrait then
		page.hunterPortrait:SetTexture("Interface\\AddOns\\TuWoW_RareScan\\Assets\\Portraits\\" .. pet.id);
	end
	if page.hunterModel then
		pcall(function()
			page.hunterModel:ClearModel();
			if page.hunterModel.SetModelScale then page.hunterModel:SetModelScale(1.0); end
			if page.hunterModel.SetPosition then page.hunterModel:SetPosition(0, 0, 0); end
			page.hunterModel:SetCreature(pet.id);
			page.hunterModel:SetFacing(page.hunterModel.modelFacing or 0.4);
		end);
	end
	if page.stage and page.stage.is3DMode then
		if page.hunterPortrait then page.hunterPortrait:Hide(); end
		if page.hunterModel then page.hunterModel:Show(); end
	else
		if page.hunterModel then page.hunterModel:Hide(); end
		if page.hunterPortrait then page.hunterPortrait:Show(); end
	end
	
	if page.badgeExotic then
		if pet.isExotic then
			page.badgeExotic:SetText("[ BESTIA EXOTICA BM 51 ]");
			page.badgeExotic:SetTextColor(unpack(Theme.colors.gold));
		else
			page.badgeExotic:SetText("[ MASCOTA RARA UNICA ]");
			page.badgeExotic:SetTextColor(0.4, 0.8, 1);
		end
	end
	
	if page.petName then
		page.petName:SetText(pet.name);
	end
	if page.petTitle then
		local famTitle = pet.title or pet.subFamily or pet.family;
		page.petTitle:SetText(string.format("<%s> | Nivel %d", famTitle, pet.level));
	end
	
	-- 2. Estadísticas de Combate
	if page.statVida then page.statVida.val:SetText(string.format("HP: %d", pet.hp or 1000)); end
	if page.statDano then page.statDano.val:SetText(pet.damage or "Normal"); end
	if page.statVel then page.statVel.val:SetText(pet.attackSpeed or "2.0 s"); end
	if page.statDieta then page.statDieta.val:SetText(pet.diet or "Carne"); end
	if page.statSkill then page.statSkill.val:SetText(pet.specialSkill or "Especial"); end
	if page.statAmenaza then page.statAmenaza.val:SetText(pet.threat or "Media"); end
	
	-- 3. Tarjeta de Consejos y Macro
	if page.cardAdvice then
		page.cardAdvice.body:SetText(pet.tips or "Usa Trampa congelante antes de empezar la domesticacion.");
	end
	if page.cardMacro then
		page.cardMacro.body:SetText(pet.macro or "/cast Domesticar bestia");
	end
	
	-- 4. Botón de Favorito
	if page.btnFav then
		if self:IsFavorite(pet.id) then
			page.btnFav.text:SetText("Quitar Fav");
			page.btnFav.text:SetTextColor(1, 0.4, 0.4);
		else
			page.btnFav.text:SetText("Agregar Fav");
			page.btnFav.text:SetTextColor(unpack(Theme.colors.gold));
		end
	end
	
	-- 5. Columna Derecha: Mapa de Zona y Pines
	if page.mapPreview then
		UI.ZoneMapPreview:SetZone(page.mapPreview, pet.zoneID, pet.spawns, pet.name);
	end
	
	if page.cardReg then
		page.cardReg.body:SetText(string.format("ID Criatura: |cffffffff#%d|r\nZona: |cffffffff%s|r", pet.id, pet.zoneName));
	end
	
	local spawnCount = pet.spawns and #pet.spawns or 0;
	if page.cardPatrol then
		if spawnCount > 0 then
			page.cardPatrol.body:SetText(string.format("|cffffffff%d|r punto(s) de patrulla registrados", spawnCount));
		else
			page.cardPatrol.body:SetText("Patrulla libre errante por el territorio");
		end
	end
	
	if page.cardCoords then
		if spawnCount > 0 then
			local badges = {};
			for i = 1, math.min(6, spawnCount) do
				local pt = pet.spawns[i];
				table.insert(badges, string.format("|cffffd200[ %.1f, %.1f ]|r", pt[1], pt[2]));
			end
			local txt = table.concat(badges, "   ");
			if spawnCount > 6 then
				txt = txt .. string.format("\n|cff888888... y %d puntos mas en el mapa|r", spawnCount - 6);
			end
			page.cardCoords.body:SetText(txt);
		else
			page.cardCoords.body:SetText("|cffffaa00[ Patrulla Abierta ]|r");
		end
	end
	
	self:UpdateHunterCardRows();
end

function UI:RefreshHunterList()
	local allPets = NRS:GetHunterPets();
	local query = (self.hunterSearchQuery or ""):lower():gsub("^%s+", ""):gsub("%s+$", "");
	local cat = self.hunterFilterCategory or "all";
	
	self.filteredHunterPets = {};
	for _, pet in ipairs(allPets) do
		local matchCat = true;
		if cat == "exotic" then
			matchCat = (pet.isExotic == true);
		elseif cat == "spirit" then
			matchCat = (pet.family == "Bestia de Espíritu");
		elseif cat == "devilsaur" then
			matchCat = (pet.family == "Demosaurio");
		elseif cat == "classic" then
			matchCat = (pet.isExotic == false);
		elseif cat == "fav" then
			matchCat = self:IsFavorite(pet.id);
		end
		
		if matchCat then
			local matchQuery = true;
			if query ~= "" then
				local hay = (pet.name .. " " .. pet.family .. " " .. (pet.subFamily or "") .. " " .. (pet.zoneName or "") .. " " .. tostring(pet.id)):lower();
				matchQuery = (hay:find(query, 1, true) ~= nil);
			end
			if matchQuery then
				table.insert(self.filteredHunterPets, pet);
			end
		end
	end
	
	if self.countHunterLabel then
		self.countHunterLabel:SetText(string.format("Mostrando %d de %d mascotas", #self.filteredHunterPets, #allPets));
	end
	
	local page = self.pageHunter;
	if page and page.scroll then
		FauxScrollFrame_Update(page.scroll, #self.filteredHunterPets, self.NUM_HUNTER_CARDS_VISIBLE, self.HUNTER_CARD_ROW_H);
	end
	
	self:UpdateHunterCardRows();
	
	-- Seleccionar la primera mascota si no hay ninguna activa
	if not self.selectedHunterPet and #self.filteredHunterPets > 0 then
		self:SelectHunterPet(self.filteredHunterPets[1]);
	end
end

function UI:UpdateHunterCardRows()
	local page = self.pageHunter;
	if not page or not page.hunterCardPool or not page.scroll then return end
	local offset = FauxScrollFrame_GetOffset(page.scroll) or 0;
	local total = #(self.filteredHunterPets or {});
	
	local colW = (page.listFrame and page.listFrame:GetWidth()) or 300;
	local cardW = math.max(220, colW - 32);
	
	for i = 1, #page.hunterCardPool do
		local card = page.hunterCardPool[i];
		local dataIdx = offset + i;
		if i <= self.NUM_HUNTER_CARDS_VISIBLE and dataIdx <= total then
			local pet = self.filteredHunterPets[dataIdx];
			card.petData = pet;
			card:SetWidth(cardW);
			
			local isSel = self.selectedHunterPet and (self.selectedHunterPet.id == pet.id);
			if isSel then
				card:SetBackdropBorderColor(unpack(Theme.colors.gold));
				card:SetBackdropColor(0.14, 0.11, 0.05, 1);
				card.name:SetTextColor(unpack(Theme.colors.gold));
			else
				card:SetBackdropBorderColor(unpack(Theme.colors.goldDim));
				card:SetBackdropColor(0.04, 0.045, 0.06, 0.95);
				card.name:SetTextColor(unpack(Theme.colors.text));
			end
			
			card.portrait:SetTexture(pet.icon or "Interface\\Icons\\Ability_Hunter_Pet_Cat");
			card.name:SetText(pet.name);
			local exTag = pet.isExotic and " (BM)" or "";
			card.sub:SetText(string.format("Nivel %d - %s%s", pet.level, pet.family, exTag));
			
			if self:IsFavorite(pet.id) then
				card.star:Show();
			else
				card.star:Hide();
			end
			
			card:ClearAllPoints();
			card:SetPoint("TOPLEFT", page.listFrame, "TOPLEFT", 6, -6 - (i - 1) * self.HUNTER_CARD_ROW_H);
			card:Show();
		else
			card.petData = nil;
			card:Hide();
		end
	end
	
	FauxScrollFrame_Update(page.scroll, total, self.NUM_HUNTER_CARDS_VISIBLE, self.HUNTER_CARD_ROW_H);
end

function UI:LayoutHunter()
	local page = self.pageHunter;
	if not page or not page:IsShown() then return end
	local contentW = self.content and self.content:GetWidth();
	if not contentW or contentW <= 100 then contentW = 962; end
	local contentH = self.content and self.content:GetHeight();
	if not contentH or contentH <= 100 then contentH = 580; end
	
	local totalW = contentW - 18;
	local col1W = math.max(260, math.min(340, totalW * 0.30));
	local col2W = math.max(280, math.min(380, totalW * 0.35));
	
	page.listFrame:SetWidth(col1W);
	page.centerCol:SetWidth(col2W);
	
	-- Redimensionamiento dinamico de tarjetas en columna central (Consejo y Macro)
	local centerH = page.centerCol:GetHeight();
	if not centerH or centerH < 200 then centerH = contentH - 56; end
	-- Alturas fijas: stage (230) + titleBox (44) + statGrid (56) + botones inferiores (32) + gaps (30) = 392
	local remainCenterH = math.max(130, centerH - 392);
	local adviceH = math.max(54, math.floor(remainCenterH * 0.40));
	local macroH = math.max(70, remainCenterH - adviceH - 6);
	
	if page.cardAdvice then page.cardAdvice:SetHeight(adviceH); end
	if page.cardMacro then page.cardMacro:SetHeight(macroH); end
	
	-- Redimensionamiento dinamico de tarjetas en columna derecha (Registro, Puntos, Coordenadas)
	local rightH = page.rightCol:GetHeight();
	if not rightH or rightH < 200 then rightH = contentH - 56; end
	local remainRightH = math.max(160, rightH - 286);
	local regH = 50;
	local patrolH = 46;
	local coordsH = math.max(64, remainRightH - regH - patrolH - 12);
	if page.cardReg then page.cardReg:SetHeight(regH); end
	if page.cardPatrol then page.cardPatrol:SetHeight(patrolH); end
	if page.cardCoords then page.cardCoords:SetHeight(coordsH); end
	
	local listH = page.listFrame:GetHeight();
	if listH and listH > 100 then
		self.NUM_HUNTER_CARDS_VISIBLE = math.max(5, math.min(14, math.floor((listH - 12) / self.HUNTER_CARD_ROW_H)));
	end
	
	local cardW = math.max(220, col1W - 32);
	for _, c in ipairs(page.hunterCardPool or {}) do
		c:SetWidth(cardW);
	end
	
	if page.mapPreview then
		UI.ZoneMapPreview:LayoutMapTiles(page.mapPreview);
	end
	
	self:UpdateHunterCardRows();
end
