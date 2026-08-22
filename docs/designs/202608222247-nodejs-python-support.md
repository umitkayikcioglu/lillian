# Teknik Tasarım: Lillian’da Node.js ve Python Geliştirme Desteği

## Metadata

- **Design Doc ID:** `DD-202608221200-node-python-development`
- **Status:** Draft
- **Author:** Codex — Architect
- **Scope:** Lillian skill, rule, routing, test senaryoları ve dokümantasyon kaynakları

## Context and Scope

Lillian şu anda TypeScript, React, Next.js ve Angular ağırlıklı frontend yönlendirmesine sahip. Node.js backend/CLI geliştirmesi ile Python uygulama, API ve CLI projeleri için birinci sınıf yönlendirme bulunmuyor.

### Goals

- Node.js ve Python projelerini manifest-first yaklaşımla tespit etmek.
- Paket yöneticisi, proje sahipliği ve doğrulama komutlarını kanıta dayalı çözümlemek.
- Monorepo ve çoklu paket senaryolarında yanlış komut çalıştırılmasını önlemek.
- Node.js frontend kurallarını mevcut `web-frontend-development` skill’inden ayırmadan backend kapsamını netleştirmek.
- Python için aynı kalite ve doğrulama standardını sağlamak.
- `.github/` kaynakları ile üretilen plugin/platform çıktılarının senkron kalmasını sağlamak.

### Non-Goals

- Lillian içinde gerçek Node.js veya Python uygulaması oluşturmak.
- Belirli bir framework, test runner, linter veya formatter’ı zorunlu kılmak.
- Mevcut .NET veya frontend kurallarını değiştirmek.
- Runtime servisi, veritabanı veya kullanıcı arayüzü oluşturmak.

## Overview

Tasarım üç katmandan oluşur:

1. Ortak proje ve workspace keşfi.
2. Node.js ve Python’a özgü geliştirme kuralları.
3. Ortak, yapılandırılmış doğrulama çıktısı.

Önerilen skill sınırları:

- `web-frontend-development`: Tarayıcı/frontend framework’leri.
- `node-development`: Node.js backend, CLI, servis, JavaScript/TypeScript runtime ve paket workspace’leri.
- `python-development`: Python uygulamaları, API’ler, CLI’ler, kütüphaneler ve paketleme.
- Ortak workspace/validation kuralları: paylaşılan referans dokümanları.

## Detailed Design

### 1. Kaynak Dosya Yapısı

Yeni ve değişen canonical kaynaklar:

- `.github/skills/node-development/SKILL.md`
- `.github/skills/python-development/SKILL.md`
- `.github/skills/web-frontend-development/references/workspace-routing.md`
- `.github/skills/web-frontend-development/references/validation-output.md`
- `.github/instructions/node.instructions.md`
- `.github/instructions/python.instructions.md`

Mevcut `web-frontend-development` skill’i frontend kapsamını koruyacak; Node backend kuralları ayrı skill’e yönlendirilecek.

`tools/sync-ai-platforms.ps1` mevcut genel kopyalama mekanizmasıyla yeni skill ve instruction dosyalarını plugin/rule çıktılarına taşıyacak. Script’te özel Node/Python mantığı eklenmeyecek.

### 2. Proje Keşfi ve Scope Resolution

Ortak keşif akışı:

1. Repository root ve manifest dosyalarını bul.
2. Workspace tanımlarını çöz.
3. Her dosyanın en spesifik owning package/project kapsamını belirle.
4. Paket yöneticisini aşağıdaki sırayla çöz:
   - Geçerli `packageManager` alanı.
   - Workspace yapılandırması.
   - Tek ve tutarlı lockfile.
   - CI kullanımı yalnızca destekleyici kanıt olarak.
5. Komutları manifest script’lerinden, project target’larından veya CI kanıtından al.
6. Komut bulunamazsa `not configured` döndür.
7. Çakışan veya belirsiz sahiplikte komut üretme.

Dışlanacak dizinler:

- `.git`
- `node_modules`
- `.venv`, `venv`
- `dist`, `build`, `coverage`
- `__pycache__`
- generated, vendored ve cache dizinleri

### 3. Node.js Skill

`node-development` şu alanların sahibidir:

- Node.js runtime ve sürüm kanıtı.
- JavaScript/TypeScript backend ve CLI.
- `package.json` script’leri.
- npm, pnpm, Yarn ve Bun.
- npm/pnpm/Yarn/Bun workspace’leri.
- Nx ve Turborepo sahiplik çözümlemesi.
- Node servislerinin test, build ve paketleme doğrulaması.
- Environment variable ve server/client sınırı.
- Async hata yönetimi, graceful shutdown ve dış servis çağrıları.

