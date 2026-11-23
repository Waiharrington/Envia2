# Envia2 Native

Envia2 es una aplicación nativa para compartir archivos, carpetas, texto y contenido del portapapeles directamente entre dispositivos de la misma red local. No necesita nube ni cuentas.

Esta rama parte de **LocalSend 1.18.2** y conserva su protocolo 2.2, su arquitectura Flutter + Rust y todas sus funciones de transferencia. El trabajo visual y de marca de Envia2 se mantiene separado de la lógica de red para conservar compatibilidad con LocalSend.

## Funciones incluidas

- Descubrimiento automático de dispositivos cercanos por UDP multicast.
- Transferencias directas y cifradas mediante HTTPS.
- Archivos, carpetas, texto y portapapeles.
- Envío y recepción con aceptación, rechazo, progreso y cancelación.
- PIN opcional, guardado rápido, carpeta de destino e historial.
- Favoritos, alias del dispositivo y envío manual por dirección.
- Envío mediante enlace para dispositivos que usan navegador.
- Bandeja del sistema, inicio automático, temas, colores e idiomas.
- Aplicaciones para Windows, macOS, Linux, Android e iOS.

## Rediseño

La interfaz Flutter está en `app/lib/`. Las pantallas principales están en:

- `app/lib/pages/home_page.dart`
- `app/lib/pages/tabs/send_tab.dart`
- `app/lib/pages/tabs/receive_tab.dart`
- `app/lib/pages/tabs/settings_tab.dart`
- `app/lib/config/theme.dart`
- `app/assets/img/`

Los textos traducibles están en `app/assets/i18n/`.

## Desarrollo

El proyecto usa Flutter `3.41.9`, administrado con FVM, y Rust. Desde `app/`:

```bash
fvm flutter pub get
fvm dart run build_runner build
fvm dart run slang
fvm flutter run
```

Las instrucciones completas de compilación y arquitectura están en [UPSTREAM_README.md](UPSTREAM_README.md) y [AGENTS.md](AGENTS.md).

## Licencia y atribución

Envia2 deriva de [LocalSend](https://github.com/localsend/localsend), creado por Tien Do Nam y sus colaboradores. El código original se distribuye bajo la licencia MIT incluida en [LICENSE](LICENSE). Los avisos de autoría y licencia deben conservarse al redistribuir la aplicación.
