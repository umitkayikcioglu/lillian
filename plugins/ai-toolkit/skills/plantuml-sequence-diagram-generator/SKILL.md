---
name: plantuml-sequence-diagram-generator
description: Generate professional PlantUML sequence diagrams with consistent styling, colors, and standardized interaction patterns. Use when a sequence diagram, service flow, or API interaction diagram is needed.
type: guidance
applies_to:
  - Planner
  - Architect
  - Developer
mandatory: conditional
mandatory_when:
  - A sequence or interaction diagram is requested
triggers:
  - sequence diagram
  - service flow
  - api interaction diagram
  - plantuml
references: []
summary: Generate professional PlantUML sequence diagrams with consistent styling, colors, and standardized interaction patterns.
---

# PlantUML Sequence Diagram Generator

Generate consistent, professional sequence diagrams with standardized styling and documentation patterns.

## Initial Questions

Before generating, ask:
1. **Company Name** - For header/footer branding
2. **Title** - Diagram subject (e.g., "Service Flow for XYZ Feature")
3. **Participant Groupings** - Which services belong together? (backend, messaging, external)
4. **Classification** - Header label (e.g., "Confidential\nINTERNAL USE ONLY", "Public")
5. **Interaction architecture** - Which API adapter/protocol and persistence interactions are selected by the
   design or existing implementation?

## Template Structure

```plantuml
@startuml sequence
scale 1.5
skinparam responseMessageBelowArrow true

!define _version %date("yyyy.MMdd.HHmmss")
!define _company [CompanyName]

header [Classification]
title [Title Details]
footer \n<b>_company (c) %date("yyyy")</b>\nVersion _version

autonumber 0.10 20 "<b>[0]"

|||

legend top right
<b><<relay>></b> Passes request as-is
<b><<mediate>></b> Transforms then forwards
end legend

|||

' Components here

' Interactions here

|||
@enduml
```

## Color Assignment (Google Material Design)

| Category | Colors | Hex Codes |
|----------|--------|-----------|
| User's services | Blue | #BBDEFB, #90CAF9, #64B5F6, #42A5F5, #2196F3 |
| External/3rd party | Grey | #ECEFF1, #CFD8DC, #B0BEC5, #90A4AE |
| Databases | Purple | #E1BEE7, #CE93D8 |
| Cache/Search | Cyan | #B2EBF2, #80DEEA, #4DD0E1 |
| Messaging/Queues | Orange/Amber | #FFE0B2, #FFCC80 |
| Success ops | Green | #C8E6C9, #A5D6A7 |
| Workflow | Indigo | #C5CAE9, #9FA8DA |

### Control Structure Colors

```plantuml
loop#EEEEEE #FFEB3B <color:#000000>description</color>
opt#EEEEEE #009688 <color:#FFFFFF>condition</color>
alt#EEEEEE #4CAF50 <color:#FFFFFF>condition1</color>
else #8BC34A <color:#000000>condition2</color>
par #E0F7FA <color:#B71C1C>system-name</color>
group #4CAF50 <color:#FFFFFF>description</color>
```

### Note Colors

| Purpose | Background | Text Color |
|---------|------------|------------|
| Field docs (hexnote) | #FBC02D | default |
| SQL/Query (rnote) | #ECEFF1 | #607D8B |
| Implementation | #FFF9C4 | default |
| Warnings | #F44336 | #FFCDD2 |
| Process | #F8BBD0 | default |
| Questions | #D1C4E9 | #673AB7 |

## Component Declaration

```plantuml
actor "user" as u1

box "Backend Services" #BBDEFB
  boundary "portal" as prt
  control "service" as svc
  control "worker" as wrk
end box

box "Data Layer" #E1BEE7
  queue "rabbitmq" as queue
  database "redis" as cache
  database "mssql" as db
  collections "dbo.Users" AS tbl
  entity "UserModel" as model
end box

participant "External\nProvider" as ext
```

**Component types:** `actor`, `boundary` (UI), `control` (services), `queue`, `database`, `collections` (tables), `entity` (models), `participant` (external)

