--[[
	TuWoW_RareScan: CreatureDetails.lua
	Base de datos ampliada y generador de fichas tecnicas (Estadisticas, Lore y Consejos Hardcore)
	Compatible con cliente WoW 3.3.5a / ForeverUI
]]

local NRS = select(2, ...);
NRS.CreatureDetails = {};
local CD = NRS.CreatureDetails;

-- Iconos representativos de cada familia de criatura
local FAMILY_ICONS = {
	[1]  = "Interface\\Icons\\Ability_Hunter_Pet_Cat",               -- Bestia
	[2]  = "Interface\\Icons\\INV_Misc_Head_Dragon_01",              -- Dragon
	[3]  = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",         -- Demonio
	[4]  = "Interface\\Icons\\Spell_Fire_Elemental_Devastation",     -- Elemental
	[5]  = "Interface\\Icons\\Ability_Racial_Avatar",                -- Gigante
	[6]  = "Interface\\Icons\\Spell_Shadow_DeathScream",             -- No-muerto
	[7]  = "Interface\\Icons\\Achievement_Character_Human_Male",     -- Humanoide
	[8]  = "Interface\\Icons\\INV_Misc_MonsterClaw_04",              -- Alimaña / Monstruosidad
	[9]  = "Interface\\Icons\\INV_Gizmo_02",                         -- Mecanico
	[10] = "Interface\\Icons\\INV_Misc_MonsterClaw_02",              -- Inclasificado
};

-- Base de Lore / Consejos de Supervivencia para criaturas emblemáticas
local SPECIAL_LORE = {
	[14430] = { -- Acechapolvo (Duskstalker)
		lore = "Acecha sigilosamente en las sombras de Teldrassil. Ataca por sorpresa con gran rapidez e inflige heridas sangrantes.",
		speed = "0.8 s",
	},
	[462] = { -- Vultros
		lore = "Pájaro carroñero gigante que aterroriza los campos de Colinas del Poniente. Desciende a gran velocidad sobre viajeros desprevenidos.",
		speed = "1.0 s",
	},
	[14222] = { -- Araga
		lore = "Feroz leona moteada que merodea las montañas de las Montañas de Alterac. Muy codiciada por cazadores expertos.",
		speed = "1.0 s",
	},
	[5822] = { -- Hoarfang
		lore = "Lobo blanco antiguo que caza en las estepas heladas de Dun Morogh. Capaz de ralentizar a sus presas con mordeduras gélidas.",
		speed = "1.2 s",
	},
	[14431] = { -- Furia Shelda
		lore = "Arácnida solitaria de los bosques nocturnos. Sus picaduras inyectan un potente veneno que debilita la resistencia física.",
		speed = "0.9 s",
	},
	[14432] = { -- Threggil
		lore = "Sátiro corrupto que practica artes oscuras en Teldrassil. Lanza maldiciones y suele tener esbirros leales cerca.",
		speed = "1.5 s",
	},
	[596] = { -- Mente Cerebro
		lore = "Múrloc legendario de los lagos de Bosque de Elwynn. En modo Hardcore, ten extremo cuidado con los múrlocs adyacentes.",
		speed = "1.4 s",
	},
	[14424] = { -- Mirelow
		lore = "Caminante de pantano en Los Humedales. Su densa corteza vegetal absorbe daño masivo antes de ceder.",
		speed = "2.0 s",
	},
	[8280] = { -- Shleipnarr
		lore = "Enorme demonio infernal que patrulla La Garganta de Fuego. Desata olas de fuego y ataques devastadores.",
		speed = "1.8 s",
	},
	[8296] = { -- Mojo el Retorcido
		lore = "Ogro hechicero exiliado en Las Tierras Devastadas. Combina fuerza descomunal con ráfagas mágicas arcanas.",
		speed = "1.6 s",
	},
	[8281] = { -- Scald
		lore = "Draco de lava ardiente que anida en las grietas de La Garganta de Fuego. Escupe aliento ígneo en cono frontal.",
		speed = "1.7 s",
	},
};

