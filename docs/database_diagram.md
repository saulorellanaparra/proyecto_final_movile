# Diagrama de Base de Datos - Inventory App

## Diagrama Mermaid (para GitHub/GitLab/Notion)

Copia y pega en cualquier editor que soporte Mermaid o en [mermaid.live](https://mermaid.live)

```mermaid
erDiagram
    %% ==================== USUARIOS Y ROLES ====================
    USERS {
        int id PK
        string username UK
        string password_hash
        string full_name
        string email UK
        string phone
        boolean is_active
        datetime created_at
        datetime updated_at
        datetime last_sync_at
        int store_id FK
        int warehouse_id FK
    }

    ROLES {
        int id PK
        string code UK
        string name
        string description
        string permissions_json
        datetime created_at
    }

    USER_ROLES {
        int id PK
        int user_id FK
        int role_id FK
        int store_id FK
        int warehouse_id FK
        boolean is_primary
        datetime assigned_at
    }

    %% ==================== UBICACIONES ====================
    STORES {
        int id PK
        string code UK
        string name
        string address
        string phone
        string email
        int manager_id FK
        real latitude
        real longitude
        boolean is_active
        datetime created_at
        datetime updated_at
        datetime last_sync_at
    }

    WAREHOUSES {
        int id PK
        string code UK
        string name
        string address
        string phone
        string email
        int manager_id FK
        real latitude
        real longitude
        boolean is_active
        datetime created_at
        datetime updated_at
        datetime last_sync_at
    }

    %% ==================== PRODUCTOS ====================
    PRODUCTS {
        int id PK
        string code UK
        string name
        string description
        string brand
        string category
        real base_price
        real cost_price
        string image_url
        boolean is_active
        datetime created_at
        datetime updated_at
        datetime last_sync_at
    }

    PRODUCT_VARIANTS {
        int id PK
        int product_id FK
        string sku UK
        string size
        string color
        string barcode UK
        real additional_price
        string notes
        string image_url
        boolean is_active
        datetime created_at
        datetime updated_at
        datetime last_sync_at
    }

    %% ==================== INVENTARIO ====================
    INVENTORY {
        int id PK
        int product_variant_id FK
        string location_type
        int location_id
        int quantity
        int min_stock
        int max_stock
        datetime last_updated
        int updated_by FK
        datetime last_sync_at
    }

    INVENTORY_MOVEMENTS {
        int id PK
        int product_variant_id FK
        string location_type
        int location_id
        string movement_type
        string reference_type
        int reference_id
        int quantity_change
        int quantity_before
        int quantity_after
        string notes
        int created_by FK
        datetime created_at
        datetime last_sync_at
    }

    %% ==================== VENTAS ====================
    SALES {
        int id PK
        string sale_number UK
        int store_id FK
        string customer_name
        string customer_document
        string customer_phone
        string customer_email
        datetime sale_date
        real subtotal
        real discount
        real tax
        real total
        string payment_method
        real cash_amount
        real card_amount
        string notes
        string status
        int created_by FK
        datetime created_at
        datetime updated_at
        datetime last_sync_at
    }

    SALE_DETAILS {
        int id PK
        int sale_id FK
        int product_variant_id FK
        int quantity
        real unit_price
        real discount
        real subtotal
        datetime created_at
        datetime last_sync_at
    }

    %% ==================== COMPRAS ====================
    PURCHASES {
        int id PK
        string purchase_number UK
        string supplier_name
        string supplier_ruc
        string supplier_phone
        string supplier_email
        int warehouse_id FK
        datetime purchase_date
        real total_amount
        string notes
        string status
        int created_by FK
        datetime created_at
        datetime updated_at
        datetime last_sync_at
    }

    PURCHASE_DETAILS {
        int id PK
        int purchase_id FK
        int product_variant_id FK
        int quantity
        real unit_cost
        real subtotal
        datetime created_at
        datetime last_sync_at
    }

    %% ==================== TRANSFERENCIAS ====================
    TRANSFERS {
        int id PK
        string transfer_number UK
        string from_type
        int from_id
        string to_type
        int to_id
        datetime transfer_date
        string status
        string notes
        int created_by FK
        datetime created_at
        int approved_by FK
        datetime approved_at
        int received_by FK
        datetime received_at
        datetime updated_at
        datetime last_sync_at
    }

    TRANSFER_DETAILS {
        int id PK
        int transfer_id FK
        int product_variant_id FK
        int quantity
        int received_quantity
        string notes
        datetime created_at
        datetime last_sync_at
    }

    %% ==================== SINCRONIZACIÓN ====================
    SYNC_QUEUE {
        int id PK
        string table_name
        int record_id
        string operation
        string data
        string status
        datetime created_at
        datetime processed_at
    }

    %% ==================== RELACIONES ====================
    USERS ||--o{ USER_ROLES : "tiene"
    ROLES ||--o{ USER_ROLES : "asignado a"
    STORES ||--o{ USER_ROLES : "ubicación"
    WAREHOUSES ||--o{ USER_ROLES : "ubicación"

    USERS ||--o| STORES : "asignado a"
    USERS ||--o| WAREHOUSES : "asignado a"
    USERS ||--o| STORES : "gerente de"
    USERS ||--o| WAREHOUSES : "gerente de"

    PRODUCTS ||--o{ PRODUCT_VARIANTS : "tiene variantes"

    PRODUCT_VARIANTS ||--o{ INVENTORY : "stock en"
    PRODUCT_VARIANTS ||--o{ INVENTORY_MOVEMENTS : "movimientos"
    PRODUCT_VARIANTS ||--o{ SALE_DETAILS : "vendido en"
    PRODUCT_VARIANTS ||--o{ PURCHASE_DETAILS : "comprado en"
    PRODUCT_VARIANTS ||--o{ TRANSFER_DETAILS : "transferido en"

    STORES ||--o{ SALES : "ventas"
    SALES ||--o{ SALE_DETAILS : "items"
    USERS ||--o{ SALES : "creó"

    WAREHOUSES ||--o{ PURCHASES : "recibe"
    PURCHASES ||--o{ PURCHASE_DETAILS : "items"
    USERS ||--o{ PURCHASES : "creó"

    TRANSFERS ||--o{ TRANSFER_DETAILS : "items"
    USERS ||--o{ TRANSFERS : "creó"
    USERS ||--o{ TRANSFERS : "aprobó"
    USERS ||--o{ TRANSFERS : "recibió"

    USERS ||--o{ INVENTORY : "actualizó"
    USERS ||--o{ INVENTORY_MOVEMENTS : "creó"
```

---

## Uso del Diagrama

### Opción 1: Mermaid Live Editor
1. Ve a [mermaid.live](https://mermaid.live)
2. Copia el código Mermaid de arriba
3. Descarga como PNG, SVG o PDF

### Opción 2: dbdiagram.io
1. Ve a [dbdiagram.io](https://dbdiagram.io)
2. Usa el archivo DBML incluido abajo
3. Exporta como PNG, PDF o SQL

### Opción 3: Draw.io / diagrams.net
1. Ve a [diagrams.net](https://app.diagrams.net)
2. Importa el diagrama o créalo manualmente
3. Exporta en cualquier formato

---

## Resumen de Tablas

| Tabla | Descripción | Registros relacionados |
|-------|-------------|------------------------|
| `users` | Usuarios del sistema | Roles, Tiendas, Almacenes |
| `roles` | Roles y permisos | Usuarios |
| `user_roles` | Asignación usuario-rol | Usuarios, Roles, Ubicaciones |
| `stores` | Tiendas/Sucursales | Ventas, Inventario, Usuarios |
| `warehouses` | Almacenes | Compras, Inventario, Usuarios |
| `products` | Productos base | Variantes |
| `product_variants` | Variantes (talla/color) | Inventario, Ventas, Compras |
| `inventory` | Stock por ubicación | Variantes, Ubicaciones |
| `inventory_movements` | Historial de movimientos | Variantes, Usuarios |
| `sales` | Cabecera de ventas | Tiendas, Usuarios |
| `sale_details` | Detalle de ventas | Ventas, Variantes |
| `purchases` | Cabecera de compras | Almacenes, Usuarios |
| `purchase_details` | Detalle de compras | Compras, Variantes |
| `transfers` | Cabecera transferencias | Usuarios (3), Ubicaciones |
| `transfer_details` | Detalle transferencias | Transferencias, Variantes |
| `sync_queue` | Cola sincronización offline | - |
