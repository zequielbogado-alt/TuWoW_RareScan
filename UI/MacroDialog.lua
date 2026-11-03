--[[****************************************************************************
  * TuWoW_RareScan - UI/MacroDialog.lua                                         *
  * Dialogo emergente para copiar y crear macros de tameo rapidamente         *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
local UI = NRS.UI or {};
NRS.UI = UI;
local Theme = NRS.Theme;

function UI:ShowMacroCopyDialog(pet)
	if not pet then return end
	if not self.macroDialog then
		local d = CreateFrame("Frame", "TuWoW_HunterMacroDialog", UIParent);
		d:SetSize(470, 270);
		d:SetPoint("CENTER", UIParent, "CENTER", 0, 50);
		d:SetFrameStrata("DIALOG");
		d:SetClampedToScreen(true);
		d:SetMovable(true);
		d:EnableMouse(true);
		Theme:ApplyPanel(d, true);
		d:SetBackdropBorderColor(unpack(Theme.colors.gold));
		table.insert(UISpecialFrames, "TuWoW_HunterMacroDialog");
		
		-- Barra superior de arrastre
		local drag = CreateFrame("Frame", nil, d);
		drag:SetPoint("TOPLEFT", 6, -6);
		drag:SetPoint("TOPRIGHT", -6, -6);
		drag:SetHeight(32);
		drag:EnableMouse(true);
		drag:RegisterForDrag("LeftButton");
		drag:SetScript("OnDragStart", function() d:StartMoving(); end);
		drag:SetScript("OnDragStop", function() d:StopMovingOrSizing(); end);
		
		local icon = drag:CreateTexture(nil, "ARTWORK");
		icon:SetSize(20, 20);
		icon:SetPoint("LEFT", 8, 0);
		icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot");
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
		
		local title = drag:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		title:SetPoint("LEFT", icon, "RIGHT", 8, 0);
		title:SetTextColor(unpack(Theme.colors.gold));
		d.title = title;
		
		local close = CreateFrame("Button", nil, d, "UIPanelCloseButton");
		close:SetPoint("TOPRIGHT", -4, -4);
		close:SetScript("OnClick", function() d:Hide(); end);
		
		local hint = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		hint:SetPoint("TOPLEFT", drag, "BOTTOMLEFT", 6, -4);
		hint:SetPoint("TOPRIGHT", drag, "BOTTOMRIGHT", -6, -4);
		hint:SetJustifyH("LEFT");
		hint:SetText("|cffffd200Texto seleccionado listo para copiar (Presiona Ctrl + C):|r\n|cffaaaaaaO haz clic en \"Crear Macro en WoW\" para guardarla directamente en tu juego.|r");
		
		-- Cuadro de texto de macro
		local inset = CreateFrame("Frame", nil, d);
		inset:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8);
		inset:SetPoint("BOTTOMRIGHT", -12, 46);
		Theme:ApplyPanel(inset, true);
		inset:SetBackdropColor(0.02, 0.02, 0.035, 0.95);
		inset:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.9);
		
		local scroll = CreateFrame("ScrollFrame", "TuWoW_MacroEditScroll", inset, "UIPanelScrollFrameTemplate");
		scroll:SetPoint("TOPLEFT", 8, -8);
		scroll:SetPoint("BOTTOMRIGHT", -26, 8);
		
		local edit = CreateFrame("EditBox", nil, scroll);
		edit:SetMultiLine(true);
		edit:SetWidth(390);
		edit:SetFontObject("GameFontHighlight");
		edit:SetAutoFocus(true);
		edit:SetScript("OnEscapePressed", function() d:Hide(); end);
		scroll:SetScrollChild(edit);
		d.edit = edit;
		
		-- Botones inferiores
		local btnCreate = Theme:CreateButton(d, "Crear Macro en WoW", 180, 26, function()
			if not d.currentPet then return end
			local p = d.currentPet;
			local mName = "Tamear " .. (p.name:sub(1, 8));
			local mBody = p.macro or "/cast Domesticar bestia";
			local numGlobal, numChar = GetNumMacros();
			local created = false;
			
			if numChar < 18 then
				local idx = CreateMacro(mName, "Ability_Hunter_BeastCall", mBody, 1);
				if idx and idx > 0 then
					created = true;
					NRS:Print(string.format("¡Macro '|cffffd200%s|r' creada con éxito en tu pestaña de personaje!", mName));
				end
			elseif numGlobal < 36 then
				local idx = CreateMacro(mName, "Ability_Hunter_BeastCall", mBody, nil);
				if idx and idx > 0 then
					created = true;
					NRS:Print(string.format("¡Macro '|cffffd200%s|r' creada con éxito en tu pestaña general!", mName));
				end
			else
				NRS:Print("No tienes espacios libres de macros. Usa Ctrl + C para copiar el texto.");
			end
			
			if created then
				pcall(PlaySound, "igMainMenuOptionCheckBoxOn");
				d:Hide();
			end
		end);
		btnCreate:SetPoint("BOTTOMLEFT", 12, 10);
		btnCreate.text:SetTextColor(unpack(Theme.colors.gold));
		
		local btnClose = Theme:CreateButton(d, "Cerrar", 80, 26, function() d:Hide(); end);
		btnClose:SetPoint("BOTTOMRIGHT", -12, 10);
		
		self.macroDialog = d;
	end
	
	local d = self.macroDialog;
	d.currentPet = pet;
	d.title:SetText(string.format("Macro de Tameo: %s", pet.name));
	d.edit:SetText(pet.macro or "/cast Domesticar bestia");
	d:Show();
	d.edit:SetFocus();
	d.edit:HighlightText();
end

