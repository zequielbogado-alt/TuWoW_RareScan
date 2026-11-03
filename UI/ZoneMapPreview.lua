--[[****************************************************************************
  * TuWoW_RareScan - UI/ZoneMapPreview.lua                                     *
  * Minimapa de zona nativo en alta resolucion con pines de aparicion.         *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
NRS.UI = NRS.UI or {};

local ZoneMapPreview = {};
NRS.UI.ZoneMapPreview = ZoneMapPreview;

function ZoneMapPreview:Create(parent)
	local container = CreateFrame("Frame", nil, parent);
	NRS.Theme:ApplyPanel(container, true);
	
	-- Titulo de la seccion del mapa
	local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	header:SetPoint("TOPLEFT", 10, -8);
	header:SetText("Mapa de Aparicion");
	header:SetTextColor(unpack(NRS.Theme.colors.gold));
	container.header = header;
	
	-- Subtitulo con nombre de zona y continente
	local zoneLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	zoneLabel:SetPoint("TOPLEFT", 10, -24);
	zoneLabel:SetPoint("TOPRIGHT", -10, -24);
	zoneLabel:SetJustifyH("LEFT");
	zoneLabel:SetText("Selecciona una criatura...");
	zoneLabel:SetTextColor(unpack(NRS.Theme.colors.text));
	container.zoneLabel = zoneLabel;
	
	-- Marco del mapa
	local mapFrame = CreateFrame("Frame", nil, container);
	mapFrame:SetPoint("TOPLEFT", 10, -42);
	mapFrame:SetPoint("TOPRIGHT", -10, -42);
	mapFrame:SetHeight(162);
	container.mapFrame = mapFrame;
	
	-- Fondo del marco del mapa
	local mapBg = mapFrame:CreateTexture(nil, "BACKGROUND");
	mapBg:SetAllPoints(mapFrame);
	NRS.Theme:SetSolidColor(mapBg, 0.03, 0.04, 0.06, 1);
	
	-- Malla de 12 texturas nativas (4 columnas x 3 filas) de WorldMap de Blizzard
	container.mapTiles = {};
	for i = 1, 12 do
		local tile = mapFrame:CreateTexture(nil, "ARTWORK");
		container.mapTiles[i] = tile;
	end
	
	-- Textura alternativa única de fallback
	local singleTile = mapFrame:CreateTexture(nil, "ARTWORK");
	singleTile:SetAllPoints(mapFrame);
	singleTile:Hide();
	container.singleTile = singleTile;
	
	-- Leyenda de estado inferior
	local footer = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	footer:SetPoint("BOTTOMLEFT", 10, 8);
	footer:SetPoint("BOTTOMRIGHT", -10, 8);
	footer:SetJustifyH("LEFT");
	footer:SetTextColor(unpack(NRS.Theme.colors.muted));
	container.footer = footer;
	
	-- Pool de pines interactivos sobre el mapa
	container.pins = {};
	for i = 1, 30 do
		local pin = CreateFrame("Button", nil, mapFrame);
		pin:SetSize(14, 14);
		pin:SetFrameLevel(mapFrame:GetFrameLevel() + 5);
		
		local pinTex = pin:CreateTexture(nil, "OVERLAY");
		pinTex:SetAllPoints(pin);
		pinTex:SetTexture("Interface\\Minimap\\Tracking\\TrivialQuests");
		pinTex:SetVertexColor(1, 0.85, 0.2, 1);
		pin.texture = pinTex;
		
		pin:SetScript("OnEnter", function(self)
			self.texture:SetVertexColor(1, 0.3, 0.3, 1);
			self:SetSize(18, 18);
			GameTooltip:SetOwner(self, "ANCHOR_TOP");
			GameTooltip:AddLine("Punto de Aparicion", 0.93, 0.72, 0.25);
			if self.coordX and self.coordY then
				GameTooltip:AddLine(string.format("Coordenadas: %.1f, %.1f", self.coordX, self.coordY), 1, 1, 1);
			end
			if self.zoneName then
				GameTooltip:AddLine(self.zoneName, 0.7, 0.7, 0.7);
			end
			GameTooltip:Show();
		end);
		
		pin:SetScript("OnLeave", function(self)
			self.texture:SetVertexColor(1, 0.85, 0.2, 1);
			self:SetSize(14, 14);
			GameTooltip:Hide();
		end);
		
		pin:Hide();
		container.pins[i] = pin;
	end
	
	-- Disposicion inicial y en cambio de tamano
	container:SetScript("OnSizeChanged", function(self)
		ZoneMapPreview:LayoutMapTiles(self);
	end);
	
	ZoneMapPreview:LayoutMapTiles(container);
	return container;
end

function ZoneMapPreview:LayoutMapTiles(container)
	if not container or not container.mapFrame then return end
	local mapFrame = container.mapFrame;
	local w = mapFrame:GetWidth();
	local h = mapFrame:GetHeight();
	if not w or w < 50 then w = 270; end
	if not h or h < 50 then h = 162; end
	
	-- Dimensiones logicas de WoW: 1002 x 668
	-- Columnas 1, 2, 3: 256px. Columna 4: 234px (256 - 22)
	-- Filas 1, 2: 256px. Fila 3: 156px (256 - 100)
	local scaleX = w / 1002;
	local scaleY = h / 668;
	
	local colWidths = { 256 * scaleX, 256 * scaleX, 256 * scaleX, 234 * scaleX };
	local rowHeights = { 256 * scaleY, 256 * scaleY, 156 * scaleY };
	
	local xEnds = { 1.0, 1.0, 1.0, 234 / 256 };
	local yEnds = { 1.0, 1.0, 156 / 256 };
	
	local currentY = 0;
	for row = 1, 3 do
		local rH = rowHeights[row];
		local yEnd = yEnds[row];
		local currentX = 0;
		for col = 1, 4 do
			local cW = colWidths[col];
			local xEnd = xEnds[col];
			local tileIdx = (row - 1) * 4 + col;
			local tile = container.mapTiles[tileIdx];
			if tile then
				tile:ClearAllPoints();
				tile:SetPoint("TOPLEFT", mapFrame, "TOPLEFT", currentX, -currentY);
				tile:SetSize(cW + 0.6, rH + 0.6);
				tile:SetTexCoord(0, xEnd, 0, yEnd);
			end
			currentX = currentX + cW;
		end
		currentY = currentY + rH;
	end
end

function ZoneMapPreview:SetZone(container, zoneID, spawns, creatureName)
	if not container then return end
	local zinfo = NRS:GetZoneInfo(zoneID);
	
	-- Actualizar etiquetas
	local continentName = "Azeroth";
	if zinfo.continent == 1 then continentName = "Kalimdor";
	elseif zinfo.continent == 2 then continentName = "Reinos del Este";
	elseif zinfo.continent == 571 then continentName = "Rasganorte";
	elseif zinfo.continent == 530 then continentName = "Terrallende";
	end
	container.zoneLabel:SetText(string.format("%s (%s)", zinfo.name, continentName));
	
	-- Ocultar pines previos
	for _, pin in ipairs(container.pins) do
		pin:Hide();
	end
	
	local mapFile = zinfo.mapFile;
	if not mapFile or mapFile == "World" or mapFile == "" then
		mapFile = "Alterac";
	end
	
	-- Siempre asegurar que los 12 tiles esten correctamente posicionados
	self:LayoutMapTiles(container);
	
	container.singleTile:Hide();
	for i = 1, 12 do
		local tile = container.mapTiles[i];
		tile:Show();
		tile:SetTexture("Interface\\WorldMap\\" .. mapFile .. "\\" .. mapFile .. i);
	end
	
	-- Dibujar los pines de coordenadas conocidas
	local mapFrame = container.mapFrame;
	local mapW = mapFrame:GetWidth();
	local mapH = mapFrame:GetHeight();
	if not mapW or mapW < 50 then mapW = 270; end
	if not mapH or mapH < 50 then mapH = 162; end
	
	local count = 0;
	if spawns and type(spawns) == "table" then
		for idx, coord in ipairs(spawns) do
			if count < #container.pins and coord[1] and coord[2] then
				count = count + 1;
				local pin = container.pins[count];
				local x, y = coord[1], coord[2];
				pin.coordX = x;
				pin.coordY = y;
				pin.zoneName = zinfo.name;
				pin:ClearAllPoints();
				pin:SetPoint("CENTER", mapFrame, "TOPLEFT", (x / 100) * mapW, - (y / 100) * mapH);
				pin:Show();
			end
		end
	end
	
	if count > 0 then
		container.footer:SetText(string.format("%d puntos de patrulla/aparicion conocidos.", count));
	else
		container.footer:SetText("Patrulla abierta en la zona.");
	end
end
