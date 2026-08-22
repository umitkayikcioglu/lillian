# Lillian Assistant — Knowledge ve Routing Referansı

## 1. Dokümanın Amacı

Bu doküman, **Lillian Assistant** için ayrıntılı başvuru kaynağıdır.

GPT Builder içindeki davranış kuralları `Instructions` alanından yönetilir. Bu dosya ise **Knowledge** bölümüne yüklenmelidir.

Bu doküman statik bir referanstır. Lillian ve kullanılan proje zaman içinde değişebileceği için nihai karar her zaman mevcut repository dosyaları incelenerek verilmelidir.

Öncelik:

> **Güncel repository içeriği bu Knowledge dokümanından üstündür.**

## 2. Önerilen Dil Yapısı

- GPT Builder `Instructions`: İngilizce
- Knowledge açıklamaları: Türkçe
- Dosya yolları, skill adları, agent adları ve teknik anahtar kelimeler: Repository’deki orijinal İngilizce biçimiyle
- Kullanıcıya verilen açıklamalar: Türkçe
- Codex promptları: Teknik doğruluk açısından varsayılan İngilizce; kullanıcı isterse Türkçe

Bu yapı, kullanıcı iletişiminde açıklığı korurken Lillian ve Codex terminolojisiyle birebir uyum sağlar.

## 3. Lillian İçerik Türleri

Lillian farklı sorumluluklara sahip içerik türleri kullanır.

| İçerik türü | Canonical konum | Görevi | Kullanım yaklaşımı |
|---|---|---|---|
| Engineering standards | `.github/CONTRIBUTING.md` | Mimari, kod kalitesi ve mühendislik standartları | İlgili görevlerde authoritative kaynak |
| Project orchestration | `AGENTS.md`, `.github/copilot-instructions.md` | Projeye özel asistan ve workflow kuralları | Mevcutsa okunmalı |
| Path instructions | `.github/instructions/*.instructions.md` | Teknoloji ve path bazlı routing | Yalnız ilgili scope için |
| Skill index | `.github/skills/INDEX.md` | Skill keşfi ve `mandatory_when` eşleşmeleri | Esas routing kaynağı |
| Skills | `.github/skills/<name>/SKILL.md` | Tekrar kullanılabilir uzmanlık bilgisi | Varsayılan uygulama mekanizması |
| Skill references | Skill altındaki `references/*.md` | Ayrıntılı teknoloji rehberleri | Deterministik ve seçici yüklenmeli |
| Prompts | `.github/prompts/*.prompt.md` | Hazır launcher ve prompt yapıları | Sıfırdan prompt üretmeden önce kontrol edilmeli |
| Workflow agents | `.github/agents/workflow-*.agent.md` | Bağımsız rol sözleşmeleri ve kalite kapıları | İhtiyaç olduğunda kullanılmalı |
| Full workflow | `.github/prompts/agent-workflow.prompt.md` | Agent sırası ve handoff kuralları | Varsayılan değildir |

## 4. Temel Routing İlkesi

Standart karar sırası:

1. Güncel repository evidence incelenir.
2. Repository-owned instructions yüklenir.
3. Zorunlu ve ilgili skill’ler seçilir.
4. Uygun hazır prompt veya skill invocation aranır.
5. Rol ayrımına ihtiyaç yoksa doğrudan uygulanır.
6. Yalnız gerekli ise tek agent seçilir.
7. Birden fazla bağımsız kalite kapısı gerekiyorsa selected multi-role route kullanılır.
8. Full workflow yalnızca yüksek fayda sağlıyorsa önerilir.

Özet:

> **Skill-first, prompt-first, agent-when-necessary.**

`Direct Skill/Prompt Route`, Lillian kullanılmadığı anlamına gelmez. Agent persona açılmadan Lillian instructions, skill, reference ve promptlarının kullanılması anlamına gelir.

## 5. Skill, Prompt ve Agent Arasındaki Fark

### 5.1 Skill

Skill, belirli bir mühendislik alanına ait tekrar kullanılabilir çalışma sözleşmesidir.

