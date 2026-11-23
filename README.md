# Envia2

Envia2 comparte archivos dentro de una red local. La computadora que inicia la sala conserva los archivos; los demás dispositivos se conectan desde el navegador. No usa cuentas ni servicios en la nube.

## Requisitos

- Node.js 20 o posterior en la computadora que inicia la sala.
- Los dispositivos deben estar conectados a la misma red Wi-Fi o LAN.

## Iniciar

### Aplicación para Windows

Abre `dist/Envia2.exe`. Windows puede mostrar una alerta del firewall la primera vez; permite el acceso a redes privadas. La ventana mostrará la dirección que debes abrir en el iPhone. El código de acceso es siempre `160620`.

Los archivos enviados desde el iPhone se guardan en la carpeta `Archivos recibidos`, junto a `Envia2.exe`.

### Desde el código fuente

En Windows, abre PowerShell en esta carpeta y ejecuta:

```powershell
npm start
```

Abre `http://localhost:53317` en esa computadora. La ventana muestra las direcciones para los otros dispositivos y un código de acceso de seis dígitos. Mantén la ventana abierta mientras uses la sala. En cada teléfono o computadora, abre la dirección de la red e introduce el código.

Si Windows pregunta si Node.js puede aceptar conexiones en redes privadas, permite el acceso en la red privada que estás usando. No hace falta permitir redes públicas.

Los archivos recibidos quedan en `Archivos recibidos/`. Al detener Envia2, la sala deja de estar disponible; los archivos guardados permanecen en esa carpeta.

## Usarlo con iPhone

1. Conecta el iPhone y la laptop a la misma red Wi-Fi.
2. Abre `Envia2.exe` en la laptop.
3. En Safari del iPhone, abre la dirección `http://192.168...` que aparece en la ventana de Envia2.
4. Escribe el código de seis dígitos.
5. Para enviar del iPhone a la laptop, toca **Elegir archivos** o **Elegir carpeta**. iOS permite escoger fotos, videos, documentos y carpetas.
6. Para enviar de la laptop al iPhone, sube el archivo o la carpeta desde la laptop y toca **Descargar** en el iPhone. Las carpetas se descargan como ZIP.

Al recibir una carpeta, Windows conserva la estructura original dentro de `Archivos recibidos` y también crea un ZIP para descargarla desde otros dispositivos.

En el iPhone puedes tocar **Compartir → Añadir a pantalla de inicio** para abrir Envia2 como si fuera una app.

## Privacidad

El código cambia cada vez que se inicia el servidor. Comparte la dirección y el código solo con las personas que quieras invitar. La transferencia funciona en la red local; usa una red de confianza.
