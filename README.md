# Control de Lenguaje de Programación y Visualización de Grafo

Este proyecto implementa un lenguaje para describir y navegar entre galaxias representadas como nodos en un grafo. Permite:

- Definir galaxias (con o sin la capacidad de reabastecer combustible).
- Definir aristas entre galaxias con un costo de combustible.
- Actualizar el costo de las aristas.
- Crear una nave con un cierto combustible inicial, posicionada en una galaxia.
- Viajar entre galaxias ya sea de forma autónoma (minimizando saltos o combustible) o manual (eligiendo entre galaxias vecinas).
- Recargar combustible cuando la galaxia actual lo permita.
- Visualizar el grafo resultante y las rutas recorridas por la nave mediante un script en Python.

## Estructura del Proyecto

- **lexer.l**: Archivo Flex para el analizador léxico.
- **parser.y**: Archivo Bison para el analizador sintáctico.
- **graficar.py**: Script en Python que:
  - Lee las mismas instrucciones que el parser en C (desde `input.txt`).
  - Construye el grafo con `networkx`.
  - Ejecuta instrucciones simplificadas.
  - Dibuja el grafo y resalta el camino recorrido por la nave.
  
- **input.txt**: Archivo de entrada con las instrucciones del lenguaje.

## Ejemplo de entrada
```text
./parser "archivo.txt"

## Ejemplo de `input.txt`

```text
GALAXIA A
GALAXIA B ABASTECER
GALAXIA C
ARISTA A B 10
ARISTA B C 20
NAVE A 50
VIAJE_AUTO DESTINO C MODO MIN_COMBUSTIBLE
RECARGAR
VIAJE_MANUAL HACIA B
SALIR