-- Formateador de números con punto de miles (ej: 1312 -> "1.312")
local function FormatNumber(val)
	if not val or val == 0 then return "0"; end
	local s = tostring(math.floor(val));
	local k;
	while true do
		s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", '%1.%2');
		if (k == 0) then break; end
	end
	return s;
end

-- Calcula o genera la ficha técnica completa
function NRS:GetCreatureDetails(record)
	if not record then return nil; end
	
	local lvl = record.minLvl or 1;
	local isElite = (record.rank == 2);
	local hp = record.minHP or (lvl * 35);
	
	-- Cálculo de Daño estimado según nivel y rango (Canónico 3.3.5a Classic)
	local minDmg, maxDmg;
	if isElite then
		minDmg = math.floor(lvl * 4.2 + 8);
		maxDmg = math.floor(lvl * 5.8 + 14);
	else
		minDmg = math.floor(lvl * 2.2 + 3);
		maxDmg = math.floor(lvl * 3.4 + 7);
	end
	if minDmg < 1 then minDmg = 1; end
	if maxDmg <= minDmg then maxDmg = minDmg + 2; end
	local dmgStr = string.format("%s - %s", FormatNumber(minDmg), FormatNumber(maxDmg));
	
	-- Cálculo de Armadura estimada según nivel y rango
	local armorVal = isElite and math.floor(lvl * 58 + 40) or math.floor(lvl * 36 + 20);
	local armorStr = FormatNumber(armorVal);
	
	-- Familia e icono
	local famInfo = NRS:GetFamilyInfo(record.family);
	local famIcon = FAMILY_ICONS[record.family] or "Interface\\Icons\\INV_Misc_MonsterClaw_02";
	
	-- Velocidad de ataque
	local speedStr = "1.5 s";
	if record.family == 1 then -- Bestias rápidas
		speedStr = "1.0 s";
	elseif record.family == 5 then -- Gigantes
		speedStr = "2.2 s";
	elseif isElite then
		speedStr = "1.8 s";
	end
	
	-- Amenaza Hardcore
	local threatStr, threatColor;
	if isElite then
		threatStr = "Crítica";
		threatColor = { 1.0, 0.25, 0.25 }; -- Rojo
	else
		threatStr = "Moderada";
		threatColor = { 1.0, 0.75, 0.15 }; -- Naranja dorado
	end
	
	-- Lore / Consejo de combate
	local loreStr;
	if SPECIAL_LORE[record.id] then
		loreStr = SPECIAL_LORE[record.id].lore;
		if SPECIAL_LORE[record.id].speed then
			speedStr = SPECIAL_LORE[record.id].speed;
		end
	else
		local zinfo = NRS:GetZoneInfo(record.zoneID);
		local zname = zinfo and zinfo.name or "Azeroth";
		if isElite then
			loreStr = string.format("Criatura Elite singular de %s. Cuenta con resistencia aumentada y daño letal. Se aconseja enfrentar con apoyo o consumibles.", zname);
		elseif record.family == 1 then
			loreStr = string.format("Especie exótica que patrulla las tierras de %s. Suele contar con ataques rápidos y botín poco común.", zname);
		elseif record.family == 6 or record.family == 3 then
			loreStr = string.format("Presencia oscura avistada en %s. Emplea habilidades debilitantes de sombras y fuego.", zname);
		elseif record.family == 7 then
			loreStr = string.format("Líder proscrito que deambula por %s. ¡Cuidado con sus aliados o esbirros en las inmediaciones!", zname);
		else
			loreStr = string.format("Espécimen raro catalogado en %s. Al ser derrotado puede soltar equipo excepcional.", zname);
		end
	end
	
	return {
		hp = hp,
		hpStr = FormatNumber(hp),
		speedStr = speedStr,
		dmgStr = dmgStr,
		armorVal = armorVal,
		armorStr = armorStr,
		familyStr = famInfo.name,
		familyIcon = famIcon,
		threatStr = threatStr,
		threatColor = threatColor,
		lore = loreStr,
	};
end

