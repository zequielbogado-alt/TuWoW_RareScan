--[[****************************************************************************
  * TuWoW_RareScan - UI/Theme.lua                                              *
  * Paleta visual, bordes dorados y componentes modernos adaptados a 3.3.5a.    *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
NRS.UI = NRS.UI or {};
NRS.UI.CURRENT_VERSION = "2.0";
NRS.Theme = NRS.Theme or {};

local Theme = NRS.Theme;

Theme.colors = {
	background = { 0.025, 0.03, 0.045, 0.98 },
	panel      = { 0.055, 0.065, 0.085, 0.97 },
	panelAlt   = { 0.085, 0.095, 0.12, 0.95 },
	gold       = { 0.93, 0.72, 0.25, 1 },
	goldDim    = { 0.48, 0.36, 0.14, 1 },
	text       = { 0.92, 0.9, 0.82, 1 },
	muted      = { 0.58, 0.6, 0.66, 1 },
	success    = { 0.31, 0.82, 0.48, 1 },
	danger     = { 0.92, 0.3, 0.26, 1 },
	info       = { 0.28, 0.65, 0.90, 1 },
};

Theme.backdrop = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
};

Theme.cardBackdrop = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 10,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
};

function Theme:ApplyPanel(frame, alternate)
	if not frame or not frame.SetBackdrop then return end
	frame:SetBackdrop(self.backdrop);
	frame:SetBackdropColor(unpack(alternate and self.colors.panelAlt or self.colors.panel));
	frame:SetBackdropBorderColor(unpack(self.colors.goldDim));
end

function Theme:ApplyButton(button)
	if not button then return end
	if button.SetBackdrop then
		button:SetBackdrop(self.cardBackdrop);
		button:SetBackdropColor(0.08, 0.09, 0.12, 1);
		button:SetBackdropBorderColor(unpack(self.colors.goldDim));
	end
	button:SetScript("OnEnter", function(self)
		if self.SetBackdropColor then self:SetBackdropColor(0.18, 0.15, 0.09, 1); end
		if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(Theme.colors.gold)); end
	end);
	button:SetScript("OnLeave", function(self)
		if self.SetBackdropColor then self:SetBackdropColor(0.08, 0.09, 0.12, 1); end
		if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(Theme.colors.goldDim)); end
	end);
end

function Theme:SetSolidColor(texture, r, g, b, a)
	if not texture then return end
	texture:SetTexture("Interface\\Buttons\\WHITE8X8");
	texture:SetVertexColor(r, g, b, a or 1);
end

-- Componentes de Interfaz
function Theme:CreateLabel(parent, text, size, color)
	local font = "GameFontNormal";
	if size == "large" then font = "GameFontNormalLarge";
	elseif size == "small" then font = "GameFontNormalSmall";
	elseif size == "title" then font = "GameFontNormalHuge"; end
	
	local label = parent:CreateFontString(nil, "OVERLAY", font);
	label:SetText(text or "");
	label:SetJustifyH("LEFT");
	if color then
		label:SetTextColor(unpack(color));
	else
		label:SetTextColor(unpack(self.colors.text));
	end
	return label;
end

function Theme:CreateButton(parent, text, width, height, callback)
	local button = CreateFrame("Button", nil, parent);
	button:SetSize(width or 110, height or 28);
	self:ApplyButton(button);
	
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	button.text:SetPoint("CENTER");
	button.text:SetText(text or "");
	button.text:SetTextColor(unpack(self.colors.text));
	
	if callback then
		button:SetScript("OnClick", callback);
	end
	return button;
end

function Theme:CreateEditBox(parent, width, height)
	local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate");
	edit:SetSize(width or 220, height or 26);
	edit:SetAutoFocus(false);
	edit:SetFontObject("ChatFontNormal");
	edit:SetTextInsets(6, 6, 0, 0);
	return edit;
end

function Theme:CreateDivider(parent)
	local line = parent:CreateTexture(nil, "ARTWORK");
	line:SetHeight(1);
	self:SetSolidColor(line, self.colors.goldDim[1], self.colors.goldDim[2], self.colors.goldDim[3], 0.6);
	return line;
end

function Theme:CreateCheckbox(parent, text, initialValue, onClick, tooltipTitle, tooltipDesc)
	Theme.cbCounter = (Theme.cbCounter or 0) + 1;
	local name = "TuWoW_RareScan_CB_" .. Theme.cbCounter;
	local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate");
	cb:SetSize(24, 24);
	if cb.SetHitRectInsets then cb:SetHitRectInsets(0, 0, 0, 0); end
	cb:SetChecked(initialValue and true or false);
	
	local textLabel = _G[name .. "Text"] or cb.text;
	if not textLabel then
		textLabel = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
		cb.text = textLabel;
	end
	textLabel:ClearAllPoints();
	textLabel:SetPoint("LEFT", cb, "RIGHT", 4, 1);
	textLabel:SetText(text or "");
	textLabel:SetTextColor(unpack(self.colors.text));
	
	cb:SetScript("OnClick", function(self)
		local checked = self:GetChecked() and true or false;
		if onClick then onClick(checked); end
	end);
	
	if tooltipTitle and tooltipDesc then
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
			GameTooltip:AddLine(tooltipTitle, 0.93, 0.72, 0.25);
			GameTooltip:AddLine(tooltipDesc, 0.85, 0.88, 0.93, true);
			GameTooltip:Show();
		end);
		cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end
	
	return cb;
end

