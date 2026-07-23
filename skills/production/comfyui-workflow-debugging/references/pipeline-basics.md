# ComfyUI Node Graph Basics

Source: https://docs.comfy.org/tutorials/basic/text-to-image (verified), plus standard node-graph convention for LoRA/ControlNet wiring (not pulled from a single doc page — verify against the actual node's input/output sockets in-app if something looks off).

## The standard txt2img chain

```
Load Checkpoint ──MODEL────────────────────────────▶ KSampler ──LATENT──▶ VAE Decode ──IMAGE──▶ Save Image
       │                                                  ▲                    ▲
       ├──CLIP──▶ CLIP Text Encode (positive) ──COND──────┤                    │
       ├──CLIP──▶ CLIP Text Encode (negative) ──COND──────┤                    │
       └──VAE────────────────────────────────────────────┴────────────────────┘
                                                            ▲
                                          Empty Latent Image (width/height/batch) ──LATENT
```

- **Load Checkpoint** (`CheckpointLoaderSimple`) outputs three sockets: `MODEL`, `CLIP`, `VAE`. Almost everything downstream traces back to one of these three.
- **CLIP Text Encode** turns a text prompt into a `CONDITIONING` tensor via the checkpoint's own CLIP. You need two instances — positive and negative — both fed from the same `CLIP` output.
- **Empty Latent Image** creates a blank latent tensor at the target width/height/batch_size. This is where resolution lives for a fresh generation.
- **KSampler** is the core: takes `MODEL`, positive `CONDITIONING`, negative `CONDITIONING`, a `LATENT`, plus widgets `seed`, `steps`, `cfg`, `sampler_name`, `scheduler`, `denoise`. Outputs a denoised `LATENT`.
- **VAE Decode** converts the denoised latent back into pixel-space `IMAGE` using the checkpoint's `VAE` output (or an explicitly loaded one — see model-compatibility.md).
- **Save Image** writes to `ComfyUI/output/`.

## img2img variant

Replace `Empty Latent Image` with: `Load Image` → `VAE Encode` (using the same VAE) → `LATENT`, fed into KSampler. Set `denoise` < 1.0 (e.g. 0.5–0.75) — at `denoise = 1.0` the sampler ignores the input image entirely and you get a pure txt2img result.

## Adding LoRA

`LoRA Loader` (`LoraLoader`) sits between the checkpoint and everything downstream: it takes `MODEL` + `CLIP` in, and outputs patched `MODEL` + `CLIP` with the LoRA's weights blended in (controlled by `strength_model` / `strength_clip` widgets). Wire the checkpoint's `MODEL`/`CLIP` into the LoRA Loader, then use the *LoRA Loader's* `MODEL`/`CLIP` outputs everywhere you'd otherwise use the checkpoint's — KSampler and both CLIP Text Encode nodes. Stack multiple LoRAs by chaining LoRA Loader nodes in series.

## Adding ControlNet

`Load ControlNet Model` loads the ControlNet weights (must match the checkpoint's architecture family — see model-compatibility.md). `Apply ControlNet` (or `ControlNetApplyAdvanced`) takes the positive (and usually negative) `CONDITIONING`, the `CONTROL_NET`, and a control/guide `IMAGE` (often pre-processed: edge map, depth map, pose, etc. via a preprocessor node), and outputs new `CONDITIONING` carrying the spatial guidance. Feed that into KSampler in place of the plain CLIP Text Encode conditioning.

## Things that aren't obvious from the graph alone

- A node's **widget values** (sliders, dropdowns, numbers typed directly into the node) are only meaningful in the *saved workflow JSON*; if you're describing a workflow in prose to build from scratch, always confirm steps/cfg/sampler/scheduler/resolution explicitly rather than assuming ComfyUI defaults, since "default" varies by ComfyUI version and by which example workflow the user started from.
- Reroute nodes are purely visual/organizational — they don't transform data, just relay a socket through a different point on the canvas. If a workflow has a lot of them, trace through them rather than assuming a direct edge.
- Not every example workflow uses `Save Image` at the end — `Preview Image` is common for iterating without writing to disk. Functionally interchangeable for debugging purposes, but `Preview Image` produces no output file.
