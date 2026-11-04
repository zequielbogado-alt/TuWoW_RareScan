--[[****************************************************************************
  * TuWoW_RareScan - UI/MainWindow.lua                                         *
  * Ventana Principal "Rare Explorer" v2.0 adaptada al estilo de ForeverGM.    *
  * Virtual Scrolling con FauxScrollFrame para 60 FPS fluidos garantizados.    *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
local UI = NRS.UI or {};
NRS.UI = UI;
local Theme = NRS.Theme;

UI.CURRENT_VERSION = "2.0";
local CURRENT_VERSION = UI.CURRENT_VERSION;

-- Constantes para Virtual Scrolling fluido (60 FPS)
UI.NUM_CARDS_VISIBLE = 9;
UI.CARD_ROW_H = 58;

-- Polyfill de SetShown para WoW 3.3.5a
local frameMeta = getmetatable(CreateFrame("Frame")).__index;
if frameMeta and not frameMeta.SetShown then
	frameMeta.SetShown = function(self, show)
		if show then self:Show() else self:Hide() end
	end
end

function UI:Create()
	if self.mainFrame then return end
	
	-- Dimensiones iniciales (1150 x 710)
	local f = CreateFrame("Frame", "TuWoW_RareScanMainFrame", UIParent);
	self.mainFrame = f;
	local initW = (TuWoW_RareScan_DB and TuWoW_RareScan_DB.windowWidth) or 1150;
	local initH = (TuWoW_RareScan_DB and TuWoW_RareScan_DB.windowHeight) or 710;
	f:SetSize(initW, initH);
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 20);
	f:SetFrameStrata("HIGH");
	f:SetClampedToScreen(true);
	f:SetMovable(true);
	f:SetResizable(true);
	if f.SetMinResize then f:SetMinResize(960, 640); end
	if f.SetMaxResize then f:SetMaxResize(1450, 950); end
	Theme:ApplyPanel(f);
	
	table.insert(UISpecialFrames, "TuWoW_RareScanMainFrame");
	
	-- 1. Barra de Cabecera (Header - 64px)
	local header = CreateFrame("Frame", nil, f);
	header:SetPoint("TOPLEFT", 6, -6);
	header:SetPoint("TOPRIGHT", -6, -6);
	header:SetHeight(64);
	Theme:ApplyPanel(header, true);
	header:EnableMouse(true);
	header:RegisterForDrag("LeftButton");
	header:SetScript("OnDragStart", function() f:StartMoving(); end);
	header:SetScript("OnDragStop", function() f:StopMovingOrSizing(); end);
	
	-- Emblema Forever
	local emblem = header:CreateTexture(nil, "ARTWORK");
	emblem:SetSize(52, 52);
	emblem:SetPoint("LEFT", 8, 0);
	emblem:SetTexture("Interface\\AddOns\\TuWoW_RareScan\\Assets\\ForeverGM-Emblem");
	
	-- Titulo y subtitulo
	local title = Theme:CreateLabel(header, "TuWoW RareScan", "large", Theme.colors.gold);
	title:SetPoint("TOPLEFT", 68, -12);
	local subtitle = Theme:CreateLabel(header, "Radar y Explorador de Criaturas Raras para Azeroth (Hardcore / Die & Rise)", "small", Theme.colors.muted);
	subtitle:SetPoint("TOPLEFT", 68, -34);
	
	-- Identidad del Jugador
	local playerInfo = Theme:CreateLabel(header, "", "small", Theme.colors.text);
	playerInfo:SetPoint("RIGHT", -80, 0);
	playerInfo:SetJustifyH("RIGHT");
	self.headerPlayerInfo = playerInfo;
	
	-- Botones de Cabecera: Cerrar [X] y Minimizar [-]
	local closeBtn = Theme:CreateButton(header, "X", 28, 26, function() UI:Hide(); end);
	closeBtn:SetPoint("TOPRIGHT", -8, -8);
	local minBtn = Theme:CreateButton(header, "-", 28, 26, function() UI:Hide(); end);
	minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0);
	
	-- 2. Barra Lateral de Navegacion (Sidebar - 170px)
	local nav = CreateFrame("Frame", nil, f);
	nav:SetPoint("TOPLEFT", 6, -74);
	nav:SetPoint("BOTTOMLEFT", 6, 36);
	nav:SetWidth(170);
	Theme:ApplyPanel(nav, true);
	self.nav = nav;
	
	local _, playerClass = UnitClass("player");
	local sections = {
		{ id = "radar",  label = "Radar y Rares", icon = "Interface\\Icons\\Ability_Hunter_BeastCall" },
		{ id = "alerts", label = "Alertas y Opciones", icon = "Interface\\Icons\\Trade_Engineering" },
		{ id = "memory", label = "Memoria WDB",   icon = "Interface\\Icons\\INV_Misc_EngGizmos_17" },
		{ id = "help",   label = "Guia y Ayuda",   icon = "Interface\\Icons\\INV_Misc_Book_09" },
	};
	if playerClass == "HUNTER" then
		table.insert(sections, { id = "hunter", label = "Mascotas Exóticas", icon = "Interface\\Icons\\Ability_Hunter_Pet_Devilsaur" });
	end
	
	self.navButtons = {};
	for idx, sec in ipairs(sections) do
		local b = CreateFrame("Button", nil, nav);
		b:SetSize(156, 36);
		b:SetPoint("TOPLEFT", 7, -8 - (idx - 1) * 42);
		Theme:ApplyButton(b);
		
		local bIcon = b:CreateTexture(nil, "ARTWORK");
		bIcon:SetSize(22, 22);
		bIcon:SetPoint("LEFT", 8, 0);
		bIcon:SetTexture(sec.icon);
		
		local bText = b:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		bText:SetPoint("LEFT", 36, 0);
		bText:SetPoint("RIGHT", -4, 0);
		bText:SetJustifyH("LEFT");
		bText:SetText(sec.label);
		bText:SetTextColor(unpack(Theme.colors.text));
		b.text = bText;
		
		b:SetScript("OnClick", function()
			UI:SetSection(sec.id);
		end);
		
		if sec.id == "hunter" then
			b:HookScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:AddLine("Mascotas Exóticas", 0.93, 0.72, 0.25);
				GameTooltip:AddLine("Pestaña especial para la clase Cazador (Hunter).", 1, 1, 1, true);
				GameTooltip:AddLine("Guía especializada de bestias exóticas de BM, habilidades únicas, consejos de tameo para Hardcore y macros seguras.", 0.85, 0.88, 0.93, true);
				GameTooltip:AddLine("Nota: Sección en desarrollo continuo, algunas características pueden variar.", 0.8, 0.6, 0.3, true);
				GameTooltip:Show();
			end);
			b:HookScript("OnLeave", function(self)
				GameTooltip:Hide();
			end);
		end
		
		self.navButtons[sec.id] = b;
	end
	
	-- 3. Area de Contenido Principal
	local content = CreateFrame("Frame", nil, f);
	content:SetPoint("TOPLEFT", nav, "TOPRIGHT", 6, 0);
	content:SetPoint("BOTTOMRIGHT", -6, 36);
	Theme:ApplyPanel(content, false);
	self.content = content;
	
	-- 4. Barra de Estado Inferior (Footer - 28px)
	local footer = CreateFrame("Frame", nil, f);
	footer:SetPoint("BOTTOMLEFT", 6, 6);
	footer:SetPoint("BOTTOMRIGHT", -6, 6);
	footer:SetHeight(28);
	Theme:ApplyPanel(footer, true);
	
	local statusText = Theme:CreateLabel(footer, "Radar Activo - 403 criaturas de Azeroth vigiladas", "small", Theme.colors.muted);
	statusText:SetPoint("LEFT", 12, 0);
	self.footerStatus = statusText;
	
	local verText = Theme:CreateLabel(footer, "v" .. CURRENT_VERSION, "small", Theme.colors.gold);
	verText:SetPoint("RIGHT", -32, 0);
	
	-- Redimensionador (Grabber)
	local grabber = CreateFrame("Button", nil, f);
	grabber:SetSize(20, 20);
	grabber:SetPoint("BOTTOMRIGHT", -2, 2);
	grabber:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
	grabber:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
	grabber:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT"); end);
	grabber:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing();
		if TuWoW_RareScan_DB then
			TuWoW_RareScan_DB.windowWidth = f:GetWidth();
			TuWoW_RareScan_DB.windowHeight = f:GetHeight();
		end
		UI:Layout();
	end);
	
	f:SetScript("OnSizeChanged", function() UI:Layout(); end);
	f:SetScript("OnShow", function() UI:OnShow(); end);
	
	-- Construir las paginas protegidas contra fallos individuales
	local ok, err;
	ok, err = pcall(function() self:CreatePageRadar(); end);
	if not ok and NRS and NRS.Print then NRS:Print("|cffff3333Error en Radar:|r " .. tostring(err)); end
	
	ok, err = pcall(function() self:CreatePageAlerts(); end);
	if not ok and NRS and NRS.Print then NRS:Print("|cffff3333Error en Alertas:|r " .. tostring(err)); end
	
	ok, err = pcall(function() self:CreatePageMemory(); end);
	if not ok and NRS and NRS.Print then NRS:Print("|cffff3333Error en Memoria:|r " .. tostring(err)); end
	
	ok, err = pcall(function() self:CreatePageHelp(); end);
	if not ok and NRS and NRS.Print then NRS:Print("|cffff3333Error en Guia:|r " .. tostring(err)); end
	
	if playerClass == "HUNTER" then
		ok, err = pcall(function() self:CreatePageHunter(); end);
		if not ok and NRS and NRS.Print then NRS:Print("|cffff3333Error en Mascotas Exoticas:|r " .. tostring(err)); end
	end
	
	f:Hide();
	self:SetSection("radar");
