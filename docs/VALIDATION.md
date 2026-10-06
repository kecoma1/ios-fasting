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

## Vídeo de revisión

El recorrido de `FastingDemoCapture.testCaptureDemo` pasó sin fallos en el simulador dedicado. Usa una base independiente con tres ayunos anteriores y uno en curso; los datos de ejemplo solo se crean en Debug con los argumentos de grabación y no usan iCloud.

La grabación real está en `docs/demo/fasting-demo-es.mp4`: 118,6 segundos, H.264, 720 × 1566, 30 fps y 3,1 MB. Se revisaron fotogramas del recorrido en los modos claro y oscuro y se comprobó la decodificación del MP4. La captura puede repetirse con `scripts/record_demo.py`; el esquema normal omite esta prueba.

## Ayunos de varios días

Se amplió el objetivo de 48 horas a un selector de días y horas, desde 1 hora hasta 365 días. Un día equivale a 24 horas transcurridas. El cronómetro muestra los días sobre `HH:MM:SS` y sigue contando después de alcanzar el objetivo. El historial, sus estadísticas y los editores muestran las duraciones completas.

Se mantiene `goalHours` como entero en SwiftData; el esquema y los datos existentes se conservan. Los casos de 49 horas, 3 días, 15 días y el límite del selector se comprobaron en almacenamiento. Un ayuno de 3 días, 4 horas y 5 minutos se reabrió, finalizó y volvió a abrir desde disco conservando su duración.

Las 13 pruebas de almacenamiento pasaron. Los seis flujos de interfaz pasaron, incluidos la reapertura de un ayuno de varios días, los cambios de objetivo desde Ajustes, el cronómetro y el historial, y el selector con el mayor tamaño de texto de accesibilidad. Los dos flujos afectados se repitieron después de identificar los botones de confirmación y reconstruir la rueda nativa cuando cambia el rango de horas; ambas repeticiones pasaron. La compilación Release para dispositivo iOS, sin firma, también pasó.

Las capturas reales con datos ficticios están en `docs/assets/timer-multiday-en.png`, `history-multiday-en.png` y `goal-multiday-en.png`. Los resultados de esta comprobación están en `build/MultiDayFinal.xcresult` (almacenamiento y cinco flujos de interfaz correctos; un fallo de selección del botón en la prueba de objetivos) y `build/MultiDayPickerVerified.xcresult` (los dos flujos afectados, correctos).

## Pendiente de validar con la cuenta de Apple

La sincronización real entre dispositivos no se ha comprobado. Requiere registrar el nuevo contenedor CloudKit, firmar con el equipo correspondiente, inicializar el esquema y probar con dos dispositivos de la misma cuenta de Apple. Las capacidades, configuración del contenedor privado y comando de inicialización están implementados; los pasos están descritos en el README.

La ejecución en iOS 17–18 y en iPad no se ha probado durante esta validación. El proyecto declara compatibilidad con iOS 17 y las APIs de Liquid Glass tienen alternativas protegidas por comprobaciones de disponibilidad.
