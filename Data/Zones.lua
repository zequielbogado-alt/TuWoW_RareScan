--[[****************************************************************************
  * TuWoW_RareScan - Data/Zones.lua                                            *
  * Diccionario de zonas y mapas nativos verificados de WotLK 3.3.5a.          *
  ****************************************************************************]]

local ADDON_NAME, NRS = ...;
NRS.Data = NRS.Data or {};

NRS.Data.Zones = {
	[0]    = { name = "Azeroth", mapFile = "World", continent = nil, isDungeon = false },
	[1]    = { name = "Dun Morogh", mapFile = "DunMorogh", continent = 2, isDungeon = false },
	[3]    = { name = "Tierras Inhospitas", mapFile = "Badlands", continent = 2, isDungeon = false },
	[4]    = { name = "Las Tierras Devastadas", mapFile = "BlastedLands", continent = 2, isDungeon = false },
	[8]    = { name = "Pantano de las Penas", mapFile = "SwampOfSorrows", continent = 2, isDungeon = false },
	[10]   = { name = "Bosque del Ocaso", mapFile = "Duskwood", continent = 2, isDungeon = false },
	[11]   = { name = "Los Humedales", mapFile = "Wetlands", continent = 2, isDungeon = false },
	[12]   = { name = "Bosque de Elwynn", mapFile = "Elwynn", continent = 2, isDungeon = false },
	[14]   = { name = "Durotar", mapFile = "Durotar", continent = 1, isDungeon = false },
	[15]   = { name = "Marjal Revolcafango", mapFile = "Dustwallow", continent = 1, isDungeon = false },
	[16]   = { name = "Azshara", mapFile = "Aszhara", continent = 1, isDungeon = false },
	[17]   = { name = "Los Baldios", mapFile = "Barrens", continent = 1, isDungeon = false },
	[28]   = { name = "Tierras de la Peste del Oeste", mapFile = "WesternPlaguelands", continent = 2, isDungeon = false },
	[33]   = { name = "Vega de Tuercespina", mapFile = "Stranglethorn", continent = 2, isDungeon = false },
	[36]   = { name = "Montanas de Alterac", mapFile = "Alterac", continent = 2, isDungeon = false },
	[38]   = { name = "Loch Modan", mapFile = "LochModan", continent = 2, isDungeon = false },
	[40]   = { name = "Paramos de Poniente", mapFile = "Westfall", continent = 2, isDungeon = false },
	[41]   = { name = "Paso de la Muerte", mapFile = "DeadwindPass", continent = 2, isDungeon = false },
	[44]   = { name = "Montanas Crestagrana", mapFile = "Redridge", continent = 2, isDungeon = false },
	[45]   = { name = "Tierras Altas de Arathi", mapFile = "Arathi", continent = 2, isDungeon = false },
	[46]   = { name = "Las Estepas Ardientes", mapFile = "BurningSteppes", continent = 2, isDungeon = false },
	[47]   = { name = "Tierras del Interior", mapFile = "Hinterlands", continent = 2, isDungeon = false },
	[51]   = { name = "La Garganta de Fuego", mapFile = "SearingGorge", continent = 2, isDungeon = false },
	[85]   = { name = "Claros de Tirisfal", mapFile = "Tirisfal", continent = 2, isDungeon = false },
	[130]  = { name = "Bosque de Argenteos", mapFile = "Silverpine", continent = 2, isDungeon = false },
	[139]  = { name = "Tierras de la Peste del Este", mapFile = "EasternPlaguelands", continent = 2, isDungeon = false },
	[141]  = { name = "Teldrassil", mapFile = "Teldrassil", continent = 1, isDungeon = false },
	[148]  = { name = "Costa Oscura", mapFile = "Darkshore", continent = 1, isDungeon = false },
	[209]  = { name = "Castillo de Colmillo Oscuro (Argenteos)", mapFile = "Silverpine", continent = 2, isDungeon = true },
	[215]  = { name = "Mulgore", mapFile = "Mulgore", continent = 1, isDungeon = false },
	[267]  = { name = "Laderas de Trabalomas", mapFile = "Hilsbrad", continent = 2, isDungeon = false },
	[331]  = { name = "Vallefresno", mapFile = "Ashenvale", continent = 1, isDungeon = false },
	[357]  = { name = "Feralas", mapFile = "Feralas", continent = 1, isDungeon = false },
	[361]  = { name = "Frondavil", mapFile = "Felwood", continent = 1, isDungeon = false },
	[400]  = { name = "Las Mil Agujas", mapFile = "ThousandNeedles", continent = 1, isDungeon = false },
	[405]  = { name = "Desolace", mapFile = "Desolace", continent = 1, isDungeon = false },
	[406]  = { name = "Sierra Espolon", mapFile = "StonetalonMountains", continent = 1, isDungeon = false },
	[440]  = { name = "Tanaris", mapFile = "Tanaris", continent = 1, isDungeon = false },
	[490]  = { name = "Crater de Un'Goro", mapFile = "UngoroCrater", continent = 1, isDungeon = false },
	[491]  = { name = "Horno Dragon (Los Baldios)", mapFile = "Barrens", continent = 1, isDungeon = true },
	[618]  = { name = "Cuna del Invierno", mapFile = "Winterspring", continent = 1, isDungeon = false },
	[717]  = { name = "Las Mazmorras (Ventormenta)", mapFile = "Stormwind", continent = 2, isDungeon = true },
	[718]  = { name = "Cuevas de los Lamentos (Los Baldios)", mapFile = "Barrens", continent = 1, isDungeon = true },
	[721]  = { name = "Gnomeregan (Dun Morogh)", mapFile = "DunMorogh", continent = 2, isDungeon = true },
	[796]  = { name = "Monasterio Escarlata (Tirisfal)", mapFile = "Tirisfal", continent = 2, isDungeon = true },
	[1176] = { name = "Zul'Farrak (Tanaris)", mapFile = "Tanaris", continent = 1, isDungeon = true },
	[1377] = { name = "Silithus", mapFile = "Silithus", continent = 1, isDungeon = false },
	[1477] = { name = "El Templo de Atal'Hakkar (Penas)", mapFile = "SwampOfSorrows", continent = 2, isDungeon = true },
	[1497] = { name = "Entranas", mapFile = "Undercity", continent = 2, isDungeon = false },
	[1519] = { name = "Ciudad de Ventormenta", mapFile = "Stormwind", continent = 2, isDungeon = false },
	[1537] = { name = "Forjaz", mapFile = "Ironforge", continent = 2, isDungeon = false },
	[1581] = { name = "Las Minas de la Muerte (Poniente)", mapFile = "Westfall", continent = 2, isDungeon = true },
	[1583] = { name = "Cumbre de Roca Negra (Estepas)", mapFile = "BurningSteppes", continent = 2, isDungeon = true },
	[1584] = { name = "Profundidades de Roca Negra (Estepas)", mapFile = "BurningSteppes", continent = 2, isDungeon = true },
	[1585] = { name = "Profundidades de Roca Negra (Estepas)", mapFile = "BurningSteppes", continent = 2, isDungeon = true },
	[1637] = { name = "Orgrimmar", mapFile = "Ogrimmar", continent = 1, isDungeon = false },
	[1638] = { name = "Cima del Trueno", mapFile = "ThunderBluff", continent = 1, isDungeon = false },
	[1657] = { name = "Darnassus", mapFile = "Darnassis", continent = 1, isDungeon = false },
	[1977] = { name = "Zul'Gurub (Tuercespina)", mapFile = "Stranglethorn", continent = 2, isDungeon = true },
	[2017] = { name = "Stratholme (Peste del Este)", mapFile = "EasternPlaguelands", continent = 2, isDungeon = true },
	[2057] = { name = "Scholomance (Peste del Oeste)", mapFile = "WesternPlaguelands", continent = 2, isDungeon = true },
	[2100] = { name = "Maraudon (Desolace)", mapFile = "Desolace", continent = 1, isDungeon = true },
	[2557] = { name = "La Masacre (Feralas)", mapFile = "Feralas", continent = 1, isDungeon = true },
	[2597] = { name = "Valle de Alterac", mapFile = "Alterac", continent = 2, isDungeon = false },
	
	-- Zonas de Rasganorte (WotLK 3.3.5a)
	[493]  = { name = "Cuenca de Sholazar", mapFile = "SholazarBasin", continent = 571, isDungeon = false },
	[490]  = { name = "Colinas Pardas", mapFile = "GrizzlyHills", continent = 571, isDungeon = false },
	[496]  = { name = "Zul'Drak", mapFile = "ZulDrak", continent = 571, isDungeon = false },
	[495]  = { name = "Las Cumbres Tormentosas", mapFile = "StormPeaks", continent = 571, isDungeon = false },
	[486]  = { name = "Tundra Boreal", mapFile = "BoreanTundra", continent = 571, isDungeon = false },
	[491]  = { name = "Fiordo Aquilonal", mapFile = "HowlingFjord", continent = 571, isDungeon = false },
	[488]  = { name = "Cementerio de Dragones", mapFile = "Dragonblight", continent = 571, isDungeon = false },
	[492]  = { name = "Corona de Hielo", mapFile = "IcecrownGlacier", continent = 571, isDungeon = false },
	[494]  = { name = "Bosque Canto de Cristal", mapFile = "CrystalsongForest", continent = 571, isDungeon = false },
	
	-- Zonas Insulares y Expansiones
	[3524] = { name = "Isla Bruma Azur", mapFile = "AzuremystIsle", continent = 1, isDungeon = false },
	[3525] = { name = "Isla Bruma de Sangre", mapFile = "BloodmystIsle", continent = 1, isDungeon = false },
	[3523] = { name = "Tormenta Abisal", mapFile = "Netherstorm", continent = 530, isDungeon = false },
	[3520] = { name = "Valle Sombraluna", mapFile = "ShadowmoonValley", continent = 530, isDungeon = false },
};

