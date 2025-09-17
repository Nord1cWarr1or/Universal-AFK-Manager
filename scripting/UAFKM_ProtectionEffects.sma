#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_stocks>
#include <reapi>

#include <msgstocks>
#include <uafkm_handler>

#define GetCvarDesc(%0)     fmt("%L", LANG_SERVER, %0)

#define RANDOM_RGB_COLOR    random_num(0, 255)

enum any: RGB { R, G, B };

enum any: AFKEffectsFlags (<<=1) {
    Effects_Transparency = 1,
    Effects_ScreenFade,
    Effects_Icon
};

/* <-- Icon model settings --> */
new const ICON_MODEL[] = "sprites/afk/afk_2.spr";
const Float: ICON_SCALE = 0.5;
const Float: ICON_RENDER_AMT = 100.0;
const Float: ICON_ANIM_FRAMERATE = 10.0;
const ICON_RENDERMODE = kRenderTransAdd;
/* <-- End --> */

// Automatically create a config in "configs/plugins"
#define AUTO_CREATE_CONFIG

new const ICON_CLASSNAME[] = "afk_icon";

new icon_modelindex;
new afk_icon_ent_id[MAX_PLAYERS + 1] = { NULLENT, ... };
new current_screenfade_color[MAX_PLAYERS + 1][RGB];

new afk_effects,
    afk_screenfade_amount,
    afk_random_screenfade_color,
    Float: afk_random_screenfade_rotation_frequency

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
}

public plugin_precache() {
    icon_modelindex = precache_model_ex(ICON_MODEL);
}

public plugin_cfg() {
    new current_value[16];
    get_cvar_string("afk_effects", current_value, charsmax(current_value));

    afk_effects = read_flags(current_value);
}

public client_disconnected(id) {
    if (!is_nullent(afk_icon_ent_id[id])) {
        remove_icon(id);
    }

    remove_task(id);

    current_screenfade_color[id] = { 0, 0, 0 };
}

public player_start_afk_post(const id, bool: is_spectator) {
    if (!is_spectator) {
        toggle_effects(id, true);
    }
}