Kullanım biçimleri:

- Codex içinde doğrudan invocation: `$web-frontend-development`
- Codex’e belirli bir `SKILL.md` dosyasını okuma talimatı verme
- Bir agent rolü içinde kullanma
- Bounded bir direct prompt içinde referans verme

Bir skill’in kullanılabilmesi için agent workflow başlatılması gerekmez.

### 5.2 Prompt

Prompt dosyaları genellikle thin launcher veya hazır görev yapısıdır.

Bir prompt:

- Bir skill’i yükleyebilir
- Standart bir işlemi başlatabilir
- Workflow rolünü destekleyebilir
- Skill kullanım örneği sunabilir

Prompt frontmatter içindeki `mode: agent`, her zaman Lillian workflow persona kullanılması gerektiği anlamına gelmez.

Rol ayrımı gerekmiyorsa:

- Alttaki skill doğrudan çağrılabilir
- Launcher direct route için uyarlanabilir
- Promptun amacı korunarak agent persona açılmayabilir

### 5.3 Agent

Agent dosyaları bağımsız rollerin `Entry`, `Responsibilities`, `Output Format`, `Behavioral Rules` ve `Exit` sınırlarını tanımlar.

Agent kullanımı şu durumlarda değerlidir:

- Bağımsız inceleme gerekiyorsa
- Bir uzmanlık alanının ayrı onayı gerekiyorsa
- Handoff ve quality gate gerçekten fayda sağlıyorsa
- Aynı context içinde rol çatışması oluşma riski varsa

Agent kullanımı token maliyetini artırabilir:

- Ortak context tekrar okunur
- Ayrı artifact üretilir
- Handoff yapılır
- Review döngüsü oluşur
- Ek context veya subagent kullanılabilir

Bu nedenle agent varsayılan değil, gerekçeli istisnadır.

## 6. Güncel Skill Catalog Yaklaşımı

Authoritative katalog `.github/skills/INDEX.md` dosyasıdır.

Bilinen temel skill’ler:

| Skill | Temel kullanım |
|---|---|
| `documentation-generator` | ADR, RFC, Design Doc, runbook, SOP, handover, postmortem, test plan ve diğer dokümanlar |
| `dotnet-service-generator` | Yeni .NET servis veya modül scaffold işlemleri |
| `excalidraw-diagram-generator` | Excalidraw tabanlı diyagramlar |
| `infrastructure` | Dockerfile, Kubernetes, deployment, container ve health probe |
| `mssql-bulk-data-operations` | Büyük MSSQL veri setlerinde güvenli batch operasyonları |
| `mssql-table-scaffolder` | MSSQL tablo oluşturma ve standardizasyon |
| `observability` | SLI, metric, trace, dashboard ve alert |
| `plantuml-sequence-diagram-generator` | Sequence ve service interaction diyagramları |
| `pressure-test` | Yüksek maliyetli çoklu persona adversarial değerlendirme |
| `project-instructions-bootstrap` | Projeye ait CONTRIBUTING ve orchestration dosyalarını oluşturma/güncelleme |
| `session-handoff` | Oturum sonu context aktarımı |
| `solution-structure` | .NET solution içindeki dosya ve klasör yerleşimi |
| `storm-research` | Çoklu perspektif ve citation tabanlı geniş araştırma |
| `web-frontend-development` | TypeScript, React, Next.js, Angular ve frontend validation |
| `work-item-generator` | Initiative, epic, feature, story, bug, spike ve task üretimi |
| `workspace-productivity` | Workspace görev ve memory süreçleri |

Bu liste kalıcı whitelist değildir. Her görevde güncel `INDEX.md` kontrol edilmelidir.

## 7. Frontend İçin Agent Kullanmadan Direct Route

### 7.1 Kullanım Alanı

Aşağıdaki işler için varsayılan olarak `web-frontend-development` skill’i doğrudan kullanılır:

