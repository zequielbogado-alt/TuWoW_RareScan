--[[****************************************************************************
  * TuWoW_RareScan - UI/PageMemory.lua                                          *
  * Modulo de diagnostico de cache WDB y explicaciones para el jugador        *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
local UI = NRS.UI or {};
NRS.UI = UI;
local Theme = NRS.Theme;

function UI:CreatePageMemory()
	local parent = self.content;
	local page = CreateFrame("Frame", nil, parent);
	page:SetAllPoints(parent);
	self.pageMemory = page;
	
	-- Encabezado con Icono y Subtítulo
	local headIcon = page:CreateTexture(nil, "ARTWORK");
	headIcon:SetSize(26, 26);
	headIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -14);
	headIcon:SetTexture("Interface\\Icons\\INV_Misc_EngGizmos_17");
	headIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
	
	local title = Theme:CreateLabel(page, "Memoria del Radar y Detección de Criaturas", "large", Theme.colors.gold);
	title:SetPoint("LEFT", headIcon, "RIGHT", 8, 4);
	
	local subTitle = Theme:CreateLabel(page, "Monitorea en tiempo real qué criaturas pueden alertar y cómo reiniciar el radar cuando cazas un rare.", "small", Theme.colors.muted);
	subTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2);
	
	-- Banner Principal de Estado Dinámico en Tiempo Real
	local statusBanner = CreateFrame("Frame", nil, page);
	statusBanner:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -56);
	statusBanner:SetPoint("TOPRIGHT", page, "TOPRIGHT", -16, -56);
	statusBanner:SetHeight(68);
	Theme:ApplyPanel(statusBanner, true);
	statusBanner:SetBackdropBorderColor(0.2, 0.75, 0.35, 0.95);
	statusBanner:SetBackdropColor(0.02, 0.025, 0.035, 0.95);
	page.statusBanner = statusBanner;
	
	local bannerIcon = statusBanner:CreateTexture(nil, "ARTWORK");
	bannerIcon:SetSize(36, 36);
	bannerIcon:SetPoint("LEFT", statusBanner, "LEFT", 14, 0);
	bannerIcon:SetTexture("Interface\\Icons\\Spell_ChargePositive");
	bannerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
	page.bannerIcon = bannerIcon;
	
	local bannerTitle = statusBanner:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	bannerTitle:SetPoint("TOPLEFT", bannerIcon, "TOPRIGHT", 12, 1);
	bannerTitle:SetText("|cff55ff55[OK] Comprobando estado del radar...|r");
	page.bannerTitle = bannerTitle;
	
	local bannerDesc = statusBanner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	bannerDesc:SetPoint("TOPLEFT", bannerTitle, "BOTTOMLEFT", 0, -4);
	bannerDesc:SetPoint("BOTTOMRIGHT", statusBanner, "BOTTOMRIGHT", -180, 8);
	bannerDesc:SetJustifyH("LEFT");
	bannerDesc:SetText("Consultando memoria del cliente...");
	page.bannerDesc = bannerDesc;
	
	local btnScan = Theme:CreateButton(statusBanner, "Actualizar Estado", 154, 26, function()
		UI:RefreshMemoryStatus();
		pcall(function() PlaySound("igMainMenuOptionCheckBoxOn"); end);
		NRS:Print("Memoria del radar re-escaneada.");
	end);
	btnScan:SetPoint("RIGHT", statusBanner, "RIGHT", -12, 0);
	
	-- Helper para tarjetas estilizadas
	local function CreateMemoryCard(parent, titleText, iconTex, h, tipTitle, tipDesc)
		local card = CreateFrame("Frame", nil, parent);
		Theme:ApplyPanel(card, true);
		card:SetBackdropBorderColor(0.28, 0.24, 0.16, 0.85);
		card:SetBackdropColor(0.02, 0.025, 0.035, 0.95);
		card:SetHeight(h or 150);
		
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
		body:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -6);
		body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 10);
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
	
	-- Contenedores para las dos columnas
	local colLeft = CreateFrame("Frame", nil, page);
	colLeft:SetPoint("TOPLEFT", statusBanner, "BOTTOMLEFT", 0, -10);
	colLeft:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 16, 16);
	colLeft:SetWidth(422);
	
	local colRight = CreateFrame("Frame", nil, page);
	colRight:SetPoint("TOPRIGHT", statusBanner, "BOTTOMRIGHT", 0, -10);
	colRight:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -16, 16);
	colRight:SetWidth(422);
	
	----------------------------------------------------------------------------
	-- COLUMNA IZQUIERDA
	----------------------------------------------------------------------------
	
	-- 1. Explicación de la Memoria
	local cardExplain = CreateMemoryCard(
		colLeft,
		"La 'Libreta de Apuntes' del Juego",
		"Interface\\Icons\\INV_Misc_Book_06",
		160,
		"Mecánica Clásica 3.3.5a",
		"Es un comportamiento original del cliente de WoW para ahorrar tráfico de datos con el servidor."
	);
	cardExplain:SetPoint("TOPLEFT", colLeft, "TOPLEFT", 0, 0);
	cardExplain:SetPoint("TOPRIGHT", colLeft, "TOPRIGHT", 0, 0);
	cardExplain.body:SetText(
		"En World of Warcraft 3.3.5a, el servidor envía datos a tu pantalla cuando un rare aparece a menos de 100 pasos.\n\n" ..
		"En cuanto tu juego ve a esa criatura por primera vez, la anota en su libreta de memoria local (Caché). A partir de ese momento, el juego asume que ya la conoces y no vuelve a pedir sus datos al servidor, por lo que el radar no puede volver a alertarte hasta que la libreta se limpie."
	);
	
	-- 2. Consejos para Cazadores de Rares
	local cardTips = CreateMemoryCard(
		colLeft,
		"Los 3 Secretos del Cazador",
		"Interface\\Icons\\Ability_Hunter_MasterMarksman",
		155,
		"Consejos de Cacería",
		"Pautas clave para que ninguna presa se te escape en Azeroth."
	);
	cardTips:SetPoint("TOPLEFT", cardExplain, "BOTTOMLEFT", 0, -8);
	cardTips:SetPoint("TOPRIGHT", cardExplain, "BOTTOMRIGHT", 0, -8);
	cardTips.body:SetText(
		"- |cffffd2001. Primera Vez:|r La alarma siempre suena con 100% de efectividad la primera vez que te cruzas con un rare.\n\n" ..
		"- |cffffd2002. Si buscas un respawn:|r Si quieres cazar a un rare que ya derrotaste ese mismo día, sal del juego un momento para limpiar la memoria.\n\n" ..
		"- |cffffd2003. En Hardcore:|r ¡Un rare en memoria no avisará con sonido! Mantén el ojo en el terreno y en la lista del radar."
	);
	
	----------------------------------------------------------------------------
	-- COLUMNA DERECHA
	----------------------------------------------------------------------------
	
	-- 3. Limpieza en 4 Pasos
	local cardSteps = CreateMemoryCard(
		colRight,
		"Cómo Limpiar la Memoria en 4 Pasos",
		"Interface\\Icons\\Spell_Holy_DispelMagic",
		180,
		"Proceso 100% Seguro",
		"Borrar la carpeta Cache/WDB no altera tus personajes, addons ni configuraciones guardadas."
	);
	cardSteps:SetPoint("TOPLEFT", colRight, "TOPLEFT", 0, 0);
	cardSteps:SetPoint("TOPRIGHT", colRight, "TOPRIGHT", 0, 0);
	cardSteps.body:SetText(
		"|cffffd2001. Sal del juego:|r Cierra tu cliente de TuWoW por completo.\n\n" ..
		"|cffffd2002. Abre la carpeta de tu juego:|r\n    |cff66bbffC:\\TuWoW\\TuWoW-Client\\Cache\\WDB|r\n\n" ..
		"|cffffd2003. Borra los archivos:|r Elimina los archivos que hay dentro (o borra la carpeta WDB entera; el juego la vuelve a crear limpia automáticamente).\n\n" ..
		"|cffffd2004. Inicia el juego:|r ¡Todas las criaturas volverán a sonar al instante!"
	);
	
	-- 4. Herramientas y Reportes
	local cardTools = CreateMemoryCard(
		colRight,
		"Herramientas de Memoria",
		"Interface\\Icons\\Trade_Engineering",
		135,
		"Diagnóstico Rápido",
		"Escribe en el chat las criaturas que están actualmente en tu libreta de memoria."
	);
	cardTools:SetPoint("TOPLEFT", cardSteps, "BOTTOMLEFT", 0, -8);
	cardTools:SetPoint("TOPRIGHT", cardSteps, "BOTTOMRIGHT", 0, -8);
	cardTools.body:SetPoint("BOTTOMRIGHT", cardTools, "BOTTOMRIGHT", -10, 40);
	cardTools.body:SetText(
		"Comprueba en cualquier momento si hay criaturas bloqueadas en tu memoria o envía el reporte completo al chat."
	);
	
	local btnListChat = Theme:CreateButton(cardTools, "Listar Criaturas en Memoria en el Chat", 260, 22, function()
		NRS:ListCachedInChat();
	end);
	btnListChat:SetPoint("BOTTOMLEFT", cardTools, "BOTTOMLEFT", 10, 8);
	
	local btnToRadar = Theme:CreateButton(cardTools, "Ir al Radar de Rares", 136, 22, function()
		UI:SetSection("radar");
	end);
	btnToRadar:SetPoint("LEFT", btnListChat, "RIGHT", 6, 0);