public player_end_afk_post(const id, bool: is_spectator) {
    if (!is_spectator) {
        toggle_effects(id, false);
    }
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

toggle_effects(const id, bool: effects_on) {
    if (effects_on) {
        if (afk_effects & Effects_Transparency) {
            rg_set_rendering(id, kRenderFxNone, 0.0, 0.0, 0.0, kRenderTransAlpha, 120.0);
        }

        if (afk_effects & Effects_Icon) {
            if (is_nullent(afk_icon_ent_id[id])) {
                create_icon(id);
            }

            show_icon(id);
        }

        if (afk_effects & Effects_ScreenFade) {
            if (get_viewent(id) != id) {
                return;
            }

            if (afk_random_screenfade_color > 0) {
                current_screenfade_color[id][R] = RANDOM_RGB_COLOR;
                current_screenfade_color[id][G] = RANDOM_RGB_COLOR;
                current_screenfade_color[id][B] = RANDOM_RGB_COLOR;
            } else {
                current_screenfade_color[id] = { 0, 0, 0 };
            }

            fade_user_screen(id, 
                .duration = 0.0,
                .fadetime = 0.0,
                .flags = ScreenFade_StayOut,
                .r = current_screenfade_color[id][R],
                .g = current_screenfade_color[id][G],
                .b = current_screenfade_color[id][B],
                .a = afk_screenfade_amount
            );

            if (afk_random_screenfade_color == 2) {
                set_task_ex(afk_random_screenfade_rotation_frequency, "set_next_screen_fade", id, .flags = SetTask_Repeat);
            }
        }
    } else {
        if (afk_effects & Effects_Transparency) {
            rg_set_rendering(id, kRenderFxNone, 0.0, 0.0, 0.0, kRenderNormal, 0.0);
        }

        if (afk_effects & Effects_Icon) {
            if (is_nullent(afk_icon_ent_id[id])) {
                return;
            }

            hide_icon(id);
        }

        if (afk_effects & Effects_ScreenFade) {
            remove_task(id);

            if (get_viewent(id) != id) {
                return;
            }

            fade_user_screen(id, 
                .duration = 0.0,
                .fadetime = 1.0,
                .flags = ScreenFade_FadeIn,
                .r = current_screenfade_color[id][R],
                .g = current_screenfade_color[id][G],
                .b = current_screenfade_color[id][B],
                .a = afk_screenfade_amount
            );
        }
    }
}

public set_next_screen_fade(id) {
    current_screenfade_color[id][R] = RANDOM_RGB_COLOR;
    current_screenfade_color[id][G] = RANDOM_RGB_COLOR;
    current_screenfade_color[id][B] = RANDOM_RGB_COLOR;

    fade_user_screen(id, 
        .duration = 0.0,
        .fadetime = 0.0,
        .flags = ScreenFade_StayOut,
        .r = current_screenfade_color[id][R],
        .g = current_screenfade_color[id][G],
        .b = current_screenfade_color[id][B],
        .a = afk_screenfade_amount
    );
}

create_icon(const id) {
    new ent = rg_create_entity("env_sprite");

    set_entvar(ent, var_classname, ICON_CLASSNAME);
    set_entvar(ent, var_model, ICON_MODEL);
    set_entvar(ent, var_modelindex, icon_modelindex);
    set_entvar(ent, var_scale, ICON_SCALE);
    set_entvar(ent, var_rendermode, ICON_RENDERMODE);
    set_entvar(ent, var_renderamt, ICON_RENDER_AMT);
    set_entvar(ent, var_framerate, ICON_ANIM_FRAMERATE);
    set_entvar(ent, var_spawnflags, SF_SPRITE_STARTON);
    set_entvar(ent, var_aiment, id);
    set_entvar(ent, var_movetype, MOVETYPE_FOLLOW);

    afk_icon_ent_id[id] = ent;

    DF_Spawn(ent);

    set_entvar(ent, var_effects, EF_NODRAW);
}

remove_icon(const id) {
    set_entvar(afk_icon_ent_id[id], var_flags, FL_KILLME);
    afk_icon_ent_id[id] = NULLENT;
}

show_icon(const id) {
    set_entvar(afk_icon_ent_id[id], var_effects, 0);
}

hide_icon(const id) {
    set_entvar(afk_icon_ent_id[id], var_effects, EF_NODRAW);
}

create_cvars() {
    new cvar_pointer;

    cvar_pointer = create_cvar("afk_effects", "abc", _, GetCvarDesc("UAFKM_CVAR_AFK_EFFECTS"));
    hook_cvar_change(cvar_pointer, "hook_cvar_afk_effects");

    cvar_pointer = create_cvar("afk_screenfade_amount", "110", _, GetCvarDesc("UAFKM_CVAR_AFK_SCREENFADE_AMOUNT"));
    bind_pcvar_num(cvar_pointer, afk_screenfade_amount);

    cvar_pointer = create_cvar("afk_random_screenfade_color", "0", _, GetCvarDesc("UAFKM_CVAR_AFK_RANDOM_SCREENFADE_COLOR"));
    bind_pcvar_num(cvar_pointer, afk_random_screenfade_color);

    cvar_pointer = create_cvar("afk_random_screenfade_rotation_frequency", "1.5", _, GetCvarDesc("UAFKM_CVAR_AFK_RANDOM_SCREENFADE_ROTATION_FREQUENCY"));
    bind_pcvar_float(cvar_pointer, afk_random_screenfade_rotation_frequency);
}

public hook_cvar_afk_effects(pCvar, const old_value[], const new_value[]) {
    afk_effects = read_flags(new_value);
}

stock rg_set_rendering(const id, const render_fx, const Float: red, const Float: green, const Float: blue, const render_mode, const Float: render_amount) {
    new Float: render_color[3];

    render_color[0] = red;
    render_color[1] = green;
    render_color[2] = blue;

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
