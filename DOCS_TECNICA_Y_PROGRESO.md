# TuWoW RareScan v2.0 - Documentación Técnica, Arquitectura y Registro de Progreso

Este documento consolida la arquitectura interna, lecciones aprendidas, errores corregidos ("gotchas") y directrices de desarrollo para el addon **TuWoW RareScan** adaptado para el cliente híbrido de **TuWoW (WoW 3.3.5a + ForeverUI)**.

---

## 🏛️ 1. Arquitectura General y Modularidad

Originalmente derivado de `_NPCScan` v3.3.5.5 (orientado exclusivamente a expansiones WotLK/TBC con menús arcaicos de Blizzard), TuWoW RareScan fue completamente rediseñado y desacoplado en una arquitectura modular orientada a eventos, rendimiento a 60 FPS y una estética oscura y dorada basada en **ForeverUI / ForeverGM**.

### Estructura de Directorios y Carga Secuencial (`TuWoW_RareScan.toc`)

```
TuWoW_RareScan/
├── Assets/
│   ├── ForeverGM-Emblem.tga        # Emblema oficial en alta resolución
│   ├── ForeverGM-Minimap-v2.tga    # Icono circular para el minimapa
│   ├── Pedestal.tga                # Pedestal 3D / 2D para rares estándar
│   ├── PedestalHunter.tga          # Pedestal rústico con runa y piel para cazadores
│   ├── Portraits/                  # Retratos 2D en formato TGA (<NpcID>.tga)
│   └── Sounds/                     # Audios de rugidos en PCM WAV 16-bit 44.1kHz
├── Data/
│   ├── Zones.lua                   # Diccionario de zonas, mapas y familias
│   ├── CreatureDetails.lua         # Estadísticas dinámicas, armadura, daño y tips
│   └── HunterPets.lua              # Base de datos de las 21 mascotas exóticas y raras
├── Libs/                           # AceEvent-3.0, LibStub, CallbackHandler, LibSharedMedia
├── Locales/                        # Traducciones completas en español (esES / esMX) y otros
├── UI/
│   ├── Theme.lua                   # Sistema de diseño ForeverUI (paleta, paneles, botones)
│   ├── ModelViewer.lua             # Visor 3D interactivo con rotación por ratón
│   ├── ZoneMapPreview.lua          # Minimapa con coordenadas y pines reactivos
│   ├── MacroDialog.lua             # Diálogo emergente para copiar y autogenerar macros
│   ├── PageRadar.lua               # Pestaña Radar y Rares (3 columnas, Virtual Scroll)
│   ├── PageAlerts.lua              # Pestaña Alertas, Sonidos y Opciones de Rastreo
│   ├── PageMemory.lua              # Pestaña Explicación y Diagnóstico de Memoria WDB
│   ├── PageHelp.lua                # Pestaña Guía interactiva y comandos
│   ├── PageHunter.lua              # Pestaña Santuario de Mascotas Exóticas (BM Hunter)
│   └── MainWindow.lua              # Marco principal, cabecera, navegación y redimensionado
├── TuWoW_RareScan.ClassicData.lua  # Base de datos de 403 rares clásicos (1-60)
├── TuWoW_RareScan.Button.lua       # Botón emergente seguro de tarjeteo y alerta en pantalla
├── TuWoW_RareScan.Overlays.lua     # Integración con rutas de mapa
├── TuWoW_RareScan.Minimap.lua      # Botón orbital del minimapa ForeverUI
└── TuWoW_RareScan.lua              # Escaneo de paquetes del servidor y motor central
```

---

## 🧠 2. Lecciones Críticas y Errores Evitados ("Gotchas")

A continuación se detallan los fallos técnicos resueltos a lo largo del desarrollo para que **jamás** se repitan en futuras iteraciones:

### A. Invocación de Métodos en Lua: `.` vs `:`
* **Problema:** En Lua, definir una función con `.` (`function me.TestAlert(id, sound)`) e invocarla con `:` (`NRS:TestAlert(id)`) inyecta automáticamente la tabla llamante (`self`) como primer argumento. Como resultado, el parámetro `id` recibía la tabla `NRS`, arruinando concatenaciones de cadenas (`..`) en macros de tarjeteo y rompiendo la ejecución antes de alcanzar `self:Show()`.
* **Regla de Oro:** Todas las funciones de la API pública deben desambiguar su primer argumento de forma preventiva:
  ```lua
  function me.TestAlert(selfOrID, testID, customSound)
      local ID = selfOrID;
      local sound = testID;
      if (type(selfOrID) == "table") then
          ID = testID;
          sound = customSound;
      end
      -- Asegurar tipo numérico si corresponde
      local numID = tonumber(ID);
      ...
  end
  ```