end

function UI:OnShow()
	local pName = UnitName("player") or "Jugador";
	local pZone = GetRealZoneText() or "Azeroth";
	local realm = GetRealmName() or "TuWoW";
	self.headerPlayerInfo:SetText(string.format("%s - %s\nZona actual: %s", pName, realm, pZone));
	self:Layout();
	if self.activeSection == "hunter" then
		if self.RefreshHunterList then self:RefreshHunterList(); end
	else
		self:RefreshRadarList();
	end
end

function UI:Show()
	self:Create();
	self.mainFrame:Show();
end

function UI:Hide()
	if self.mainFrame then self.mainFrame:Hide(); end
end

function UI:Toggle()
	if self.mainFrame and self.mainFrame:IsShown() then
		self:Hide();
	else
		self:Show();
	end
end

function UI:SetSection(secID)
	self.activeSection = secID;
	for id, btn in pairs(self.navButtons) do
		if id == secID then
			btn:SetBackdropBorderColor(unpack(Theme.colors.gold));
			btn:SetBackdropColor(0.14, 0.12, 0.08, 1);
			btn.text:SetTextColor(unpack(Theme.colors.gold));
		else
			btn:SetBackdropBorderColor(unpack(Theme.colors.goldDim));
			btn:SetBackdropColor(0.08, 0.09, 0.12, 1);
			btn.text:SetTextColor(unpack(Theme.colors.text));
		end
	end
	
	if self.pageRadar then if secID == "radar" then self.pageRadar:Show() else self.pageRadar:Hide() end end
	if self.pageAlerts then if secID == "alerts" then self.pageAlerts:Show() else self.pageAlerts:Hide() end end
	if self.pageMemory then if secID == "memory" then self.pageMemory:Show() else self.pageMemory:Hide() end end
	if self.pageHelp then if secID == "help" then self.pageHelp:Show() else self.pageHelp:Hide() end end
	if self.pageHunter then if secID == "hunter" then self.pageHunter:Show() else self.pageHunter:Hide() end end
	
	if secID == "radar" then
		self:Layout();
		self:RefreshRadarList();
	elseif secID == "memory" then
		self:RefreshMemoryStatus();
	elseif secID == "hunter" then
		if self.RefreshHunterList then self:RefreshHunterList(); end
		if self.LayoutHunter then self:LayoutHunter(); end
	end
