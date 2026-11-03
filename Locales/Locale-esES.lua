--[[****************************************************************************
  * _NPCScan by Saiket - Adapted for TuWoW (ForeverUI)                         *
  * Locales/Locale-esES.lua - Localized string constants (es-ES / es-MX).      *
  ****************************************************************************]]

if ( GetLocale() ~= "esES" and GetLocale() ~= "esMX" ) then
	return;
end

local _NPCScan = select( 2, ... );

-- Lookup table for Spanish NPC names (dynamically linked to ClassicNPCs database)
_NPCScan.L.NPCs = setmetatable( {
	[ 18684 ] = "Bro'Gaz sin Clan",
	[ 32491 ] = "Protodraco Tiempo Perdido",
	[ 33776 ] = "Gondria",
	[ 35189 ] = "Skoll",
	[ 38453 ] = "Arcturis",
}, {
	__index = function ( t, id )
		if ( _NPCScan.ClassicNPCs and _NPCScan.ClassicNPCs[ id ] ) then
			return _NPCScan.ClassicNPCs[ id ].NameES;
		end
		return rawget( t, id );
	end
} );

local L = _NPCScan.L;

L.BUTTON_FOUND = "¡PNJ encontrado!";
L.CACHED_FORMAT = "Las siguientes criaturas ya están en la caché: %s.";
L.CACHED_LONG_FORMAT = "Las siguientes criaturas ya están en la memoria del juego: %s. Para volver a rastrearlas puedes vaciar tu carpeta Cache/WDB.";
L.CACHED_PET_RESTING_FORMAT = "Las siguientes mascotas domesticables entraron en la memoria mientras descansabas: %s.";
L.CACHED_WORLD_FORMAT = "Las siguientes criaturas de %2$s ya están en la memoria: %1$s.";
L.CACHELIST_ENTRY_FORMAT = '|cff808080"%s"|r';
L.CACHELIST_SEPARATOR = ", ";

L.CMD_ADD = "ADD";
L.CMD_CACHE = "CACHE";
L.CMD_CACHE_EMPTY = "Ninguna de las criaturas buscadas está en la memoria actualmente.";
L.CMD_HELP = 'Comandos de TuWoW RareScan:\n|cff808080"/rs"|r o |cff808080"/rarescan"|r - Abrir ventana de configuración.\n|cff808080"/rs add <ID> <Nombre>"|r - Añadir criatura manual.\n|cff808080"/rs remove <ID o Nombre>"|r - Quitar criatura.\n|cff808080"/rs cache"|r - Listar criaturas en memoria.';
L.CMD_REMOVE = "REMOVE";
L.CMD_REMOVENOTFOUND_FORMAT = 'La criatura |cff808080"%s"|r no fue encontrada.';

L.CONFIG_ALERT = "Opciones de alerta";
L.CONFIG_ALERT_SOUND = "Sonido de alerta";
L.CONFIG_ALERT_SOUND_DEFAULT = "|cffffd200Predeterminado|r";
L.CONFIG_ALERT_SOUND_DESC = 'Elige el sonido que se reproducirá cuando se encuentre una criatura rara. Puedes añadir más sonidos mediante addons de |cff808080"SharedMedia"|r.';
L.CONFIG_ALERT_UNMUTE = "Activar sonido temporalmente";
L.CONFIG_ALERT_UNMUTE_DESC = "Activa brevemente el sonido del juego al encontrar una criatura si tienes el audio silenciado, para que no te pierdas la alerta.";
L.CONFIG_CACHEWARNINGS = "Avisos de memoria al entrar y cambiar de continente";
L.CONFIG_CACHEWARNINGS_DESC = "Si una criatura ya fue cargada en la memoria al iniciar sesión o cambiar de continente, muestra un recordatorio en el chat indicando qué criaturas no se pueden buscar hasta reiniciar la memoria.";
L.CONFIG_MINIMAP = "Mostrar botón en el minimapa";
L.CONFIG_MINIMAP_DESC = "Muestra u oculta el botón circular de TuWoW RareScan en el borde del minimapa (compatible con ForeverUI).";
L.CONFIG_DESC = "Estas opciones te permiten configurar el comportamiento y las alertas de TuWoW RareScan al encontrar criaturas raras en Azeroth.";
L.CONFIG_TEST = "Probar alerta";
L.CONFIG_TEST_DESC = "Simula una alerta de criatura encontrada para probar el sonido y el botón de selección.";
L.CONFIG_TEST_HELP_FORMAT = "Haz clic en el botón o usa el atajo asignado para seleccionar al objetivo encontrado. Mantén presionado |cffffffff<%s>|r y arrastra para mover el botón. (Si estás en combate, el botón esperará a que salgas de combate).";
L.CONFIG_TEST_NAME = "¡Tú! (Prueba)";
L.CONFIG_TITLE = "|cff00ccffTuWoW|r |cffffd200RareScan|r";

