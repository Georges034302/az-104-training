# AZ-104 Azure Administrator Training (Workflow-free, Topic-Based)

This repository is designed for **AZ-104** preparation and real-world Azure administration practice.

## Structure
- `modules/<module>/lessons/` → concept lessons (one topic per file) with **flow architecture diagrams**
- `modules/<module>/labs/` → hands-on labs (one topic per file). Each lab:
  - creates its **own** resources (including its own Resource Group)
  - uses **parameterised** variables
  - provides **Portal + CLI** steps (ARM included where helpful)
  - includes a **Cleanup** section
  - keeps CLI commands **commented out** (uncomment after review)
  - captures outputs into **variables** and **echoes** them

## Default region
All labs default to:
- `LOCATION=australiaeast`

## How to use
1. Start in `docs/toc.md` and pick any lesson/lab.
2. For labs, copy the CLI blocks into a `.sh` script, set parameters, then uncomment and run.
3. Always run the **Cleanup** section to avoid costs.

## Safety
See `docs/cost-safety.md` for guardrails and cost tips.