end

function UI:Layout()
	if not self.content then return end
	if self.activeSection == "radar" and self.LayoutRadar then
		self:LayoutRadar();
	elseif self.activeSection == "hunter" and self.LayoutHunter then
		self:LayoutHunter();
	end
end



function UI:IsFavorite(npcID)
	if not npcID or not TuWoW_RareScan_DB or not TuWoW_RareScan_DB.favorites then return false end
	return TuWoW_RareScan_DB.favorites[npcID] and true or false;
end

function UI:ToggleFavorite(npcID)
	if not TuWoW_RareScan_DB then TuWoW_RareScan_DB = {}; end
	TuWoW_RareScan_DB.favorites = TuWoW_RareScan_DB.favorites or {};
	if TuWoW_RareScan_DB.favorites[npcID] then
		TuWoW_RareScan_DB.favorites[npcID] = nil;
		NRS:Print("Criatura eliminada de tus favoritos.");
	else
		TuWoW_RareScan_DB.favorites[npcID] = true;
		NRS:Print("Criatura agregada a tus favoritos.");
	end
	if self.selectedRare and self.selectedRare.id == npcID then
		self:SelectCreature(self.selectedRare);
	end
	if self.selectedHunterPet and self.selectedHunterPet.id == npcID then
		self:SelectHunterPet(self.selectedHunterPet);
	end
end


