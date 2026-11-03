--[[****************************************************************************
  * TuWoW_RareScan - UI/ModelViewer.lua                                        *
  * Escenario de exhibicion grafica (Pedestal + Retrato 2D / Visor 3D WotLK)   *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
NRS.UI = NRS.UI or {};

local ModelViewer = {};
NRS.UI.ModelViewer = ModelViewer;

function ModelViewer:Create(parent)
	local container = CreateFrame("Frame", nil, parent);
	NRS.Theme:ApplyPanel(container, true);
	container.is3DMode = false;
	
	-- Fondo oscuro con tenue viñeta
	local bg = container:CreateTexture(nil, "BACKGROUND", nil, -8);
	bg:SetAllPoints(container);
	NRS.Theme:SetSolidColor(bg, 0.012, 0.015, 0.022, 0.96);
	
	-- Pedestal mistico rúnico con cristales azules (Asset en TGA 512x256)
	local pedestal = container:CreateTexture(nil, "BACKGROUND", nil, -1);
	pedestal:SetTexture("Interface\\AddOns\\TuWoW_RareScan\\Assets\\Pedestal");
	pedestal:SetPoint("BOTTOM", container, "BOTTOM", 0, -2);
	pedestal:SetSize(250, 125);
	container.pedestal = pedestal;
	
	-- Retrato 2D de alta resolución (256x256 con transparencia perfecta)
	local portrait = container:CreateTexture(nil, "ARTWORK", nil, 1);
	portrait:SetPoint("BOTTOM", container, "BOTTOM", 0, 24);
	portrait:SetSize(165, 165);
	container.portrait = portrait;
	
	-- Marco 3D nativo PlayerModel de 3.3.5a (Modo alternativo)
	local model = CreateFrame("PlayerModel", nil, container);
	model:SetPoint("TOPLEFT", 6, -20);
	model:SetPoint("BOTTOMRIGHT", -6, 22);
	model:EnableMouse(true);
	model:EnableMouseWheel(true);
	model:Hide();
	container.model = model;
	
	model.rotation = 0.61;
	model.zoom = 0;
	model.isDragging = false;
	model.lastX = 0;
	
	-- Rotacion con arrastre de raton en 3D
	model:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self.isDragging = true;
			self.lastX = GetCursorPosition();
		elseif button == "RightButton" then
			self.rotation = 0.61;
			self:SetFacing(self.rotation);
			if self.SetPosition then self:SetPosition(0, 0, 0); end
			if self.SetModelScale then self:SetModelScale(1.0); end
		end
	end);
	
	model:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self.isDragging = false;
		end
	end);
	
	model:HookScript("OnUpdate", function(self, elapsed)
		if self.isDragging then
			local curX = GetCursorPosition();
			local scale = self:GetEffectiveScale();
			local delta = (curX - self.lastX) / scale;
			self.lastX = curX;
			self.rotation = (self.rotation + delta * 0.025) % (math.pi * 2);
			self:SetFacing(self.rotation);
		end
	end);
	
	-- Zoom con rueda del raton en 3D
	model:SetScript("OnMouseWheel", function(self, delta)
		if self.SetPosition then
			self.zoom = math.max(-2, math.min(3, (self.zoom or 0) + delta * 0.3));
			local curX, curY, curZ = self:GetPosition();
			self:SetPosition(curX or 0, (curY or 0) + delta * 0.25, curZ or 0);
		end
	end);
	
	-- Leyenda inferior de controles (solo en 3D)
	local hint = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	hint:SetPoint("BOTTOM", container, "BOTTOM", 0, 4);
	hint:SetText("Arrastra para rotar | Clic der: Reset");
	hint:SetTextColor(unpack(NRS.Theme.colors.muted));
	hint:Hide();
	container.hint = hint;
	
	-- Etiqueta de aviso superior izquierdo
	local statusLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	statusLabel:SetPoint("TOPLEFT", container, "TOPLEFT", 8, -6);
	statusLabel:SetText("|cff88aacc[Retrato 2D]|r");
	container.statusLabel = statusLabel;
	
	-- Boton para alternar modo 2D / 3D
	local btnToggle = NRS.Theme:CreateButton(container, "3D", 38, 18, function()
		container.is3DMode = not container.is3DMode;
		ModelViewer:RefreshDisplayMode(container);
	end);
	btnToggle:SetPoint("TOPRIGHT", container, "TOPRIGHT", -6, -5);
	container.btnToggle = btnToggle;
	
	return container;
end

function ModelViewer:RefreshDisplayMode(container)
	if not container or not container.currentRecord then return end
	local record = container.currentRecord;
	local model = container.model;
	local portrait = container.portrait;
	
	if container.is3DMode then
		-- Modo 3D
		container.btnToggle.text:SetText("2D");
		portrait:Hide();
		model:Show();
		if container.hint then container.hint:Show(); end
		if container.statusLabel then
			container.statusLabel:SetText("|cffffd200[Modelo 3D]|r");
		end
		
		model:ClearModel();
		model.rotation = 0.61;
		model:SetFacing(0.61);
		if model.SetModelScale then model:SetModelScale(1.0); end
		if model.SetPosition then model:SetPosition(0, 0, 0); end
		
		if record.id and record.id > 0 then
			pcall(function() model:SetCreature(record.id); end);
		end
	else
		-- Modo 2D (Default con pedestal)
		container.btnToggle.text:SetText("3D");
		model:Hide();
		portrait:Show();
		if container.hint then container.hint:Hide(); end
		if container.statusLabel then
			container.statusLabel:SetText("|cff88aacc[Ficha Rara]|r");
		end
		
		-- Intentar cargar textura TGA local
		local path = "Interface\\AddOns\\TuWoW_RareScan\\Assets\\Portraits\\" .. record.id;
		portrait:SetTexture(path);
	end
end

function ModelViewer:SetCreature(container, targetOrID, familyID)
	if not container then return end
	
	local record = nil;
	if type(targetOrID) == "table" then
		record = targetOrID;
	elseif type(targetOrID) == "number" then
		record = { id = targetOrID, family = familyID, name = "" };
	end
	if not record then return end
	
	container.currentRecord = record;
	ModelViewer:RefreshDisplayMode(container);
end
