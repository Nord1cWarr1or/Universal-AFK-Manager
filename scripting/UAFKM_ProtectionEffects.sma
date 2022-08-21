#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <reapi>

#include <msgstocks>
#include <universal_afk_manager>

#define GetCvarDesc(%0) fmt("%L", LANG_SERVER, %0)

enum _:AFKEffectsFlags (<<=1)
{
    Effects_Transparency = 1,
    Effects_ScreenFade,
    Effects_Icon
};

new const ICON_MODEL[] = "sprites/afk/afk_6test.spr";
new const ICON_CLASSNAME[] = "afk_icon";

// Automatically create a config in "configs/plugins"
#define AUTO_CREATE_CONFIG

new g_iIconModelIndex;
new g_pCvarEffects;
new g_iPlayerIcon[MAX_PLAYERS + 1] = { NULLENT, ... };

new afk_effects,
    afk_screenfade_amount,
    afk_random_screenfade_color,
    afk_random_screenfade_type,
    Float:afk_random_screenfade_rotation_frequency

new g_szEffects[4];

public stock const PluginName[]         = "UAFKM: Protection Effects";
public stock const PluginVersion[]      = "0.1.0";
public stock const PluginAuthor[]       = "Nordic Warrior";
public stock const PluginURL[]          = "https://github.com/Nord1cWarr1or/Universal-AFK-Manager";
public stock const PluginDescription[]  = "Sample text";

public plugin_init()
{
    if(uafkm_get_amxx_version() < 1100)
    {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }

    register_dictionary("uafkm_protection_effects.txt");

    RegisterHookChain(RG_CBasePlayer_Spawn, "RG_OnPlayerSpawn_Pre", .post = false);
    RegisterHookChain(RG_CBasePlayer_Killed, "RG_OnPlayerKilled_Pre", .post = false);

    CreateCVars();

#if defined AUTO_CREATE_CONFIG
    AutoExecConfig();
#endif

    hook_cvar_change(g_pCvarEffects, "CvarEffectsChanged");

    // Fix https://github.com/alliedmodders/amxmodx/issues/728#issue-450682936
    // Credits: wopox1337 (https://github.com/ChatAdditions/ChatAdditions_AMXX/commit/47c682051f2d1697a4b3d476f4f3cdd3eb1f6be7)
    set_task(6.274, "_OnConfigsExecuted");
}

public plugin_precache()
{
    g_iIconModelIndex = precache_model_ex(ICON_MODEL);
}

public _OnConfigsExecuted()
{
    afk_effects = read_flags(g_szEffects);
}

public client_disconnected(id)
{
    if(!is_nullent(g_iPlayerIcon[id]))
    {
        RemoveIcon(id);
    }

    remove_task(id);
}

public player_start_afk_post(const id)
{
    ToggleEffects(id, true);
}

public player_end_afk_post(const id)
{
    ToggleEffects(id, false);
}

public RG_OnPlayerSpawn_Pre(const id)
{
    if(!is_user_alive(id))
        return;

    ToggleEffects(id, false);
}

public RG_OnPlayerKilled_Pre(const id, pevAttacker, iGib)
{
    ToggleEffects(id, false);
}

ToggleEffects(const id, bool:bState)
{
    if(bState)
    {
        if(afk_effects & Effects_Transparency)
        {
            rg_set_rendering(id, kRenderFxNone, 0.0, 0.0, 0.0, kRenderTransAlpha, 120.0);
        }

        if(afk_effects & Effects_Icon)
        {
            if(is_nullent(g_iPlayerIcon[id]))
            {
                CreateIcon(id);
            }

            ShowIcon(id);
        }

        if(afk_effects & Effects_ScreenFade)
        {
            if(get_viewent(id) != id)
                return;

            fade_user_screen(id, 
                .duration = 0.0,
                .fadetime = 0.0,
                .flags = ScreenFade_StayOut,
                .r = afk_random_screenfade_color ? random(255) : 0,
                .g = afk_random_screenfade_color ? random(255) : 0,
                .b = afk_random_screenfade_color ? random(255) : 0,
                .a = afk_screenfade_amount
            );

            if(afk_random_screenfade_color && afk_random_screenfade_type == 2)
            {
                set_task_ex(afk_random_screenfade_rotation_frequency, "SetNextScreenFade", id, .flags = SetTask_Repeat);
            }
        }
    }
    else
    {
        if(afk_effects & Effects_Transparency)
        {
            rg_set_rendering(id, kRenderFxNone, 0.0, 0.0, 0.0, kRenderNormal, 0.0);
        }

        if(afk_effects & Effects_Icon)
        {
            HideIcon(id);
        }

        if(afk_effects & Effects_ScreenFade)
        {
            if(get_viewent(id) != id)
                return;

            fade_user_screen(id, 
                .duration = 0.0,
                .fadetime = afk_random_screenfade_color ? 0.0 : 1.0,
                .flags = ScreenFade_FadeIn,
                .r = 0,
                .g = 0,
                .b = 0,
                .a = afk_screenfade_amount
            );

            remove_task(id);
        }
    }
}

