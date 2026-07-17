# Códigos Mermaid para Diagramas Académicos (Optimizados para Dos Columnas)

El formato de dos columnas de IEEE Access requiere que las figuras sean **horizontales** (más anchas que altas) o muy compactas para evitar desbordes o desperdicio de espacio vertical. 

A continuación se presentan tres opciones optimizadas que puede exportar en formato JPG o PNG desde [Mermaid Live Editor](https://mermaid.live/) y colocar en su directorio `oficial/images/`.

---

## 1. Rediseño Horizontal de la Arquitectura de Red
Este diseño utiliza una distribución de izquierda a derecha (`graph LR`) en lugar de vertical. Se consolida el flujo para que el aspecto sea alargado (horizontal) y quepa dentro del ancho de una columna (`\columnwidth`) sin superar los 3.5 cm de altura en el PDF.

**Nombre sugerido para guardar:** `arquitectura_red.png`

```mermaid
graph TD
    %% Estilos de nodos
    classDef wan fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px;
    classDef fw fill:#dae8fc,stroke:#6c8ebf,stroke-width:1.5px;
    classDef sw fill:#e1d5e7,stroke:#9673a6,stroke-width:1.5px;
    classDef pc fill:#d5e8d4,stroke:#82b366,stroke-width:1px;
    classDef server fill:#f5f5f5,stroke:#666,stroke-width:1.5px;

    %% Nodos principales con formas semánticas
    WAN(((Internet WAN))):::wan
    FW[Firewall Perimetral]:::fw
    SW{Switch Central - Rack}:::sw

    %% Subgrafo compacto para los objetivos de la infección
    subgraph LAN [Entorno de Red Interna]
        SRV[(Servidor Local)]:::server
        L1[Lab 1 <br> 20 Nodos]:::pc
        L2[Lab 2 <br> 20 Nodos]:::pc
        L7[Lab 7 <br> 20 Nodos]:::pc
    end

    %% Flujo del ataque
    WAN -- Intento de Infección <br> Puerto TCP 445 --> FW
    FW -- Tasa de Filtrado: 70% --> SW
    
    %% Ramificación interna
    SW --> SRV
    SW --> L1
    SW --> L2
    SW -. Propagación Lateral <br> Labs 3-6 .-> L7
```

---

## 2. Diagrama de Transición de Estados del Agente (FSM)
Este diagrama de máquina de estados describe de forma muy compacta cómo transita un nodo/PC entre los diferentes estados de la simulación. Es cuadrado y encaja en cualquier sección del artículo (por ejemplo, en la Sección III. Metodología).

**Nombre sugerido para guardar:** `estados_agente.png`

```mermaid
stateDiagram-v2
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:1px;
    
    [*] --> Sano : Inicialización
    
    state Sano {
        [*] --> Susceptible
    }
    
    Susceptible --> Infectado : Ataque Exitoso<br/>U(0,1) < P(i->j)
    Susceptible --> Protegido_Aislado : Contingencia Activa<br/>(Infección >= 30%)
    
    Infectado --> [*] : Cifrado Completo
    Protegido_Aislado --> [*] : Inmunizado
```

---

## 3. Diagrama de Flujo del Motor de Infección (Decisión)
Este diagrama describe la lógica probabilística por cada intento de infección desde un nodo comprometido hacia un vecino. Sirve para enriquecer la explicación de la Sección III-C (Motor Matemático).

**Nombre sugerido para guardar:** `flujo_infeccion.png`

```mermaid
flowchart TD
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:1px;
    classDef check fill:#dae8fc,stroke:#6c8ebf,stroke-width:1.5px;
    classDef action fill:#d5e8d4,stroke:#82b366,stroke-width:1.5px;
    classDef block fill:#f8cecc,stroke:#b85450,stroke-width:1.5px;

    Start([Vecino Seleccionado]) --> IsolCheck{¿Está Aislado o Asegurado?}:::check
    IsolCheck -- Sí --> Block[Infección Bloqueada]:::block
    IsolCheck -- No --> PortCheck{¿Puerto 445 Abierto?}:::check
    
    PortCheck -- No --> Block
    PortCheck -- Sí --> CalcProb[Calcular Probabilidad P_inf<br/>Atenuada por Firewall y Parcheo]:::action
    
    CalcProb --> RollCheck{¿U(0,1) < P_inf?}:::check
    RollCheck -- No --> Block
    RollCheck -- Sí --> Infect[Infectar Host]:::action
```

---

## 4. Diagrama del Dashboard de Monitoreo y Flujo de Datos
Este diagrama representa la arquitectura interna de la aplicación frontend en Vue 3 y el flujo dinámico de datos desde la simulación en GAMA Platform hasta los gráficos temporales y topológicos de la interfaz. Representa conceptualmente lo mostrado en la **Figura 4** (curvas de propagación, parches e intenciones BDI).

**Nombre sugerido para guardar:** `curvas_simulacion.png` o `dashboard_flow.png`

```mermaid
%%{init: {'theme': 'default', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'Helvetica, Arial, sans-serif' }}}%%
flowchart TD
    %% Estilos de alto contraste adaptados para impresión/lectura en columna
    classDef data fill:#f5f5f5,stroke:#666,stroke-width:2px,color:#333333,font-size:15px,font-weight:bold;
    classDef logic fill:#dae8fc,stroke:#6c8ebf,stroke-width:2px,color:#1a365d,font-size:15px,font-weight:bold;
    classDef ui fill:#d5e8d4,stroke:#82b366,stroke-width:2px,color:#1f4728,font-size:15px,font-weight:bold;

    subgraph Capa_Datos [1. Datos: GAMA Simulator]
        CSV["Fuentes .csv<br/>(Métricas, Nodos,<br/>Topología)"]:::data
    end

    subgraph Capa_Logica [2. Middleware: Vue 3]
        Papa["PapaParse<br/>(Async Parser)"]:::logic
        State["Vue State<br/>(Local Reactivo)"]:::logic
    end

    subgraph Capa_UI [3. Interfaz de Monitoreo]
        Cytoscape["Mapa de Red<br/>(Cytoscape)"]:::ui
        ECharts["Métricas<br/>(ECharts)"]:::ui
        Table["Incidentes<br/>(BDI)"]:::ui
        
        %% TRUCO: Enlaces invisibles para forzar el apilamiento vertical
        Cytoscape ~~~ ECharts
        ECharts ~~~ Table
    end

    %% Flujo Lineal Principal
    CSV -->|Polling 2s| Papa
    Papa -->|Objects JSON| State
    
    %% Conexiones de datos hacia la UI
    State -->|Binding| Cytoscape
    State -->|Binding| ECharts
    State -->|Binding| Table
```
