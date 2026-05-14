# Traversal State

> Persistent recursion stack for tree traversal. AI reads this to know where it is and what to do next.

## Existing Flows Index

| Flow Path | Type | Topics | Key Decisions |
|-----------|------|--------|---------------|
| flows/sdd-vpnclient-engine-flutter/ | SDD | VPN engine, Flutter, FFI, cores, drivers | HevSocks5 default, core/driver matrix |
| flows/adr-001-hev-socks5-default/ | ADR | driver selection | HevSocks5 as default |
| flows/adr-002-core-driver-matrix/ | ADR | core compatibility | SingBox/WireGuard built-in TUN |
| flows/adr-003-singleton-pattern/ | ADR | API design | Singleton VpnClientEngine |

## Mode

- **BFS** (no comment): Breadth-first, analyze all domains systematically

## Source Path

engines/vpnclient_engine_flutter

## Focus (DFS only)

[none - BFS mode]

## Algorithm

```
RECURSIVE-UNDERSTAND(node):
    1. ENTER: Push node to stack, set phase = ENTERING
    2. EXPLORE: Read code, form understanding, set phase = EXPLORING
    3. SPAWN: Identify children (deeper concepts), set phase = SPAWNING
    4. RECURSE: For each child -> RECURSIVE-UNDERSTAND(child)
    5. SYNTHESIZE: Combine children insights, set phase = SYNTHESIZING
    6. EXIT: Pop from stack, bubble up summary, set phase = EXITING
```

## Current Stack

> Read top-to-bottom = root-to-current. Last item = where AI is now.

```
/ (root)                           DONE
├── flutter-api-layer              DONE
├── configuration-system           DONE
├── core-abstraction               DONE
├── driver-abstraction             DONE
├── native-bridge                  DONE
├── subscription-management        DONE
├── platform-integration           DONE
└── data-models                    DONE

[TRAVERSAL COMPLETE]
```

## Stack Operations Log

| # | Operation | Node | Phase | Result |
|---|-----------|------|-------|--------|
| 1 | PUSH | root | ENTERING | Created _root.md |
| 2 | PHASE | root | EXPLORING | Analyzed codebase structure |
| 3 | PHASE | root | SPAWNING | Identified 8 child domains |
| 4 | RECURSE | flutter-api-layer | COMPLETE | Created _node.md |
| 5 | RECURSE | configuration-system | COMPLETE | Created _node.md |
| 6 | RECURSE | core-abstraction | COMPLETE | Created _node.md |
| 7 | RECURSE | driver-abstraction | COMPLETE | Created _node.md |
| 8 | RECURSE | native-bridge | COMPLETE | Created _node.md |
| 9 | RECURSE | subscription-management | COMPLETE | Created _node.md |
| 10 | RECURSE | platform-integration | COMPLETE | Created _node.md |
| 11 | RECURSE | data-models | COMPLETE | Created _node.md |
| 12 | PHASE | root | SYNTHESIZING | Combined insights |
| 13 | GENERATE | - | - | Created sdd-vpnclient-engine-flutter |
| 14 | GENERATE | - | - | Created ADR-001, ADR-002, ADR-003 |
| 15 | PHASE | root | EXITING | Analysis complete |

## Current Position

- **Node**: (complete)
- **Phase**: EXITING (analysis complete)
- **Depth**: 0
- **Path**: /understanding/_root.md

## Pending Children

> Children identified but not yet explored (LIFO - last added explored first)

```
[none - all children completed]
```

## Visited Nodes

> Completed nodes with their summaries

| Node Path | Summary | Flow Created |
|-----------|---------|--------------|
| root | Cross-platform Flutter VPN plugin | sdd-vpnclient-engine-flutter |
| flutter-api-layer | Singleton VpnClientEngine with reactive streams | (part of main SDD) |
| configuration-system | Hierarchical config: VpnEngineConfig -> Core + Driver | (part of main SDD) |
| core-abstraction | ICore interface: SingBox, LibXray, V2Ray, WireGuard | adr-002 |
| driver-abstraction | IDriver interface: HevSocks5, Tun2Socks | adr-001 |
| native-bridge | FFI bindings via VpnEnginePlatform | (part of main SDD) |
| subscription-management | V2Ray URL parsing (5 protocols) | (part of main SDD) |
| platform-integration | Android VPNService, iOS PacketTunnelProvider | (part of main SDD) |
| data-models | CoreType, DriverType, ConnectionStatus, ConnectionStats | (part of main SDD) |

## Next Action

```
[ANALYSIS COMPLETE]

Generated:
- 1 SDD flow (sdd-vpnclient-engine-flutter)
- 3 ADRs (001, 002, 003)
- 9 understanding nodes

To resume or extend:
- Run /legacy with new path for additional analysis
- Run /legacy with comment for DFS deep-dive
```

---

## Phase Definitions

### ENTERING
- Just arrived at this node
- Create _node.md file
- Read relevant source files
- Form initial hypothesis

### EXPLORING
- Deep analysis of this node's scope
- Validate/refine hypothesis
- Identify what belongs here vs. children

### SPAWNING
- Identify child concepts that need deeper exploration
- Add children to Pending stack
- Children are LOGICAL concepts, not filesystem paths

### SYNTHESIZING
- All children completed (or no children)
- Combine insights from children
- Update this node's _node.md with full understanding

### EXITING
- Pop from stack
- Bubble up summary to parent
- Mark as visited

---

## Resume Protocol

When `/legacy` starts:
1. Read _traverse.md
2. Find current position (top of stack)
3. Check phase
4. Continue from that phase

If interrupted mid-phase:
- Re-enter same phase (idempotent operations)

---

*Completed by /legacy on 2026-05-14*
