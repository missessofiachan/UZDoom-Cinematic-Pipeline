class EyeAdaptationHandler : StaticEventHandler
{
    private ui double currentExposure;
    private ui CVar cv_enabled;
    private ui CVar cv_speed;
    private ui CVar cv_dark_boost;
    private ui CVar cv_bright_dim;
    private ui CVar cv_tonemap;
    private ui CVar cv_reinhard_burn;
    private ui CVar cv_split_screen;
    private ui CVar cv_tonemap_exposure;
    private ui CVar cv_film_contrast;
    private ui CVar cv_film_saturation;
    private ui CVar cv_tonemap_strength;
    
    private ui CVar cv_bloom_intensity;
    private ui CVar cv_bloom_threshold;
    private ui CVar cv_vignette;
    private ui CVar cv_chromatic;
    private ui CVar cv_grain;

    private ui CVar cv_cas;
    private ui CVar cv_lift;
    private ui CVar cv_gamma;
    private ui CVar cv_gain;

    // Expanded Architecture Module Hooks
    private ui CVar cv_flare_intensity;
    private ui CVar cv_flare_stretch;
    private ui CVar cv_lens_warp;

    private ui void InitCVars()
    {
        PlayerInfo player = players[consoleplayer];
        if (!player || cv_enabled) return;

        cv_enabled = CVar.GetCVar("eye_adapt_enabled", player);
        cv_speed = CVar.GetCVar("eye_adapt_speed", player);
        cv_dark_boost = CVar.GetCVar("eye_adapt_dark_boost", player);
        cv_bright_dim = CVar.GetCVar("eye_adapt_bright_dim", player);
        cv_tonemap = CVar.GetCVar("eye_adapt_tonemap", player);
        cv_reinhard_burn = CVar.GetCVar("eye_adapt_reinhard_burn", player);
        cv_split_screen = CVar.GetCVar("eye_adapt_split_screen", player);
        cv_tonemap_exposure = CVar.GetCVar("eye_adapt_tonemap_exposure", player);
        cv_film_contrast = CVar.GetCVar("eye_adapt_film_contrast", player);
        cv_film_saturation = CVar.GetCVar("eye_adapt_film_saturation", player);
        cv_tonemap_strength = CVar.GetCVar("eye_adapt_tonemap_strength", player);
        
        cv_bloom_intensity = CVar.GetCVar("eye_adapt_bloom_intensity", player);
        cv_bloom_threshold = CVar.GetCVar("eye_adapt_bloom_threshold", player);
        cv_vignette = CVar.GetCVar("eye_adapt_vignette", player);
        cv_chromatic = CVar.GetCVar("eye_adapt_chromatic", player);
        cv_grain = CVar.GetCVar("eye_adapt_grain", player);

        cv_cas = CVar.GetCVar("eye_adapt_cas", player);
        cv_lift = CVar.GetCVar("eye_adapt_lift", player);
        cv_gamma = CVar.GetCVar("eye_adapt_gamma", player);
        cv_gain = CVar.GetCVar("eye_adapt_gain", player);

        // Bind Architectural Variables
        cv_flare_intensity = CVar.GetCVar("eye_adapt_flare_intensity", player);
        cv_flare_stretch = CVar.GetCVar("eye_adapt_flare_stretch", player);
        cv_lens_warp = CVar.GetCVar("eye_adapt_lens_warp", player);
    }

    override void RenderOverlay(RenderEvent e)
    {
        PlayerInfo player = players[consoleplayer];
        if (!player || !player.camera || !player.camera.CurSector || gamestate == GS_TITLELEVEL || automapactive)
        {
            PPShader.SetEnabled("EyeAdaptationShader", false);
            PPShader.SetEnabled("BloomShader", false);
            PPShader.SetEnabled("AnamorphicFlareShader", false);
            PPShader.SetEnabled("LensDistortionShader", false);
            PPShader.SetEnabled("CinematicEffectsShader", false);
            return;
        }

        InitCVars();
        if (cv_enabled && !cv_enabled.GetBool())
        {
            PPShader.SetEnabled("EyeAdaptationShader", false);
            PPShader.SetEnabled("BloomShader", false);
            PPShader.SetEnabled("AnamorphicFlareShader", false);
            PPShader.SetEnabled("LensDistortionShader", false);
            PPShader.SetEnabled("CinematicEffectsShader", false);
            return;
        }

        if (currentExposure <= 0.0)
        {
            currentExposure = 1.0;
        }

        double speed = cv_speed ? cv_speed.GetFloat() : 0.05;
        double maxBoost = cv_dark_boost ? cv_dark_boost.GetFloat() : 2.0;
        double minDim = cv_bright_dim ? cv_bright_dim.GetFloat() : 0.5;
        int tonemapVal = cv_tonemap ? cv_tonemap.GetInt() : 2;
        double reinhardBurnVal = cv_reinhard_burn ? cv_reinhard_burn.GetFloat() : 2.5;
        int splitScreenVal = (cv_split_screen && cv_split_screen.GetBool()) ? 1 : 0;
        double tonemapExpVal = cv_tonemap_exposure ? cv_tonemap_exposure.GetFloat() : 1.0;
        double filmContrastVal = cv_film_contrast ? cv_film_contrast.GetFloat() : 1.0;
        double filmSaturationVal = cv_film_saturation ? cv_film_saturation.GetFloat() : 1.0;
        double tonemapStrengthVal = cv_tonemap_strength ? cv_tonemap_strength.GetFloat() : 1.0;

        double sectorLight = player.camera.CurSector.lightlevel;
        double targetExposure = 1.0;
        if (sectorLight <= 32)
        {
            targetExposure = maxBoost;
        }
        else if (sectorLight >= 224)
        {
            targetExposure = minDim;
        }
        else
        {
            double t = (sectorLight - 32) / 192.0;
            targetExposure = maxBoost + t * (minDim - maxBoost);
        }

        currentExposure += (targetExposure - currentExposure) * speed;

        // Stage 1: Exposure Control & Color Workspace Curve Distributions
        PPShader.SetEnabled("EyeAdaptationShader", true);
        PPShader.SetUniform1f("EyeAdaptationShader", "exposure", currentExposure);
        PPShader.SetUniform1i("EyeAdaptationShader", "tonemapMode", tonemapVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "reinhardBurn", reinhardBurnVal);
        PPShader.SetUniform1i("EyeAdaptationShader", "splitScreen", splitScreenVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "tonemapExposure", tonemapExpVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "filmContrast", filmContrastVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "filmSaturation", filmSaturationVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "tonemapStrength", tonemapStrengthVal);

        // Stage 2: Spherical Gaussian Glow Scatter
        double bIntensity = cv_bloom_intensity ? cv_bloom_intensity.GetFloat() : 0.40;
        double bThreshold = cv_bloom_threshold ? cv_bloom_threshold.GetFloat() : 0.70;
        PPShader.SetEnabled("BloomShader", true);
        PPShader.SetUniform1f("BloomShader", "bloomIntensity", bIntensity);
        PPShader.SetUniform1f("BloomShader", "bloomThreshold", bThreshold);

        // Stage 3: Sci-Fi Horizontal Anamorphic Flare Extraction
        double fIntensity = cv_flare_intensity ? cv_flare_intensity.GetFloat() : 0.50;
        double fStretch = cv_flare_stretch ? cv_flare_stretch.GetFloat() : 3.0;
        PPShader.SetEnabled("AnamorphicFlareShader", true);
        PPShader.SetUniform1f("AnamorphicFlareShader", "flareIntensity", fIntensity);
        PPShader.SetUniform1f("AnamorphicFlareShader", "flareStretch", fStretch);
        PPShader.SetUniform1f("AnamorphicFlareShader", "bloomThreshold", bThreshold);

        // Stage 4: Cubic Wide-Angle Camera Geometric Distortion
        double lWarp = cv_lens_warp ? cv_lens_warp.GetFloat() : 0.15;
        PPShader.SetEnabled("LensDistortionShader", true);
        PPShader.SetUniform1f("LensDistortionShader", "lensWarp", lWarp);

        // Stage 5: Spatial Sharpening, Cinematic Grading, Lens Artifact Overlays
        double vignetteValue = cv_vignette ? cv_vignette.GetFloat() : 0.50;
        double chromaticValue = cv_chromatic ? cv_chromatic.GetFloat() : 2.0;
        double grainValue = cv_grain ? cv_grain.GetFloat() : 1.5;
        double renderTicks = System.GetTimeFrac() + level.time;
        
        double sharpnessValue = cv_cas ? cv_cas.GetFloat() : 1.5;
        double liftValue = cv_lift ? cv_lift.GetFloat() : 0.0;
        double gammaValue = cv_gamma ? cv_gamma.GetFloat() : 1.0;
        double gainValue = cv_gain ? cv_gain.GetFloat() : 1.0;

        PPShader.SetEnabled("CinematicEffectsShader", true);
        PPShader.SetUniform1f("CinematicEffectsShader", "vignetteIntensity", vignetteValue);
        PPShader.SetUniform1f("CinematicEffectsShader", "chromaticAberration", chromaticValue);
        PPShader.SetUniform1f("CinematicEffectsShader", "grainIntensity", grainValue);
        PPShader.SetUniform1f("CinematicEffectsShader", "timer", renderTicks);
        PPShader.SetUniform1f("CinematicEffectsShader", "casSharpness", sharpnessValue);
        PPShader.SetUniform1f("CinematicEffectsShader", "liftVal", liftValue);
        PPShader.SetUniform1f("CinematicEffectsShader", "gammaVal", gammaValue);
        PPShader.SetUniform1f("CinematicEffectsShader", "gainVal", gainValue);
    }
}