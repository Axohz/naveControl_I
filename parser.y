%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h> 

int yylex(void);
void yyerror(const char *s);
extern FILE *yyin;

#define MAX_GAL 1000

typedef struct {
    char *name;
    int fueling; // 1 si se puede reabastecer, 0 si no
} Galaxy;

typedef struct EdgeNode {
    int dest;
    int cost;
    struct EdgeNode *next;
} EdgeNode;

// Lista de adyacencia
EdgeNode *adjList[MAX_GAL];
int galaxy_count = 0;
Galaxy *galaxies[MAX_GAL];

int galaxyIndex(char *name) {
    for (int i=0; i<galaxy_count; i++) {
        if (strcmp(galaxies[i]->name, name)==0) return i;
    }
    return -1;
}

int addGalaxy(char *name, int fueling) {
    // Agrega una galaxia y devuelve su índice
    Galaxy *g = malloc(sizeof(Galaxy));
    g->name = name;
    g->fueling = fueling;
    galaxies[galaxy_count] = g;
    adjList[galaxy_count] = NULL;
    galaxy_count++;
    printf("Definida galaxia: %s (abastecer=%d)\n", name, fueling);
    return galaxy_count-1;
}

void addEdgeInternal(int g1, int g2, int cost) {
    // agrega arista g1->g2
    EdgeNode *e = malloc(sizeof(EdgeNode));
    e->dest = g2;
    e->cost = cost;
    e->next = adjList[g1];
    adjList[g1] = e;
}

void addEdge(char *g1, char *g2, int cost) {
    int i1 = galaxyIndex(g1);
    int i2 = galaxyIndex(g2);
    if (i1==-1 || i2==-1) {
        printf("Error: una de las galaxias no existe.\n");
        return;
    }
    // Grafo no dirigido
    addEdgeInternal(i1, i2, cost);
    addEdgeInternal(i2, i1, cost);
    printf("Agregada arista: %s - %s, costo=%d\n", g1, g2, cost);
}

void updateEdge(char *g1, char *g2, int cost) {
    int i1 = galaxyIndex(g1);
    int i2 = galaxyIndex(g2);
    if (i1==-1 || i2==-1) {
        printf("No se encontró la arista %s - %s para actualizar.\n", g1, g2);
        return;
    }
    int found = 0;
    // Actualizar i1->i2
    for (EdgeNode *e = adjList[i1]; e; e = e->next) {
        if (e->dest == i2) {
            e->cost = cost;
            found = 1;
        }
    }
    // Actualizar i2->i1
    for (EdgeNode *e = adjList[i2]; e; e = e->next) {
        if (e->dest == i1) {
            e->cost = cost;
            found = 1;
        }
    }

    if (!found) {
        printf("No se encontró la arista %s - %s para actualizar.\n", g1, g2);
    } else {
        printf("Arista actualizada: %s - %s, nuevo costo=%d\n", g1, g2, cost);
    }
}

int nave_pos = -1;
int nave_combustible = 0;

void crearNave(char *galaxia, int combustible) {
    int idx = galaxyIndex(galaxia);
    if (idx == -1) {
        printf("No se pudo crear la nave: la galaxia no existe.\n");
        return;
    }
    nave_pos = idx;
    nave_combustible = combustible;
    printf("Nave creada en galaxia %s con %d de combustible.\n", galaxia, combustible);
}

// Funciones auxiliares para rutas
// Modo MIN_COMBUSTIBLE: Dijkstra
int distCombustible[MAX_GAL];
int prevComb[MAX_GAL];
int visited[MAX_GAL];

void dijkstra(int start, int goal) {
    for (int i=0; i<galaxy_count; i++) {
        distCombustible[i] = INT_MAX;
        prevComb[i] = -1;
        visited[i] = 0;
    }
    distCombustible[start] = 0;

    for (int i=0; i<galaxy_count; i++) {
        int u=-1; int best=INT_MAX;
        for (int j=0; j<galaxy_count; j++) {
            if (!visited[j] && distCombustible[j]<best) {
                best=distCombustible[j]; u=j;
            }
        }
        if (u==-1) break;
        visited[u]=1;
        for (EdgeNode *e=adjList[u]; e; e=e->next) {
            int alt = distCombustible[u] + e->cost;
            if (alt<distCombustible[e->dest]) {
                distCombustible[e->dest]=alt;
                prevComb[e->dest]=u;
            }
        }
    }
}

// Modo MIN_SALTOS: BFS
int distSaltos[MAX_GAL];
int prevSaltos[MAX_GAL];

