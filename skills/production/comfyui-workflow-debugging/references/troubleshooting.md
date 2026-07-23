# ComfyUI Troubleshooting Reference

Sources: https://docs.comfy.org/troubleshooting/custom-node-issues, https://docs.comfy.org/troubleshooting/model-issues, https://docs.comfy.org/get_started/manual_install, https://docs.comfy.org/installation/install_custom_node, plus aggregated GitHub issues (comfyanonymous/ComfyUI, Comfy-Org/ComfyUI, Comfy-Org/ComfyUI_frontend) and community write-ups. Rough frequency estimate across reports: missing nodes ~85% of "broken external workflow" complaints, model path issues ~12%, version/dependency conflicts ~3% — treat as a directional prior, not a hard statistic.

## 1. Missing node type / red nodes

**Symptom**: loading a workflow shows one or more nodes outlined in red, or the console prints something like `Node type "XYZ" not found` / the graph won't queue.

**Cause**: the workflow JSON references a `class_type` / node `type` that isn't registered in this ComfyUI install — almost always because the original author had a custom node package installed that you don't.

**Fix sequence**:
1. Open **ComfyUI-Manager** → "Install Missing Custom Nodes." It scans the loaded workflow for unresolved node types and offers to install matches from its registry. This resolves the large majority of cases.
2. **Fully restart ComfyUI** (stop and relaunch the process — a browser refresh alone won't register newly installed nodes).
3. If Manager doesn't find a match (the node isn't in its registry): search the exact node type/class name on GitHub — node authors usually name their repo close to the class name. Install via Manager's "Install via Git URL," or `git clone` directly into `ComfyUI/custom_nodes/<repo>`, then `pip install -r requirements.txt` inside that folder, then restart.
4. If the missing node is cosmetic/post-processing only (not on the critical path to your output), it's faster to delete or bypass it and verify the core checkpoint→sampler→VAE→save chain works, then decide if the missing feature is worth chasing down.

## 2. "Value not in list" / model path mismatches

**Symptom**: `CheckpointLoaderSimple: - Value not in list: ckpt_name: 'model.safetensors' not in []` (or the same for `lora_name`, `vae_name`, `control_net_name`, etc.), or the loader's dropdown is just empty/shows a different file selected than intended.

**Cause**: loader widgets store the model's **filename as a literal string** at save time. ComfyUI populates the dropdown by scanning its configured model folders at startup — if the exact filename isn't found there, the saved value can't be matched and the field shows empty or errors.

**Fix options** (pick based on situation):
- **File exists locally under a different name** → rename it to match exactly, or just reselect any compatible file from the now-populated dropdown (only valid if the model is actually architecture-compatible — see model-compatibility.md).
- **Models live in a different/shared directory** (common when sharing models across multiple ComfyUI installs, or moving a workflow between machines) → copy `extra_model_paths.yaml.example` to `extra_model_paths.yaml` in the ComfyUI root, set a `base_path` and per-type subfolder paths (`checkpoints:`, `loras:`, `vae:`, `controlnet:`, etc.) pointing at the shared location, restart ComfyUI.
- **Can't move/copy the actual files** → symlink them into the relevant `ComfyUI/models/<type>/` folder instead of duplicating.
- Either way, this requires a ComfyUI **restart** — the model folder scan happens at startup, not live.

## 3. VAE / checkpoint mismatch (washed colors, black frames, NaN)

See [model-compatibility.md](model-compatibility.md) for the full family-matching table. Quick version: if output looks washed-out/purple, blurry, or solid black, check that the VAE, CLIP/text-encoder, and checkpoint are all from the same model family (SD1.5 / SDXL / SD3 / Flux) before touching anything else — community consensus is this is the cause in the overwhelming majority of "bad output but no error" cases.

## 4. "IMPORT FAILED" / dependency conflicts

**Symptom**: ComfyUI's startup console shows `(IMPORT FAILED)` next to one or more custom node packages; those nodes are unusable (often shown as missing/red when a workflow tries to use them, indistinguishable at a glance from case #1 above — always check the startup console log to tell them apart).

**Cause**: each custom node repo ships its own `requirements.txt`. Installing many packages over time means pip may have silently up/downgraded a shared dependency (numpy, opencv-python, transformers, pydantic, etc.) to satisfy whichever node was installed/updated most recently, breaking an earlier one that needed a different version.

**Diagnosis**: the `(IMPORT FAILED)` line itself is not the useful part — scroll **up** in the console output to find the actual Python traceback printed just before it; that names the real exception (usually an `ImportError` or version-incompatibility error) and which package is involved.

**Fix options**, roughly in order of effort:
1. If you know which node was just installed/updated, check whether ComfyUI-Manager offers a rollback/specific-version install for it.
2. Disable custom node packages by moving their folder out of `custom_nodes/` (or use Manager's disable toggle) and re-enable one at a time to bisect which one introduced the conflicting dependency.
3. Manually align the conflicting package to a version both node packs accept (check both `requirements.txt` files for the package and pick a compatible version, or check each node's GitHub issues for known-good pins).
4. As a last resort, recreate the Python virtual environment and reinstall only the custom nodes actually in use — this resets all dependency state but loses nothing structural since node packages themselves aren't deleted.

## 5. Other frequently-seen gotchas

- **PNG shared via Discord/Twitter/forums loses embedded workflow metadata** on re-compression — if a user only has a re-shared image (not the original save or an exported `.json`), tell them up front it likely won't drag-and-drop back into a working graph; they need the original file.
- **OOM on a shared workflow** is often just resolution: workflows authored for large GPUs may use 1536px+ which silently OOMs on smaller cards. Check `Empty Latent Image` / any resize nodes' width/height before assuming something is broken.
- **Tensor "size mismatch" errors** are usually a LoRA or ControlNet from the wrong model family (see model-compatibility.md), or a resize happening on one graph branch but not a parallel one feeding the same downstream node.
- **Corrupt/incomplete model downloads** are a frequent silent failure — Manager's "Show report" / error detail usually names the specific file; delete and redownload it rather than debugging the graph.
- **Node renames after a core ComfyUI update** can leave reroute/links orphaned in older saved workflows — if a node that should exist still shows red after confirming it's installed, check whether its class name changed upstream and the workflow needs re-wiring at that specific node.
