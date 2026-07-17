# Códigos Mermaid para Diagramas Académicos (Optimizados para Dos Columnas)

El formato de dos columnas de IEEE Access requiere que las figuras sean **horizontales** (más anchas que altas) o muy compactas para evitar desbordes o desperdicio de espacio vertical. 

A continuación se presentan tres opciones optimizadas que puede exportar en formato JPG o PNG desde [Mermaid Live Editor](https://mermaid.live/) y colocar en su directorio `oficial/images/`.

---

## 1. Rediseño Horizontal de la Arquitectura de Red
Este diseño utiliza una distribución de izquierda a derecha (`graph LR`) en lugar de vertical. Se consolida el flujo para que el aspecto sea alargado (horizontal) y quepa dentro del ancho de una columna (`\columnwidth`) sin superar los 3.5 cm de altura en el PDF.

**Nombre sugerido para guardar:** `arquitectura_red.png`

```mermaid
graph LR
    %% Estilos
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:1px;
    classDef wan fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px;
    classDef fw fill:#dae8fc,stroke:#6c8ebf,stroke-width:1.5px;
    classDef sw fill:#e1d5e7,stroke:#9673a6,stroke-width:1.5px;
    classDef pc fill:#d5e8d4,stroke:#82b366,stroke-width:1px;
    classDef server fill:#f5f5f5,stroke:#666,stroke-width:1.5px;

    %% Nodos
    WAN["Internet (WAN)"]:::wan
    FW["Firewall Perimetral"]:::fw
    SW["Switch Central (Rack)"]:::sw
    SRV["Servidor Local"]:::server

    %% Conexiones principales
    WAN -->|Puerto 445| FW
    FW -->|Filtro 70%| SW
    SW --> SRV

    %% Subgrafos de laboratorios compactos y paralelos
    subgraph L1 ["Lab 1"]
        P1["PC 01 → PC 02 → ... → PC 20"]:::pc
    end

    subgraph L2 ["Lab 2"]
        P2["PC 01 → PC 02 → ... → PC 20"]:::pc
    end

    subgraph L7 ["Lab 7"]
        P7["PC 01 → PC 02 → ... → PC 20"]:::pc
    end

    %% Enlaces de acceso
    SW --> L1
    SW --> L2
    SW -.->|Labs 3-6| L7
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