NRS.Data.Families = {
	[1]  = { name = "Bestia", icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat" },
	[2]  = { name = "Dragonante", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
	[3]  = { name = "Demonio", icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter" },
	[4]  = { name = "Elemental", icon = "Interface\\Icons\\Spell_Fire_Elemental_Devastation" },
	[5]  = { name = "Gigante", icon = "Interface\\Icons\\Ability_Racial_Avatar" },
	[6]  = { name = "No-muerto", icon = "Interface\\Icons\\Spell_Shadow_RaiseDead" },
	[7]  = { name = "Humanoide", icon = "Interface\\Icons\\INV_Misc_Head_Human_01" },
	[8]  = { name = "Alimana", icon = "Interface\\Icons\\Ability_Hunter_Pet_Critter" },
	[9]  = { name = "Mecanico", icon = "Interface\\Icons\\INV_Misc_Gear_01" },
	[10] = { name = "Desconocido", icon = "Interface\\Icons\\INV_Misc_MonsterClaw_04" },
};

function NRS:GetZoneInfo(zoneID)
	return self.Data.Zones[zoneID or 0] or { name = "Azeroth", mapFile = "World", continent = nil, isDungeon = false };
end

function NRS:GetFamilyInfo(familyID)
	return self.Data.Families[familyID or 10] or self.Data.Families[10];
end

function NRS:GetRankText(rank)
	if rank == 4 then return "Elite Raro", 1.0, 0.8, 0.0;
	elseif rank == 1 then return "Elite", 1.0, 0.8, 0.0;
	else return "Raro", 0.0, 0.8, 1.0; end
end
