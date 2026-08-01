# .NET / C# Profile

Activate only when at least one `.sln` or `.csproj` is present.

Durable guidance:

- Preserve solution and project boundaries when documenting scopes.
- Prefer commands declared by solution, project, repository scripts, or CI before suggesting any framework default.
- Treat `global.json` as supporting SDK evidence only; it does not activate this profile without `.sln` or `.csproj`.
- Keep C# standards in `.github/CONTRIBUTING.md`; do not duplicate full language guidance in orchestration.
- When multiple solutions exist, document validation commands per solution working directory.

Do not infer .NET usage from `.cs` files alone.
