# Model Family Compatibility (SD1.5 / SDXL / SD3 / Flux)

Source: https://docs.comfy.org/troubleshooting/model-issues, plus community-confirmed symptom patterns (lower confidence, marked below). The single rule that explains most "it generates garbage" reports: **checkpoint, VAE, and CLIP/text-encoder must all be from the same model family.** Treat any cross-family substitution as broken until proven otherwise.

## Family cheat sheet

| Family | Latent channels | VAE | Text encoder(s) | Typical native resolution |
|---|---|---|---|---|
| SD1.5 | 4 | `vae-ft-mse-840000-ema-pruned` or checkpoint's baked-in VAE | 1× CLIP ViT-L/14 | ~512×512 (community-reported, lower confidence) |
| SDXL | 4 | `sdxl_vae.safetensors` (or `sdxl-vae-fp16-fix`) | CLIP ViT-L/14 + OpenCLIP ViT-bigG/14 (dual) | ~1024×1024-area, e.g. 896×1152, 1216×832 |
| SD3 | 16 | SD3's own VAE (don't substitute SD1.5/SDXL VAEs) | multiple text encoders per SD3 spec | 1024×1024-area |
| Flux | 16 | `ae.safetensors` (Flux-specific) | CLIP-L + T5-XXL, in **separate** slots — don't load the same T5 file into both | 1024×1024-area |

## Why mismatches break things

- **4-channel vs 16-channel latents**: SD1.5/SDXL use 4-channel latents; SD3/Flux use 16-channel. A VAE built for one literally cannot decode the other's latent tensor shape correctly — this is a hard architecture incompatibility, not a quality tradeoff.
- **VAE mismatch symptoms** (community-reported pattern, very consistently repeated across sources): washed-out or purple-tinted images, blurry/low-detail output, solid black frames, or NaN values surfacing as a crash in VAE Decode. If the image looks wrong in one of these specific ways, check the VAE before anything else — it's described as "the problem ~99% of the time" when colors are washed out.
- **Baked-in VAE vs explicit Load VAE**: many checkpoints already include a VAE internally (that's what the checkpoint's `VAE` output socket provides). Adding a separate `Load VAE` node and wiring it in when the baked-in one is already fine is the second most common mistake — it's not wrong per se, but it's a common source of confusion when the explicit VAE doesn't match the checkpoint's family.
- **ControlNet must match checkpoint family too** — an SD1.5 ControlNet model will not produce sensible guidance on an SDXL (or SD3/Flux) checkpoint, even though ComfyUI may not refuse to load it outright.
- **LoRA must match the base checkpoint's family and often the specific base model** — an SDXL LoRA on an SD1.5 checkpoint is a classic source of `size mismatch` / tensor shape errors in the console, because LoRA weights are shaped against specific layer dimensions that differ across families.

## Diagnostic shortcut

When a workflow runs without error but the output looks wrong, check in this order:
1. VAE family matches checkpoint family? (most common)
2. Any LoRA loaded — does it match the checkpoint's family/base model?
3. ControlNet (if used) — matches family?
4. Resolution — is it within the family's native range, or far outside it (very small/very large can degrade quality or OOM independent of family matching)?

When a workflow throws a **tensor size mismatch** error before any image is produced, it's almost always #2 or #3 above — a LoRA or ControlNet shaped for a different architecture than the loaded checkpoint.