void bfs_saltos(int start) {
    for (int i=0; i<galaxy_count; i++) {
        distSaltos[i]=INT_MAX;
        prevSaltos[i]=-1;
    }
    distSaltos[start]=0;
    int queue[MAX_GAL], front=0, rear=0;
    queue[rear++]=start;
    while(front<rear) {
        int u=queue[front++];
        for (EdgeNode *e=adjList[u]; e; e=e->next) {
            if (distSaltos[e->dest]==INT_MAX) {
                distSaltos[e->dest]=distSaltos[u]+1;
                prevSaltos[e->dest]=u;
                queue[rear++]=e->dest;
            }
        }
    }
}

// Construir ruta desde prev[] dado el destino
int buildPath(int prev[], int start, int goal, int path[]) {
    // Reconstruye la ruta inversa
    int stack[1000]; 
    int top=0;
    int current=goal;
    if (prev[goal]==-1 && start!=goal) {
        return 0; // no hay ruta
    }
    while(current!=-1) {
        stack[top++]=current;
        current=prev[current];
    }
    // invertir
    int len=0;
    for (int i=top-1; i>=0; i--) {
        path[len++]=stack[i];
    }
    return len;
}

void viajarAutonomo(char *destino, int modo, int pasos) {
    int goal = galaxyIndex(destino);
    if (goal==-1) {
        printf("No se puede viajar: la galaxia destino no existe.\n");
        return;
    }
    if (nave_pos==-1) {
        printf("No se puede viajar: la nave no ha sido creada.\n");
        return;
    }

    int start = nave_pos;

    int path[1000]; 
    int path_len=0;

    if (modo==1) { 
        // MIN_COMBUSTIBLE
        dijkstra(start, goal);
        if (distCombustible[goal]==INT_MAX) {
            printf("No hay ruta hacia %s.\n", destino);
            return;
        }
        path_len=buildPath(prevComb, start, goal, path);
    } else {
        // MIN_SALTOS
        bfs_saltos(start);
        if (distSaltos[goal]==INT_MAX) {
            printf("No hay ruta hacia %s.\n", destino);
            return;
        }
        path_len=buildPath(prevSaltos, start, goal, path);
    }

    // path contiene la ruta desde start hasta goal
    // Pasos: avanzar 'pasos' nodos desde la posición actual
    // La posición actual ya está en path[0] = start
    // Debemos encontrar la posición actual en la ruta (será path[0] = start)
    // Avanzar hasta min(path_len-1, pasos) nodos más (no contamos el start)
    int currentIndexInPath=0;
    // encontrar la posicion actual en la ruta
    // (ya está en start, se asume path[0] = start)
    // Mover la nave 'pasos' nodos más adelante en el path.
    int toMove = pasos;
    while (toMove>0 && currentIndexInPath<path_len-1) {
        int u = path[currentIndexInPath];
        int v = path[currentIndexInPath+1];
        // Encontrar costo u->v
        int edgeCost = -1;
        for (EdgeNode *e=adjList[u]; e; e=e->next) {
            if (e->dest == v) { edgeCost=e->cost; break; }
        }
        if (edgeCost==-1) {
            printf("Error interno: arista no encontrada.\n");
            return;
        }
        if (nave_combustible<edgeCost) {
            // Sin combustible suficiente
            printf("La nave se quedó sin combustible en el camino. La tripulación muere.\n");
            return;
        }
        // Consumir combustible
        nave_combustible-=edgeCost;
        nave_pos=v;
        currentIndexInPath++;
        toMove--;
    }

    if (nave_pos==goal) {
        printf("La nave ha llegado a la galaxia destino %s.\n", destino);
    } else {
        printf("La nave se encuentra ahora en %s con %d de combustible. Ruta no completada.\n",
            galaxies[nave_pos]->name, nave_combustible);
    }
}

void verVecinas(int radio) {
    if (nave_pos==-1) {
        printf("La nave no ha sido creada.\n");
        return;
    }
    // BFS hasta 'radio' niveles
    int dist[MAX_GAL];
    for (int i=0; i<galaxy_count; i++) {
        dist[i]=INT_MAX;
    }
    dist[nave_pos]=0;
    int queue[1000], front=0,rear=0;
    queue[rear++]=nave_pos;
    printf("Galaxias alcanzables (radio=%d):\n", radio);
    while(front<rear) {
        int u=queue[front++];
        if (dist[u]<=radio) {
            // imprimir galaxia
            if (u!=nave_pos) {
                printf(" - %s (distancia=%d)\n", galaxies[u]->name, dist[u]);
            }
            if (dist[u]<radio) {
                for (EdgeNode *e=adjList[u]; e; e=e->next) {
                    if (dist[e->dest]==INT_MAX) {
                        dist[e->dest]=dist[u]+1;
                        queue[rear++]=e->dest;
                    }
                }
            }
        }
    }
}

