# UZDoom Cinematic Pipeline

A high-fidelity, production-grade post-processing suite for UZDoom. This pipeline elevates GZDoom's visual fidelity to modern engine standards (Unreal Engine 5, id Tech 8, Crytek) through a unified, high-performance shading architecture.

## Features
* **Multi-Stage Pipeline:** Optimized exposure, bloom, and cinematic lens FX.
* **Hollywood Color Grading:** Integrated Lift, Gamma, Gain (LGG) color wheels.
* **Professional Tone-Mapping:** Choice of ACES (Original/Fitted), AgX Filmic, Khronos PBR Neutral, and Hable.
* **AMD Contrast Adaptive Sharpening (CAS):** Crystal clear texture detail without aliasing artifacts.
* **Cinematic Artifacts:** Anamorphic flares, physical wide-angle lens warping, and dynamic film grain.

## Included Shaders
* `EyeAdaptation.fp`: Exposure fusion + 6+ Professional Tone-mapping curves.
* `Bloom.fp`: High-density Gaussian ring-blur distribution.
* `AnamorphicFlare.fp`: Sci-Fi horizontal lens streak extraction.
* `LensDistortion.fp`: Cubic wide-angle barrel warp.
* `CinematicEffects.fp`: Unified pass for CAS, LGG Color Grading, Vignette, and Grain.

## Requirements
* UZDoom 5.0.0+
* Vulkan or OpenGL 3.3+ backend recommended.

## Configuration
All settings are accessible in-game via the **"Next-Gen Shading Pipeline"** menu. Use the built-in presets to instantly toggle between "id Tech 8 Industrial," "UE5 Cinematic," and "Crytek Maximum" styles.
