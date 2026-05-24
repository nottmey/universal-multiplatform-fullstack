# Agent instructions

## Project principles

Prefer the **simplest design that works**. After planning or coding, review for overengineering.
Seek **fast feedback** (tests, checks, validation).
When requirements are unclear, **ask before building**.
Write/adapt **tests first**. Apply **red/green testing**. Keep tests effective. **Minimum amount of code, maximum amount of verification, fastest execution**.
**Improve every code you touch**.
**Communicate intent through naming**, not through comments.
**Naming:** Never abbreviate identifiers—types, functions, parameters, variables, enum values, and file names should spell words in full. Exceptions: `e` for caught errors, `i` in classic `for`-loop indices. Booleans read as natural yes/no predicates (e.g. `isX`, `hasY`). Prefer 1-3 distinctive, non-generic words per name.
Prioritize **immutability** and a **functional programming** style.
**Feature slices:** One feature = one domain. On the JVM keep domain types and Rama/gRPC code under `backend/src/main/java/social/example/features/<name>/` (tests under `backend/src/test/java/.../features/<name>/`). On Flutter keep feature UI and clients under `frontend/lib/features/<name>/`. Shared protos live in `backend/src/main/proto/`; generated Dart stubs live in `frontend/lib/proto/`. Do not spread domain rules across features—import across slices only at boundaries.
For **Rama** architecture — modules, depots, PStates, paths, stream/microbatch/query topologies — read [`.cursor/skills/rama/SKILL.md`](.cursor/skills/rama/SKILL.md) for design essentials (ACK levels, mirrors, partitioning), then follow official **[Rama documentation](https://redplanetlabs.com/docs/~/index.html)** and **[Rama Javadoc](https://redplanetlabs.com/javadoc/index.html)**. Name types: Rama **inputs** end with `Event` (instances/collections: `event` / `events`); Rama **outputs** end with `View` (`view` / `views`). Types implementing `RamaSerializable` are prefixed with `Rama`.
For **Armeria** (gRPC, routing) follow official **[Armeria documentation — Running a gRPC service](https://armeria.dev/docs/server/grpc)**.
For **Patrol** integration tests follow official **[Patrol documentation](https://patrol.leancode.co/documentation)**.

## Final validation

Before treating a task as done (after code changes and unit/backend tests as appropriate), **always run** [`scripts/patrol_e2e.sh`](scripts/patrol_e2e.sh) from the repo root for end-to-end validation. Prefer `web-headless` when no physical device or simulator is required (e.g. `./scripts/patrol_e2e.sh web-headless`). Use another device argument per the script’s usage when validating on iOS/Android.

Use **conventional commits** without scope param.

## Dart conventions

Prefer **inferring generic type arguments** when the surrounding expression already fixes them. Write explicit type arguments only when inference fails or would widen incorrectly.

Omit redundant **parameter type annotations** on formals—including required or optional positional parameters, named parameters, and **`catch`** parameters—when the assignee or enclosing API **determines** the type. Add explicit parameter types where omission would infer **`dynamic`** or where **strict-inference** (Dart analyzer language mode) or the **`strict_top_level_inference`** lint **requires an explicit type**.

Never use **`final` on formal parameters**. Use **`final`** for locals, fields, and top-level variables.

## Java conventions

**Protobuf/gRPC:** Generated message getters never return `null` (proto3 strings default to `""`, nested messages to `getDefaultInstance()`). Do not null-check those values; use `isBlank()` for strings and `hasField()` when presence matters.

Prefer a **functional programming style** in code: pure functions, immutable data, explicit inputs and outputs, minimal shared mutable state, and composition. Use Lombok **`@RequiredArgsConstructor`** when a constructor only assigns `final` fields, and **`@Log4j2`** instead of hand-written `LogManager.getLogger` fields. Use Lombok **`val`** for immutable locals (and try-with-resources) and **`var`** for reassignable locals when the type is obvious from the right-hand side; keep explicit types on parameters, fields, and `catch` clauses.
When the standard library is impractical for a functional workflow, **add a well-known dependency** rather than bolting on ad-hoc helpers.

After implementing tests, run `./gradlew test` from [`backend/`](backend/) and check [backend/build/reports/jacoco/test/jacocoTestReport.xml](backend/build/reports/jacoco/test/jacocoTestReport.xml) for the lines the test should cover; confirm coverage is good, then tighten the test for more coverage where it matters.
