import networkx as nx
import matplotlib.pyplot as plt
import sys
from math import inf
from heapq import heappush, heappop
from collections import deque

galaxies = {}
fueling = {}
G = nx.Graph()
ship_pos = None
ship_fuel = 0
visited_edges = [] # lista de (nodo1, nodo2) del recorrido

def add_galaxy(name, can_fuel=False):
    galaxies[name] = name
    fueling[name] = can_fuel
    G.add_node(name)

def add_edge(g1, g2, cost):
    if g1 in G and g2 in G:
        G.add_edge(g1, g2, weight=cost)

def update_edge(g1, g2, cost):
    if G.has_edge(g1,g2):
        G[g1][g2]['weight']=cost
    else:
        print(f"No se encuentra arista {g1}-{g2} para actualizar.")

def create_ship(galaxy, fuel):
    global ship_pos, ship_fuel
    if galaxy not in G:
        print("Error: galaxia no existe.")
        return
    ship_pos = galaxy
    ship_fuel = fuel

def dijkstra(G, start, end):
    dist = {n:inf for n in G.nodes}
    prev = {n:None for n in G.nodes}
    dist[start]=0
    heap=[(0,start)]
    while heap:
        d,u = heappop(heap)
        if d>dist[u]:
            continue
        if u==end:
            break
        for v in G[u]:
            w=G[u][v]['weight']
            alt=d+w
            if alt<dist[v]:
                dist[v]=alt
                prev[v]=u
                heappush(heap,(alt,v))
    if dist[end]==inf:
        return []
    path=[]
    curr=end
    while curr is not None:
        path.append(curr)
        curr=prev[curr]
    return path[::-1]

def bfs_min_saltos(G,start,end):
    dist={n:inf for n in G.nodes}
    prev={n:None for n in G.nodes}
    dist[start]=0
    q=deque([start])
    while q:
        u=q.popleft()
        if u==end:
            break
        for v in G[u]:
            if dist[v]==inf:
                dist[v]=dist[u]+1
                prev[v]=u
                q.append(v)
    if dist[end]==inf:
        return []
    path=[]
    curr=end
    while curr is not None:
        path.append(curr)
        curr=prev[curr]
    return path[::-1]

def move_ship_along_path(path, steps):
    global ship_pos, ship_fuel
    if ship_pos not in path:
        if path and ship_pos != path[0]:
            return
    idx = path.index(ship_pos)
    to_move=steps
    while to_move>0 and idx<len(path)-1:
        u=path[idx]
        v=path[idx+1]
        cost=G[u][v]['weight']
        if ship_fuel<cost:
            print(f"La nave se quedó sin combustible entre {u} y {v}. Tripulación muere.")
            sys.exit(1)
        ship_fuel-=cost
        ship_pos=v
        visited_edges.append((u,v))
        idx+=1
        to_move-=1

def viajar_auto(destino, modo, pasos):
    global ship_pos
    if ship_pos is None:
        print("Nave no creada.")
        return
    if destino not in G:
        print(f"Destino {destino} no existe.")
        return
    if modo==1:
        path=dijkstra(G, ship_pos, destino)
    else:
        path=bfs_min_saltos(G, ship_pos, destino)
    if not path:
        print(f"No hay ruta hacia {destino}")
        return
    move_ship_along_path(path, pasos)
    if ship_pos==destino:
        print(f"La nave ha llegado a {destino}")

def ver_vecinas(radio):
    if ship_pos is None:
        return
    dist={n:inf for n in G.nodes}
    dist[ship_pos]=0
    q=deque([ship_pos])
    result=[]
    while q:
        u=q.popleft()
        for v in G[u]:
            if dist[v]==inf:
                dist[v]=dist[u]+1
                if dist[v]<=radio:
                    result.append((v,dist[v]))
                    q.append(v)
    print(f"Galaxias alcanzables con radio {radio} desde {ship_pos}:")
    for (g,d) in result:
        print(f" - {g} (dist={d})")

def viaje_manual_hacia(dest):
    global ship_pos, ship_fuel
    if ship_pos is None:
        return
    if dest not in G:
        print(f"Galaxia {dest} no existe.")
        return
    if dest not in G[ship_pos]:
        print(f"La galaxia {dest} no es vecina inmediata.")
        return
    cost=G[ship_pos][dest]['weight']
    if ship_fuel<cost:
        print(f"Sin combustible para ir a {dest}, tripulación muere.")
        sys.exit(1)
    ship_fuel-=cost
    visited_edges.append((ship_pos,dest))
    ship_pos=dest
    print(f"Nave ahora en {ship_pos}, combustible={ship_fuel}")

def recargar():
    global ship_fuel
    if ship_pos is None:
        return
    if fueling[ship_pos]:
        ship_fuel=100
        print(f"Recargado en {ship_pos}, combustible=100")
    else:
        print(f"No se puede recargar en {ship_pos}")

filename = "input.txt"
with open(filename,"r") as f:
    for line in f:
        line=line.strip()
        if not line:
            continue
        parts=line.split()
        cmd=parts[0].upper()

        if cmd=="GALAXIA":
            if len(parts)==2:
                add_galaxy(parts[1], False)
            elif len(parts)==3 and parts[2].upper()=="ABASTECER":
                add_galaxy(parts[1], True)

        elif cmd=="ARISTA":
            if len(parts)==4:
                add_edge(parts[1], parts[2], int(parts[3]))

        elif cmd=="ACTUALIZAR_ARISTA":
            if len(parts)==4:
                update_edge(parts[1], parts[2], int(parts[3]))

        elif cmd=="NAVE":
            if len(parts)==3:
                create_ship(parts[1], int(parts[2]))

        elif cmd=="VIAJE_AUTO":
            destino=None
            modo=1
            pasos=1
            if "DESTINO" in parts:
                idx=parts.index("DESTINO")
                destino=parts[idx+1]
            if "MODO" in parts:
                idx=parts.index("MODO")
                if parts[idx+1].upper()=="MIN_COMBUSTIBLE":
                    modo=1
                else:
                    modo=2
            if "PASOS" in parts:
                idx=parts.index("PASOS")
                pasos=int(parts[idx+1])
            if destino:
                viajar_auto(destino, modo, pasos)

        elif cmd=="VIAJE_MANUAL":
            if "VER_VECINAS" in parts and "RADIO" in parts:
                idx=parts.index("RADIO")
                r=int(parts[idx+1])
                ver_vecinas(r)
            elif "HACIA" in parts:
                idx=parts.index("HACIA")
                d=parts[idx+1]
                viaje_manual_hacia(d)

        elif cmd=="RECARGAR":
            recargar()

        elif cmd=="SALIR":
            print("Saliendo del programa...")
            break

pos = nx.spring_layout(G, seed=42)
plt.figure(figsize=(10,7))
nx.draw_networkx_nodes(G, pos, node_size=700, node_color="lightblue")
nx.draw_networkx_labels(G, pos)
nx.draw_networkx_edges(G, pos, edge_color="gray")

# Destacar las aristas visitadas por la nave
# Convertir en conjunto las aristas para no duplicar
visited_undirected=set()
for (u,v) in visited_edges:
    if (v,u) not in visited_undirected:
        visited_undirected.add((u,v))
nx.draw_networkx_edges(G, pos, edgelist=list(visited_undirected), edge_color="red", width=2.5)
edge_labels = nx.get_edge_attributes(G, 'weight')
nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, font_size=10)
plt.title("Grafo resultante con ruta de la nave")
plt.axis("off")
plt.show()
