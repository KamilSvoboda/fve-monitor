# Repository Guidelines

## Project Structure & Module Organization
This repository is intentionally small. The main executable is [fve_monitor.sh](/Users/kasvo/Development/projects/fve-monitor/fve_monitor.sh), which polls a local Fronius-style power-flow endpoint and renders a terminal bar chart. [README.md](/Users/kasvo/Development/projects/fve-monitor/README.md) is currently minimal and should stay aligned with script behavior if commands or prerequisites change.

Keep new logic close to the script unless the project is intentionally expanded. If additional assets or helper scripts are added, place them in clearly named top-level directories such as `docs/`, `examples/`, or `scripts/`.

## Core Feature Implementation

The script polls a Fronius-style power-flow endpoint that returns a JSON structure. The key attributes used by the monitor are:

- `P_PV`: Current PV generation power in watts. Minimum value is 0, maximum is 6000.
- `P_Load`: Current total household consumption in watts. Always a negative value.
- `P_Grid`: Current power flow to/from the grid in watts. Positive value indicates consumption from the grid, negative value indicates surplus power fed back to the grid (excess PV generation exceeds household consumption).
- `P_Akku`: Current power flow to/from batteries in watts. Behaves the same as `P_Grid`. Not currently installed but may be added in the future.

The script extracts these values from the JSON response path: `.site.P_PV`, `.site.P_Load`, and `.site.P_Grid`, and renders them as a terminal bar chart for real-time visualization.

## Build, Test, and Development Commands
There is no build step; this is a Bash script.

- `chmod +x fve_monitor.sh` ensures the script is executable.
- `./fve_monitor.sh` runs the monitor against the configured `URL`.
- `bash -n fve_monitor.sh` checks shell syntax before committing.
- `shellcheck fve_monitor.sh` performs static analysis if `shellcheck` is installed.

The script depends on `curl`, `jq`, `awk`, `tput`, and a reachable inverter API endpoint.

## Coding Style & Naming Conventions
Use Bash with 4-space indentation inside functions and control blocks. Prefer uppercase names for configuration constants such as `URL`, `MAX_POWER`, and `INTERVAL`, and lowercase names for local runtime variables such as `pv`, `load`, and `grid`.

Quote variable expansions unless unquoted use is required. Prefer small functions, direct control flow, and readable terminal output over clever compactness. Keep comments short and only where they clarify non-obvious behavior.

## Testing Guidelines
There is no automated test suite yet. At minimum:

- Run `bash -n fve_monitor.sh`.
- Run `shellcheck fve_monitor.sh`.
- Execute `./fve_monitor.sh` against a live or mocked endpoint and verify parsing of `.site.P_PV`, `.site.P_Load`, and `.site.P_Grid`.

If tests are added later, place them under `tests/` and name them after the behavior they cover, for example `tests/powerflow_parsing.sh`.

## Commit & Pull Request Guidelines
Current Git history uses short, lowercase commit subjects such as `initial version` and `first commit`. Keep commit messages brief, imperative, and focused on one change.

As this is a solo developer project, pull requests are not created. Changes are committed directly to the main branch.

## File Distribution
Distribution will consist of copying the script to the user's home directory and setting the file permissions for execution.