public SetNextScreenFade(id)
{
    fade_user_screen(id, 
        .duration = 0.0,
        .fadetime = 0.0,
        .flags = ScreenFade_StayOut,
        .r = random_num(10, 255),
        .g = random_num(10, 255),
        .b = random_num(10, 255),
        .a = afk_screenfade_amount
    );
}

CreateIcon(const id)
{
    new iEnt = rg_create_entity("env_sprite");

    set_entvar(iEnt, var_classname, ICON_CLASSNAME);
    set_entvar(iEnt, var_model, ICON_MODEL);
    set_entvar(iEnt, var_modelindex, g_iIconModelIndex);
    set_entvar(iEnt, var_scale, 0.5);
    set_entvar(iEnt, var_rendermode, kRenderTransAdd);
    set_entvar(iEnt, var_renderamt, 100.0);
    set_entvar(iEnt, var_framerate, 10.0);
    set_entvar(iEnt, var_spawnflags, SF_SPRITE_STARTON);
    set_entvar(iEnt, var_aiment, id);
    set_entvar(iEnt, var_movetype, MOVETYPE_FOLLOW);

    g_iPlayerIcon[id] = iEnt;

    dllfunc(DLLFunc_Spawn, iEnt);

    set_entvar(iEnt, var_effects, EF_NODRAW);
}

RemoveIcon(const id)
{
    set_entvar(g_iPlayerIcon[id], var_flags, FL_KILLME);

    g_iPlayerIcon[id] = NULLENT;
}

ShowIcon(const id)
{
    set_entvar(g_iPlayerIcon[id], var_effects, 0);
}

HideIcon(const id)
{
    set_entvar(g_iPlayerIcon[id], var_effects, EF_NODRAW);
}

CreateCVars()
{
    bind_pcvar_string(
        g_pCvarEffects = create_cvar(
            .name = "afk_effects", 
            .string = "abc",
            .description = GetCvarDesc("UAFKM_CVAR_AFK_EFFECTS")
        ),

        g_szEffects, charsmax(g_szEffects)
    );

    bind_pcvar_num(
        create_cvar(
            .name = "afk_screenfade_amount", 
            .string = "110",
            .description = GetCvarDesc("UAFKM_CVAR_AFK_SCREENFADE_AMOUNT")
        ),

        afk_screenfade_amount
    );

    bind_pcvar_num(
        create_cvar(
            .name = "afk_random_screenfade_color", 
            .string = "0",
            .description = GetCvarDesc("UAFKM_CVAR_AFK_RANDOM_SCREENFADE_COLOR")
        ),

        afk_random_screenfade_color
    );

    bind_pcvar_num(
        create_cvar(
            .name = "afk_random_screenfade_type", 
            .string = "1",
            .description = GetCvarDesc("UAFKM_CVAR_AFK_RANDOM_SCREENFADE_TYPE")
        ),

        afk_random_screenfade_type
    );

    bind_pcvar_float(
        create_cvar(
            .name = "afk_random_screenfade_rotation_frequency", 
            .string = "1.5",
            .description = GetCvarDesc("UAFKM_CVAR_AFK_RANDOM_SCREENFADE_ROTATION_FREQUENCY")
        ),

        afk_random_screenfade_rotation_frequency
    );
}

public CvarEffectsChanged(pCvar, const szOldValue[], const szNewValue[])
{
    afk_effects = read_flags(szNewValue);
}

stock rg_set_rendering(const id, const iRenderFx, const Float:R, const Float:G, const Float:B, const iRenderMode, const Float:flRenderAmount)
{
    new Float:flRenderColor[3];

    flRenderColor[0] = R;
    flRenderColor[1] = G;
    flRenderColor[2] = B;

    set_entvar(id, var_renderfx, iRenderFx);
    set_entvar(id, var_rendercolor, flRenderColor);
    set_entvar(id, var_rendermode, iRenderMode);
    set_entvar(id, var_renderamt, flRenderAmount);
}

stock precache_model_ex(const szModelName[])
{
    if(file_exists(szModelName, true))
    {
        return precache_model(szModelName);
    }

    set_fail_state("Model <%s> not found. Plugin stopped.", szModelName);
    return 0;
}