end

function UI:RefreshMemoryStatus()
	if not self.pageMemory or not self.pageMemory.bannerTitle then return end
	local cachedCount = 0;
	local total = 403;
	for id in pairs(NRS.ClassicNPCs) do
		if NRS:IsCached(id) then
			cachedCount = cachedCount + 1;
		end
	end
	
	local page = self.pageMemory;
	if cachedCount == 0 then
		page.statusBanner:SetBackdropBorderColor(0.2, 0.75, 0.35, 0.95);
		page.bannerIcon:SetTexture("Interface\\Icons\\Spell_ChargePositive");
		page.bannerTitle:SetText("|cff55ff55[OK] Radar 100% Despejado y Activo|r");
		page.bannerDesc:SetText(string.format("Las %d criaturas de Azeroth están vigiladas. La alarma sonará con total normalidad ante cualquier rare cercano.", total));
	else
		local ready = total - cachedCount;
		page.statusBanner:SetBackdropBorderColor(0.9, 0.65, 0.15, 0.95);
		page.bannerIcon:SetTexture("Interface\\Icons\\INV_Misc_EngGizmos_17");
		page.bannerTitle:SetText(string.format("|cffffd200[!] %d Rares en Memoria  |  %d Listos para Alertar|r", cachedCount, ready));
		page.bannerDesc:SetText(string.format("Has avistado %d criatura(s) en esta sesión. Para que vuelvan a sonar sus alarmas, sigue los 4 pasos de limpieza a la derecha.", cachedCount));
	end
end

--------------------------------------------------------------------------------
-- PAGINA 4: GUIA Y AYUDA (Centro de Conocimiento del Jugador)
--------------------------------------------------------------------------------
