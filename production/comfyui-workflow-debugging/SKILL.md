---
name: comfyui-workflow-debugging
description: Use whenever the user is running ComfyUI locally (Windows), mentions a workflow JSON or .png with embedded workflow they downloaded/shared, or pastes a ComfyUI error like "missing node type", "value not in list", red/missing nodes, "IMPORT FAILED", washed-out/black VAE output, or size-mismatch tensor errors. Also trigger when the user wants Claude to design or modify a ComfyUI workflow from scratch (checkpoint → CLIP encode → KSampler → VAE → save chain), wire in LoRA/ControlNet, or understand why a node/model isn't showing up in a dropdown. Covers node/model basics, the two ComfyUI workflow JSON formats (UI vs API), model folder layout, ComfyUI-Manager custom node installs, and SD1.5/SDXL/SD3/Flux compatibility rules. Don't wait for the user to say "ComfyUI skill" explicitly — any workflow-not-running, red-node, or model-mismatch complaint about ComfyUI should trigger this.
---

# ComfyUI Workflow Debugging & Authoring

ComfyUI workflows fail in a small number of recurring ways: a node type isn't installed, a model file isn't where the workflow expects it, or two pieces (checkpoint/VAE/CLIP/LoRA) come from incompatible model families. Diagnosing systematically beats guessing — most "it just doesn't work" reports collapse into one of the categories below within a minute of reading the console log or the workflow JSON.

## Step 1: Identify what you're dealing with

Ask (or infer from what's pasted):
- **A workflow JSON/PNG that won't load or won't run** → go to [Step 2: Triage](#step-2-triage-an-external-workflow).
- **A workflow to design or extend from a description** → go to [references/pipeline-basics.md](references/pipeline-basics.md) for the node graph anatomy, then [references/json-format.md](references/json-format.md) if you need to hand-write or script the JSON.
- **A specific pasted error** → jump straight to the matching entry in [references/troubleshooting.md](references/troubleshooting.md) rather than reading everything.

## Step 2: Triage an external workflow

Read the actual file before theorizing — open the `.json` (or extract metadata from the `.png` if that's what was shared: ComfyUI embeds the full workflow in PNG metadata, but Discord/Twitter/most chat apps strip it on re-upload, so if the user only has a re-shared image, tell them up front it likely won't drag-and-drop back into ComfyUI and they need the original file or the exported JSON).

Check, in order — each maps to a distinct failure class:

1. **Does every `class_type` (API format) / node `type` (UI format) exist in this ComfyUI install?** A node referenced in the JSON but not registered locally is the single most common failure (rough community estimate: ~85% of "broken workflow" reports). Fix path is ComfyUI-Manager's "Install Missing Custom Nodes," not hand-editing the graph. Details: [references/troubleshooting.md#missing-nodes](references/troubleshooting.md#1-missing-node-type--red-nodes).
2. **Do the model filenames in loader widgets (`ckpt_name`, `lora_name`, `vae_name`, `control_net_name`, ...) exist on disk in this machine's `models/` folders?** These are baked-in literal strings at save time — they don't travel with the workflow. "Value not in list" is the signature error. Details: [references/troubleshooting.md#model-paths](references/troubleshooting.md#2-value-not-in-list--model-path-mismatches).
3. **Do the checkpoint, VAE, CLIP/text-encoder, and any LoRA/ControlNet all belong to the same model family** (SD1.5 / SDXL / SD3 / Flux)? Mixing families is the top cause of washed-out colors, black frames, and tensor size-mismatch crashes. Details: [references/model-compatibility.md](references/model-compatibility.md).
4. **Did ComfyUI-Manager just update something?** Console "IMPORT FAILED" lines mean a Python exception happened during node loading — the useful error is the traceback *above* that line, not the line itself. Custom nodes each ship independent `requirements.txt` files and a Manager update can silently break a shared dependency for an unrelated node pack. Details: [references/troubleshooting.md#dependency-conflicts](references/troubleshooting.md#4-import-failed--dependency-conflicts).

Work through these in order — don't jump to "reinstall ComfyUI" or "fresh venv" until 1–3 are ruled out, since those are graph/data problems, not environment problems, and a fresh install won't fix them.

## Step 3: Fix, then verify

After fixing, restart ComfyUI fully (not a browser refresh — new custom nodes and updated model scans only register on process restart), reload the workflow, and check the console log on load for any remaining red text before queueing a generation. If the user wants to confirm with a real run, queue a small/cheap generation (low steps, small resolution) first rather than the original full-res settings, to isolate graph/config errors from just-slow generation.

## Designing or modifying a workflow

When asked to build or extend a workflow rather than fix one:
- Read [references/pipeline-basics.md](references/pipeline-basics.md) first for the standard node graph shape (txt2img, img2img, LoRA, ControlNet wiring) — get the data flow right before worrying about JSON syntax.
- Read [references/json-format.md](references/json-format.md) when you need to actually write or script the file — it covers the UI-format (`nodes`/`links`, used by the ComfyUI editor) vs. API-format (flat `{node_id: {class_type, inputs}}`, used for `/prompt` automation) and which one a given task needs.
- Cross-check new nodes/models against [references/model-compatibility.md](references/model-compatibility.md) before wiring anything — picking an SDXL VAE for a Flux checkpoint, for instance, is wrong before the workflow ever runs.

## Confidence notes

This skill is built from official docs (docs.comfy.org) plus aggregated community reports (GitHub issues, Reddit, blog troubleshooting guides). Architecture compatibility rules (model-compatibility.md) and node JSON field names (json-format.md) are documented and fairly reliable. Some specifics — exact `widgets_values` typing across ComfyUI frontend versions, and whether a given Manager update broke a specific node pack — change over time as ComfyUI evolves quickly; if something in the references doesn't match what's actually in front of you (e.g., the JSON looks different from the documented shape), trust the actual file over the reference and say so.