- TypeScript geliştirme veya review
- React component, hook, state ve rendering işleri
- Next.js router, server/client boundary, caching, metadata ve route handler işleri
- Angular DI, standalone/module, signals, RxJS, forms, routing ve template işleri
- Lint, type-check, test veya build hataları
- Package manager ve workspace command routing
- Frontend test ve validation analizi

Normal frontend geliştirme için Planner, Architect veya Developer agent zorunlu değildir.

### 7.2 Zorunlu Reference Yükleme

Her aktif frontend görevinde bir kez yüklenir:

- `references/frontend-quality.md`
- `references/package-management.md`

Teknoloji referansları yalnız definitive evidence bulunduğunda yüklenir:

| Teknoloji | Definitive evidence |
|---|---|
| TypeScript | `tsconfig*.json` veya declared `typescript` dependency |
| React | Declared `react` dependency veya peer dependency |
| Next.js | Declared `next` dependency |
| Angular | `angular.json` veya declared `@angular/core` dependency |

`references/testing.md` yalnız test oluşturma, test düzeltme, test review veya test validation kapsamdaysa yüklenir.

### 7.3 Manifest-First Discovery

İnceleme sırası:

1. Root manifest
2. Workspace declaration
3. Owning package manifest
4. Framework configuration
5. Framework kesinleştikten sonra gerekli source dosyaları

Şunlar tek başına framework aktivasyonu için yeterli değildir:

- `.tsx` uzantısı
- `app/` veya `pages/` klasörü
- `next.config.*`
- Angular benzeri dosya adları
- CI içindeki framework benzeri script adı

### 7.4 Scope-Aware Validation

Her touched scope için ayrı ayrı belirlenir:

- Owning project/package
- Working directory
- Package manager
- Exact command
- Validation category
- Evidence source

Yapılmaması gerekenler:

- npm komutunu pnpm/Yarn/Bun komutuna çevirmek
- Olmayan script uydurmak
- `lint`, `test`, `build` veya `e2e` target’ı var kabul etmek
- `Not configured` sonucunu PASS saymak
- Onaysız package veya test framework eklemek
- Varsayılan olarak repository-wide mutating formatter çalıştırmak

### 7.5 Örnek Direct Frontend Codex Promptu

```text
Use the `$web-frontend-development` skill.

Read the repository-owned instructions and relevant package manifests first.
Activate TypeScript, React, Next.js, or Angular guidance only from definitive repository evidence.
Load frontend-quality and package-management exactly once.
Load testing guidance only if tests are in scope.

Objective:
[bounded objective]

Scope:
[files, package, or workspace]

Constraints:
- Preserve the existing component architecture and styling system.
- Do not add or replace dependencies.
- Do not invent validation scripts.
- Do not perform unrelated cleanup.

Validation:
Discover exact commands from repository evidence for the owning scope and report each result separately.

Output:
Summarize changed files, acceptance-criteria evidence, exact commands, results, and blockers.
```

## 8. .NET İçin Agent Kullanmadan Direct Route

### 8.1 Normal .NET Geliştirme

Bounded bir .NET işi için:

- Repository C#/.NET instructions okunur
- En yakın owning `.csproj` belirlenir
- `.sln` grouping evidence olarak değerlendirilir
- `.github/CONTRIBUTING.md` uygulanır
- İlgili skill’ler seçilir
- Repository-defined build, test, analyzer ve format commandları kullanılır
- Tasarım belirsizliği yoksa Planner veya Architect agent açılmaz

### 8.2 Yeni Servis Scaffold

Aşağıdaki durumlarda `dotnet-service-generator` kullanılır:

- Yeni .NET service oluşturma
- Yeni service module ekleme
- Service boilerplate üretme

Skill tipik olarak şu bilgileri toplar:

- Service name
- Namespace
- Purpose
- Output location
- Interface visibility
- Dependencies
- Service lifetime

İlişkili skill’ler:

- `solution-structure`: Dosya/klasör yerleşimi
- `observability`: Instrumentation ve metric gereksinimleri
- `infrastructure`: Deployment/container dosyaları kapsamdaysa

Mevcut bir service içindeki küçük değişiklik için `dotnet-service-generator` kullanılmamalıdır.

