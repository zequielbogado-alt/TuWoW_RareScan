--[[****************************************************************************
  * TuWoW_RareScan - UI/PageRadar.lua                                           *
  * Modulo de la pestana Radar y Explorador de Rares (3 columnas, 60 FPS)     *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
local UI = NRS.UI or {};
NRS.UI = UI;
local Theme = NRS.Theme;

function UI:CreatePageRadar()
	local parent = self.content;
	local page = CreateFrame("Frame", nil, parent);
	page:SetAllPoints(parent);
	self.pageRadar = page;
	
	-- 1. Barra de Herramientas Superior (44px)
	local toolbar = CreateFrame("Frame", nil, page);
	toolbar:SetPoint("TOPLEFT", 6, -6);
	toolbar:SetPoint("TOPRIGHT", -6, -6);
	toolbar:SetHeight(44);
	Theme:ApplyPanel(toolbar, true);
	page.toolbar = toolbar;
	
	-- Buscador
	local search = Theme:CreateEditBox(toolbar, 240, 26);
	search:SetPoint("LEFT", 10, 0);
	search:SetScript("OnEscapePressed", function(e) e:ClearFocus(); end);
	search:SetScript("OnTextChanged", function(e)
		UI.searchQuery = e:GetText();
		UI:RefreshRadarList();
	end);
	
	local searchHint = Theme:CreateLabel(search, "Buscar por nombre o ID...", "small", Theme.colors.muted);
	searchHint:SetPoint("LEFT", 8, 0);
	search:SetScript("OnEditFocusGained", function() searchHint:Hide(); end);
	search:SetScript("OnEditFocusLost", function(e) if e:GetText() == "" then searchHint:Show(); end end);
	
	-- Filtros de Continente: [Todos] [Kalimdor] [Reinos Este] [Mazmorras]
	self.filterWorld = "all";
	local btnAll = Theme:CreateButton(toolbar, "Todos", 64, 26, function() UI.filterWorld = "all"; UI:RefreshRadarList(); end);
	btnAll:SetPoint("LEFT", search, "RIGHT", 10, 0);
	local btnKal = Theme:CreateButton(toolbar, "Kalimdor", 80, 26, function() UI.filterWorld = 1; UI:RefreshRadarList(); end);
	btnKal:SetPoint("LEFT", btnAll, "RIGHT", 6, 0);
	local btnEK = Theme:CreateButton(toolbar, "Reinos Este", 90, 26, function() UI.filterWorld = 2; UI:RefreshRadarList(); end);
	btnEK:SetPoint("LEFT", btnKal, "RIGHT", 6, 0);
	local btnDung = Theme:CreateButton(toolbar, "Mazmorras", 90, 26, function() UI.filterWorld = "dungeon"; UI:RefreshRadarList(); end);
	btnDung:SetPoint("LEFT", btnEK, "RIGHT", 6, 0);
	
	-- Boton [Favoritos]
	self.filterOnlyFavorites = false;
	local btnFav = Theme:CreateButton(toolbar, "Favoritos", 84, 26, function()
		UI.filterOnlyFavorites = not UI.filterOnlyFavorites;
		UI:RefreshRadarList();
	end);
	btnFav:SetPoint("LEFT", btnDung, "RIGHT", 6, 0);
	self.btnFav = btnFav;
	
	-- Contador
	local countLabel = Theme:CreateLabel(toolbar, "", "small", Theme.colors.gold);
	countLabel:SetPoint("RIGHT", -12, 0);
	self.countLabel = countLabel;
	
	-- 2. Columna 1: Lista de Tarjetas (FauxScrollFrame nativo ultra fluido)
	local listFrame = CreateFrame("Frame", nil, page);
	listFrame:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -6);
	listFrame:SetPoint("BOTTOMLEFT", 6, 6);
	listFrame:SetWidth(330);
	Theme:ApplyPanel(listFrame, true);
	page.listFrame = listFrame;
	
	local scroll = CreateFrame("ScrollFrame", "TuWoW_RareScanFauxScroll", listFrame, "FauxScrollFrameTemplate");
	scroll:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -6);
	scroll:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -26, 6);
	scroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, UI.CARD_ROW_H, function() UI:UpdateCardRows(); end);
	end);
	page.scroll = scroll;
	
	-- Soporte de rueda de raton en toda la columna
	listFrame:EnableMouseWheel(true);
	listFrame:SetScript("OnMouseWheel", function(self, delta)
		local cur = FauxScrollFrame_GetOffset(scroll);
		local maxOffset = math.max(0, #UI.filteredRares - UI.NUM_CARDS_VISIBLE);
		local newOffset = math.max(0, math.min(maxOffset, cur - delta * 2));
		local scrollBar = _G[scroll:GetName() .. "ScrollBar"];
		if scrollBar then
			scrollBar:SetValue(newOffset * UI.CARD_ROW_H);
		end
		UI:UpdateCardRows();
	end);
	
	-- Pool de exactamente 12 tarjetas reciclables
	self.cardPool = {};
	for i = 1, 12 do
		local card = self:CreateCard(i, listFrame);
		card:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 6, -6 - (i - 1) * UI.CARD_ROW_H);
		self.cardPool[i] = card;
	end
	
	-- 3. Columna 2: Centro (Ficha Tecnica Grafica con Pedestal, Retrato 2D/3D y Estadisticas)
	local centerCol = CreateFrame("Frame", nil, page);
	centerCol:SetPoint("TOPLEFT", listFrame, "TOPRIGHT", 6, 0);
	centerCol:SetPoint("BOTTOMLEFT", listFrame, "BOTTOMRIGHT", 6, 0);
	centerCol:SetWidth(270);
	page.centerCol = centerCol;
	
	-- Encabezado: Nombre de la criatura
	local infoName = Theme:CreateLabel(centerCol, "Selecciona una criatura", "large", Theme.colors.gold);
	infoName:SetPoint("TOPLEFT", centerCol, "TOPLEFT", 0, 0);
	infoName:SetPoint("TOPRIGHT", centerCol, "TOPRIGHT", 0, 0);
	infoName:SetJustifyH("CENTER");
	infoName:SetHeight(18);
	page.infoName = infoName;
	
	-- Subtítulo / Tag de la criatura (<Winterax Hero>)
	local infoSub = Theme:CreateLabel(centerCol, "", "small", Theme.colors.muted);
	infoSub:SetPoint("TOPLEFT", infoName, "BOTTOMLEFT", 0, -1);
	infoSub:SetPoint("TOPRIGHT", infoName, "BOTTOMRIGHT", 0, -1);
	infoSub:SetJustifyH("CENTER");
	infoSub:SetHeight(13);
	page.infoSub = infoSub;
	
	-- Píldora de Rango / Nivel (estilo banner de bronce/dorado)
	local rankPill = Theme:CreateLabel(centerCol, "TuWoW RareScan v2.0", "small", Theme.colors.goldDim);
	rankPill:SetPoint("TOPLEFT", infoSub, "BOTTOMLEFT", 0, -1);
	rankPill:SetPoint("TOPRIGHT", infoSub, "BOTTOMRIGHT", 0, -1);
	rankPill:SetJustifyH("CENTER");
	rankPill:SetHeight(14);
	page.rankPill = rankPill;
	
	-- Escenario Grafico (Visor con Pedestal y Retrato 2D de alta resolución)
	local modelViewer = UI.ModelViewer:Create(centerCol);
	modelViewer:SetPoint("TOPLEFT", rankPill, "BOTTOMLEFT", 0, -4);
	modelViewer:SetPoint("TOPRIGHT", rankPill, "BOTTOMRIGHT", 0, -4);
	modelViewer:SetHeight(190);
	page.modelViewer = modelViewer;
	
	-- Helper para tarjetas de estadistica
	local function CreateStatCard(parent, defaultTitle, defaultIcon, tipTitle, tipDesc)
		local card = CreateFrame("Frame", nil, parent);
		Theme:ApplyPanel(card, true);
		card:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
		card:SetBackdropColor(0.02, 0.025, 0.035, 0.95);
		
		local icon = card:CreateTexture(nil, "ARTWORK");
		icon:SetSize(16, 16);
		icon:SetPoint("LEFT", card, "LEFT", 5, 0);
		icon:SetTexture(defaultIcon);
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
		card.icon = icon;
		
		local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		title:SetPoint("LEFT", icon, "RIGHT", 5, 0);
		title:SetText(defaultTitle);
		title:SetTextColor(unpack(Theme.colors.goldDim));
		card.title = title;
		
		local val = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		val:SetPoint("RIGHT", card, "RIGHT", -6, 0);
		val:SetText("-");
		card.val = val;
		
		card:EnableMouse(true);
		card:SetScript("OnEnter", function(self)
			self:SetBackdropBorderColor(unpack(Theme.colors.gold));
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(tipTitle, 1, 0.82, 0);
			GameTooltip:AddLine(tipDesc, 1, 1, 1, true);
			GameTooltip:Show();
		end);
		card:SetScript("OnLeave", function(self)
			self:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
			GameTooltip:Hide();
		end);
		
		return card;
	end
	
	-- Grid de 6 Estadisticas (2 Columnas x 3 Filas)
	local statGrid = CreateFrame("Frame", nil, centerCol);
	statGrid:SetPoint("TOPLEFT", modelViewer, "BOTTOMLEFT", 0, -5);
	statGrid:SetPoint("TOPRIGHT", modelViewer, "BOTTOMRIGHT", 0, -5);
	statGrid:SetHeight(80);
	page.statGrid = statGrid;
	
	-- Fila 1: Vida & Velocidad
	local cardVida = CreateStatCard(statGrid, "Vida", "Interface\\Icons\\Spell_Holy_SealOfSacrifice", "Salud Máxima", "Puntos de vida de la criatura. Vital para calcular la duración del combate en Hardcore.");
	cardVida:SetPoint("TOPLEFT", statGrid, "TOPLEFT", 0, 0);
	cardVida:SetSize(132, 24);
	page.cardVida = cardVida;
	
	local cardVelocidad = CreateStatCard(statGrid, "Velocidad", "Interface\\Icons\\Ability_Rogue_Sprint", "Velocidad de Ataque", "Frecuencia con la que asesta golpes cuerpo a cuerpo. Enemigos más veloces interrumpen lanzamientos con mayor facilidad.");
	cardVelocidad:SetPoint("TOPRIGHT", statGrid, "TOPRIGHT", 0, 0);
	cardVelocidad:SetSize(132, 24);
	page.cardVelocidad = cardVelocidad;
	
	-- Fila 2: Daño & Tipo
	local cardDmg = CreateStatCard(statGrid, "Daño", "Interface\\Icons\\Ability_SteelWeapon", "Daño Físico Estimado", "Rango de impacto estimado por golpe cuerpo a cuerpo básico contra armadura estándar.");
	cardDmg:SetPoint("TOPLEFT", cardVida, "BOTTOMLEFT", 0, -4);
	cardDmg:SetSize(132, 24);
	page.cardDmg = cardDmg;
	
	local cardTipo = CreateStatCard(statGrid, "Tipo", "Interface\\Icons\\Ability_Hunter_Pet_Cat", "Clasificación Biológica", "Familia del objetivo. Determina susceptibilidad a trampas, habilidades de cazador o inmunidades mágicas.");
	cardTipo:SetPoint("TOPRIGHT", cardVelocidad, "BOTTOMRIGHT", 0, -4);
	cardTipo:SetSize(132, 24);
	page.cardTipo = cardTipo;
	
	-- Fila 3: Armadura & Amenaza
	local cardArmor = CreateStatCard(statGrid, "Armadura", "Interface\\Icons\\INV_Shield_04", "Armadura Básica", "Reducción de daño físico pasivo de la criatura.");
	cardArmor:SetPoint("TOPLEFT", cardDmg, "BOTTOMLEFT", 0, -4);
	cardArmor:SetSize(132, 24);
	page.cardArmor = cardArmor;
	
	local cardThreat = CreateStatCard(statGrid, "Amenaza", "Interface\\Icons\\Spell_Shadow_DeathScream", "Nivel de Amenaza", "Riesgo de supervivencia en modo Hardcore (Die & Rise). Los monstruos Elite requieren sumo cuidado.");
	cardThreat:SetPoint("TOPRIGHT", cardTipo, "BOTTOMRIGHT", 0, -4);
	cardThreat:SetSize(132, 24);
	page.cardThreat = cardThreat;
	
	-- Caja de Lore y Consejos
	local loreBox = CreateFrame("Frame", nil, centerCol);
	loreBox:SetPoint("TOPLEFT", statGrid, "BOTTOMLEFT", 0, -5);
	loreBox:SetPoint("TOPRIGHT", statGrid, "BOTTOMRIGHT", 0, -5);
	loreBox:SetHeight(54);
	Theme:ApplyPanel(loreBox, true);
	loreBox:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
	page.loreBox = loreBox;
	
	local loreIcon = loreBox:CreateTexture(nil, "ARTWORK");
	loreIcon:SetSize(18, 18);
	loreIcon:SetPoint("TOPLEFT", loreBox, "TOPLEFT", 6, -8);
	loreIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09");
	loreIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
	loreBox.icon = loreIcon;
	
	local loreText = loreBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	loreText:SetPoint("TOPLEFT", loreIcon, "TOPRIGHT", 6, 1);
	loreText:SetPoint("BOTTOMRIGHT", loreBox, "BOTTOMRIGHT", -6, 6);
	loreText:SetJustifyH("LEFT");
	loreText:SetJustifyV("TOP");
	loreText:SetTextColor(0.85, 0.85, 0.85);
	loreText:SetText("Selecciona una criatura de la lista para ver su ficha técnica, estadísticas y consejos de combate.");
	page.loreText = loreText;
	
	-- Caja de Ubicacion & Boton "Ver en el Mapa"
	local locBox = CreateFrame("Frame", nil, centerCol);
	locBox:SetPoint("TOPLEFT", loreBox, "BOTTOMLEFT", 0, -5);
	locBox:SetPoint("TOPRIGHT", loreBox, "BOTTOMRIGHT", 0, -5);
	locBox:SetHeight(48);
	Theme:ApplyPanel(locBox, true);
	locBox:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
	page.locBox = locBox;
	
	local locPin = locBox:CreateTexture(nil, "ARTWORK");
	locPin:SetSize(14, 14);
	locPin:SetPoint("TOPLEFT", locBox, "TOPLEFT", 6, -6);
	locPin:SetTexture("Interface\\Icons\\INV_Misc_Map02");
	locPin:SetTexCoord(0.08, 0.92, 0.08, 0.92);
	
	local locLabel = locBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	locLabel:SetPoint("LEFT", locPin, "RIGHT", 4, 0);
	locLabel:SetText("Lugar de Aparición:");
	locLabel:SetTextColor(unpack(Theme.colors.gold));
	
	local locZone = locBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	locZone:SetPoint("LEFT", locLabel, "RIGHT", 4, 0);
	locZone:SetPoint("RIGHT", locBox, "RIGHT", -6, 0);
	locZone:SetJustifyH("LEFT");
	locZone:SetText("-");
	page.locZone = locZone;
	
	local btnViewMap = Theme:CreateButton(locBox, "Ver en el Mapa", 256, 20, function()
		if UI.selectedRare then
			pcall(function() PlaySound("igQuestListOpen"); end);
			if page.mapPreview then
				UI.ZoneMapPreview:SetZone(page.mapPreview, UI.selectedRare.zoneID, UI.selectedRare.spawns, UI.selectedRare.name);
			end
		end
	end);
	btnViewMap:SetPoint("BOTTOM", locBox, "BOTTOM", 0, 4);
	page.btnViewMap = btnViewMap;
	
	-- Botones de Accion Inferiores
	local btnTestAlert = Theme:CreateButton(centerCol, "Probar Alerta", 132, 24, function()
		if UI.selectedRare then
			NRS:TestAlert(UI.selectedRare.id);
		end
	end);
	btnTestAlert:SetPoint("BOTTOMLEFT", centerCol, "BOTTOMLEFT", 0, 0);
	page.btnTestAlert = btnTestAlert;
	
	local btnToggleFav = Theme:CreateButton(centerCol, "Favorito", 132, 24, function()
		if UI.selectedRare then
			UI:ToggleFavorite(UI.selectedRare.id);
		end
	end);
	btnToggleFav:SetPoint("BOTTOMRIGHT", centerCol, "BOTTOMRIGHT", 0, 0);
	page.btnToggleFav = btnToggleFav;
	
	-- 4. Columna 3: Derecha (Minimapa de Aparicion + Detalles)
	local rightCol = CreateFrame("Frame", nil, page);
	rightCol:SetPoint("TOPLEFT", centerCol, "TOPRIGHT", 6, 0);
	rightCol:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -6, 6);
	page.rightCol = rightCol;
	
	local mapPreview = UI.ZoneMapPreview:Create(rightCol);
	mapPreview:SetPoint("TOPLEFT", 0, 0);
	mapPreview:SetPoint("TOPRIGHT", 0, 0);
	mapPreview:SetHeight(230);
	page.mapPreview = mapPreview;
	
	local spawnDetails = CreateFrame("Frame", nil, rightCol);
	spawnDetails:SetPoint("TOPLEFT", mapPreview, "BOTTOMLEFT", 0, -6);
	spawnDetails:SetPoint("BOTTOMRIGHT", 0, 0);
	Theme:ApplyPanel(spawnDetails, true);
	page.spawnDetails = spawnDetails;
	
	local spTitle = Theme:CreateLabel(spawnDetails, "Coordenadas y Rutas de Patrulla", "large", Theme.colors.gold);
	spTitle:SetPoint("TOPLEFT", 10, -10);
	spTitle:SetPoint("TOPRIGHT", -10, -10);
	spTitle:SetHeight(16);
	
	-- Helper para tarjetas de ancho completo (sin doble fila)
	local function CreateRightCard(parent, titleText, iconTex, h, tipTitle, tipDesc)
		local card = CreateFrame("Frame", nil, parent);
		Theme:ApplyPanel(card, true);
		card:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
		card:SetBackdropColor(0.02, 0.025, 0.035, 0.95);
		card:SetHeight(h or 44);
		
		local icon = card:CreateTexture(nil, "ARTWORK");
		icon:SetSize(16, 16);
		icon:SetPoint("TOPLEFT", card, "TOPLEFT", 6, -6);
		icon:SetTexture(iconTex);
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
		card.icon = icon;
		
		local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, 0);
		title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -6, 0);
		title:SetJustifyH("LEFT");
		title:SetText(titleText);
		title:SetTextColor(unpack(Theme.colors.gold));
		card.title = title;
		
		local body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		body:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -3);
		body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -6, 4);
		body:SetJustifyH("LEFT");
		body:SetJustifyV("TOP");
		body:SetTextColor(0.85, 0.85, 0.85);
		card.body = body;
		
		if tipTitle then
			card:EnableMouse(true);
			card:SetScript("OnEnter", function(self)
				self:SetBackdropBorderColor(unpack(Theme.colors.gold));
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(tipTitle, 1, 0.82, 0);
				if tipDesc then GameTooltip:AddLine(tipDesc, 1, 1, 1, true); end
				GameTooltip:Show();
			end);
			card:SetScript("OnLeave", function(self)
				self:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
				GameTooltip:Hide();
			end);
		end
		
		return card;
	end
	
	-- Tarjeta 1: Registro & Territorio
	local cardReg = CreateRightCard(spawnDetails, "Registro y Territorio", "Interface\\Icons\\INV_Misc_EngGizmos_17", 44, "Registro Oficial", "Identificador numérico y territorio asignado en Azeroth.");
	cardReg:SetPoint("TOPLEFT", spawnDetails, "TOPLEFT", 8, -32);
	cardReg:SetPoint("TOPRIGHT", spawnDetails, "TOPRIGHT", -8, -32);
	page.cardReg = cardReg;
	
	-- Tarjeta 2: Puntos de Patrulla
	local cardPatrol = CreateRightCard(spawnDetails, "Frecuencia de Avistamiento", "Interface\\Icons\\INV_Misc_Spyglass_03", 44, "Puntos de Patrulla", "Número de puntos registrados donde se ha confirmado la presencia de este rare.");
	cardPatrol:SetPoint("TOPLEFT", cardReg, "BOTTOMLEFT", 0, -5);
	cardPatrol:SetPoint("TOPRIGHT", cardReg, "BOTTOMRIGHT", 0, -5);
	page.cardPatrol = cardPatrol;
	
	-- Tarjeta 3: Coordenadas GPS
	local cardCoords = CreateRightCard(spawnDetails, "Coordenadas Conocidas (X, Y)", "Interface\\Icons\\INV_Misc_Map02", 64, "Coordenadas GPS", "Puntos cartográficos de patrulla y reaparición en esta zona.");
	cardCoords:SetPoint("TOPLEFT", cardPatrol, "BOTTOMLEFT", 0, -5);
	cardCoords:SetPoint("TOPRIGHT", cardPatrol, "BOTTOMRIGHT", 0, -5);
	page.cardCoords = cardCoords;
	
	-- Tarjeta 4: Estado del Radar WDB
	local cardCache = CreateRightCard(spawnDetails, "Estado del Radar WDB", "Interface\\Icons\\Spell_ChargePositive", 48, "Caché de Memoria WDB", "El motor 3.3.5a solo suena si la criatura no está en la memoria caché local.");
	cardCache:SetPoint("TOPLEFT", cardCoords, "BOTTOMLEFT", 0, -5);
	cardCache:SetPoint("TOPRIGHT", cardCoords, "BOTTOMRIGHT", 0, -5);
	page.cardCache = cardCache;
	
	-- Tarjeta 5: Consejo de Rastreo
	local cardAdvice = CreateRightCard(spawnDetails, "Consejo de Supervivencia", "Interface\\Icons\\Ability_Hunter_TrackBeast", 44, "Supervivencia Hardcore", "Recomendaciones para evitar muertes accidentales en modo Die & Rise.");
	cardAdvice:SetPoint("TOPLEFT", cardCache, "BOTTOMLEFT", 0, -5);
	cardAdvice:SetPoint("TOPRIGHT", cardCache, "BOTTOMRIGHT", 0, -5);
	cardAdvice.body:SetText("Mantén el volumen de alertas alto para reaccionar a tiempo.");
	page.cardAdvice = cardAdvice;
