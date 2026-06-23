# PHP Coding Agent — Live Coding Session

Build a minimal AI coding agent from scratch in PHP. This repository is the **starter base** for a live coding presentation: you implement an LLM client, an agentic REPL loop, and file-system tools step by step in a single file.

Inspired by [How to Build an Agent](https://ampcode.com/notes/how-to-build-an-agent) from Amp.

## What you'll build

A CLI agent that:

1. **Talks to an LLM** via an OpenAI-compatible chat-completions API
2. **Runs an agentic loop** — read user input, call the model, repeat
3. **Calls tools** — `read_file`, `list_files`, `edit_file`, `write_file` — so the model can explore and modify the codebase

No frameworks, no Composer dependencies. Plain PHP, cURL, and stdin/stdout.

## Prerequisites

- **PHP 8.1+** (uses `str_contains` and other modern features)
- **PHP cURL extension** (`php -m | grep curl`)
- **API key** for an OpenAI-compatible endpoint
- **Linux** (optional): `inotify-tools` for the progress bar script

Default model and endpoint in the snippets:

| Setting | Value |
|---------|--------|
| Model | `Qwen3-Coder-30B-A3B-Instruct` |
| Endpoint | `https://oai.endpoints.kepler.ai.cloud.ovh.net/v1/chat/completions` |

Any OpenAI-compatible API works — update the URL and model name in `callLlm()`.

## Quick start

```bash
# 1. Set your API key
export API_KEY="your-api-key-here"

# 2. Create or open agent.php and start coding (see Live coding flow below)

# 3. Run the agent
php agent.php
```

For a quick smoke test of just the LLM client (before the full loop):

```bash
php -r '
require "agent.php";
$conversation[] = ["role" => "user", "content" => "hello who are you?"];
$response = callLlm($conversation);
echo $response["choices"][0]["message"]["content"] ?? "No response";
'
```

Or use the `tllm` snippet in VS Code (see below).

## Repository layout

```
.
├── agent.php          # ← main file you build during the session (start empty or minimal)
├── demo.php           # optional scratch file for demos
├── test.php           # working copy with the full implementation (for testing)
├── final-code/
│   └── agent.php      # completed reference solution (with comments)
├── script.md          # presenter notes / talk outline
├── watch.sh           # live line-count progress bar for agent.php
└── .vscode/
    └── php.code-snippets   # VS Code snippets for fast live coding
```

| File | Purpose |
|------|---------|
| `agent.php` | The file you edit on stage. Grows from LLM client → loop → tools. |
| `final-code/agent.php` | Finished version with docblocks and comments. |
| `test.php` | Full agent without extra comments — handy for local runs. |
| `script.md` | Step-by-step narrative for the presenter. |
| `watch.sh` | Shows a 400-line progress bar while you code. |

## Live coding flow

The session is designed to be built in **three layers**, each testable on its own.

### 1. LLM client (`callLlm`)

Implement a function that:

- Reads `API_KEY` from the environment
- POSTs a JSON payload to the chat-completions endpoint
- Returns the decoded response (or throws on cURL / API errors)

**Snippet:** type `cllm` in VS Code.

**Test:** type `tllm` — sends a single message and prints the reply.

### 2. Agentic loop (`runAgent`)

Add a `while (true)` REPL that:

- Prompts the user (colored output: blue = you, yellow = agent, green = tools)
- Appends messages to a `$conversation` array
- Calls `callLlm()` and prints the assistant reply
- Keeps full message history for multi-turn chat

**Snippet:** type `loop`.

**Try it:** ask *"Who are you?"* — then add a system message for personality.

**Snippet:** type `sys` — sets the agent name to "Agent 007".

### 3. Tools

Define four file-system tools the model can call:

| Tool | What it does |
|------|----------------|
| `read_file` | Read a file by relative path |
| `list_files` | Recursively list files under a directory |
| `edit_file` | Search-and-replace (or create a new file) |
| `write_file` | Overwrite / create a file |

Each tool needs:

- `name` — identifier the model uses
- `description` — **critical** for tool selection; write it for the LLM
- `input_schema` — JSON Schema for parameters
- `function` — PHP callable that runs the tool

Also add `buildLlmTools()` (schema → OpenAI tool format) and `executeTool()` (dispatch + catch errors as strings).

**Snippet:** type `tools`.

**Try it:** *"List files in the current directory"* — then ask it to read or edit a file.

### Agent loop with tools

When the model returns `tool_calls`:

1. Execute each tool and collect results
2. Append `role: tool` messages to `$conversation`
3. Call the LLM again **without** prompting the user (`$readUserInput = false`)
4. Repeat until the model stops with `finish_reason: stop` and no pending tools

```
User → LLM → (optional) tool calls → tool results → LLM → … → final reply → User
```

## VS Code snippets

Open this folder in VS Code / Cursor. Snippets are in `.vscode/php.code-snippets`:

| Prefix | Inserts |
|--------|---------|
| `cllm` | `callLlm()` function |
| `tllm` | Quick LLM test |
| `loop` | `runAgent()` + color helpers |
| `sys` | System message (Agent 007) |
| `tools` | Full `$tools` array + `buildLlmTools` + `executeTool` |

## Progress bar (presenter)

Monitor how many lines you've written during the session (target: ~400 lines):

```bash
# Install on Debian/Ubuntu
sudo apt install inotify-tools

# In a second terminal
./watch.sh agent.php
```

## Architecture (reference)

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  stdin/     │     │   runAgent   │     │    callLlm      │
│  stdout     │◄───►│  (REPL loop) │◄───►│  (cURL → API)   │
└─────────────┘     └──────┬───────┘     └─────────────────┘
                           │
                    tool_calls?
                           │
                           ▼
                   ┌───────────────┐
                   │ executeTool   │
                   │ read/list/    │
                   │ edit/write    │
                   └───────────────┘
```

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `API_KEY` | Yes | Bearer token for the LLM API |

## Troubleshooting

**`API_KEY environment variable is not set`**
→ `export API_KEY=...` in the same shell before `php agent.php`.

**`cURL error` / SSL issues**
→ The snippets disable SSL verification for the OVH endpoint. For production, enable verification and point cURL at a CA bundle.

**Model doesn't call tools**
→ Check that `buildLlmTools($tools)` is passed to `callLlm()`, tool descriptions are clear, and you're using a model that supports function calling (e.g. Qwen3-Coder).

**`old_str not found in file`**
→ `edit_file` requires an exact, unique match. Use `read_file` first or switch to `write_file` for full rewrites.

## After the session

Compare your `agent.php` with `final-code/agent.php`. The reference includes docblocks explaining the non-obvious parts (tool loop without re-prompting, conversation history shape, etc.).

## Resources

* https://ampcode.com/notes/how-to-build-an-agent
* https://levelup.gitconnected.com/building-claude-code-with-harness-engineering-d2e8c0da85f0
* https://addyosmani.com/blog/agent-harness-engineering/


## License

Use freely for workshops, meetups, and learning.
