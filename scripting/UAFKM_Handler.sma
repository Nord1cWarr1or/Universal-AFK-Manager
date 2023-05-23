#include <amxmodx>
#include <reapi>

#include <uafkm_core>

#define GetCvarDesc(%0) fmt("%L", LANG_SERVER, %0)

enum _:API_FORWARDS {
    AFK_START_PRE,
    AFK_START_POST,
    AFK_END_PRE,
    AFK_END_POST
};

// Automatically create a config in "configs/plugins"
#define AUTO_CREATE_CONFIG

new bool:g_isPlayerAFK[MAX_PLAYERS + 1];

new g_forwardsPointers[API_FORWARDS];
new g_return;

new Float:afk_time, Float:afk_time_spec;

public stock const PluginName[]         = "UAFKM: Handler";
public stock const PluginVersion[]      = "0.1.0 alpha";
public stock const PluginAuthor[]       = "Nordic Warrior";
public stock const PluginURL[]          = "https://github.com/Nord1cWarr1or/Universal-AFK-Manager";
public stock const PluginDescription[]  = "Sample text";

public plugin_init() {
    if (get_amxx_verint() < 1100) {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }

    CreateCVars();
    CreateForwards();

    register_dictionary("uafk_manager.txt");

#if defined AUTO_CREATE_CONFIG
    AutoExecConfig();
#endif
}

CreateCVars() {
    bind_pcvar_float(
        create_cvar(
            .name = "afk_time", 
            .string = "15.0",
            .description = GetCvarDesc("UAFKM_CVAR_AFK_TIME"),
            .has_min = true,
            .min_val = 1.0
        ),

        afk_time
    );

    bind_pcvar_float(
        create_cvar(
            .name = "afk_time_spec", 
            .string = "15.0",
            .description = GetCvarDesc("UAFKM_CVAR_AFK_TIME_SPEC"),
            .has_min = true,
            .min_val = 1.0
        ),

        afk_time_spec
    );
}

public player_afk_think(const id, Float:time, bool:spectator) {
    new Float:player_afk_time = afk_get_timer(id);

    if (g_isPlayerAFK[id]) {
        if (spectator && player_afk_time < afk_time_spec) {
            AFKEnd(id, spectator);
        } else if (!spectator && player_afk_time < afk_time) {
            AFKEnd(id, spectator);
        }
    } else {
        if (spectator && player_afk_time >= afk_time_spec) {
            AFKStart(id, spectator);
        } else if (!spectator && player_afk_time >= afk_time) {
            AFKStart(id, spectator);
        }
    }
}

AFKStart(const id, bool:spectator) {
    ExecuteForward(g_forwardsPointers[AFK_START_PRE], g_return, id, spectator);

    if(g_return == PLUGIN_HANDLED) {
        return;
    }

    g_isPlayerAFK[id] = true;

    ExecuteForward(g_forwardsPointers[AFK_START_POST], g_return, id, spectator);
}

AFKEnd(const id, bool:spectator) {
    ExecuteForward(g_forwardsPointers[AFK_END_PRE], g_return, id, spectator);

    if(g_return == PLUGIN_HANDLED) {
        return;
    }

    g_isPlayerAFK[id] = false;

    ExecuteForward(g_forwardsPointers[AFK_END_POST], g_return, id, spectator);
}

CreateForwards() {
    g_forwardsPointers[AFK_START_PRE] = CreateMultiForward("player_start_afk_pre", ET_STOP, FP_CELL, FP_CELL);
    g_forwardsPointers[AFK_START_POST] = CreateMultiForward("player_start_afk_post", ET_IGNORE, FP_CELL, FP_CELL);
    g_forwardsPointers[AFK_END_PRE] = CreateMultiForward("player_end_afk_pre", ET_STOP, FP_CELL, FP_CELL);
    g_forwardsPointers[AFK_END_POST] = CreateMultiForward("player_end_afk_post", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives() {
    register_native("afk_get_status", "native_afk_get_status");
    register_native("afk_set_status", "native_afk_set_status");
}

public bool:native_afk_get_status(plugin, params) {
    enum { arg_player = 1 };

    new id = get_param(arg_player);

    return g_isPlayerAFK[id];
}

public native_afk_set_status(plugin, params) {
    enum { arg_player = 1, arg_status };

    new id = get_param(arg_player);
    new bool:status = bool:get_param(arg_status);

    new bool:spectator, TeamName:playerTeam;
    playerTeam = get_member(id, m_iTeam);
    spectator = bool:!is_user_alive(id) && (playerTeam != TEAM_CT && playerTeam != TEAM_TERRORIST)

    if (status) {
        AFKStart(id, spectator);
    } else {
        AFKEnd(id, spectator);
    }
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
