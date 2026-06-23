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
    }

    override void WorldLoaded(WorldEvent e)
    {
        // Play context method cannot write to UI variables like currentExposure.
        // We initialize currentExposure dynamically in the UI context instead.
    }

    override void RenderOverlay(RenderEvent e)
    {
        PlayerInfo player = players[consoleplayer];
        if (!player || !player.camera || !player.camera.CurSector || gamestate == GS_TITLELEVEL || automapactive)
        {
            PPShader.SetEnabled("EyeAdaptationShader", false);
            return;
        }

        InitCVars();
        if (cv_enabled && !cv_enabled.GetBool())
        {
            PPShader.SetEnabled("EyeAdaptationShader", false);
            return;
        }

        if (currentExposure <= 0.0)
        {
            currentExposure = 1.0;
        }

        double speed = cv_speed ? cv_speed.GetFloat() : 0.05;
        double maxBoost = cv_dark_boost ? cv_dark_boost.GetFloat() : 2.0;
        double minDim = cv_bright_dim ? cv_bright_dim.GetFloat() : 0.5;
        int tonemapVal = cv_tonemap ? cv_tonemap.GetInt() : 0;
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

        PPShader.SetEnabled("EyeAdaptationShader", true);
        PPShader.SetUniform1f("EyeAdaptationShader", "exposure", currentExposure);
        PPShader.SetUniform1i("EyeAdaptationShader", "tonemapMode", tonemapVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "reinhardBurn", reinhardBurnVal);
        PPShader.SetUniform1i("EyeAdaptationShader", "splitScreen", splitScreenVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "tonemapExposure", tonemapExpVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "filmContrast", filmContrastVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "filmSaturation", filmSaturationVal);
        PPShader.SetUniform1f("EyeAdaptationShader", "tonemapStrength", tonemapStrengthVal);
    }
}