end

function UI:LayoutRadar()
	local page = self.pageRadar;
	if not page or not page:IsShown() then return end
	local contentW = self.content and self.content:GetWidth();
	if not contentW or contentW <= 100 then contentW = 872; end
	local totalW = contentW - 18;
	local col1W = math.max(260, math.min(340, totalW * 0.32));
	local col2W = math.max(240, math.min(320, totalW * 0.30));
	
	page.listFrame:SetWidth(col1W);
	page.centerCol:SetWidth(col2W);
	
	-- Ajustar tarjetas al ancho de la columna
	local cardW = math.max(220, col1W - 32);
	for _, c in ipairs(self.cardPool) do
		c:SetWidth(cardW);
	end
	
	-- Calcular cuantas tarjetas entran en la altura visible
	local listH = page.listFrame:GetHeight();
	if listH and listH > 100 then
		self.NUM_CARDS_VISIBLE = math.max(5, math.min(12, math.floor((listH - 12) / self.CARD_ROW_H)));
	end
	
	if page.mapPreview then
		UI.ZoneMapPreview:LayoutMapTiles(page.mapPreview);
	end
	
	self:UpdateCardRows();
end

function UI:CreateCard(idx, parent)
	local card = CreateFrame("Button", nil, parent);
	card:SetHeight(54);
	card:SetWidth(296);
	Theme:ApplyPanel(card, false);
	
	-- Icono de Familia
	local icon = card:CreateTexture(nil, "ARTWORK");
	icon:SetSize(36, 36);
	icon:SetPoint("LEFT", 8, 0);
	card.icon = icon;
	
	-- Nombre de la Criatura
	local name = Theme:CreateLabel(card, "", "large", Theme.colors.text);
	name:SetPoint("TOPLEFT", 50, -6);
	name:SetPoint("TOPRIGHT", -20, -6);
	name:SetHeight(16);
	name:SetJustifyH("LEFT");
	card.name = name;
	
	-- Subtitulo / Rango
	local meta = Theme:CreateLabel(card, "", "small", Theme.colors.muted);
	meta:SetPoint("BOTTOMLEFT", 50, 6);
	meta:SetPoint("BOTTOMRIGHT", -8, 6);
	meta:SetJustifyH("LEFT");
	card.meta = meta;
	
	-- Indicador visual de estado (Rastreando / En Memoria)
	local statusDot = card:CreateTexture(nil, "OVERLAY");
	statusDot:SetSize(8, 8);
	statusDot:SetPoint("TOPRIGHT", -8, -8);
	card.statusDot = statusDot;
	
	card:SetScript("OnClick", function(self)
		if self.record then UI:SelectCreature(self.record); end
	end);
	
	-- Soporte de rueda de raton al pasar el cursor sobre cualquier tarjeta
	card:EnableMouseWheel(true);
	card:SetScript("OnMouseWheel", function(self, delta)
		local scroll = UI.pageRadar.scroll;
		if not scroll then return end
		local cur = FauxScrollFrame_GetOffset(scroll);
		local maxOffset = math.max(0, #UI.filteredRares - UI.NUM_CARDS_VISIBLE);
		local newOffset = math.max(0, math.min(maxOffset, cur - delta * 2));
		local scrollBar = _G[scroll:GetName() .. "ScrollBar"];
		if scrollBar then
			scrollBar:SetValue(newOffset * UI.CARD_ROW_H);
		end
		UI:UpdateCardRows();
	end);
	
	card:Hide();
	return card;
end

function UI:UpdateCardRows()
	if not self.pageRadar or not self.pageRadar.scroll then return end
	local scroll = self.pageRadar.scroll;
	local total = #(self.filteredRares or {});
	local offset = FauxScrollFrame_GetOffset(scroll) or 0;
	
	local colW = (self.pageRadar.listFrame and self.pageRadar.listFrame:GetWidth()) or 330;
	local cardW = math.max(220, colW - 32);
	
	for i = 1, #self.cardPool do
		local card = self.cardPool[i];
		local idx = offset + i;
		if i <= self.NUM_CARDS_VISIBLE and idx <= total then
			local r = self.filteredRares[idx];
			card.record = r;
			card:SetWidth(cardW);
			
			local fam = NRS:GetFamilyInfo(r.family);
			card.icon:SetTexture(fam.icon);
			card.name:SetText(r.name);
			
			local rankText = (r.rank == 4 and "Elite Raro" or (r.rank == 1 and "Elite" or "Raro"));
			local zinfo = NRS:GetZoneInfo(r.zoneID);
			card.meta:SetText(string.format("Nivel %d - %s - %s", r.minLvl or 0, rankText, zinfo.name));
			
			local inCache = NRS:IsCached(r.id);
			if inCache then
				Theme:SetSolidColor(card.statusDot, 0.6, 0.6, 0.6, 0.8);
			else
				Theme:SetSolidColor(card.statusDot, 0.2, 0.9, 0.4, 1.0);
			end
			
			if self.selectedRare and self.selectedRare.id == r.id then
				card:SetBackdropBorderColor(unpack(Theme.colors.gold));
				card:SetBackdropColor(0.14, 0.12, 0.08, 1);
				card.name:SetTextColor(unpack(Theme.colors.gold));
			else
				card:SetBackdropBorderColor(unpack(Theme.colors.goldDim));
				card:SetBackdropColor(unpack(Theme.colors.panel));
				card.name:SetTextColor(unpack(Theme.colors.text));
			end
			card:Show();
		else
			card.record = nil;
			card:Hide();
		end
	end
	
	FauxScrollFrame_Update(scroll, total, self.NUM_CARDS_VISIBLE, self.CARD_ROW_H);
end

function UI:RefreshRadarList()
	if not self.pageRadar then return end
	local query = (self.searchQuery or ""):lower();
	local world = self.filterWorld;
	local onlyFav = self.filterOnlyFavorites;
	local favs = (TuWoW_RareScan_DB and TuWoW_RareScan_DB.favorites) or {};
	
	self.filteredRares = {};
	for id, r in pairs(NRS.ClassicNPCs) do
		local matchQuery = true;
		if query ~= "" then
			local nES = (r.NameES or ""):lower();
			local nEN = (r.NameEN or ""):lower();
			local idStr = tostring(id);
			if not nES:find(query, 1, true) and not nEN:find(query, 1, true) and not idStr:find(query, 1, true) then
				matchQuery = false;
			end
		end
		
		local matchWorld = true;
		if world == 1 or world == 2 then
			matchWorld = (r.WorldID == world);
		elseif world == "dungeon" then
			local zinfo = NRS:GetZoneInfo(r.ZoneID);
			matchWorld = zinfo.isDungeon or (r.WorldID == nil);
		end
		
		local matchFav = true;
		if onlyFav then
			matchFav = favs[id] and true or false;
		end
		
		if matchQuery and matchWorld and matchFav then
			table.insert(self.filteredRares, {
				id = id,
				name = r.NameES or r.NameEN,
				subname = r.SubName,
				minLvl = r.MinLvl,
				maxLvl = r.MaxLvl,
				minHP = r.MinHP,
				maxHP = r.MaxHP,
				rank = r.Rank,
				family = r.Family,
				zoneID = r.ZoneID,
				spawns = r.Spawns,
				worldID = r.WorldID
			});
		end
	end
	
	-- Ordenar por nivel y luego nombre
	table.sort(self.filteredRares, function(a, b)
		if (a.minLvl or 0) ~= (b.minLvl or 0) then
			return (a.minLvl or 0) < (b.minLvl or 0);
		end
		return a.name < b.name;
	end);
	
	self.countLabel:SetText(string.format("Mostrando %d de 403 rares", #self.filteredRares));
	if self.btnFav then
		if onlyFav then
			self.btnFav:SetBackdropBorderColor(unpack(Theme.colors.gold));
			self.btnFav.text:SetTextColor(unpack(Theme.colors.gold));
		else
			self.btnFav:SetBackdropBorderColor(unpack(Theme.colors.goldDim));
			self.btnFav.text:SetTextColor(unpack(Theme.colors.text));
		end
	end
	
	-- Reiniciar scroll arriba al cambiar filtros
	local scroll = self.pageRadar.scroll;
	if scroll then
		FauxScrollFrame_SetOffset(scroll, 0);
		local scrollBar = _G[scroll:GetName() .. "ScrollBar"];
		if scrollBar then scrollBar:SetValue(0); end
	end
	
	self:UpdateCardRows();
	
	-- Mantener o seleccionar primer resultado
	local hasSelection = false;
	if self.selectedRare then
		for _, r in ipairs(self.filteredRares) do
			if r.id == self.selectedRare.id then
				hasSelection = true;
				break;
			end
		end
	end
	if not hasSelection and #self.filteredRares > 0 then
		self:SelectCreature(self.filteredRares[1]);
	end
end

function UI:SelectCreature(record)
	if not record then return end
	self.selectedRare = record;
	local page = self.pageRadar;
	
	self:UpdateCardRows();
	
	-- Actualizar Ficha Tecnica Central
	page.infoName:SetText(record.name);
	if record.subname and record.subname ~= "" then
		page.infoSub:SetText("<" .. record.subname .. ">");
	else
		page.infoSub:SetText("");
	end
	
	local rankText = NRS:GetRankText(record.rank);
	local zinfo = NRS:GetZoneInfo(record.zoneID);
	local details = NRS:GetCreatureDetails(record);
	
	if page.rankPill then
		page.rankPill:SetText(string.format("Nivel %d - %s", record.minLvl or 1, rankText));
	end
	
	-- Actualizar las 6 micro-tarjetas de estadisticas
	if page.cardVida and details then
		page.cardVida.val:SetText(details.hpStr);
	end
	if page.cardVelocidad and details then
		page.cardVelocidad.val:SetText(details.speedStr);
	end
	if page.cardDmg and details then
		page.cardDmg.val:SetText(details.dmgStr);
	end
	if page.cardTipo and details then
		page.cardTipo.icon:SetTexture(details.familyIcon);
		page.cardTipo.val:SetText(details.familyStr);
	end
	if page.cardArmor and details then
		page.cardArmor.val:SetText(details.armorStr);
	end
	if page.cardThreat and details then
		page.cardThreat.val:SetText(details.threatStr);
		if details.threatColor then
			page.cardThreat.val:SetTextColor(unpack(details.threatColor));
		end
	end
	
	-- Actualizar Lore y Consejos de Supervivencia
	if page.loreText and details then
		page.loreText:SetText(details.lore);
	end
	
	-- Actualizar Ubicacion
	if page.locZone then
		local continent = (record.worldID == 1) and "Kalimdor" or "Reinos del Este";
		page.locZone:SetText(string.format("%s (%s)", zinfo.name, continent));
	end
	
	-- Actualizar boton de Favorito
	local isFav = (TuWoW_RareScan_DB and TuWoW_RareScan_DB.favorites and TuWoW_RareScan_DB.favorites[record.id]);
	page.btnToggleFav.text:SetText(isFav and "Quitar Fav" or "Agregar Fav");
	if isFav then
		page.btnToggleFav:SetBackdropBorderColor(unpack(Theme.colors.gold));
	else
		page.btnToggleFav:SetBackdropBorderColor(unpack(Theme.colors.goldDim));
	end
	
	-- Actualizar Visor Grafico 2D / 3D con Pedestal
	if page.modelViewer then
		UI.ModelViewer:SetCreature(page.modelViewer, record);
	end
	
	-- Actualizar Minimapa de Aparicion
	if page.mapPreview then
		UI.ZoneMapPreview:SetZone(page.mapPreview, record.zoneID, record.spawns, record.name);
	end
	
	-- Actualizar lista de coordenadas textuales en columna derecha
	-- Actualizar Tarjetas de Ubicacion e Inteligencia Geografica (Columna Derecha)
	local continent = (record.worldID == 1) and "Kalimdor" or "Reinos del Este";
	if page.cardReg then
		page.cardReg.body:SetText(string.format("ID #|cffffffff%d|r  |  Zona: |cffffffff%s|r (%s)", record.id, zinfo.name, continent));
	end
	
	local spawnCount = record.spawns and #record.spawns or 0;
	if page.cardPatrol then
		if spawnCount > 0 then
			page.cardPatrol.body:SetText(string.format("|cffffffff%d|r ubicacion(es) de aparicion registradas en radar", spawnCount));
		elseif zinfo.isDungeon then
			page.cardPatrol.body:SetText("Encuentro de interior (Dentro de la mazmorra indicada)");
		else
			page.cardPatrol.body:SetText("Patrulla abierta errante por todo el territorio de la zona");
		end
	end
	
	if page.cardCoords then
		if spawnCount > 0 then
			local coordBadges = {};
			for i = 1, math.min(6, spawnCount) do
				local pt = record.spawns[i];
				table.insert(coordBadges, string.format("|cffffd200[ %.1f, %.1f ]|r", pt[1], pt[2]));
			end
			local text = table.concat(coordBadges, "   ");
			if spawnCount > 6 then
				text = text .. string.format("\n|cff888888... y %d puntos mas proyectados en el mapa|r", spawnCount - 6);
			end
			page.cardCoords.body:SetText(text);
		elseif zinfo.isDungeon then
			page.cardCoords.body:SetText("|cff66bbff[ Instancia de Mazmorra ]|r\nAparece en el interior de la estancia.");
		else
			page.cardCoords.body:SetText("|cffffaa00[ Patrulla Libre ]|r\nSin ruta fija. Vigilancia perimetral activa.");
		end
	end
	
	if page.cardCache then
		local inCache = NRS:IsCached(record.id);
		if inCache then
			page.cardCache.body:SetText("|cffff5555[!] EN MEMORIA LOCAL|r\nReinicia el juego para que vuelva a alertar.");
		else
			page.cardCache.body:SetText("|cff55ff55[OK] VIGILANCIA ACTIVA|r\nListo para detectar y disparar alarma a 100m.");
		end
	end
end

