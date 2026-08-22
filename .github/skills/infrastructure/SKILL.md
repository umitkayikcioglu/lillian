---
name: infrastructure
description: Docker and Kubernetes patterns for .NET 10 services including health probes, resource limits, and graceful shutdown. Use when writing or reviewing Dockerfiles, Kubernetes manifests, container deployments, or health probes.
type: guidance
applies_to:
  - Developer
  - Reviewer
mandatory: conditional
mandatory_when:
  - Creating or updating Dockerfiles
  - Creating or updating Kubernetes manifests
  - Configuring health probes
triggers:
  - dockerfile
  - kubernetes
  - container
  - deployment
  - health probe
references:
  - templates/dockerfile.md
  - templates/kubernetes.md
summary: Docker and Kubernetes patterns for .NET 10 services including health probes, resource limits, and graceful shutdown.
---

# Infrastructure Skill

Defines containerization and orchestration standards for .NET services.

Dockerfile and deployable-project placement comes from
[`Canonical deployable-runner identities`](../solution-structure/SKILL.md#canonical-deployable-runner-identities),
and Kubernetes placement comes from
[`Canonical Kubernetes directory structure`](../solution-structure/SKILL.md#canonical-kubernetes-directory-structure).
This skill owns the contents of Dockerfiles and Kubernetes manifests, not a second repository layout.

## Roles

- **Developer**: Creates and maintains Dockerfile and Kubernetes manifests
- **Reviewer**: Verifies infrastructure configuration meets standards

---

## Dockerfile Standards

See [templates/dockerfile.md](templates/dockerfile.md) for complete template.

The Dockerfile's `{DeployableProcessName}` is the full canonical deployable runner project name resolved from
`solution-structure` (for example, the value matching its `{Organization}.{Product}.Host` form). Do not shorten
it to a service name or invent app/core/infrastructure project identities.

### Required Structure

1. **Multi-stage build**: base → build → publish → final
2. **.NET 10 base images**: `mcr.microsoft.com/dotnet/aspnet:10.0` and `sdk:10.0`
3. **Non-root user**: `USER app`
4. **Standard ports**: 8080 (HTTP), 8081 (HTTPS)
5. **Build files**: Copy the four root build files required by `solution-structure`: `Directory.Packages.props`, `Directory.Build.props`, `Directory.Build.targets`, and `global.json`

### Build Arguments

| Argument | Purpose | Required |
|----------|---------|----------|
| `BUILD_CONFIGURATION` | Release/Debug | No (default: Release) |
| `GITHUB_PAT` | NuGet package authentication | Yes |
| `VERSION` | Assembly version | No (default: timestamp) |

### Security

- Never embed secrets in image layers
- Use non-root user
- Minimize image layers
- Use specific image tags, not `latest`

---

## Kubernetes Standards

See [templates/kubernetes.md](templates/kubernetes.md) for complete templates.

### Placement contract

Use the [canonical Kubernetes directory structure](../solution-structure/SKILL.md#canonical-kubernetes-directory-structure)
before creating or moving a manifest. It exclusively owns the Kubernetes topology, filenames, and structural
identity tokens. This skill owns the content and deployment behavior of those structure-selected manifests.

### Deployable identity and image tokens

- Resolve `{DeployableProcessName}`, `{DeploymentName}`, `{KubernetesEnvironmentName}`, and
  `{KubernetesEnvironmentKebabName}` from the
  [canonical Kubernetes authority](../solution-structure/SKILL.md#canonical-kubernetes-directory-structure).
- `{DeploymentKebabName}` is the only Kubernetes resource-name rendering. Lowercase the complete
  `{DeploymentName}`, replace dots and other non-alphanumeric runs with one hyphen, and trim leading/trailing
  hyphens. If the result exceeds Kubernetes' 63-character label limit, take its first 54 characters, trim any
  trailing hyphen, then append a hyphen and the first eight lowercase hexadecimal characters of the SHA-256
  of the unshortened kebab value. Resolve it at scaffold time; committed manifests contain the literal.
- `app-image:latest` is the deploy-time image placeholder. CI rewrites it with
  `kustomize edit set image "app-image:latest=<image>:<tag>"` in the selected deployment overlay. CI may set
  the namespace in that same overlay.

### Conditional manifest content

- Keep each base `Deployment` and its `kustomization.yaml` complete and deployable. Add `service.yaml` only
  when that deployment exposes a stable network Service; a worker-only deployment does not generate one.
- Add `base/{DeploymentName}/configmap.yaml` only when the deployment has non-secret configuration to mount. Add an overlay ConfigMap
  patch only when that deployment or environment changes those values. Never create an empty ConfigMap as a
  structural placeholder.
- Mount a Secret only when the workload consumes one. Secrets are externally supplied; never commit secret
  values or put them in a ConfigMap.
- Configure liveness and readiness probes when the corresponding endpoints exist. Add a startup probe when
  initialization can delay readiness. A manifest must not probe an endpoint the process does not map.
- Declare resource requests and limits for deployed workloads. Start from the environment defaults below,
  then replace them with measured values when profiling supports the change.
- Use the restricted security context by default. Relax only an incompatible setting, document why, and prefer
  a writable volume over disabling `readOnlyRootFilesystem` for the whole container.
- Add private-registry pull secrets, in-pod HTTPS ports, configuration mounts, node selectors, affinity,
  tolerations, and workload-specific volumes only when the deployment actually requires them.

---

## Health Probes

### Endpoints

| Probe | Path | Purpose | Tags |
|-------|------|---------|------|
| Liveness | `/healthz/live` | Process is alive | `live` |
| Readiness | `/healthz/ready` | Can accept traffic | `ready` |
| Startup | `/healthz/startup` | Initialization complete | `startup` |

These are the canonical probe paths for new integrations. An existing aggregate or compatibility endpoint may
remain when current consumers depend on it; it is not a fourth canonical probe. Do not remove, rename, or
retarget an established alias without an explicit compatibility and consumer-migration decision.

### Probe Configuration

| Probe | initialDelay | period | timeout | failureThreshold |
|-------|--------------|--------|---------|------------------|
| Liveness | 0s | 60s | 1s | 3 |
| Readiness | 5s | 180s | 1s | 3 |
| Startup | 0s | 10s | 1s | 30 |

### Implementation

For health check implementation and registration patterns, see the dotnet-service-generator skill's `references/health-check.md`.

```csharp
// Endpoints
app.MapHealthChecks("/healthz/live", new HealthCheckOptions
{
    Predicate = _ => false // Always healthy if process is running
}).AllowAnonymous();

app.MapHealthChecks("/healthz/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
}).AllowAnonymous();

app.MapHealthChecks("/healthz/startup", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("startup")
}).AllowAnonymous();
```

Probe endpoints are anonymous so orchestrators can call them without application credentials. Their responses
must not expose secrets, dependency connection material, or other sensitive diagnostics.

---

## Resource Limits

### Default Values

| Environment | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-------------|-------------|-----------|----------------|--------------|
| Integration | 250m | 500m | 256Mi | 512Mi |
| Testing | 500m | 1000m | 512Mi | 1024Mi |
| Staging | 500m | 1000m | 512Mi | 1024Mi |
| Production | 500m | 2000m | 512Mi | 2048Mi |

### Ephemeral Storage

All environments:
- Request: 1Gi
- Limit: 2Gi

### Adjustment Guidelines

- Profile actual usage before adjusting
- CPU limit should be 2x request for burst capacity
- Memory limit should be 2x request for safety margin
- Monitor OOMKilled events to detect memory pressure

---

## Graceful Shutdown

### Configuration

```yaml
terminationGracePeriodSeconds: 60
```

### Application Requirements

1. Handle SIGTERM signal
2. Stop accepting new requests
3. Complete in-flight requests
4. Close database connections
5. Flush telemetry buffers
6. Release distributed locks

### .NET Implementation

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Configure graceful shutdown
builder.Host.ConfigureHostOptions(options =>
{
    options.ShutdownTimeout = TimeSpan.FromSeconds(30);
});

var app = builder.Build();

app.Lifetime.ApplicationStopping.Register(() =>
{
    // Cleanup logic here
});
```

---

## Volumes and Secrets

### Standard Mounts

| Path | Source | Purpose |
|------|--------|---------|
| `/app/configuration/secret` | Kubernetes Secret | Sensitive configuration, when used |
| `/app/configuration/configmap` | ConfigMap | Non-sensitive configuration, when used |

### Configuration Loading

```csharp
var environmentName = builder.Environment.EnvironmentName;

builder.Configuration
    .AddJsonFile("appsettings.json", optional: false)
    .AddJsonFile($"appsettings.{environmentName}.json", optional: true)
    .AddJsonFile("/app/configuration/configmap/appsettings.json", optional: true)
    .AddJsonFile("/app/configuration/secret/appsettings.json", optional: true)
    .AddEnvironmentVariables();
```

---

## Deployment Strategy

### Default: Rolling Update

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 0%
    maxUnavailable: 100%
```

This configuration:
- Terminates all old pods before creating new ones
- Minimizes resource usage during deployment
- Suitable for stateless services

### Alternative: Zero-Downtime

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%
    maxUnavailable: 0%
```

Use when:
- Service must maintain availability during deployment
- Sufficient cluster resources for extra pods

---

## Reviewer Checklist

When reviewing infrastructure changes:

- [ ] Multi-stage Dockerfile with proper layer ordering
- [ ] Non-root user in container
- [ ] Health probes configured with appropriate timing
- [ ] Resource requests and limits defined
- [ ] Graceful shutdown period set
- [ ] Any sensitive configuration is mounted from a Kubernetes Secret, never a ConfigMap
- [ ] Optional pull secrets, ports, probes, volumes, and ConfigMaps exist only when the workload uses them
- [ ] Only supported environments and actual complete deployment identities have overlay leaves
- [ ] The full process and deployment identities were resolved once; DNS-label fields use their canonical kebab renderings
- [ ] CI pins the image and namespace in the actual selected deployment overlay
- [ ] The change was exercised locally with the repository's applicable container/orchestration harness; use
      Docker Compose or Minikube when that is the repository's established local runtime
