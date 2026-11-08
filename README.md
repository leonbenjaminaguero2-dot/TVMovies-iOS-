# TVMovies Mobile — SwiftUI con Liquid Glass nativo (iOS 26+)

App de **iPhone** (no selector Móvil/TV/PC), basada en el aspecto de TVMovies Mobile. Pantallas **Películas, Series, Canales, Cuenta, Ajustes**. La barra inferior no está dibujada como una imitación de vidrio: se crea con **`TabView` y `tabItem` de SwiftUI compiladas con el SDK de iOS 26**, lo que activa **el Liquid Glass flotante nativo del sistema** y sus animaciones. El buscador y el botón de 9 puntos también usan APIs nativas (`glassEffect` y `.buttonStyle(.glass)`). No hay botón para transmitir ni engranaje en la cabecera.

La app requiere **iOS 26 o posterior**. Está pensada para un iPhone moderno con iOS 27. Debe compilarse con Xcode 26.2 o posterior; el workflow usa Xcode 26.6.

## Catálogo sincronizado: el mismo Firestore de la web

Se comprobó la configuración del HTML original: proyecto Firebase **`tvmovies-6b05d`**, colección **`catalogo`**. La app hace `Firestore.firestore().collection("catalogo").addSnapshotListener`, por lo que agregar, editar o borrar contenido desde el panel web actualizará la lista de la app, según la conectividad y las reglas de Firestore.

Se respetan los campos **`tipo`** (`pelis` / `series` / `canales`), **`titulo`**, **`plataforma`**, **`poster`**, **`backdrop`** (opcional), **`stream`**, **`desc`**, **`capitulos`** (`[{numero, titulo, link}]`) y, si existen, `anio`, `genero`, `destacado`. El filtro del botón de **9 puntos** lee las plataformas disponibles en Firestore, como Netflix, Disney+, Prime Video, etc. **No** hay contenido de prueba preinstalado: sin permiso o sin documentos de Firebase aparece un estado de error/vacío claro.

Los perfiles y favoritos son **locales**, no una sincronización de cuentas entre dispositivos. Para sincronizar también cuenta/historial/favoritos hará falta definir un modelo de usuarios de Firebase Auth/Firestore. Esta versión **no escribe** sobre el catálogo.

## Configuración necesaria de Firebase iOS

La configuración de la **web** de Firebase no sustituye a la de iOS: necesitas registrar una aplicación iOS en el mismo proyecto.

1. Abrí [Firebase Console](https://console.firebase.google.com/), proyecto **tvmovies-6b05d**.
2. En «Configuración del proyecto → Tus aplicaciones → Agregar aplicación → Apple (iOS)», registrá **`com.tvmovies.mobile`** como Bundle ID.
3. Descargá el **`GoogleService-Info.plist`** generado para esa app.
4. **En el Mac local**: colocalo en `TVMoviesMobile/GoogleService-Info.plist` **antes** de `xcodegen generate`.
5. **En GitHub**: agregá el secreto de Actions **`FIREBASE_GOOGLESERVICE_INFO_BASE64`** con el contenido del archivo codificado en Base64 (texto sin saltos de línea). PowerShell en Windows:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes('GoogleService-Info.plist'))
   ```

   En macOS: `base64 -i GoogleService-Info.plist | tr -d '\n'`.

El workflow **falla a propósito si el secreto no existe** o si el plist pertenece a otro Bundle ID/proyecto. Así evita entregarte una IPA que parece funcionar pero no puede sincronizar el catálogo. El plist se incluye en el bundle compilado: contiene identificadores de cliente, no claves privadas de administrador. **La seguridad de tus datos depende de las reglas de Firestore**; no abras permisos de escritura por hacer funcionar esta app.

## Crear la IPA desde GitHub (sin reemplazar la anterior)

El ZIP incluye `.github/workflows/build-ipa.yml`, `project.yml` para XcodeGen y los archivos Swift.

1. Recomendación: subí la carpeta a una **rama nueva** `swift-native` de tu repo `leonbenjaminaguero2-dot/TVMovies-iOS`, o a un repo nuevo **privado** si preferís no publicar el código.
2. Agregá el secreto `FIREBASE_GOOGLESERVICE_INFO_BASE64` en **Settings → Secrets and variables → Actions**.
3. **Subí el código a la rama `swift-native` luego de crear el secreto.** El workflow se activa automáticamente mediante `push` en esa rama. Abrí **Actions** para revisar el resultado.
4. Descargá el Artifact **TVMoviesMobile-IPA-sin-firma**: contiene `TVMoviesMobile-unsigned.ipa`. Si además copiás el workflow a la rama principal (`main`), GitHub permitirá ejecutarlo manualmente con «Run workflow» y seleccionar `swift-native`.

GitHub Actions usa `macos-26` + Xcode 26.6 + XcodeGen + el SDK Firebase Apple 13.1.1 por Swift Package Manager. Compila para un dispositivo iPhone (`Release-iphoneos`) con `CODE_SIGNING_ALLOWED=NO`, comprueba la presencia del bundle y empaqueta `Payload/TVMoviesMobile.app`.

**La IPA se crea sin firma**, por lo que tendrás que firmarla con tu método habitual antes de instalarla en el iPhone. Sin ejecutar el workflow en macOS ni conectar el archivo Firebase real, **no está verificado aún** que el build termine o que el streaming de cada enlace funcione; los tests incluidos revisan estructura y sintaxis, no sustituyen la ejecución real en iOS.

## Reproducción

- URLs directas `m3u8`, `mp4`, `m4v`, `mov`: **AVPlayer**.
- Enlaces web/embeds: **WKWebView**. Algunas webs prohíben incrustaciones, requieren inicio de sesión o usan DRM y pueden no funcionar.
- Series: cada capítulo lee su `link`/`stream` del documento de Firestore.
- Se permite HTTP para compatibilidad con enlaces antiguos; se recomienda HTTPS y reglas ATS restrictivas en producción.

## Verificación rápida sin un Mac

```bash
python3 scripts/verify_structure.py
# swiftc -frontend -parse ... (revisa solo sintaxis Swift)
```

Generación local en macOS:

```bash
brew install xcodegen
xcodegen generate --spec project.yml
open TVMoviesMobile.xcodeproj
```


## Fidelidad al HTML Movil(1).html

Se añadió el flujo inicial de perfiles locales (crear/seleccionar) y elección de plataforma: Canales, Netflix, Disney+ y Prime Video. Los perfiles se almacenan en UserDefaults como en el HTML original se almacenaban en localStorage; **no son cuentas Firebase Authentication**. El catálogo sigue escuchando `catalogo` en Firestore. La barra inferior es TabView nativa de iOS 26+ para Liquid Glass auténtico. El diseño está adaptado a SwiftUI y no es una reproducción píxel por píxel del HTML. No se ha compilado en un runner macOS todavía.


## Animaciones nativas añadidas
- Transiciones de entrada/salida entre selección de perfil, creación y selección de plataforma con spring y fade.
- Respuesta táctil de tarjetas y botones mediante `TVPressStyle` (escala/opacity).
- Transiciones animadas de selección y cambio de plataforma, sin reemplazar la TabView Liquid Glass de Apple.
- `accessibilityReduceMotion` desactiva las animaciones personalizadas para quien tenga activado Reducir movimiento.
- Animaciones implementadas en SwiftUI, sin WebView. Falta verificar en un iPhone real.
