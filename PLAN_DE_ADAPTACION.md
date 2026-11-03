# Plan de Acción: Adaptación de _NPCScan para TuWoW (ForeverUI)

## Resumen del Proyecto
Adaptar el addon `_NPCScan` (v3.3.5.5) para que funcione de forma óptima en el cliente híbrido de TuWoW (WoW 3.3.5a + ForeverUI). 
El objetivo es transformar un addon originalmente pensado para rares de expansión (Rasganorte y Terrallende) en un detector de criaturas raras de alta utilidad para el leveo 1-60 en modo Hardcore / Die & Rise en Azeroth, completamente integrado a ForeverUI visual y funcionalmente.

---

## Fases de Ejecución

### Fase 1: Incorporación de la Base de Datos de Rares Clásicos (Azeroth 1-60)
* **Objetivo:** Permitir que `_NPCScan` rastree automáticamente más de 400 criaturas raras de Kalimdor y Reinos del Este.
* **Acciones:**
  1. Crear el módulo `_NPCScan.ClassicData.lua` con la base de datos de rares clásicos (Rank 2 Rare Elite y Rank 4 Rare) clasificados por continente:
     - `WorldID 1`: Kalimdor.
     - `WorldID 2`: Reinos del Este.
     - `WorldID nil`: Mobs globales o de instancias clásicas (Minas de la Muerte, Cueva de las Lamentaciones, etc.).
  2. Extraer los nombres oficiales en español (`esES` / `esMX`) directamente de la base de datos de Questie que reside en el cliente.
  3. Modificar `_NPCScan.Synchronize()` en `_NPCScan.lua` para que al inicializarse el personaje en TuWoW, se carguen los rares clásicos en la lista activa de escaneo de forma transparente y eficiente.

### Fase 2: Módulo de Botón para el Minimapa (ForeverUI)
* **Objetivo:** Brindar acceso rápido a la configuración, estado de escaneo y pruebas desde el borde del minimapa de ForeverUI.
* **Acciones:**
  1. Crear `_NPCScan.Minimap.lua` implementando un botón circular arrastrable con el icono temático de radar/ojo de _NPCScan.
  2. Implementar la compensación de escala (`Minimap:GetScale()`, factor `1.414`) y radio `100` para que orbite perfectamente el anillo de ForeverUI sin desfasarse.
  3. Soporte para eventos de clic:
     * **Clic Izquierdo:** Abre la ventana de configuración y búsqueda (`/npcscan`).
     * **Clic Derecho:** Ejecuta la prueba de alerta (`Test Alert`).
     * **Shift + Clic:** Imprime en el chat el resumen de mobs activos y mobs en caché.
     * **Arrastre (Drag):** Permite mover el icono alrededor del perímetro del minimapa guardando la posición en `_NPCScanOptions.MinimapPos`.
  4. Tooltip informativo en español con instrucciones de uso.

### Fase 3: Rediseño Visual del Botón de Alerta (`_NPCScanButton`)
* **Objetivo:** Sustituir la estética de pergamino de logros de 2008 por una apariencia coherente con el tema de ForeverUI (tonos oscuros, bordes definidos y tipografía legible).
* **Acciones:**
  1. Modificar `_NPCScan.Button.lua`:
     - Fondo: Fondo oscuro translúcido tipo pizarra/cuero.
     - Borde: Estilo `UI-Tooltip-Border` / dorado sutil con iluminación reactiva.
     - Textos: Título en dorado (`#ffd10d`), subtítulo en verde o naranja de alerta.
  2. Mantener intacta la seguridad de ejecución (`SecureActionButtonTemplate`) y el modelo 3D animado con rotación suave.
  3. Anclaje seguro por encima de las barras de acción de ForeverUI (`Y >= 130`) con persistencia de posición si el usuario decide moverlo.
  4. Nivel de capa `FULLSCREEN_DIALOG` para garantizar que ninguna ventana de ForeverUI lo tape en momentos críticos.

### Fase 4: Localización Completa al Español (`Locale-esES.lua`)
* **Objetivo:** 100% de los textos, comandos y alertas traducidos al español.
* **Acciones:**
  1. Reescribir [Locales/Locale-esES.lua](file:///c:/TuWoW/TuWoW-Client/Interface/AddOns/_NPCScan/Locales/Locale-esES.lua) traduciendo:
     * Comandos de chat (`/npcscan add`, `/npcscan remove`, `/npcscan cache`).
     * Alertas en pantalla y chat (`"¡Criatura encontrada!"`, `"Aviso de caché"`).
     * Opciones del panel de configuración (sonidos, silenciado, alertas).
     * Pestañas y columnas del buscador de NPCs.

### Fase 5: Navegación de Opciones e Integración con el TOC
* **Objetivo:** Eliminar fallos de apertura en el menú de interfaz de 3.3.5 / ForeverUI.
* **Acciones:**
  1. Corregir en `_NPCScan.lua` la función `SlashCommand` para evitar el bug nativo de Blizzard al abrir subcategorías de opciones en 3.3.5.
  2. Actualizar `_NPCScan.toc` agregando en orden secuencial:
     - `_NPCScan.ClassicData.lua`
     - `_NPCScan.Minimap.lua`
  3. Asegurar que `_NPCScanOptions` guarde las opciones del botón de minimapa.

---

## Plan de Verificación y Pruebas
1. **Prueba de Carga:** Ingreso al juego sin errores de Lua en chat ni fallas de carga de librerías.
2. **Prueba del Minimapa:** Comprobar que el icono orbita limpiamente el minimapa de ForeverUI, no se desplaza al hacer zoom/cambiar zona, y responde a clics y arrastre.
3. **Prueba de Alerta Visual y Sonora:** Usar el botón de test para verificar que el marco emergente luce el nuevo estilo ForeverUI, reproduce el sonido de alerta y crea la macro segura de tarjeteo.
4. **Prueba de Detección:** Verificar con el comando `/npcscan cache` que los rares de Azeroth están registrados por continente según la zona actual.

