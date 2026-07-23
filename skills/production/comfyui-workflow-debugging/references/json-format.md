# ComfyUI Workflow JSON Formats

ComfyUI has **two different JSON shapes** that both get called "the workflow." Confusing them is a common source of "this script doesn't work" — know which one you're holding.

## 1. UI format (`.json` saved/exported from the editor, "Save" / "Export")

This is what the ComfyUI frontend uses to redraw the graph. Top-level shape:

```json
{
  "nodes": [
    {
      "id": 3,
      "type": "KSampler",
      "pos": [800, 200],
      "size": [315, 262],
      "flags": {},
      "order": 4,
      "mode": 0,
      "inputs": [ { "name": "model", "type": "MODEL", "link": 1 }, ... ],
      "outputs": [ { "name": "LATENT", "type": "LATENT", "links": [5] } ],
      "widgets_values": [156680208700286, "randomize", 20, 8, "euler", "normal", 1]
    }
  ],
  "links": [
    [1, 4, 0, 3, 0, "MODEL"]
  ],
  "groups": [...],
  "extra": {...}
}
```

- Each entry in `links` is `[link_id, origin_node_id, origin_slot_index, target_node_id, target_slot_index, type]`.
- `widgets_values` is a positional array matching the node definition's widget order — e.g. for KSampler: `[seed, control_after_generate, steps, cfg, sampler_name, scheduler, denoise]`. The order is defined by the node's Python class, not by the JSON itself, so don't reorder it by guesswork — read it off a real exported KSampler node, or read the node's Python source if you're hand-authoring.
- This format embeds in PNG metadata when you save an image from ComfyUI — that's how drag-and-drop "load workflow from image" works, and why a re-compressed/re-uploaded PNG (Discord, X, etc.) usually loses it.

## 2. API format (exported via "Export (API)", or what you POST to `/prompt`)

Flat dictionary keyed by string node IDs:

```json
{
  "3": {
    "class_type": "KSampler",
    "inputs": {
      "seed": 156680208700286,
      "steps": 20,
      "cfg": 8,
      "sampler_name": "euler",
      "scheduler": "normal",
      "denoise": 1,
      "model": ["4", 0],
      "positive": ["6", 0],
      "negative": ["7", 0],
      "latent_image": ["5", 0]
    }
  },
  "4": { "class_type": "CheckpointLoaderSimple", "inputs": { "ckpt_name": "v1-5-pruned-emaonly.safetensors" } }
}
```

- `inputs` mixes literal scalar values (numbers, strings, bools) with link references: `["<source_node_id>", <source_output_slot_index>]`.
- No `pos`/`size`/`widgets_values` — purely the data needed to execute the graph.
- This is the format to generate when **scripting** ComfyUI (calling its HTTP API directly) — POST it as `{"prompt": {...}, "client_id": "..."}` to `/prompt`.

## Practical implications

- If the user wants to **load a workflow back into the ComfyUI editor**, they need the UI format. The API format alone won't reopen as an editable graph.
- If you're **writing automation** that submits jobs to a running ComfyUI server, you need the API format. Get it from the editor's "Export (API)" option, not "Save" — don't hand-convert a UI-format export, the structures are different enough that a manual conversion is error-prone.
- When **hand-editing a model filename or a sampler setting** in a UI-format JSON, you must edit the right *positional* slot in `widgets_values` — editing the wrong index silently breaks an unrelated parameter. When in doubt, change it in the ComfyUI editor UI itself and re-export, rather than hand-patching the array.
- When you only have a **PNG**, extracting embedded workflow metadata (via ComfyUI's own drag-and-drop, or a script reading the PNG's `tEXt`/`exif` chunks for the `workflow` or `prompt` key) gives you the UI format if `workflow` is present, or the API format if only `prompt` metadata survived. Tell the user which one you found if it matters for what they're trying to do next.