L.FOUND_FORMAT = '¡Encontrado |cff808080"%s"|r!';
L.FOUND_TAMABLE_FORMAT = '¡Encontrado |cff808080"%s"|r! |cffff2020(Criatura domesticable, puede ser la mascota de otro cazador)|r';
L.FOUND_TAMABLE_WRONGZONE_FORMAT = 'Falsa alarma: Se detectó la criatura domesticable |cff808080"%s"|r en %s en lugar de %s (ID %d); es una mascota.';
L.PRINT_FORMAT = "|cff00ccffTuWoW|r |cffffd200RareScan|r: %s";

L.SEARCH_ACHIEVEMENTADDFOUND = "Buscar criaturas de logros ya completados";
L.SEARCH_ACHIEVEMENTADDFOUND_DESC = "Continúa buscando todos los objetivos de logros de criaturas raras, incluso si ya los has completado.";
L.SEARCH_ACHIEVEMENT_DISABLED = "Desactivado";
L.SEARCH_ADD = "+";
L.SEARCH_ADD_DESC = "Añadir nueva criatura o guardar cambios.";
L.SEARCH_ADD_TAMABLE_FORMAT = 'Nota: |cff808080"%s"|r es domesticable; si otro cazador pasa con ella como mascota, causará una falsa alarma.';
L.SEARCH_CACHED = "En caché";
L.SEARCH_COMPLETED = "Listo";
L.SEARCH_DESC = "Esta tabla te permite añadir o quitar criaturas y logros a buscar automáticamente en TuWoW.";
L.SEARCH_ID = "ID del PNJ:";
L.SEARCH_ID_DESC = "El ID numérico del PNJ a buscar (obtenido de Wowhead o Questie).";
L.SEARCH_NAME = "Nombre:";
L.SEARCH_NAME_DESC = "Nombre o etiqueta identificativa para la criatura en la lista.";
L.SEARCH_NPCS = "Criaturas Personalizadas";
L.SEARCH_NPCS_DESC = "Añade cualquier criatura a rastrear, incluso si no pertenece a un logro.";
L.SEARCH_REMOVE = "-";
L.SEARCH_TITLE = "Búsqueda";
L.SEARCH_WORLD = "Continente:";
L.SEARCH_WORLD_DESC = "Continente o mundo al que limitar la búsqueda (1=Kalimdor, 2=Reinos del Este, o nombre de mazmorra). Déjalo vacío para buscar en cualquier lugar.";
L.SEARCH_WORLD_FORMAT = "(%s)";

-- Minimapa
L.MINIMAP_SUBTITLE = "Escáner de Criaturas Raras (TuWoW)";
L.MINIMAP_CLICK_LEFT = "Clic Izquierdo:";
L.MINIMAP_CLICK_LEFT_DESC = "Abrir configuración y buscador de rares";
L.MINIMAP_CLICK_RIGHT = "Clic Derecho:";
L.MINIMAP_CLICK_RIGHT_DESC = "Probar alerta sonora y botón (Test Alert)";
L.MINIMAP_CLICK_SHIFT = "Shift + Clic:";
L.MINIMAP_CLICK_SHIFT_DESC = "Comprobar estado de la caché en el chat";
L.MINIMAP_DRAG = "Arrastrar:";
L.MINIMAP_DRAG_DESC = "Mover este icono alrededor del minimapa";