Framework aktivasyonu yalnızca kesin kanıtla yapılır:

- TypeScript: `tsconfig*.json` veya `typescript` dependency.
- Express/Fastify/NestJS vb.: ilgili declared dependency veya framework config.
- Next.js/React/Angular: mevcut frontend skill’ine devredilir.

### 4. Python Skill

`python-development` şu alanların sahibidir:

- Python sürüm ve proje metadata tespiti.
- `pyproject.toml`, `setup.py`, `setup.cfg`, `requirements*.txt`, `Pipfile`, `poetry.lock`, `uv.lock` ve benzeri kanıtlar.
- Paket yöneticisi ve sanal ortam çözümlemesi.
- Python uygulaması, API, CLI ve kütüphane paketleme.
- Lint, format, type-check, unit/integration test ve build doğrulaması.
- Async sınırlar, kaynak yönetimi, hata sınıflandırması ve yapılandırma güvenliği.
- FastAPI, Django, Flask ve benzeri framework’ler yalnızca dependency/config kanıtı varsa etkinleştirilir.

Belirli araçlar varsayılan olarak zorunlu tutulmayacak. Örneğin Ruff, Black, Mypy, Pyright veya pytest yalnızca repository kanıtı varsa doğrulanmış araç olarak raporlanacak.

### 5. Ortak Validation Output

Her scope ve kategori için aşağıdaki alanlar üretilecek:

| Alan | Zorunlu içerik |
|---|---|
| Scope | Repository, workspace, package veya project |
| Owner | Paket/proje adı ve kökü |
| Working directory | Komutun çalıştırılacağı dizin |
| Runtime | Node.js veya Python |
| Package manager | npm/pnpm/Yarn/Bun veya Python paket yöneticisi |
| Framework evidence | Dependency/configuration kanıtı |
| Category | lint, format, type-check, test, build, security |
| Exact command | Gerçek komut veya `not configured` |
| Evidence | Manifest, script, target, CI veya config yolu |
| Result | passed, failed, skipped, ambiguous, not configured |
| Blocker | Evet/hayır ve nedeni |

Root-level bir komut alt paketlerin sahiplik bilgisini silmeyecek.

### 6. Ortak Kalite Kuralları

Node ve Python için:

- Girdi sınırlarında doğrulama.
- Sırlar, token’lar ve PII loglanmamalı.
- Async I/O’da bloklayıcı çağrılardan kaçınılmalı.
- Dış servis çağrılarında timeout ve uygun retry politikası.
- Dependency değişikliklerinde lockfile bütünlüğü.
- Testler deterministik ve izole olmalı.
- Eksik kalite aracı başarı olarak raporlanmamalı.
- Mutating formatter veya dependency install varsayılan olarak çalıştırılmamalı.
- Yeni üçüncü taraf dependency için mevcut approval politikası uygulanmalı.

### 7. Platform Senkronizasyonu

Canonical kaynak `.github/` olacaktır.

Beklenen çıktılar:

- `plugins/ai-toolkit/skills/node-development`
- `plugins/ai-toolkit/skills/python-development`
- `plugins/ai-toolkit/rules/node.md`
- `plugins/ai-toolkit/rules/python.md`
- `.claude/rules/node.md`
- `.claude/rules/python.md`
- `.agents/rules/node.md`
- `.agents/rules/python.md`

`INDEX.md` frontmatter’dan generator tarafından güncellenecek; elle düzenlenmeyecek.

## Cross-Cutting Concerns

### Security

- Client bundle’a server secret aktarımı engellenecek.
- Python ve Node configuration örneklerinde gerçek credential kullanılmayacak.
- Dependency ve lockfile riskleri raporlanacak.
- Kullanıcı girdisi, auth boundary ve outbound request kontrolleri kalite kapsamına alınacak.

### Scalability

- Keşif manifest-first olacak.
- Büyük workspace’lerde kaynak kodu yerine manifest ve config dosyaları önceliklendirilecek.
- Her paket/proje bağımsız raporlanacak.

### Monitoring

Bu bir runtime servisi değil; gözlemlenebilirlik skill kalite ölçümleri üzerinden sağlanacak.

## Observability Requirements