### 8.3 Solution Structure

Aşağıdakilerin nereye yerleştirileceği belirlenirken `solution-structure` kullanılmalıdır:

- .NET service ve project dosyaları
- Test projectleri
- Documentation
- Dashboard
- Kubernetes manifest
- Embedded SQL veya template
- Module artifactları

`dotnet-service-generator` ile `solution-structure` arasında placement çelişkisi varsa `solution-structure` kazanır.

### 8.4 Observability

Aşağıdakiler kapsamdaysa `observability` skill’i yüklenir:

- Structured logging
- Event ID
- OpenTelemetry trace
- Metric
- SLI
- Grafana dashboard
- Alert
- Health, readiness veya liveness monitoring

Task veya repository standardı gerektirmiyorsa gereksiz observability artifact üretilmemelidir.

### 8.5 Örnek Direct .NET Codex Promptu

```text
Operate through a direct Lillian skill route; do not start the full agent workflow.

Read:
- AGENTS.md
- .github/CONTRIBUTING.md
- applicable C#/.NET instructions
- .github/skills/INDEX.md
- the nearest owning .csproj
- any applicable skill files

Apply:
- `$dotnet-service-generator` only if this creates a new service/module
- `solution-structure` for placement decisions
- `observability` only when instrumentation is in scope
- `infrastructure` only when deployment/container files are in scope

Objective:
[bounded objective]

Approved inputs:
[plan, architecture, checklist, or none]

Constraints:
- Keep the change minimal.
- Preserve existing public contracts unless explicitly approved.
- Add no new dependency without approval.
- Do not perform unrelated refactoring.
- Use the repository-defined testing policy.

Validation:
Discover and run exact repository-defined commands for each touched .NET scope.
Do not invent commands or report unavailable validation as PASS.

Output:
Changed files, criteria mapping, skills applied, exact validation commands, results, and blockers.
```

## 9. Hazır Prompt Kullanım Politikası

Sıfırdan prompt üretmeden önce `.github/prompts/` kontrol edilir.

Uygun prompt bulunursa:

1. Canonical launcher veya structural base olarak kullanılır.
2. Amacı ve sınırları korunur.
3. Mevcut task scope, acceptance criteria ve validation requirements eklenir.
4. Skill tarafından zaten yönetilen içerik tekrar yazılmaz.
5. Prompt frontmatter nedeniyle otomatik workflow agent açılmaz.
6. Şu kavramlar ayrıştırılır:
   - Codex execution mode
   - Lillian workflow persona
   - Skill invocation

Hazır prompt görevi doğrudan karşılamıyorsa ancak alttaki skill uygunsa skill doğrudan çağrılır.

### Bilinen Örnekler

- `.github/prompts/web-frontend-development.prompt.md`
- `.github/prompts/agent-workflow.prompt.md`

Frontend launcher thin loader’dır ve `web-frontend-development` skill’ini yükler. Tek başına Planner, Architect veya Developer geçişi başlatmaz.

`agent-workflow.prompt.md` ise yalnız formal role sequencing ve human approval gate gerektiğinde kullanılmalıdır.

### Prompt Catalog

Authoritative prompt listesi her zaman `.github/prompts/` üzerinden doğrulanmalıdır.

Güncel repository evidence ile doğrulanan promptlar:

| Prompt | Temel kullanım |
|---|---|
| `add-grafana-dashboard.prompt.md` | Servis için Grafana dashboard ekleme |
| `add-tests.prompt.md` | Mevcut kod için test scaffolding veya test ekleme |
| `agent-workflow.prompt.md` | Formal Lillian sequential workflow |
| `code-review.prompt.md` | CONTRIBUTING standardına göre review gate |
| `migrate-service.prompt.md` | Mevcut .NET service migration |
| `my-code-review-comprehensive.prompt.md` | Çok boyutlu kapsamlı review |
| `my-code-review-requirements.prompt.md` | Business requirement ve flow doğrulama review |
| `my-repo-analysis.prompt.md` | Repository amacı, mimarisi ve işleyiş analizi |
| `new-service.prompt.md` | Yeni .NET service scaffold |
| `project-instructions-bootstrap.prompt.md` | Consuming repository için instruction bootstrap |
| `restructure-service.prompt.md` | Mevcut service folder/naming restructure |
| `scaffold-table.prompt.md` | MSSQL tablo oluşturma veya migration |
| `sequence-plantuml-diagram.prompt.md` | PlantUML sequence diagram üretimi |
| `update-docs.prompt.md` | Değişikliklere göre doküman güncelleme |
| `validate-service-migration.prompt.md` | Service migration davranış koruma validation |
| `web-frontend-development.prompt.md` | Frontend skill launcher |

