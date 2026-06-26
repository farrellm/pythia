# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Pythia is a Haskell library for talking to LLM provider APIs (OpenAI, Anthropic), with both
buffered and server-sent-event streaming support. It is a Stack project with three packages:

- **pythia-core** — provider-agnostic typeclasses (`LLM`, `LLMStreaming`, `ChatEvent`). No HTTP, no JSON.
- **pythia-client** — concrete provider clients (`Pythia.Client.OpenAI`, `Pythia.Client.Anthropic`) built on Servant. This is where almost all real code lives.
- **pythia-effectful** — currently a stub (empty `Lib`); intended to host an `effectful`-based interface.

`pythia-core/src/Lib.hs` and `pythia-effectful/src/Lib.hs` are placeholder stubs. The working
entry point is `pythia-client/src/Lib.hs`, which holds runnable example/test functions
(`testOpenAI`, `testAnthropic`, the streaming variants), invoked by `pythia-client-exe`.

## Commands

`stack` drives everything (`system-ghc: true`, LTS 24.32):

```sh
stack build                          # build all three packages
stack build pythia-client            # build one package
stack test                           # run all test suites (currently stubs)
stack exec pythia-client-exe         # run the example/test driver (runs runTest in Lib.hs)
stack ghci pythia-client             # REPL with the client loaded; call testAnthropic etc. directly
```

Running the example driver hits live APIs and requires `OPENAI_API_KEY` / `ANTHROPIC_API_KEY`
in the environment. `runTest` in `pythia-client/src/Lib.hs` selects which example runs.

**`package.yaml` is the source of truth** (hpack); the `*.cabal` files are generated — edit
`package.yaml` to change dependencies/options, never the `.cabal`. All packages build with `-Wall`
plus an extended warning set (see any `package.yaml`); keep new code warning-clean.

## Architecture

### The provider abstraction (pythia-core)

`Pythia.Core.Class` defines the whole contract via associated type families. A provider is an
empty tag type (e.g. `data OpenAI`) selected at the value level with a `Proxy`:

```haskell
class LLM a where
  type Request a; type Response a; type Error a
  query :: Proxy a -> Request a -> ExceptT (Error a) IO (Response a)

class LLM a => LLMStreaming a where
  type Chunk a
  queryStreaming :: Proxy a -> Request a -> (ChatEvent (Chunk a) -> IO ()) -> ExceptT (Error a) IO ()
```

`ChatEvent a = ChatDelta a | ChatDone | ChatUnknown String` is the normalized stream event each
provider maps its raw SSE messages into. All results are returned in `ExceptT err IO`.

### Provider clients (pythia-client)

Each provider module (`OpenAI.hs`, `Anthropic.hs`) follows the same shape:
- A type-level Servant `API` and `StreamingAPI` describing the endpoint, headers, and body.
  Streaming uses `ServerSentEvents'` from `servant-client-core`.
- `client`/`S.client` derive the request functions; `query`/`queryStreaming` wrap them by building
  a TLS `Manager` + `BaseUrl`, running the Servant client, and re-throwing `ClientError` into `ExceptT`.
- A `jsonChatEvent :: EventMessage -> Maybe (ChatEvent ...)` that decodes each SSE frame and maps
  it to a `ChatEvent` (returns `Nothing` to drop frames like pings / dispatch markers).

The `*/API.hs` modules hold the request/response record types and their JSON instances only.

### JSON encoding conventions (important and provider-specific)

- `Pythia.Client.Common.jsonOptions` is the shared baseline: snake_case field and constructor names
  (via `Cases.snakify`) and `omitNothingFields = True`. Use it for new types.
- Anthropic overrides this in `Anthropic/API.hs`: `anthropicOptions` additionally maps the Haskell
  field `contentType` → the wire field `"type"`, and `chunkOptions` decodes the streaming `ChatChunk`
  sum type as a `TaggedObject` discriminated on `"type"` (and renames `messageDelta` → `"delta"`).
  When adding fields whose Haskell name can't match the wire name, extend these `Options` rather than
  renaming records.
- `Pythia.Client.Orphan` provides an orphan `Out Text` instance so `GenericPretty` can pretty-print
  Anthropic types; `Common.pprint`/`pshow` pretty-print any `ToJSON` value as indented JSON.

When adding a provider: create `Pythia/Client/<Name>.hs` + `<Name>/API.hs`, define a tag type and
`Proxy`, give it `LLM`/`LLMStreaming` instances, and add request/response types with JSON instances
derived from `jsonOptions` (overriding `Options` where the wire format demands).
