#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <reapi>

#include <msgstocks>
#include <uafkm_handler>

#define GetCvarDesc(%0) fmt("%L", LANG_SERVER, %0)

enum any: AFKEffectsFlags (<<=1) {
    Effects_Transparency = 1,
    Effects_ScreenFade,
    Effects_Icon
};

new const ICON_MODEL[] = "sprites/afk/afk_6test.spr";
new const ICON_CLASSNAME[] = "afk_icon";

// Automatically create a config in "configs/plugins"
#define AUTO_CREATE_CONFIG

new icon_modelindex;
new effects_cvar_pointer;
new afk_incon_ent_id[MAX_PLAYERS + 1] = { NULLENT, ... };

new afk_effects,
    afk_screenfade_amount,
    afk_random_screenfade_color,
    afk_random_screenfade_type,
    Float:afk_random_screenfade_rotation_frequency

new effects[4];

public stock const PluginName[]         = "UAFKM: Protection Effects";
public stock const PluginVersion[]      = "0.1.0";
public stock const PluginAuthor[]       = "Nordic Warrior";
public stock const PluginURL[]          = "https://github.com/Nord1cWarr1or/Universal-AFK-Manager";
public stock const PluginDescription[]  = "Sample text";

public plugin_init() {
    if (get_amxx_verint() < 1100) {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }

    register_dictionary("uafkm_protection_effects.txt");

    RegisterHookChain(RG_CBasePlayer_Spawn, "player_spawn", .post = false);
    RegisterHookChain(RG_CBasePlayer_Killed, "player_killed", .post = false);

    create_cvars();

#if defined AUTO_CREATE_CONFIG
    AutoExecConfig();
#endif

    hook_cvar_change(effects_cvar_pointer, "hook_cvar_afk_effects");

    // Fix https://github.com/alliedmodders/amxmodx/issues/728#issue-450682936
    // Credits: wopox1337 (https://github.com/ChatAdditions/ChatAdditions_AMXX/commit/47c682051f2d1697a4b3d476f4f3cdd3eb1f6be7)
    set_task(6.274, "_OnConfigsExecuted");
}

public plugin_precache() {
    icon_modelindex = precache_model_ex(ICON_MODEL);
}

public _OnConfigsExecuted() {
    afk_effects = read_flags(effects);
}

public client_disconnected(id) {
    if (!is_nullent(afk_incon_ent_id[id])) {
        remove_icon(id);
    }

    remove_task(id);
}

public player_start_afk_post(const id) {
    toggle_effects(id, true);
}

public player_end_afk_post(const id) {
    toggle_effects(id, false);
}

public player_spawn(const id) {
    if (!is_user_alive(id)) {
        return;
    }

    toggle_effects(id, false);
}

public player_killed(const id, attacker, gib) {
    toggle_effects(id, false);
}

toggle_effects(const id, bool: state) {
    if (state) {
        if (afk_effects & Effects_Transparency) {
            rg_set_rendering(id, kRenderFxNone, 0.0, 0.0, 0.0, kRenderTransAlpha, 120.0);
        }

        if (afk_effects & Effects_Icon) {
            if (is_nullent(afk_incon_ent_id[id])) {
                create_icon(id);
            }

            show_icon(id);
        }

        if (afk_effects & Effects_ScreenFade) {
            if (get_viewent(id) != id) {
                return;
            }

            fade_user_screen(id, 
                .duration = 0.0,
                .fadetime = 0.0,
                .flags = ScreenFade_StayOut,
                .r = afk_random_screenfade_color ? random_num(0, 255) : 0,
                .g = afk_random_screenfade_color ? random_num(0, 255) : 0,
                .b = afk_random_screenfade_color ? random_num(0, 255) : 0,
                .a = afk_screenfade_amount
            );

            if (afk_random_screenfade_color && afk_random_screenfade_type == 2) {
                set_task_ex(afk_random_screenfade_rotation_frequency, "set_next_screen_fade", id, .flags = SetTask_Repeat);
            }
        }
    } else {
        if (afk_effects & Effects_Transparency) {
            rg_set_rendering(id, kRenderFxNone, 0.0, 0.0, 0.0, kRenderNormal, 0.0);
        }

        if (afk_effects & Effects_Icon) {
            hide_icon(id);
        }

        if (afk_effects & Effects_ScreenFade) {
            if (get_viewent(id) != id) {
                return;
            }

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

public set_next_screen_fade(id) {
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

create_icon(const id) {
    new ent = rg_create_entity("env_sprite");

    set_entvar(ent, var_classname, ICON_CLASSNAME);
    set_entvar(ent, var_model, ICON_MODEL);
    set_entvar(ent, var_modelindex, icon_modelindex);
    set_entvar(ent, var_scale, 0.5);
    set_entvar(ent, var_rendermode, kRenderTransAdd);
    set_entvar(ent, var_renderamt, 100.0);
    set_entvar(ent, var_framerate, 10.0);
    set_entvar(ent, var_spawnflags, SF_SPRITE_STARTON);
    set_entvar(ent, var_aiment, id);
    set_entvar(ent, var_movetype, MOVETYPE_FOLLOW);

    afk_incon_ent_id[id] = ent;

    dllfunc(DLLFunc_Spawn, ent);

    set_entvar(ent, var_effects, EF_NODRAW);
}

remove_icon(const id) {
    set_entvar(afk_incon_ent_id[id], var_flags, FL_KILLME);
    afk_incon_ent_id[id] = NULLENT;
}

show_icon(const id) {
    set_entvar(afk_incon_ent_id[id], var_effects, 0);
}

hide_icon(const id) {
    set_entvar(afk_incon_ent_id[id], var_effects, EF_NODRAW);
}

create_cvars() {
    bind_pcvar_string(
        effects_cvar_pointer = create_cvar(
            .name = "afk_effects", 
            .string = "abc",
            .description = GetCvarDesc("UAFKM_CVAR_AFK_EFFECTS")
        ),

        effects, charsmax(effects)
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

public hook_cvar_afk_effects(pCvar, const old_value[], const new_value[]) {
    afk_effects = read_flags(new_value);
}

stock rg_set_rendering(const id, const render_fx, const Float: R, const Float: G, const Float: B, const render_mode, const Float: render_amount) {
    new Float: render_color[3];

    render_color[0] = R;
    render_color[1] = G;
    render_color[2] = B;

    set_entvar(id, var_renderfx, render_fx);
    set_entvar(id, var_rendercolor, render_color);
    set_entvar(id, var_rendermode, render_mode);
    set_entvar(id, var_renderamt, render_amount);
}

stock precache_model_ex(const model_name[]) {
    if (model_name[0] != EOS && file_exists(model_name, true)) {
        return precache_model(model_name);
    }

    set_fail_state("Model <%s> not found. The plugin has been stopped.", model_name);
    return 0;
}

stock get_amxx_verint() {
    new buffer[16];
    get_amxx_verstring(buffer, charsmax(buffer));

    if (strfind(buffer, "1.10.0") != -1) {
        return 1100;
    } else if (strfind(buffer, "1.9.0") != -1) {
        return 190;
    } else if (strfind(buffer, "1.8.3") != -1) {
        return 183;
    } else if (strfind(buffer, "1.8.2") != -1) {
        return 182;
    }

    return 0;
}