## 10. Agent Referansı

| Agent | Ürettiği çıktı | Ne zaman kullanılır | Ne zaman atlanır |
|---|---|---|---|
| Planner | Scope, plan, acceptance criteria, required skills/roles | Gereksinimler materially ambiguous ise | Approved plan varsa veya iş bounded ise |
| Architect | Technical design, boundaries, data flow, observability requirements | Sistem tasarımı unresolved ise | Design onaylıysa veya değişiklik lokal ise |
| Designer | UI mockup, component mapping, user flow | Visual/interaction design gerçekten gerekiyorsa | Existing UI pattern yeterince açıksa |
| DBA | Schema, migration, index, rollback, locking analizi | Database specialist judgment gerekiyorsa | Schema/index/migration değişmiyorsa |
| Developer | Implementation ve validation evidence | Workflow içinde ayrı implementation rolü gerekiyorsa | Direct skill route yeterliyse |
| Reviewer | PASS/FAIL ve fix checklist | Bağımsız quality gate gerekiyorsa | Kullanıcı yalnız bounded implementation istiyorsa |
| Tester Phase 1 | Acceptance criteria ile eşleşen test cases | Formal build contract değerliyse | Test cases zaten varsa veya iş basitse |
| Tester Phase 2 | Executable tests | Bağımsız test uygulama rolü gerekiyorsa | Direct implementation yeterliyse |
| Documenter | RFC, Design Doc, ADR, README, runbook, SOP | Formal documentation lifecycle gerekiyorsa | Documentation etkisi olmayan küçük değişiklikte |

### Workflow Agent Dosyaları

| Dosya | Rol |
|---|---|
| `workflow-planner.agent.md` | Planner |
| `workflow-architect.agent.md` | Architect |
| `workflow-designer.agent.md` | Designer |
| `workflow-dba.agent.md` | DBA |
| `workflow-developer.agent.md` | Developer |
| `workflow-reviewer.agent.md` | Reviewer |
| `workflow-tester.agent.md` | Tester |
| `workflow-documenter.agent.md` | Documenter |

### Council Agent Dosyaları

Council agentları varsayılan route değildir. `pressure-test` veya benzeri adversarial değerlendirme açıkça istenirse kullanılır.

| Dosya | Perspektif |
|---|---|
| `council-buyer.agent.md` | Buyer |
| `council-contrarian.agent.md` | Contrarian |
| `council-expansionist.agent.md` | Expansionist |
| `council-logician.agent.md` | Logician |
| `council-researcher.agent.md` | Researcher |

## 11. Tamamlanmış Artifactların Tekrar Kullanımı

Tamamlanmış workflow çıktıları yeniden üretilmez.

| Mevcut artifact | Doğru sonraki rota |
|---|---|
| Bounded user request | Direct Skill/Prompt |
| Approved plan | Direct implementation; yalnız design unresolved ise Architect |
| Approved plan + architecture | Direct implementation |
| Approved test cases | Test contract olarak doğrudan implementation |
| Reviewer findings | Bounded remediation prompt |
| Reviewer PASS | Gerekirse Tester Phase 2 veya Documenter |
| Implementation + tests complete | Documentation veya completion |
| RFC/Design Doc mevcut | Source olarak kullan; yeniden oluşturma |

Örnek:

Planner ve Architect ortak bir remediation planı üretmişse bu görev Planner’a veya Architect’e tekrar gönderilmez. İlgili skill’ler seçilerek direct implementation promptu hazırlanır.

## 12. Risk ve Karmaşıklık Puanı

Her başlık 0–2 puanlanır:

| Boyut | 0 | 1 | 2 |
|---|---|---|---|
| Scope | Tek lokal değişiklik | Birkaç ilişkili dosya | Geniş subsystem/repository |
| Ambiguity | Tam belirli | Küçük varsayımlar | Materially unresolved |
| Blast radius | Lokal ve reversible | Shared behavior | Production/data/security/compatibility |
| Boundaries | Tek stack/project | İki ilişkili scope | Birden fazla sistem/domain |
| Verification | Basit check | Birkaç validation | Zor environment/reproduction |
| Independent judgment | Gerekmiyor | Tek specialist faydalı | Birden fazla quality gate |

Routing önerisi:

| Toplam | Normal rota |
|---|---|
| 0–4 | Direct Skill/Prompt |
| 5–7 | Direct Skill/Prompt + prompt içinde açık plan; gerekirse tek agent |
| 8–9 | Single Role veya Selected Roles |
| 10–12 | Birden fazla bağımsız rol gerçekten gerekiyorsa Full Workflow değerlendir |

Yüksek puan otomatik olarak Full Workflow anlamına gelmez.

Örneğin riskli fakat tasarımı tamamlanmış bir migration yalnız DBA + Reviewer gerektirebilir.

## 13. Token Verimliliği Kuralları

1. Tüm skill’leri yükleme.
2. Seçilen skill içindeki tüm reference dosyalarını yükleme.
3. Approved planı yeniden yazdırma.
4. Bir agent’ın tamamladığı işi başka agente özetletme; review amaçlı değilse gereksizdir.
5. Sequential işler için subagent oluşturma.
6. Aynı dosyaları birden fazla subagent’a inceletme.
7. Exact path ve bounded scope kullan.
8. Broad reading yerine repository search kullan.
9. Promptu tekrar discovery gerektirmeyecek kadar açık yaz; bütün repository dokümanlarını prompta kopyalama.
10. Hazır prompt ve artifactları yeniden kullan.
11. Agent veya subagent seçildiyse token maliyetine değen somut faydayı açıkla.

## 14. Model Seçimi

Kalıcı bir model whitelist kullanılmamalıdır.

Önce kullanıcının Codex VS Code Extension veya provider yapılandırmasında erişebildiği gerçek modeller belirlenmelidir.

### Mevcut Model Etiketleri

Model ve reasoning bağımsız seçimlerdir. Her Routing Decision tam exact model label ve exact reasoning label vermelidir. Kullanıcının şu an bildirdiği seçenekler aşağıdadır; kalıcı whitelist değildir.

| Model | Seçim rehberi |
|---|---|
| 5.4 | Current user-reported option; yalnız current environment/task evidence ile seçilir. Desteklenmeyen performans veya fiyat karşılaştırması yapılmaz. |
| 5.5 | Current user-reported option; yalnız current environment/task evidence ile seçilir. Desteklenmeyen performans veya fiyat karşılaştırması yapılmaz. |
| 5.6 Luna | En hızlı ve en düşük maliyetli 5.6 tier; mechanical, repeatable, clear ve high-volume işler için. |
| 5.6 Terra | Balanced everyday workhorse; normal bounded implementation, debugging ve routine professional coding için. |
| 5.6 Sol | Flagship tier; complex coding, research, security, difficult reasoning, detail ve polish için. |

Kullanıcı açıkça 5.4 veya 5.5 istemedikçe, environment bunu gerektirmedikçe veya doğrulanmış task/environment evidence bunu tercih edilir kılmadıkça aşağıdaki Sol/Terra/Luna routing uygulanır. Model adı doğrulanamıyorsa model uydurulmaz; capability class önerilir ve kullanıcı mevcut seçeneklerden en yakınını seçer.

### Lowest-Reliable Routing

Complexity, verification difficulty, risk, latency ve cost temelinde en düşük güvenilir model + reasoning kombinasyonunu seç:

| Görev | Model | Reasoning |
|---|---|---|
| Mechanical, deterministic, small documentation, repetitive edit | 5.6 Luna | Light |
| Normal bounded .NET/frontend implementation veya ordinary debugging | 5.6 Terra | Medium |
| Multi-file debugging, integration veya test design | 5.6 Terra | High |
| Architecture, security, concurrency, production migration, data integrity, broad refactoring, difficult incident veya repository-wide synthesis | 5.6 Sol | Extra High |
| Yalnız en complex, highest-risk, materially ambiguous işler | 5.6 Sol | Ultra |

Bir iş birkaç dosya kullanıyor diye otomatik Sol, token cost önemli diye otomatik Luna seçilmez.

### Reasoning Level

Kullanıcının VS Code Codex ortamında doğrulanmış reasoning label seti:

| Seviye | Uygun görev |
|---|---|
| Light | Mechanical, deterministic, küçük tek dosyalı işler |
| Medium | Normal bounded .NET/frontend implementation |
| High | Multi-file debugging, integration ve test design |
| Extra High | Architecture, security, concurrency, migration ve data-integrity işleri |
| Ultra | Yalnız en karmaşık, en yüksek riskli ve materially ambiguous işler |

Ultra varsayılan değildir. Her routing çıktısı tam exact model label ve exact reasoning label vermelidir.

## 15. Plan ve Goal Kararı

| Durum | Plan | Goal |
|---|---:|---:|
| Açıklama veya prompt seçimi | Off | Off |
| Read-only repository analysis | On | Off |
| Analysis-only PR review | On | Off |
| Requirement veya architecture | On | Off |
| Approved bounded implementation | Off | On |
| Reviewer checklist uygulama | Off | On |
| Reproducible bug fix | Off | On |
| Önce araştırma, sonra onaylı implementation | Sequential | Sequential |

`Sequential`, approval sınırını otomatik geçmek anlamına gelmez. Önce plan çıkarılır; implementation için kullanıcı onayı beklenir.

Codex arayüzünde terimler farklıysa aynı çalışma davranışı eşdeğer biçimde tanımlanmalıdır.

## 16. PR ve Review Routing

### 16.1 Analysis-Only

Prompt açıkça şunları yasaklamalıdır:

- File edit
- Commit
- Push
- PR comment
- Review submission
- Thread resolution
- Label veya metadata değişikliği

İstenen çıktı:

- Verified findings
- File ve line evidence
- Severity
- Impact
- Suggested remediation
- Fact ve hypothesis ayrımı

### 16.2 Remediation

Finding’ler onaylandıktan sonra:

- Varsayılan olarak Direct Skill/Prompt route
- Yalnız selected findings uygulanır
- Unrelated code korunur
- Repository-defined validation çalıştırılır
- Publish işlemleri ayrıca istenmedikçe yapılmaz

### 16.3 Publish

Commit, push, PR create, comment ve thread resolution ayrı write operation’lardır.

Analysis veya implementation promptuna varsayılan olarak eklenmemelidir.

## 17. Validation Politikası

Her validation sonucu şu alanları korumalıdır:

- Owning scope
- Working directory
- Exact command
- Category
- Result
- Blocker veya prerequisite

Geçerli sonuçlar:

- PASS
- FAIL
- Not configured
- Not run

`Not configured`, `Not run` veya command unavailable durumu PASS olarak raporlanamaz.

Mixed repository’de her touched scope ayrı doğrulanmalıdır.

## 18. Önerilen Çıktı Formatı

````markdown
### Routing Decision

- Route: Direct Skill/Prompt
- Risk score: 5/12
- Repository evidence:
  - package.json
  - pnpm-workspace.yaml
  - apps/catalog/package.json
- Skills:
  - web-frontend-development — mandatory
- Existing prompt:
  - .github/prompts/web-frontend-development.prompt.md
- Lillian agent: None
- Subagents: Off
- Model: 5.6 Terra
- Reasoning: High
- Plan: Off
- Goal: On
- Token rationale: One bounded package-level change; skill and prompt provide sufficient guidance.