### B. Sistema de Audio en WoW 3.3.5a: Manejo de Archivos Loose vs MPQ
* **Problema:** El motor de audio de WoW 3.3.5a en `PlaySoundFile(path)` **no** reproduce fiablemente rutas internas de MPQ si no están previamente cacheadas o indexadas en las tablas de sonido internas de Blizzard. Además, rutas con barras simples o caracteres de escape erróneos fallan silenciosamente.
* **Solución Implementada:**
  1. Todos los sonidos personalizados (ej. los 10 rugidos de bestias) deben residir físicamente como archivos sueltos en el disco dentro de `Interface\AddOns\TuWoW_RareScan\Assets\Sounds\`.
  2. El formato de audio **debe ser obligatoriamente PCM WAV estándar sin comprimir (16-bit, 44100 Hz, estéreo o mono)**. Los archivos OGG Vorbis sin decodificar no son reproducidos por `PlaySoundFile` en 3.3.5a.
  3. Proteger la llamada con `pcall(PlaySoundFile, path, "Master")` y verificar que el audio general no esté silenciado (`Sound_EnableAllSound`).

### C. Conflicto Visual de Alertas: Separación Estricta 2D vs 3D
* **Problema:** Al alertar sobre una criatura, si se dibujaban al mismo tiempo el `PlayerModel` 3D y la textura 2D circular con el pedestal, ambos se solapaban de forma desprolija.
* **Regla de Separación:**
  * **Avistamiento en vivo (detección real por paquete del servidor) o prueba del personaje:**
    * Solo modelo 3D activo: `Model:Show()`, `Portrait:Hide()`, `Pedestal:Hide()`.
  * **Prueba manual desde el Explorador de Rares o Santuario de Cazador:**
    * Solo 2D sobre pedestal: `Portrait:Show()`, `Pedestal:Show()`, `Model:Hide()`.
    * Para cazadores se usa `PedestalHunter.tga`; para rares convencionales, `Pedestal.tga`.
    * Cero colisión visual garantizada.

### D. Paternidad de Texturas y Capas de Animación
* **Problema:** Si la textura que contiene el `AnimationGroup` del destello de alerta (`Glow`) se crea como hija del frame `Model` (`Model:CreateTexture`), al ocultar el modelo (`Model:Hide()`) para mostrar el modo 2D, la animación de glow dejaba de reproducirse.
* **Solución:** Las texturas de brillo, resplandor e iluminación perimetral se anclan directamente al marco base del botón (`me:CreateTexture(nil, "OVERLAY")`).

### E. Rendimiento Extremo: Virtual Scrolling con `FauxScrollFrame`
* En lugar de instanciar cientos de tarjetas para los 403 rares o las 21 mascotas (lo cual causaría micro-tirones y alto uso de memoria), se implementó un pool fijo de **9 tarjetas reutilizables** actualizadas al vuelo mediante `FauxScrollFrame_Update`.
* Desplazamiento ultra fluido a 60 FPS estables.

### F. API de Macros en WoW 3.3.5a (`CreateMacro`)
* WoW 3.3.5a impone límites estrictos de macros:
  * Máximo 18 macros específicas del personaje (`perCharacter = 1`).
  * Máximo 36 macros generales de la cuenta (`perCharacter = nil`).
* El diálogo de macros (`MacroDialog.lua`) verifica `GetNumMacros()` antes de llamar a `CreateMacro`. Si ambas pestañas están llenas, avisa amigablemente al jugador y resalta el texto en un `EditBox` enfocado para que pueda copiarlo con `Ctrl + C`.

### G. Codificación de Caracteres y Fuentes
* Los clientes WoW 3.3.5a carecen de soporte para emojis UTF-8 modernos (renderizan el caracter `?` o un recuadro blanco).
* Todas las interfaces usan iconos oficiales de Blizzard (`Interface\\Icons\\...`), marcadores de banda nativos de WoW (`Interface\\TargetingFrame\\UI-RaidTargetingIcons`) y colores hexadecimales estándar (`|cffffd200...|r`).

### H. Modularización y Ámbito de Variables Locales (File Scope)
* **Problema:** Al dividir un archivo monolítico en submódulos (ej. `PageAlerts.lua`, `PageHelp.lua`), las variables declaradas como `local` en el archivo origen (como `local CURRENT_VERSION = "2.0";`) se vuelven `nil` en los nuevos archivos. Esto causaba un error de concatenación silencioso (`attempt to concatenate global 'CURRENT_VERSION'`), deteniendo la construcción de la página tras crear únicamente el primer icono de cabecera.
* **Solución:** Compartir siempre las constantes globales a través de la tabla del módulo (`UI.CURRENT_VERSION = "2.0";`), y en cada submódulo realizar fallback seguro: `local CURRENT_VERSION = (UI and UI.CURRENT_VERSION) or "2.0";`. Además, envolver las llamadas de inicialización de páginas en `pcall` que reporten el error al chat en caso de fallo en lugar de silenciarlo.

### I. Control Dinámico de Volumen de Alertas en WoW 3.3.5a
* **Limitación de la API 3.3.5a:** La función `PlaySoundFile(filePath, "Master")` carece de un parámetro individual para regular el volumen de un archivo específico; se reproduce directamente escalado según la CVar global `Sound_MasterVolume`.
* **Solución implementada (`PrepareAudioPlayback`):**
  1. Al detonar cualquier sonido (aviso de rare, botón de prueba en la UI o rugido de mascota de cazador), se guarda el `Sound_MasterVolume` original del usuario (y el estado de `Sound_EnableAllSound` si estaba silenciado).
  2. Se aplica temporalmente el volumen elegido por el usuario en el addon (`TuWoW_RareScan_DB.alertVolume`, valor por defecto 70%).
  3. Tras una ventana de 3.5 a 4.0 segundos, un frame temporizador restaura automáticamente el volumen maestro del juego a su valor previo sin alterar la configuración del jugador ni persistir cambios indeseados en `Config.wtf`.
  4. Si el jugador juega con sonido apagado pero activó el desmuteo temporal de emergencia, el canal de audio se cierra nuevamente al finalizar el aviso.
* **Componente Slider ForeverUI:** Se añadió el método `Theme:CreateSlider` con base en `OptionsSliderTemplate`, estilizado con textos dorados, porcentajes y botones de acceso rápido `[ 25% ] [ 50% ] [ 75% ] [ 100% ]` que proveen retroalimentación auditiva inmediata al hacer clic.

---

## 📋 3. Resumen de Módulos Funcionales

1. **Radar y Rares (`PageRadar.lua`):**
   * Vista de 3 columnas: lista interactiva con buscador rápido por nombre/ID, visor central con stats dinámicas y minimapa satelital con coordenadas GPS.
2. **Alertas y Opciones (`PageAlerts.lua`):**
   * Control de desmuteo temporal, destello rojo en pantalla, selector de sonido de aviso (cuerno, tambores, campana, etc.) y asignación de marcas de banda (Target Markers).
3. **Memoria WDB (`PageMemory.lua`):**
   * Panel explicativo sin tecnicismos sobre cómo funciona la caché de criaturas del cliente de WoW y cómo reiniciar el rastreo borrando la carpeta `Cache\WDB`.
4. **Guía y Ayuda (`PageHelp.lua`):**
   * Resumen de comandos, consejos para Hardcore y botón de restablecimiento de ventana.
5. **Mascotas Exóticas (`PageHunter.lua`):**
   * Exclusivo para la clase Cazador. Base de datos con las 21 bestias de BM y rares únicas de Azeroth, Terrallende y Rasganorte con stats, dietas, habilidades exóticas, coordenadas y botón de simulación de tameo.
6. **Diálogo de Macros (`MacroDialog.lua`):**
   * Generador de macros con un clic para `/targetexact` y `/cast Domesticar bestia`.

---

## 🚀 4. Guía para Futuras Modificaciones

* **Para agregar nuevos rares:** Editar `TuWoW_RareScan.ClassicData.lua` con la estructura `{ WorldID, NameEN, NameES, MinLvl, MaxLvl, MinHP, MaxHP, Rank, Family, ZoneID, Spawns = {{X, Y}, ...} }`.
* **Para agregar nuevas mascotas de cazador:** Editar `Data/HunterPets.lua` agregando el ID, coordenadas, dieta y ruta de rugido WAV.
* **Para agregar opciones:** Vincular el control a `TuWoW_RareScan_DB` o `me.Options` y registrar su guardado.
* **Verificación de sintaxis:** Ejecutar siempre el script de validación sintáctica (`scratch/check_lua_syntax.py`) antes de cerrar tareas para garantizar 0 errores en runtime.

