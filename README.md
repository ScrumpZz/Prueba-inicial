# Freno 🛑 — app para iPhone contra la adicción a reels y redes

Cada vez que abres Instagram, TikTok (o la app que elijas):

1. **Aparece una pantalla de Freno encima de la app** que te pregunta *"¿Por qué quieres entrar?"*.
2. Puedes tocar **"Mejor no entro"** (se cuenta como victoria 💪) o **"Necesito entrar"**.
3. Si necesitas entrar, llega una notificación que abre Freno, donde:
   - escribes **el motivo** (o eliges uno rápido: "Responder un mensaje", "Publicar algo"…),
   - eliges **de 5 a 10 minutos**,
   - esperas una **pausa de 10 segundos** para romper el impulso automático.
4. La app se desbloquea. **Cuando se cumple el tiempo de uso, se bloquea sola**: si estás dentro, la pantalla de Freno aparece encima al instante. 1 minuto antes te avisa.
5. En la pantalla principal ves estadísticas del día y el **historial de motivos** (útil para darte cuenta de cuántas veces entras "por aburrimiento").

## ¿Cómo funciona por dentro?

iOS **no permite** que una app detecte cuándo abres otra ni que la cierre directamente.
La única forma oficial es la API de **Tiempo de uso** de Apple (Screen Time API), que es lo que usa Freno:

| Pieza | Framework | Qué hace |
|---|---|---|
| `Freno` (app) | SwiftUI + `FamilyControls` | Permisos, elegir apps, preguntar el motivo, estadísticas |
| `FrenoShieldConfiguration` | `ManagedSettingsUI` | Diseño de la pantalla que tapa Instagram/TikTok |
| `FrenoShieldAction` | `ManagedSettings` | Botones de esa pantalla ("Mejor no entro" / "Necesito entrar") |
| `FrenoMonitor` | `DeviceActivity` | Corre en segundo plano y vuelve a bloquear al cumplirse los minutos |
| `Shared/` | — | Código compartido (App Group, bloqueos, notificaciones) |

El límite se mide como **minutos de uso real dentro de la app**. Además, por una restricción de iOS
(los intervalos duran mínimo 15 min), cada sesión expira a los 15 minutos de reloj aunque no hayas usado todos tus minutos.

## Requisitos

- Un **Mac** con **Xcode 15 o superior**.
- Un **iPhone con iOS 17+** (las APIs de Tiempo de uso **no funcionan en el simulador**).
- Una cuenta de **Apple Developer de pago** (99 USD/año). La capacidad *Family Controls* y los *App Groups* no están disponibles con una cuenta gratuita.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) para generar el proyecto: `brew install xcodegen`.

## Configuración (una sola vez)

1. **Clona el repo** en tu Mac.
2. **Cambia el identificador** `com.tunombre` por uno tuyo (p. ej. `com.camiloavendano`):
   ```bash
   grep -rl "com.tunombre" project.yml Shared | xargs sed -i '' 's/com\.tunombre/com.camiloavendano/g'
   ```
3. **Genera el proyecto** y ábrelo:
   ```bash
   xcodegen generate
   open Freno.xcodeproj
   ```
4. En Xcode, para **cada uno de los 4 targets** (`Freno`, `FrenoMonitor`, `FrenoShieldConfiguration`, `FrenoShieldAction`):
   *Signing & Capabilities* → elige tu **Team**. Xcode registrará automáticamente los bundle IDs,
   la capacidad *Family Controls* y el App Group `group.com.<tuid>.freno`.
   (También puedes poner tu Team ID en `DEVELOPMENT_TEAM` dentro de `project.yml`.)
5. Conecta tu iPhone, actívale el **Modo desarrollador** (Ajustes → Privacidad y seguridad) y pulsa ▶︎ Run.
6. En la app: da permiso de Tiempo de uso → elige Instagram, TikTok, etc. → activa notificaciones → **Activar Freno**.

## Consejos para que funcione de verdad

- Siempre podrás desactivar Freno desde la app o desde *Ajustes → Tiempo de uso*. Si quieres hacerlo más difícil, pídele a alguien de confianza que ponga un **código de Tiempo de uso** que tú no sepas.
- Elige también la categoría **"Redes sociales"** en el selector para que cubra apps nuevas que instales.
- Si algún día el bloqueo no vuelve a tiempo, abre Freno: al abrirse revisa las sesiones vencidas y vuelve a bloquear.

## Limitaciones conocidas

- Desde la pantalla de bloqueo iOS no deja abrir otra app, por eso se usa una **notificación** para llevarte a Freno.
- El conteo de minutos lo hace iOS; en algunas versiones puede retrasarse unos segundos o hasta un minuto.
- Para publicarla en la App Store tendrías que pedirle a Apple el permiso *Family Controls (Distribution)*. Para uso personal no hace falta.

## Estructura

```
project.yml                     # Definición del proyecto (XcodeGen)
Shared/                         # Compartido entre app y extensiones
  SharedStore.swift             # Datos en el App Group (selección, sesiones, historial)
  ShieldManager.swift           # Bloquear / desbloquear / programar el fin de sesión
  Notifier.swift                # Notificaciones locales
Freno/                          # App principal (SwiftUI)
  FrenoApp.swift, AppModel.swift
  Views/ OnboardingView, HomeView, UnlockView, HistoryView, RootView
FrenoMonitor/                   # Extensión DeviceActivityMonitor
FrenoShieldConfiguration/       # Extensión: diseño de la pantalla de bloqueo
FrenoShieldAction/              # Extensión: botones de la pantalla de bloqueo
```