## Phase Structure

```plantuml
== Phase 1: Description ==
autonumber inc A
' interactions
== Phase 2: Description ==
autonumber inc A
```

## Interaction Patterns

### Field Documentation (hexnote)

**CRITICAL:** Hex notes go ABOVE sender, BEFORE the arrow.

```plantuml
hnote over prt #FBC02D
""@BATCH_SIZE <color: #795548>1000""
""@TIMEOUT    <color: #795548>30""
====
""ID          <color: #795548>{ID}""
====
""STATUS      <color: #795548>{success, failed}""
""MODIFIEDAT  <color: #795548>sysutcdatetime()""
<i><color #455A64>... (fields omitted)</color></i>
end note
prt -> svc: <<action>>
```

**Structure:** Parameters (with `@`) → `====` → Unique IDs → `====` → Update fields

**Array notation:**
```plantuml
hnote over component #FBC02D
""[]""
  ""FIELD1""
  ""FIELD2""
end note
```

### SQL Queries (rnote)

```plantuml
wrk -> db: <<query>>
rnote over db #ECEFF1
<color: #607D8B>""SELECT TOP <color: #B71C1C>@BatchSize""
<color: #607D8B>""FROM dbo.table AS t""
<color: #607D8B>""WHERE t.Status = 1""
end note
db --> wrk: <<recordSet>>
```

### HTTP Endpoints

Read the selected adapter and exact method/route from the documented implementation or the
[API adapter authority](../dotnet-service-generator/references/api-patterns.md#select-the-api-adapter). This
skill visualizes that decision; it does not select or rename the API surface.

```plantuml
' Show the actual selected interaction; do not derive a route in the diagram.
wrk -> svc: <<request>> \n""{ActualHttpMethod} {ActualRoute}""
```

`{ActualHttpMethod}` and `{ActualRoute}` are diagram inputs copied from the selected implementation, not route
naming conventions. Represent a direct database interaction only when that participant actually owns it; API
adapter selection and persistence access are independent architectural decisions.

### Arrow Types

| Arrow | Purpose |
|-------|---------|
| `->` | Sync call |
| `-->` | Sync response |
| `->>` | Async send |
| `-->>` | Async callback |

### Activation

```plantuml
component1 -> component2: <<action>>
activate component1
activate component2
component2 --> component1: result
deactivate component2
deactivate component1
```

## Action Verbs

Use camelCase in double angle brackets:

- **Lifecycle:** `<<initiate>>`, `<<publish>>`, `<<acknowledge>>`, `<<notify>>`
- **CRUD:** `<<createRecord>>`, `<<updateRecord>>`, `<<deleteRecord>>`
- **Read:** `<<read>>`, `<<query>>`, `<<count>>`, `<<retrieve>>`, `<<search>>`
- **Processing:** `<<transform>>`, `<<process>>`, `<<validate>>`, `<<decide>>`
- **Transfer:** `<<relay>>` (as-is), `<<mediate>>` (transforms)
- **Data:** `<<insert>>`, `<<upload>>`, `<<download>>`, `<<sync>>`
- **State:** `<<lock>>`, `<<unlock>>`, `<<set>>`, `<<get>>`, `<<cache>>`

Add context: `<<prepare>> records for insertion`

## Special Elements

```plantuml
... batch process ...
... implementation details omitted ...
|||  ' spacing
destroy component1  ' lifeline end
```

## Critical Rules

1. Hex notes ALWAYS above sender, NEVER on receiver
2. Control structure text MUST be readable (use appropriate `<color:>` tags)
3. Reflect the selected API adapter/protocol and actual persistence boundary; never substitute OData for a
   direct database interaction, or raw SQL for an API call, merely as a diagram preference
4. Use rnote spanning components for WHERE clauses
5. Double `====` in hex: Parameters → Unique IDs → Fields
6. Parameter values: `<color:#795548>`
7. Comments: `<color:#455A64>`
8. Field names in double quotes
9. Add `|||` spacing before Phase 1 and before `@enduml`
