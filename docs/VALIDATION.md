# Validación inicial

Fecha: 6 de octubre de 2026. Xcode 26.3, SDK iOS 26.2 y simulador dedicado de iPhone 17 Pro con iOS 26.3.

| Comprobación | Resultado |
| --- | --- |
| Compilación Debug para simulador | Correcta |
| Compilación Release para dispositivo iOS, sin firma | Correcta |
| 11 pruebas de almacenamiento | Correctas |
| Iniciar, cerrar, reabrir, finalizar y consultar el historial | Correcto |
| Añadir, abrir, guardar y eliminar un ayuno anterior | Correcto |
| Interfaz y ajustes en español | Correctos |
| Revisión visual de los modos claro y oscuro | Correcta |
| Iniciar con el tamaño de texto de accesibilidad más grande | Correcto |
| Todos los textos extraídos por el compilador tienen traducción | Correcto |
| Icono de 1024 × 1024, opaco | Correcto |

Las pruebas de almacenamiento verifican persistencia tras reabrir la base, prevención de sesiones activas duplicadas, duración final inmutable, validación de fechas y objetivos, conservación del registro ante una edición inválida, edición y eliminación persistentes, recuperación de los valores visibles tras un guardado fallido, estadísticas sin sesiones activas, reloj de más de 24 horas y valores por defecto compatibles con el esquema de CloudKit.

En las pruebas de interfaz se corrigieron la zona de pulsación de la fila del historial y la altura de la hoja de inicio con texto de accesibilidad. Los flujos afectados se repitieron y pasaron. Las pruebas de almacenamiento se repitieron completas tras corregir la recuperación de los valores observados cuando el disco rechaza un guardado.

Los resultados de XCTest se generan en `build/` y no se suben al repositorio. Las capturas reales seleccionadas están en `docs/assets/`.

## Pendiente de validar con la cuenta de Apple

La sincronización real entre dispositivos no se ha comprobado. Requiere registrar el nuevo contenedor CloudKit, firmar con el equipo correspondiente, inicializar el esquema y probar con dos dispositivos de la misma cuenta de Apple. Las capacidades, configuración del contenedor privado y comando de inicialización están implementados; los pasos están descritos en el README.

La ejecución en iOS 17–18 y en iPad no se ha probado durante esta validación. El proyecto declara compatibilidad con iOS 17 y las APIs de Liquid Glass tienen alternativas protegidas por comprobaciones de disponibilidad.
