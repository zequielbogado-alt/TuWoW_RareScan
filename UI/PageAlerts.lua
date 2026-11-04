--[[****************************************************************************
  * TuWoW_RareScan - UI/PageAlerts.lua                                          *
  * Modulo de configuracion: Alertas, Sonidos y Opciones de Rastreo           *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
local UI = NRS.UI or {};
NRS.UI = UI;
local Theme = NRS.Theme;
local CURRENT_VERSION = (UI and UI.CURRENT_VERSION) or "2.0";

function UI:CreatePageAlerts()
	local parent = self.content;
	local page = CreateFrame("Frame", nil, parent);
	page:SetAllPoints(parent);
	self.pageAlerts = page;
	
	-- Encabezado con Icono y Subtitulo
	local headIcon = page:CreateTexture(nil, "ARTWORK");
	headIcon:SetSize(26, 26);
	headIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -14);
	headIcon:SetTexture("Interface\\Icons\\Trade_Engineering");
	headIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
	
	local title = Theme:CreateLabel(page, "Centro de Control y Alertas - TuWoW RareScan v" .. CURRENT_VERSION, "large", Theme.colors.gold);
	title:SetPoint("LEFT", headIcon, "RIGHT", 8, 4);
	
	local subTitle = Theme:CreateLabel(page, "Personaliza como y cuando te avisa el radar: sonidos, destellos en pantalla, filtros y marcas.", "small", Theme.colors.muted);
	subTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2);
	
	-- Helper para tarjetas de opciones
	local function CreateOptionCard(parent, titleText, iconTex, h, tipTitle, tipDesc)
		local card = CreateFrame("Frame", nil, parent);
		Theme:ApplyPanel(card, true);
		card:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
		card:SetBackdropColor(0.02, 0.025, 0.035, 0.95);
		card:SetHeight(h or 94);
		
		local icon = card:CreateTexture(nil, "ARTWORK");
		icon:SetSize(22, 22);
		icon:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10);
		icon:SetTexture(iconTex);
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
		card.icon = icon;
		
		local cardTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		cardTitle:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1);
		cardTitle:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -1);
		cardTitle:SetJustifyH("LEFT");
		cardTitle:SetText(titleText);
		cardTitle:SetTextColor(unpack(Theme.colors.gold));
		card.title = cardTitle;
		
		local body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		body:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -5);
		body:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -35);
		body:SetJustifyH("LEFT");
		body:SetJustifyV("TOP");
		body:SetTextColor(0.85, 0.85, 0.85);
		card.body = body;
		
		card:EnableMouse(true);
		card:SetScript("OnEnter", function(self)
			self:SetBackdropBorderColor(unpack(Theme.colors.gold));
			if tipTitle then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(tipTitle, 1, 0.82, 0);
				if tipDesc then GameTooltip:AddLine(tipDesc, 1, 1, 1, true); end
				GameTooltip:Show();
			end
		end);
		card:SetScript("OnLeave", function(self)
			self:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
			GameTooltip:Hide();
		end);
		
		return card;
	end
	
	-- Contenedores para dos columnas
	local colLeft = CreateFrame("Frame", nil, page);
	colLeft:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -58);
	colLeft:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 16, 16);
	colLeft:SetWidth(422);
	
	local colRight = CreateFrame("Frame", nil, page);
	colRight:SetPoint("TOPRIGHT", page, "TOPRIGHT", -16, -58);
	colRight:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -16, 16);
	colRight:SetWidth(422);
	
	----------------------------------------------------------------------------
	-- COLUMNA IZQUIERDA: Deteccion y Comportamiento Visual
	----------------------------------------------------------------------------
	
	-- 1. Sonido en Silencio
	local cardSound = CreateOptionCard(
		colLeft,
		"Aviso Sonoro Inteligente",
		"Interface\\Icons\\INV_Misc_Horn_01",
		94,
		"Audio de Emergencia",
		"Si juegas sin sonido, activa temporalmente el canal de efectos para que no te pierdas la alarma."
	);
	cardSound:SetPoint("TOPLEFT", colLeft, "TOPLEFT", 0, 0);
	cardSound:SetPoint("TOPRIGHT", colLeft, "TOPRIGHT", 0, 0);
	cardSound.body:SetText("Si juegas con el sonido del juego desactivado, el radar abrira el audio unos segundos para que no te pierdas la alarma.");
	
	local cbSound = Theme:CreateCheckbox(cardSound, "Activar sonido temporalmente si juegas en silencio",
		TuWoW_RareScan_DB and TuWoW_RareScan_DB.soundUnmute,
		function(val) if TuWoW_RareScan_DB then TuWoW_RareScan_DB.soundUnmute = val; end end
	);
	cbSound:SetPoint("BOTTOMLEFT", cardSound, "BOTTOMLEFT", 10, 8);
	
	-- 2. Destello Visual
	local cardFlash = CreateOptionCard(
		colLeft,
		"Destello Visual en Pantalla",
		"Interface\\Icons\\Spell_Fire_Fireball02",
		94,
		"Alerta Perimetral",
		"Genera un resplandor en los bordes para avisarte incluso si juegas sin auriculares."
	);
	cardFlash:SetPoint("TOPLEFT", cardSound, "BOTTOMLEFT", 0, -8);
	cardFlash:SetPoint("TOPRIGHT", cardSound, "BOTTOMRIGHT", 0, -8);
	cardFlash.body:SetText("Parpadeo visual rojo en los bordes de la pantalla para alertarte al instante cuando un rare entra en tu radio de 100m.");
	
	local cbFlash = Theme:CreateCheckbox(cardFlash, "Destello rojo en los bordes de pantalla al detectar un rare",
		TuWoW_RareScan_DB and TuWoW_RareScan_DB.screenFlash,
		function(val) if TuWoW_RareScan_DB then TuWoW_RareScan_DB.screenFlash = val; end end
	);
	cbFlash:SetPoint("BOTTOMLEFT", cardFlash, "BOTTOMLEFT", 10, 8);
	
	-- 3. Filtro por Nivel
	local cardLevel = CreateOptionCard(
		colLeft,
		"Filtro de Seguridad por Nivel (+/- 10)",
		"Interface\\Icons\\Achievement_Level_80",
		104,
		"Seguridad Hardcore",
		"Evita alertar criaturas mortales o insignificantes durante la subida de nivel."
	);
	cardLevel:SetPoint("TOPLEFT", cardFlash, "BOTTOMLEFT", 0, -8);
	cardLevel:SetPoint("TOPRIGHT", cardFlash, "BOTTOMRIGHT", 0, -8);
	cardLevel.body:SetText("Ignora alertas de criaturas con mas de 10 niveles por encima de ti (peligro mortal en Hardcore) o 10 por debajo (mobs grises).");
	
	local cbLevel = Theme:CreateCheckbox(cardLevel, "Ignorar criaturas fuera de mi rango (+/- 10 niveles)",
		TuWoW_RareScan_DB and TuWoW_RareScan_DB.filterByLevel,
		function(val) if TuWoW_RareScan_DB then TuWoW_RareScan_DB.filterByLevel = val; end end
	);
	cbLevel:SetPoint("BOTTOMLEFT", cardLevel, "BOTTOMLEFT", 10, 8);
	
	-- 4. Boton en Minimapa
	local cardMinimap = CreateOptionCard(
		colLeft,
		"Acceso Rapido en el Minimapa",
		"Interface\\Icons\\INV_Misc_Map02",
		94,
		"Emblema del Minimapa",
		"Acceso con un clic junto al mapa circular."
	);
	cardMinimap:SetPoint("TOPLEFT", cardLevel, "BOTTOMLEFT", 0, -8);
	cardMinimap:SetPoint("TOPRIGHT", cardLevel, "BOTTOMRIGHT", 0, -8);
	cardMinimap.body:SetText("Muestra un boton redondo dorado con el emblema de TuWoW en el borde de tu minimapa para abrir este panel.");
	
	local cbMinimap = Theme:CreateCheckbox(cardMinimap, "Mostrar boton de radar en el borde del minimapa",
		TuWoW_RareScan_DB and not (TuWoW_RareScan_DB.minimap and TuWoW_RareScan_DB.minimap.hide),
		function(val)
			if TuWoW_RareScan_DB then
				TuWoW_RareScan_DB.minimap = TuWoW_RareScan_DB.minimap or {};
				TuWoW_RareScan_DB.minimap.hide = not val;
				if NRS.MinimapButton then
					if val then NRS.MinimapButton:Show() else NRS.MinimapButton:Hide() end
				end
			end
		end
	);
	cbMinimap:SetPoint("BOTTOMLEFT", cardMinimap, "BOTTOMLEFT", 10, 8);
	
	----------------------------------------------------------------------------
	-- COLUMNA DERECHA: Sonidos, Marcas y Simulador
	----------------------------------------------------------------------------
	
	-- 5. Personalizacion de Sonido
	local cardSoundTone = CreateOptionCard(
		colRight,
		"Efecto de Sonido de la Alarma",
		"Interface\\Icons\\INV_Misc_Horn_02",
		134,
		"Tono de Alerta",
		"Elige la llamada sonora que reproducira el addon al detectar un rare."
	);
	cardSoundTone:SetPoint("TOPLEFT", colRight, "TOPLEFT", 0, 0);
	cardSoundTone:SetPoint("TOPRIGHT", colRight, "TOPRIGHT", 0, 0);
	
	local sounds = {
		{ name = "Tambores", file = "Sound\\Spells\\PVPFlagCaptured.wav" },
		{ name = "Alerta Banda", file = "Sound\\Interface\\RaidWarning.wav" },
		{ name = "Campana", file = "Sound\\Doodad\\BellTollAlliance.wav" },
		{ name = "Subida Nivel", file = "Sound\\Interface\\LevelUp.wav" },
	};
	
	local curFile = (TuWoW_RareScan_DB and TuWoW_RareScan_DB.soundFile) or (NRS.Options and NRS.Options.AlertSound);
	local currentSoundName = "Tambores";
	for _, s in ipairs(sounds) do
		if s.file == curFile then
			currentSoundName = s.name;
			break;
		end
	end
	
	local soundCurrent = cardSoundTone:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	soundCurrent:SetPoint("TOPLEFT", cardSoundTone.icon, "BOTTOMLEFT", 0, -6);
	soundCurrent:SetPoint("TOPRIGHT", cardSoundTone, "TOPRIGHT", -10, -32);
	soundCurrent:SetJustifyH("LEFT");
	soundCurrent:SetText("Sonido actual: |cffffd200" .. currentSoundName .. "|r");
	page.soundCurrent = soundCurrent;
	
	for i, s in ipairs(sounds) do
		local btn = Theme:CreateButton(cardSoundTone, s.name, 96, 24, function()
			if TuWoW_RareScan_DB then TuWoW_RareScan_DB.soundFile = s.file; end
			page.soundCurrent:SetText("Sonido actual: |cffffd200" .. s.name .. "|r");
			NRS:PlayAlertSound();
		end);
		local col = (i - 1) % 2;
		local row = math.floor((i - 1) / 2);
		btn:SetPoint("TOPLEFT", cardSoundTone, "TOPLEFT", 10 + col * 102, -60 - row * 28);
	end
	
	local btnTestSound = Theme:CreateButton(cardSoundTone, "Escuchar Tono", 130, 24, function()
		NRS:PlayAlertSound();
	end);
	btnTestSound:SetPoint("BOTTOMRIGHT", cardSoundTone, "BOTTOMRIGHT", -10, 10);
	btnTestSound.text:SetTextColor(unpack(Theme.colors.gold));
	
	-- 6. Volumen del Sonido de Alerta
	local cardVolume = CreateOptionCard(
		colRight,
		"Volumen de la Alarma y Rugidos",
		"Interface\\Icons\\INV_Misc_Horn_03",
		106,
		"Intensidad Sonora",
		"Regula la intensidad de volumen con la que se reproducen las alarmas del radar y rugidos de mascotas."
	);
	cardVolume:SetPoint("TOPLEFT", cardSoundTone, "BOTTOMLEFT", 0, -8);
	cardVolume:SetPoint("TOPRIGHT", cardSoundTone, "BOTTOMRIGHT", 0, -8);
	cardVolume.body:SetText("Ajusta el volumen temporal durante las alarmas y rugidos sin alterar tu sonido general:");
	
	local initialVol = 0.7;
	if TuWoW_RareScan_DB and TuWoW_RareScan_DB.alertVolume ~= nil then
		initialVol = tonumber(TuWoW_RareScan_DB.alertVolume) or 0.7;
	elseif NRS.Options and NRS.Options.AlertVolume ~= nil then
		initialVol = tonumber(NRS.Options.AlertVolume) or 0.7;
	end
	local initialPct = math.floor(initialVol * 100 + 0.5);
	
	local volDisplay = cardVolume:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	volDisplay:SetPoint("TOPRIGHT", cardVolume, "TOPRIGHT", -12, -10);
	volDisplay:SetText("Nivel: |cffffd200" .. initialPct .. "%|r");
	page.volDisplay = volDisplay;
	
	local sliderVol = Theme:CreateSlider(cardVolume, "Intensidad", 10, 100, 5, initialPct, function(val)
		local frac = val / 100;
		if TuWoW_RareScan_DB then TuWoW_RareScan_DB.alertVolume = frac; end
		if NRS.Options then NRS.Options.AlertVolume = frac; end
		volDisplay:SetText("Nivel: |cffffd200" .. val .. "%|r");
	end, 185);
	sliderVol:SetPoint("BOTTOMLEFT", cardVolume, "BOTTOMLEFT", 14, 20);
	page.sliderVol = sliderVol;
	
	pcall(function()
		sliderVol:HookScript("OnMouseUp", function()
			NRS:PlayAlertSound();
		end);
	end);
	
	-- Botones de niveles rapidos
	local presetLabel = cardVolume:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	presetLabel:SetPoint("BOTTOMLEFT", sliderVol, "TOPRIGHT", 20, 2);
	presetLabel:SetTextColor(unpack(Theme.colors.muted));
	presetLabel:SetText("Ajuste rapido:");
	
	local presets = { 25, 50, 75, 100 };
	for i, pct in ipairs(presets) do
		local pBtn = Theme:CreateButton(cardVolume, pct .. "%", 42, 22, function()
			sliderVol:SetValue(pct);
			NRS:PlayAlertSound();
		end);
		pBtn:SetPoint("LEFT", sliderVol, "RIGHT", 20 + (i - 1) * 46, 2);
	end
	
	-- 7. Marcador de Objetivo
	local cardMarker = CreateOptionCard(
		colRight,
		"Marcador de Objetivo Automatico",
		"Interface\\Icons\\Ability_Hunter_MasterMarksman",
		108,
		"Raid Target Icon",
		"Coloca un icono sobre la criatura para localizarla rapidamente en el terreno."
	);
	cardMarker:SetPoint("TOPLEFT", cardVolume, "BOTTOMLEFT", 0, -8);
	cardMarker:SetPoint("TOPRIGHT", cardVolume, "BOTTOMRIGHT", 0, -8);
	cardMarker.body:SetText("Aplica de forma automatica un marcador visual sobre la cabeza del rare en cuanto lo seleccionas:");
	
	local markers = {
		{ id = 0, name = "Ninguna" },
		{ id = 8, name = "Calavera" },
		{ id = 7, name = "Cruz" },
		{ id = 4, name = "Triangulo" },
		{ id = 1, name = "Estrella" },
	};
	
	for i, m in ipairs(markers) do
		local btn = Theme:CreateButton(cardMarker, m.name, 76, 24, function()
			if TuWoW_RareScan_DB then TuWoW_RareScan_DB.targetIcon = m.id; end
			NRS:Print("Marcador visual establecido en: " .. m.name);
			pcall(function() PlaySound("igMainMenuOptionCheckBoxOn"); end);
		end);
		btn:SetPoint("BOTTOMLEFT", cardMarker, "BOTTOMLEFT", 10 + (i - 1) * 80, 10);
	end
	
	-- 8. Centro de Pruebas y Simulacion
	local cardSim = CreateOptionCard(
		colRight,
		"Centro de Pruebas y Simulacion",
		"Interface\\Icons\\Ability_Warrior_WarCry",
		98,
		"Simulador Integral",
		"Prueba el aviso completo con sonido, destello y ventana 3D interactiva."
	);
	cardSim:SetPoint("TOPLEFT", cardMarker, "BOTTOMLEFT", 0, -8);
	cardSim:SetPoint("TOPRIGHT", cardMarker, "BOTTOMRIGHT", 0, -8);
	cardSim.body:SetText("Dispara una alerta simulada con un rare de prueba para verificar el volumen del audio, el destello y el boton de tarjeteo 3D:");
	
	local btnSim = Theme:CreateButton(cardSim, "Simular Alerta de Prueba Completa", 280, 26, function()
		NRS:TestAlert(448);
	end);
	btnSim:SetPoint("BOTTOMLEFT", cardSim, "BOTTOMLEFT", 10, 10);
	btnSim.text:SetTextColor(unpack(Theme.colors.gold));
end

--------------------------------------------------------------------------------
-- PAGINA 3: MEMORIA WDB (Centro de Diagnóstico y Estado del Radar)
--------------------------------------------------------------------------------
