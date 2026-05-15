# Status: sdd-vpnclient.engine-h2.core

## Current Phase

REQUIREMENTS

## Phase Status

DRAFTING

## Last Updated

2026-05-14 by Claude

## Blockers

- None

## Progress

- [x] Requirements drafted
- [ ] Requirements approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete

## Context Notes

Key decisions and context for resuming:

- **h2.core** is an HTTPS VPN that uses HTTP/2 CONNECT over TLS (~600 LOC core)
- xray-core compatible API (drop-in replacement)
- Provides SOCKS5 interface locally
- Prebuilt binaries available in `vendors/h2.core/dist/`:
  - `h2_linux_amd64`
  - `h2_linux_arm64`
  - `h2_macos_silicon`
- Written in Go, need to link as external process or CGO library
- vpnclient_engine_flutter uses C++ cores with ICore interface

## Fork History

- Not forked
- Created fresh for h2.core integration

## Next Actions

1. Complete requirements elicitation
2. Get user approval on requirements
3. Draft specifications for integration approach
