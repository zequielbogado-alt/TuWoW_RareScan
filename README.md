# TuWoW RareScan v2.0 (Edición "Rare Explorer")

[![WoW Version](https://img.shields.io/badge/WoW-3.3.5a%20(Build%2012340)-blue.svg)](https://github.com/zequielbogado-alt/TuWoW_RareScan)
[![Interface](https://img.shields.io/badge/Interface-30300-orange.svg)](https://github.com/zequielbogado-alt/TuWoW_RareScan)
[![UI Theme](https://img.shields.io/badge/Theme-ForeverUI%20Dark%20%26%20Gold-gold.svg)](https://github.com/zequielbogado-alt/TuWoW_RareScan)
[![Status](https://img.shields.io/badge/Status-Stable%20v2.0-brightgreen.svg)](https://github.com/zequielbogado-alt/TuWoW_RareScan)

**TuWoW RareScan** es el sistema definitivo de detección, exploración e inteligencia de criaturas raras y bestias domesticables para el servidor **TuWoW**, optimizado específicamente para su cliente híbrido con interfaz **ForeverUI**.

Evolucionado a partir del legendario motor de `_NPCScan`, este addon ha sido completamente reconstruido y modularizado para brindar una experiencia inmersiva, ligera y fluida (60 FPS estables) para el leveo 1-60 en modo **Hardcore / Die & Rise** en Azeroth, además de soporte para criaturas de Terrallende y Rasganorte.

---

## 🌟 Características Principales

### 1. Radar y Explorador de Rares de Classic (403 Criaturas)
* **Base de datos completa de Azeroth 1-60**: 403 criaturas raras catalogadas con nombres oficiales en español, nivel, vida estimada, daño, velocidad de ataque, armadura y nivel de amenaza.
* **Buscador en Vivo y Filtros de Continente**: Búsqueda instantánea por nombre o ID, con pestañas rápidas para Kalimdor, Reinos del Este, Mazmorras y Favoritos.
* **Visor 3D Interactivo**: Visualiza a la criatura en 3D con rotación con clic izquierdo, reinicio con clic derecho y zoom con la rueda del ratón.
* **Minimapa Satelital de Aparición**: Renderiza el mapa del territorio con pines luminosos interactivos que revelan las coordenadas GPS exactas `(X, Y)` de cada patrulla conocida.
* **Tarjetas de Coordenadas**: Diseño limpio en fila única con formato de tarjeta y resumen de puntos de spawn.

### 2. Pestaña Exclusiva para Cazadores: "Mascotas Exóticas"
* **Detección Automática de Clase**: La pestaña solo aparece para personajes de clase Cazador (*Hunter*).
* **Las 21 Bestias Legendarias y Exóticas de BM**: Abarca desde Bestias de Espíritu (Loque'nahak, Gondria, Skoll, Arcturis), Demosaurios (Rey Krush, Rey Mosh), Canes del Núcleo (Uvuros, El Kurken), Quimeras (La Razza, Nuramoc), Gusanos y Silítidos, hasta clásicas únicas (Diente Roto, Humar, Rak'shiri, Mazzranache).
* **Pedestal Personalizado**: Renderiza un pedestal rústico con runa de garra brillante y pieles salvajes (`PedestalHunter.tga`).
* **Banco de Rugidos Auténticos**: Archivos de audio PCM WAV de alta fidelidad para escuchar el rugido característico de cada familia de bestias antes de iniciar la búsqueda.
* **Ficha de Tameo Hardcore**: Consejos de supervivencia, dieta de la mascota, daño estimado y habilidad exótica única.
* **Generador de Macros de Tameo Seguro**: Diálogo interactivo para copiar la macro con `Ctrl + C` o crearla directamente en las macros del personaje con un solo clic (`Crear Macro en WoW`).

### 3. Sistema de Alerta Inteligente y Seguro
* **Detección por Red en Tiempo Real**: Detecta la presencia de cualquier criatura en un radio de ~100 metros tan pronto como el servidor envía los paquetes al cliente de WoW.
* **Botón Emergente Protegido (`SecureActionButtonTemplate`)**: Permite apuntar instantáneamente al rare con un solo clic sin perder tiempo buscando el objetivo en pantalla.
* **Separación Visual 2D vs 3D**:
  * *Avistamiento real en vivo o prueba de personaje*: Muestra **únicamente el modelo 3D** en movimiento.
  * *Pruebas manuales desde el explorador*: Muestra el **retrato 2D nítido sobre el pedestal correspondiente**, garantizando cero colisiones visuales.
* **Avisos Multisensoriales**: Sonido configurable (cuernos de guerra, tambores ogros, campana de subasta, subida de nivel), destello perimetral rojo en los bordes de la pantalla y asignación automática de iconos de banda (marcador de calavera, triángulo verde, cruz, etc.).

### 4. Diagnóstico Amigable de la Memoria WDB
* Pestaña dedicada a explicar en lenguaje claro cómo funciona la memoria caché del cliente de WoW (`Cache\WDB`) y cómo reiniciarla fácilmente para que el juego vuelva a consultar al servidor por criaturas ya descubiertas.
* Botón de diagnóstico para listar en el chat las criaturas que ya se encuentran cacheadas.

### 5. Arquitectura Modular y Alto Rendimiento (60 FPS)
* **Virtual Scrolling con `FauxScrollFrame`**: Sistema de reciclado de filas en la lista que garantiza cero tirones y mínimo consumo de memoria RAM.
* **Estructura Desacoplada**: El código está dividido en submódulos ordenados (`PageRadar.lua`, `PageAlerts.lua`, `PageMemory.lua`, `PageHelp.lua`, `PageHunter.lua`, `MacroDialog.lua`), haciéndolo sumamente estable y mantenible.

---

## ⌨️ Comandos de Chat

| Comando | Acción |
| :--- | :--- |
| `/rarescan` o `/rs` | Abre o cierra la ventana principal de exploración. |
| `/rarescan test` | Simula una alerta completa con sonido y modelo 3D. |
| `/rarescan cache` | Informa en el chat qué criaturas están en la caché WDB local. |
| `/rarescan reset` | Restablece el tamaño y la posición de la ventana al centro de la pantalla. |

---

## 🕹️ Botón del Minimapa

* Icono circular con el emblema dorado de Forever en el borde del minimapa.
* **Compensación automática de escala**: Diseñado específicamente para no desfasarse con la escala `1.414x` del minimapa de ForeverUI.
* **Clic Izquierdo**: Abre o cierra el explorador.
* **Clic Derecho**: Dispara una alerta de prueba.
* **Shift + Clic**: Muestra en el chat el estado de la memoria caché.
* **Arrastrar**: Permite mover libremente el botón alrededor del anillo del minimapa.

---

## 📦 Instalación

1. Descarga o clona este repositorio.
2. Copia la carpeta `TuWoW_RareScan` en el directorio de addons de tu cliente:
   ```
   TuWoW-Client/Interface/AddOns/TuWoW_RareScan
   ```
3. Inicia el juego o escribe `/reload` si ya estás conectado.
4. ¡Disfruta de la cacería de rares en Azeroth!

---

## 🛠️ Tecnologías y Compatibilidad

* **Cliente Base:** World of Warcraft: Wrath of the Lich King (3.3.5a - Build 12340).
* **Entorno Gráfico:** Compatible 100% con **ForeverUI** y la interfaz estándar de Blizzard.
* **Bibliotecas Integradas:** `LibStub`, `CallbackHandler-1.0`, `AceEvent-3.0`, `LibSharedMedia-3.0`.
* **Archivos de Audio:** WAV PCM 16-bit 44.1 kHz sin compresión para máxima compatibilidad con el motor de sonido nativo.

---

## 📄 Licencia y Créditos

* Desarrollado y modernizado para la comunidad de **TuWoW**.
* Basado en la lógica de escaneo original de `_NPCScan` por Saiket.
* Recursos gráficos y sonoros adaptados de Petopia, Wowhead y ForeverUI.
