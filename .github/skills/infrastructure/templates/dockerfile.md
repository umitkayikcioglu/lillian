# Dockerfile Template

Multi-stage Dockerfile for .NET 10 services.

[`Canonical deployable-runner identities`](../../solution-structure/SKILL.md#canonical-deployable-runner-identities)
owns the deployable project path and identity. Resolve those before applying this content template.

## Template

```dockerfile
# Base runtime image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER app
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
ARG GITHUB_PAT
ARG VERSION

# Configure NuGet for private packages
RUN dotnet nuget add source https://nuget.pkg.github.com/{GitHubPackageOwner}/index.json \
    -n "github" -u "docker" -p "$GITHUB_PAT" --store-password-in-clear-text

WORKDIR /build

# Copy build configuration files first (better layer caching)
COPY ["Directory.Packages.props", "./"]
COPY ["Directory.Build.props", "./"]
COPY ["Directory.Build.targets", "./"]
COPY ["global.json", "./"]

# Copy the deployable project file and restore
COPY ["src/{DeployableProcessName}/{DeployableProcessName}.csproj", "src/{DeployableProcessName}/"]
RUN dotnet restore "./src/{DeployableProcessName}/{DeployableProcessName}.csproj" -p:Configuration=Release

# Copy source and build
COPY . .
WORKDIR "/build/src/{DeployableProcessName}"

# Publish stage
FROM build AS publish
RUN dotnet publish "./{DeployableProcessName}.csproj" \
    -c $BUILD_CONFIGURATION \
    -o /app/publish \
    /p:UseAppHost=false \
    /p:Version=${VERSION:-$(date "+%y.%m%d.%H%M")}

# Final runtime image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "{DeployableProcessName}.dll"]
```

## Placeholders

| Placeholder | Replace With |
|-------------|--------------|
| `{DeployableProcessName}` | Full canonical deployable runner identity resolved from `solution-structure`; reuse it as the project stem and do not shorten it to a service or app name |
| `{GitHubPackageOwner}` | Actual GitHub account or organization that owns the package feed |
| `{ReferencedProjectDirectory}` | Exact repository-relative directory of one referenced canonical project |
| `{ReferencedProjectName}` | Full project-file stem for that referenced project |

## Usage

### Build Command

```bash
docker build \
  --build-arg GITHUB_PAT=$GITHUB_PAT \
  --build-arg VERSION=1.0.0 \
  -t "${CONTAINER_IMAGE}:1.0.0" \
  -f "src/{DeployableProcessName}/Dockerfile" \
  .
```

### Multi-Project Solution

If the deployable project references other projects in the solution, copy every referenced project file before
restore. Resolve each repository-relative project directory and full project name from `solution-structure`
and the actual project reference; do not infer project types from this example.

```dockerfile
# Copy all project files for restore
COPY ["src/{DeployableProcessName}/{DeployableProcessName}.csproj", "src/{DeployableProcessName}/"]
COPY ["{ReferencedProjectDirectory}/{ReferencedProjectName}.csproj", "{ReferencedProjectDirectory}/"]
RUN dotnet restore "./src/{DeployableProcessName}/{DeployableProcessName}.csproj" -p:Configuration=Release
```

Repeat the `{ReferencedProjectDirectory}` / `{ReferencedProjectName}` line once for each referenced project,
using its resolved canonical repository path and full project file stem.

## Layer Optimization

The Dockerfile is structured for optimal layer caching:

1. **Base image** - Changes rarely
2. **Build configuration files** - Changes occasionally
3. **Project files + restore** - Changes when dependencies change
4. **Source code** - Changes frequently
5. **Publish** - Rebuilds when source changes
6. **Final image** - Always rebuilt

## Security Notes

- `USER app` runs as non-root (UID 1654)
- No secrets stored in image layers
- GitHub PAT only used during build (not in final image)
- Use specific version tags, not `latest`