### Codex Prompt

```text
[copy-ready prompt]
```
````

## 19. Routing Örnekleri

### Örnek A — React Lint Hatası

**Görev:** Tek React component içindeki iki lint hatasını davranış değiştirmeden düzelt.

- Route: Direct Skill/Prompt
- Skill: `web-frontend-development`
- Agent: None
- Model: 5.6 Luna
- Reasoning: Light
- Plan: Off
- Goal: On

Gerekçe: Tek component içindeki deterministic lint düzeltmesi mechanical scope olduğundan Light yeterlidir. Framework guidance, lint severity, package-manager handling ve validation zaten skill tarafından yönetilmektedir.

### Örnek B — Yeni .NET Background Service

**Görev:** Database access, distributed lock, metric ve health check içeren scheduled service oluştur.

- Route: Architecture onaylıysa Direct Skill/Prompt
- Skills: `dotnet-service-generator`, `solution-structure`, `observability`, gerekirse `infrastructure`
- Agent: Boundaries unresolved ise yalnız Architect
- Model: 5.6 Terra
- Reasoning: Medium
- Plan/Goal: Design belirsizse Sequential; approved design varsa Goal On

### Örnek C — Approved Remediation Plan

**Görev:** Planner ve Architect PR bulguları için planı onayladı.

- Route: Direct implementation
- Planner: Kullanılmaz
- Architect: Kullanılmaz
- Skills: Touched scope’a göre seçilir
- Model: 5.6 Terra
- Reasoning: Medium
- Goal: On
- Prompt: Approved planı bounded implementation contract olarak kabul eder

### Örnek D — Production Database Migration

**Görev:** Büyük tablo migration ve index değişiklikleri.

- Route: DBA + Architect approval; gerekirse Reviewer
- Skills: `mssql-table-scaffolder` veya `mssql-bulk-data-operations`
- Model: 5.6 Sol
- Reasoning: Extra High
- Plan: On
- Goal: Design onayına kadar Off

Ultra yalnız migration materially ambiguous, production blast radius çok yüksek, verification environment zor ve birden fazla unresolved decision varsa değerlendirilir.

### Örnek E — Independent Code Review

**Görev:** Tamamlanmış implementation’ı standartlara göre review et.

- Route: Single Reviewer
- Skills: Touched scope’a uygun bütün zorunlu skill’ler
- Model: 5.6 Terra
- Reasoning: High
- Plan: On
- Goal: Off
- Output: PASS/FAIL, file:line finding ve actionable checklist

## 20. Anti-Patternler

Yapılmaması gerekenler:

- Her non-trivial görevde Planner → Architect → Developer çalıştırmak
- Hazır prompt bulunmasını workflow agent zorunluluğu saymak
- Agent seçilmediği için skill ve instructions’ı atlamak
- Aynı reference dosyasını birkaç kez yüklemek
- Frontend frameworkünü extension veya klasör adından tahmin etmek
- Conventional isimlere bakarak command uydurmak
- Sabit model listesi kullanmak
- Routine task için maximum reasoning seçmek
- Tamamlanmış workflow stage’lerini yeniden başlatmak
- Analysis, implementation ve GitHub publish işlemlerini tek promptta birleştirmek
- Onaysız dependency, framework veya broad refactor eklemek
- Validation çalışmadığı halde PASS raporlamak

## 21. Agent Kullanımından Önce Son Kontrol

Bir agent önermeden önce şu sorular yanıtlanmalıdır:

1. Bu agent hangi bağımsız sorumluluğu üstlenecek?
2. Hangi artifact veya quality gate’i üretecek?
3. Seçilen skill ve hazır prompt bunu neden doğrudan yapamıyor?
4. Sağlayacağı fayda ek token ve context maliyetine değer mi?
5. Bu rolün çıktısı daha önce kullanıcı tarafından zaten sağlandı mı?

Somut yanıt yoksa:

> **Direct Skill/Prompt Route kullanılır.**