void viajeManualHacia(char *destino) {
    if (nave_pos==-1) {
        printf("La nave no ha sido creada.\n");
        return;
    }
    int goal=galaxyIndex(destino);
    if (goal==-1) {
        printf("La galaxia %s no existe.\n", destino);
        return;
    }
    // Verificar si es vecina inmediata
    int edgeCost=-1;
    for (EdgeNode *e=adjList[nave_pos]; e; e=e->next) {
        if (e->dest==goal) {
            edgeCost=e->cost; 
            break;
        }
    }
    if (edgeCost==-1) {
        printf("La galaxia %s no es vecina inmediata. No se puede viajar manualmente.\n", destino);
        return;
    }
    if (nave_combustible<edgeCost) {
        printf("La nave se quedó sin combustible al intentar desplazarse. La tripulación muere.\n");
        return;
    }
    nave_combustible-=edgeCost;
    nave_pos=goal;
    printf("Nave ahora en %s, combustible=%d.\n", galaxies[nave_pos]->name, nave_combustible);
}

void recargarCombustible() {
    if (nave_pos==-1) {
        printf("La nave no ha sido creada.\n");
        return;
    }
    if (galaxies[nave_pos]->fueling==1) {
        // Establecemos un combustible máximo, por ejemplo 100
        nave_combustible=100;
        printf("Combustible recargado en %s, ahora combustible=%d.\n", galaxies[nave_pos]->name, nave_combustible);
    } else {
        printf("No se puede recargar en %s.\n", galaxies[nave_pos]->name);
    }
}

%}

%union {
    int intval;
    char *strval;
}

%token <strval> IDENTIFICADOR
%token <intval> NUMERO

%token GALAXIA
%token ABASTECER
%token ARISTA
%token ACTUALIZAR_ARISTA
%token NAVE
%token VIAJE_AUTO
%token DESTINO
%token MODO
%token MIN_COMBUSTIBLE
%token MIN_SALTOS
%token PASOS
%token VIAJE_MANUAL
%token VER_VECINAS
%token RADIO
%token HACIA
%token RECARGAR
%token SALIR

%type <intval> modo_opt
%type <intval> pasos_opt

%start entrada

%%

entrada:
    /* vacío */
    | entrada linea
    ;

linea:
      def_galaxia
    | def_arista
    | upd_arista
    | crear_nav
    | cmd_viaje_auto
    | cmd_viaje_manual
    | cmd_recarga
    | cmd_salir
    | error { yyerrok; }
    ;

def_galaxia:
    GALAXIA IDENTIFICADOR { addGalaxy($2,0); }
    | GALAXIA IDENTIFICADOR ABASTECER { addGalaxy($2,1); }
    ;

def_arista:
    ARISTA IDENTIFICADOR IDENTIFICADOR NUMERO { addEdge($2,$3,$4); }
    ;

upd_arista:
    ACTUALIZAR_ARISTA IDENTIFICADOR IDENTIFICADOR NUMERO { updateEdge($2,$3,$4); }
    ;

crear_nav:
    NAVE IDENTIFICADOR NUMERO { crearNave($2,$3); }
    ;

cmd_viaje_auto:
    VIAJE_AUTO DESTINO IDENTIFICADOR modo_opt pasos_opt {
        int m = ($4 == 1) ? 1 : 2;
        viajarAutonomo($3,m,$5);
    }
    ;

modo_opt:
    MODO MIN_COMBUSTIBLE { $$=1; }
    | MODO MIN_SALTOS { $$=2; }
    ;

pasos_opt:
    PASOS NUMERO { $$=$2; }
    | /* vacío */ { $$=1; }
    ;

cmd_viaje_manual:
    VIAJE_MANUAL VER_VECINAS RADIO NUMERO { verVecinas($4); }
    | VIAJE_MANUAL HACIA IDENTIFICADOR { viajeManualHacia($3); }
    ;

cmd_recarga:
    RECARGAR { recargarCombustible(); }
    ;

cmd_salir:
    SALIR { printf("Saliendo del programa...\n"); exit(0); }
    ;

%%

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *f = fopen(argv[1],"r");
        if (!f) {
            perror("No se pudo abrir el archivo");
            return 1;
        }
        yyin = f;
    }
    yyparse();
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error sintáctico: %s\n", s);
}