| SLI | Target | Dashboard | Alert Threshold |
|---|---:|---|---|
| Zorunlu routing senaryoları başarı oranı | %100 | Skill QA raporu | Her başarısız zorunlu senaryo kritik |
| Yanlış framework aktivasyonu | 0 | Activation QA raporu | Her yanlış aktivasyon kritik |
| Yanlış owning package komutu | 0 | Scope routing raporu | Her yanlış komut kritik |
| Eksik validation output alanı | 0 | Report schema QA | Her eksik alan kritik |
| Senkronize kaynak/çıktı tutarlılığı | %100 | Sync validation raporu | Her tutarsızlık kritik |
| Dışlanan dizinlerin yanlış taranması | 0 | Discovery QA raporu | Her ihlal uyarı, tekrarında kritik |

## Testing Strategy

- **Unit/table tests:** Manifest, lockfile, dependency ve script precedence senaryoları.
- **Integration fixture tests:** Node workspace, Nx, Turborepo, Python `pyproject.toml`, Poetry/uv ve requirements tabanlı projeler.
- **Negative tests:** Yanlış framework aktivasyonu, çakışan package manager, eksik script ve belirsiz sahiplik.
- **Sync tests:** `.github/` kaynaklarının plugin ve platform çıktılarıyla eşleşmesi.
- **Performance tests:** `node_modules`, `.venv`, generated ve cache dizinlerinin taranmaması.
- **Security tests:** Secret exposure, unsafe environment handling ve auth-boundary senaryoları.

## Alternatives Considered

### Tek bir `polyglot-development` skill’i

Reddedildi. Node ve Python’ın manifest, package manager ve runtime kuralları farklı; tek skill gereksiz koşullu karmaşıklık oluşturur.

### Node kurallarını yalnızca `web-frontend-development` içine eklemek

Reddedildi. Frontend ve backend scope’larının karışmasına ve yanlış framework/komut yönlendirmesine yol açar.

### Her araç için ayrı skill oluşturmak

Şimdilik ertelendi. Ruff, pytest, Poetry, uv, Nx veya Turborepo gibi araçlar için ayrı skill’ler ancak gerçek kullanım yoğunluğu ortaya çıkarsa eklenmeli.

## Rollout Planı

1. Ortak workspace-routing ve validation-output sözleşmesini ekle.
2. `node-development` skill ve instruction dosyasını ekle.
3. `python-development` skill ve instruction dosyasını ekle.
4. Mevcut frontend skill’inin Node backend ile sınırlarını netleştir.
5. Routing, negative ve sync test senaryolarını ekle.
6. Generator ile plugin/rule çıktıları güncelle.
7. README ve skill index çıktısını doğrula.
8. Reviewer kalite kapısından sonra yayınla.

## Skills to Apply

| Skill | Uygulama |
|---|---|
| `web-frontend-development` | Mevcut frontend kapsamı ve ortak workspace/validation kuralları |
| `observability` | Skill kalite SLIs, dashboard ve alarm eşikleri |
| `documentation-generator` | Bu tasarımın ve README güncellemelerinin dokümantasyon standardı |
| `solution-structure` | Skill, instruction ve `docs/designs` dosya konumları |

## Notes for Developer

- Uygulama koduna dokunma; değişiklikler Lillian kaynak skill/rule/instruction ve dokümantasyon dosyalarıyla sınırlı kalsın.
- Framework veya tool default komutları icat etme.
- Node frontend yönlendirmesini `web-frontend-development` içinde bırak; backend/CLI yönlendirmesini `node-development` sahiplenmeli.
- Python araçlarını yalnızca repository kanıtıyla etkinleştir.
- Yeni skill frontmatter’ını güncel `INDEX.md` generator sözleşmesine uygun yaz.
- Sync script’te özel dil mantığı eklemek yerine mevcut genel keşif davranışından yararlan.
- Her pozitif routing kuralı için en az bir negative test ekle.
- Mimari, DBA ve UI kapsamı olmadığı için DBA ve Designer rolleri gerekli değil.

## Open Questions

- Ortak `workspace-routing.md` referansı `web-frontend-development` altında mı kalmalı, yoksa üst düzey ortak skill’e mi taşınmalı?
- Python validation output aynı tablo sözleşmesini mi kullanmalı? Öneri: Evet.
- Node.js backend ve TypeScript backend ayrı skill olarak mı bölünmeli? Öneri: Hayır; aynı runtime ve package ekosistemini paylaşırlar.

## References

- `.github/skills/web-frontend-development/SKILL.md`
- `.github/skills/web-frontend-development/references/package-management.md`
- `.github/skills/web-frontend-development/references/frontend-quality.md`
- `.github/skills/observability/SKILL.md`
- `.github/skills/documentation-generator/templates/design-doc.md`
- `.github/prompts/agent-workflow.prompt.md`
- `.github/agents/workflow-architect.agent.md`
