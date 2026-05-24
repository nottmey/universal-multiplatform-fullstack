---
name: rama
description: >-
  Rama distributed platform essentials: depots, PStates, modules, mirrors,
  ACK levels, partitioning, and topology design tradeoffs. Use when designing or
  implementing Rama modules, depots, stream/microbatch/query topologies,
  cross-module dependencies, or client services that append to depots.
---

# Rama essentials

Official references: [Rama docs](https://redplanetlabs.com/docs/~/index.html), [Javadoc](https://redplanetlabs.com/javadoc/index.html). For module mirrors: [Dependencies between modules](https://redplanetlabs.com/docs/~/module-dependencies.html). For depots: [Depots](https://redplanetlabs.com/docs/~/depots.html).

- **Ids:** `*name` — depots and dataflow vars; `$$name` — PStates (required). [tutorial2](https://redplanetlabs.com/docs/~/tutorial2.html), [PStates](https://redplanetlabs.com/docs/~/pstates.html).

## One-line mental model

**Rama design = pick depot ingress, partition key, which module owns ETL, and what ACK means “done” for the API — then accept the cost of mirrors, extra depots, and async boundaries.**

Most architecture arguments in Rama reduce to **ACK patterns** and **module boundaries**.

---

## Core objects

| Object | Role |
|--------|------|
| **Depot** | Append-only log; **only** ingress for new data |
| **PState** | Materialized queryable state; built by topologies, not written by clients |
| **Stream topology** | Continuous ETL: depot → PState (near real time) |
| **Microbatch topology** | Windowed / batched aggregation |
| **Query topology** | On-demand reads; invokable from other topologies |
| **Module** | Deployable unit: depots, PStates, topologies, tasks |

**Rule:** Clients append to depots. Topologies derive PStates. You cannot “subscribe to a PState” to build another PState — source a **depot** (own or mirrored).

---

## ACK levels (client appends)

| Level | Client gets success when… |
|-------|---------------------------|
| `NONE` | Append accepted locally (fire-and-forget) |
| `APPEND_ACK` | Record is on the depot partition and replicated; colocated stream topologies have not run yet |
| `ACK` | Colocated stream topologies sourcing **that depot on that module** finished processing the record |

**Cross-module:** `ACK` on a depot in module A does **not** wait for stream topologies in module B that mirror-source that depot. Mirror subscribers are **not coordinated** with appends. Docs: [module-dependencies — tradeoffs](https://redplanetlabs.com/docs/~/module-dependencies.html).

**Depot → depot in one module:** `ACK` on depot A waits for the topology that sourced A; it does **not** wait for topologies consuming depot B.

**Streaming ack return:** With `AckLevel.ACK`, `depot.append` returns `Map<topologyName, returnValue>` for colocated streams that use `.ackReturn(...)`.

---

## Modules and mirrors

Each `RamaModule` exposes a single module id used by mirrors and cluster clients:

```java
public static final String NAME = PostsModule.class.getName();
```

Reference `OtherModule.NAME` everywhere else (mirror setup, `clusterDepot`, `clusterPState`, `clusterQuery`) — do not repeat `OtherModule.class.getName()`.

Declare cross-module access in `Setup` using string literals for the target object names:

```java
setup.clusterDepot("*mirrorDepot", OtherModule.NAME, "*targetDepot");
setup.clusterPState("$$mirror", OtherModule.NAME, "$$targetPState");
setup.clusterQuery("*mirrorQuery", OtherModule.NAME, "targetQueryTopologyName");
```

Use mirrors in topology code like local depots/PStates/queries.

| Same module | Different module (mirror) |
|-------------|---------------------------|
| Colocated reads/writes (thread-local when aligned) | Network on every mirror `localSelect` / append |
| `ACK` covers colocated stream processing | No cross-module ACK coordination |
| Synchronous snapshot across colocated `localSelect`s in one event | Mirror `localSelect` is an **async boundary** |

**Yielding constraints on Mirror Selects:**
All queries and selects on mirror PStates execute asynchronously across the network and are always allowed to yield. Do **not** manually add `.allowYield()` to mirror selects/queries, as Rama forbids explicit yielding configuration on mirror objects and doing so will throw a compilation/runtime exception.

**Operational rules:** Cannot launch/update if mirror target missing. Cannot destroy a module others mirror. Exposed depots/PStates are a **public API** between modules.

**Circular dependencies:** Possible via module updates; not recommended upfront.

---

## Partitioning

- `Depot.random()` — even spread; **no** per-key ordering guarantees.
- `Depot.hashBy(fn)` — same extracted key → same partition → **local ordering** for that key.
- `Depot.disallow()` — client appends forbidden; topology-only ingest (good for derived/event buses).

**Colocation:** When depot partition key matches PState key layout, stream topologies can often `.source(...).localTransform(...)` without `.hashPartition`.

**Misalignment:** Requires `.hashPartition(key)` before every cross-partition `localTransform` or `depotPartitionAppend`.

**Mirror depots:** Before `depotPartitionAppend` to a mirror, use `.hashPartition("*mirrorDepot", "*key")` — mirror may have different task count than current module.

---

## Patterns: one depot, many consumers

A depot can feed:

- Multiple topologies in the same module
- Mirror `source` in other modules

Each consumer has its own offset. There is no built-in “all consumers finished” ACK unless you orchestrate it (e.g. two appends with two ACKs, or colocate ETL in one module).

---

## Deriving one depot from another

Inside a topology:

```java
setup.declareDepot("*outgoing", Depot.disallow());
// ...
s.source("*incoming").out("*event")
 .hashPartition("*partitionKey")  // required if target partition matters
 .depotPartitionAppend("*outgoing", "*transformed");
```

`depotPartitionAppend` writes to the **current task’s partition** unless you partitioned first.

**Downsides:** double storage/IO; extra latency (async boundary); decoupled ACK (downstream not in client ACK); loop risk if topology writes back upstream; partition mistakes if you skip `hashPartition`.

**When useful:** split raw ingest into clean domain events; cross-module event bus with `Depot.disallow()` on the derived depot.

---

## Events and consistency

Topologies run in **events** separated by **async boundaries** (partitioners, mirror `localSelect`, etc.).

- Two colocated `localSelect`s in the **same event** → consistent snapshot.
- Mirror `localSelect` → ends event; subsequent colocated reads may see a **different moment in time**.

Reorder reads or colocate if you need synchronized multi-PState views.

---

## Design decision checklist

When adding or changing Rama behavior, answer in order:

1. **Ingress:** Which depot receives this fact? What is the event payload type?
2. **Partition key:** What key preserves ordering and colocation with the PState?
3. **Module ownership:** Which module owns the depot and ETL?
4. **ACK semantics:** What must be true before the client/API returns success?
   - Only one materialized view updated → `ACK` on that module’s depot.
   - Multiple modules must be consistent → colocate ETLs **or** multiple appends + wait for each ACK **or** accept eventual consistency with mirror-only downstream.
5. **Cross-module?** If yes, document weaker ACK and async boundaries.
6. **Fan-out:** One depot + multiple topologies/modules vs dedicated derived depot?

State which ACK level and module layout you choose and why.

### Common shapes (tradeoffs)

| Shape | Pros | Cons |
|-------|------|------|
| Single module, one depot, multiple `localTransform`s | One ACK, colocated, simple | Blurs module boundaries |
| Separate modules, mirror `clusterDepot` + `source` | Clean decomposition, independent deploy | No cross-module ACK; downstream lags upstream |
| Separate downstream depot + second client append | Explicit boundary; per-module ACK | Multiple writes; client orchestrates ACKs |
| Topology `depotPartitionAppend` A→B | Decoupled pipeline | Double log; decoupled ACK; partition care |

---

## Testing

- Use `InProcessCluster` in module tests; `cluster.clusterDepot(moduleName, "*depot")`, `cluster.clusterPState(...)`.
- Mirror tests: launch owner module first, then dependent module; consider `StreamSourceOptions.startFromBeginning()` when testing mirror consumers right after launch.

---

## Anti-patterns

- Client writes directly to a PState.
- Assuming mirror-module processing is included in the owning module’s depot `ACK`.
- `depotPartitionAppend` without `hashPartition` when target partition matters.
- Mirror depot ↔ source depot feedback loop.
- Splitting modules without documenting the public depot/PState contract.

---

## Doc map (read when needed)

| Topic | Page |
|-------|------|
| Tutorial / full example | [tutorial6](https://redplanetlabs.com/docs/~/tutorial6.html) |
| Stream topologies, ackReturn | [stream](https://redplanetlabs.com/docs/~/stream.html) |
| PStates, migrations | [pstates](https://redplanetlabs.com/docs/~/pstates.html) |
| Partitioners, mirror partitioners | [partitioners](https://redplanetlabs.com/docs/~/partitioners.html) |
| Module ops (launch/update) | [operating-rama](https://redplanetlabs.com/docs/~/operating-rama.html) |
