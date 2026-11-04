--[[****************************************************************************
  * TuWoW_RareScan - UI/PageHelp.lua                                            *
  * Modulo de guia y ayuda interactiva para el jugador                        *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
local UI = NRS.UI or {};
NRS.UI = UI;
local Theme = NRS.Theme;
local CURRENT_VERSION = (UI and UI.CURRENT_VERSION) or "2.0";

function UI:CreatePageHelp()
	local parent = self.content;
	local page = CreateFrame("Frame", nil, parent);
	page:SetAllPoints(parent);
	self.pageHelp = page;
	
	-- Encabezado con Icono y Subtítulo
	local headIcon = page:CreateTexture(nil, "ARTWORK");
	headIcon:SetSize(26, 26);
	headIcon:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -14);
	headIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09");
	headIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
	
	local title = Theme:CreateLabel(page, "Guía y Manual del Jugador - TuWoW RareScan v" .. CURRENT_VERSION, "large", Theme.colors.gold);
	title:SetPoint("LEFT", headIcon, "RIGHT", 8, 4);
	
	local subTitle = Theme:CreateLabel(page, "Todo lo que necesitas saber para cazar criaturas raras sin complicaciones ni tecnicismos.", "small", Theme.colors.muted);
	subTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2);
	
	-- Helper para tarjetas de ayuda
	local function CreateHelpCard(parent, titleText, iconTex, h, tipTitle, tipDesc, borderColor)
		local card = CreateFrame("Frame", nil, parent);
		Theme:ApplyPanel(card, true);
		local baseBorder = borderColor or { 0.28, 0.24, 0.16, 0.85 };
		card:SetBackdropBorderColor(unpack(baseBorder));
		card:SetBackdropColor(0.02, 0.025, 0.035, 0.95);
		card:SetHeight(h or 140);
		
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
		body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 32);
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
			self:SetBackdropBorderColor(unpack(baseBorder));
			GameTooltip:Hide();
		end);
		
		return card;
	end
	
	-- Contenedores para las dos columnas
	local colLeft = CreateFrame("Frame", nil, page);
	colLeft:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -58);
	colLeft:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 16, 16);
	colLeft:SetWidth(422);
	
	local colRight = CreateFrame("Frame", nil, page);
	colRight:SetPoint("TOPRIGHT", page, "TOPRIGHT", -16, -58);
	colRight:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -16, 16);
	colRight:SetWidth(422);
	
	----------------------------------------------------------------------------
	-- COLUMNA IZQUIERDA
	----------------------------------------------------------------------------
	
	-- 1. Alerta Automática
	local cardAlert = CreateHelpCard(
		colLeft,
		"¡Detección Automática a 100 Pasos!",
		"Interface\\Icons\\Ability_Hunter_BeastCall",
		144,
		"Radar Silencioso",
		"El addon vigila continuamente los alrededores. No necesitas tocar nada para que detecte."
	);
	cardAlert:SetPoint("TOPLEFT", colLeft, "TOPLEFT", 0, 0);
	cardAlert:SetPoint("TOPRIGHT", colLeft, "TOPRIGHT", 0, 0);
	cardAlert.body:SetText(
		"Mientras exploras el mundo, el radar vigila todo a tu alrededor.\n" ..
		"En cuanto un rare aparezca cerca, escucharás un redoble de tambores de guerra y verás un botón brillante con la figura del monstruo en tu pantalla para no perderlo de vista jamás."
	);
	
	local btnTest = Theme:CreateButton(cardAlert, "Probar Alerta en Pantalla", 210, 22, function()
		NRS:TestAlert(14430);
	end);
	btnTest:SetPoint("BOTTOMLEFT", cardAlert, "BOTTOMLEFT", 10, 8);
	
	-- 2. Apuntado con un Clic
	local cardTarget = CreateHelpCard(
		colLeft,
		"Apuntado Instantáneo con un Clic",
		"Interface\\Icons\\Ability_Hunter_SniperShot",
		122,
		"Macro Inteligente",
		"El botón emergente selecciona al objetivo al instante con solo hacer clic."
	);
	cardTarget:SetPoint("TOPLEFT", cardAlert, "BOTTOMLEFT", 0, -8);
	cardTarget:SetPoint("TOPRIGHT", cardAlert, "BOTTOMRIGHT", 0, -8);
	cardTarget.body:SetText(
		"¡No pierdas tiempo buscándolo entre los árboles o escribiendo comandos!\n" ..
		"Al hacer clic sobre el botón que aparece en pantalla, tu personaje seleccionará al monstruo de inmediato, facilitando atacarlo o huir deprisa."
	);
	
	-- 3. La Memoria del Juego
	local cardMemory = CreateHelpCard(
		colLeft,
		"El Secreto de la Memoria del Juego",
		"Interface\\Icons\\INV_Misc_EngGizmos_17",
		156,
		"Caché WDB",
		"Explicación simple de por qué el motor del juego sólo alerta la primera vez que ve un rare."
	);
	cardMemory:SetPoint("TOPLEFT", cardTarget, "BOTTOMLEFT", 0, -8);
	cardMemory:SetPoint("TOPRIGHT", cardTarget, "BOTTOMRIGHT", 0, -8);
	cardMemory.body:SetText(
		"En esta versión de WoW, el juego 'recuerda' a cada rare que ves por primera vez.\n" ..
		"Si derrotas a un rare o pasas cerca de él, para que la alarma vuelva a sonar la próxima vez que reaparezca, simplemente reinicia el juego o vacía tu memoria temporal."
	);
	
	local btnMemory = Theme:CreateButton(cardMemory, "Revisar Memoria de Rares", 210, 22, function()
		UI:SetSection("memory");
	end);
	btnMemory:SetPoint("BOTTOMLEFT", cardMemory, "BOTTOMLEFT", 10, 8);
	
	----------------------------------------------------------------------------
	-- COLUMNA DERECHA
	----------------------------------------------------------------------------
	
	-- 4. Modo Hardcore
	local cardHardcore = CreateHelpCard(
		colRight,
		"¡Precaución en Modo Hardcore!",
		"Interface\\Icons\\Spell_Shadow_DeathScream",
		144,
		"Supervivencia Die & Rise",
		"Los rares Elite son extremadamente peligrosos para personajes en solitario.",
		{ 0.65, 0.22, 0.22, 0.9 }
	);
	cardHardcore:SetPoint("TOPLEFT", colRight, "TOPLEFT", 0, 0);
	cardHardcore:SetPoint("TOPRIGHT", colRight, "TOPRIGHT", 0, 0);
	cardHardcore.body:SetText(
		"¡No todos los rares son presas fáciles! Los monstruos marcados como |cffff4444Elite|r pegan el doble de duro y tienen mucha más vida.\n" ..
		"Si juegas en modo 1 sola vida, abre su ficha en el Radar antes de atacar para conocer su daño, armadura y consejos de combate."
	);
	
	local btnRadar = Theme:CreateButton(cardHardcore, "Consultar Fichas en el Radar", 210, 22, function()
		UI:SetSection("radar");
	end);
	btnRadar:SetPoint("BOTTOMLEFT", cardHardcore, "BOTTOMLEFT", 10, 8);
	
	-- 5. Comandos Rápidos
	local cardCmds = CreateHelpCard(
		colRight,
		"Comandos Rápidos y Ajustes",
		"Interface\\Icons\\Trade_Engineering",
		142,
		"Comandos de Chat",
		"Atajos rápidos por comando para la consola de chat."
	);
	cardCmds:SetPoint("TOPLEFT", cardHardcore, "BOTTOMLEFT", 0, -8);
	cardCmds:SetPoint("TOPRIGHT", cardHardcore, "BOTTOMRIGHT", 0, -8);
	cardCmds.body:SetText(
		"Escribe estos comandos sencillos en el chat cuando los necesites:\n" ..
		"  - |cffffd200/rarescan|r : Abre o cierra esta ventana principal.\n" ..
		"  - |cffffd200/rarescan test|r : Lanza una alarma de prueba con sonido.\n" ..
		"  - |cffffd200/rarescan reset|r : Devuelve la ventana al centro de la pantalla."
	);
	
	local btnReset = Theme:CreateButton(cardCmds, "Centrar Ventana en Pantalla", 210, 22, function()
		UI.mainFrame:ClearAllPoints();
		UI.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 20);
		UI.mainFrame:SetSize(1150, 710);
		if TuWoW_RareScan_DB then
			TuWoW_RareScan_DB.windowWidth = 1150;
			TuWoW_RareScan_DB.windowHeight = 710;
		end
		NRS:Print("Posición de ventana restablecida al centro.");
	end);
	btnReset:SetPoint("BOTTOMLEFT", cardCmds, "BOTTOMLEFT", 10, 8);
	
	-- 6. Enciclopedia de 403 Rares
	local cardCatalog = CreateHelpCard(
		colRight,
		"403 Criaturas Listas para Explorar",
		"Interface\\Icons\\INV_Misc_Spyglass_03",
		134,
		"Base de Datos Completa",
		"Acceso a la enciclopedia completa de Azeroth clásica."
	);
	cardCatalog:SetPoint("TOPLEFT", cardCmds, "BOTTOMLEFT", 0, -8);
	cardCatalog:SetPoint("TOPRIGHT", cardCmds, "BOTTOMRIGHT", 0, -8);
	cardCatalog.body:SetText(
		"Dispones de la base de datos completa de Azeroth con mapas de cuadrantes, rutas de patrulla, estadísticas y modelos de criaturas.\n" ..
		"Puedes marcar tus favoritas con una estrella dorada para seguirlas de cerca."
	);
	
	local btnFavs = Theme:CreateButton(cardCatalog, "Ver Mis Rares Favoritos", 210, 22, function()
		UI.filterOnlyFavorites = true;
		UI:SetSection("radar");
		UI:RefreshRadarList();
	end);
	btnFavs:SetPoint("BOTTOMLEFT", cardCatalog, "BOTTOMLEFT", 10, 8);
end
