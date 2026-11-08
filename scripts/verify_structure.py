#!/usr/bin/env python3
"""Small project-contract test. Does NOT replace building with Xcode."""
from pathlib import Path
import json
root = Path(__file__).resolve().parent.parent
models = (root / 'TVMoviesMobile/Models/CatalogItem.swift').read_text()
service = (root / 'TVMoviesMobile/Services/CatalogStore.swift').read_text()
workflow = (root / '.github/workflows/build-ipa.yml').read_text()
example = json.loads((root / 'examples/catalogo-documento.json').read_text())
assert all(key in example for key in ('tipo','titulo','plataforma','poster','desc','capitulos'))
assert 'collection("catalogo")' in service
rootview = (root / 'TVMoviesMobile/Views/RootScreen.swift').read_text()
assert 'TabView(selection: $selected)' in rootview, 'Usar la TabView nativa iOS26'
assert '.tabItem { Label(tab.label, systemImage: tab.icon) }' in rootview
assert 'square.grid.3x3.fill' in rootview and 'Cambiar plataforma' in rootview
assert '.glassEffect(.regular, in: Capsule())' in rootview
assert "iOS: '26.0'" in (root / 'project.yml').read_text()
assert 'addSnapshotListener' in service
assert all(f'data["{key}"]' in models for key in ('tipo','titulo','plataforma','poster','stream','desc','capitulos'))
assert 'CODE_SIGNING_ALLOWED=NO' in workflow
assert 'actions/upload-artifact@v4' in workflow
assert 'FIREBASE_GOOGLESERVICE_INFO_BASE64' in workflow
onboarding = (root / 'TVMoviesMobile/Views/TVMoviesOnboarding.swift').read_text()
settings = (root / 'TVMoviesMobile/Views/AccountSettings.swift').read_text()
assert all(platform in onboarding for platform in ('Canales', 'Netflix', 'Disney+', 'Prime Video'))
assert all(label in onboarding for label in ('¿Quién está viendo?', 'Creá tu perfil.', '¿Qué plataforma'))
assert 'sessionActive' in rootview and 'AccountScreen' in rootview
assert all(word in settings for word in ('Cambiar nombre', 'Eliminar perfil', 'Color de énfasis', 'Diseño compacto'))
assert 'Firebase' not in settings.split('struct SettingsScreen: View {', 1)[-1]
assert 'Payload/TVMoviesMobile.app' in workflow
print('OK: estructura, Firebase catalogo y empaquetado IPA sin firma verificados.')
