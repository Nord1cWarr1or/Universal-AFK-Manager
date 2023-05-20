#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <xs>

#define GetCvarDesc(%0) fmt("%L", LANG_SERVER, %0)

enum _:XYZ { Float:X, Float:Y, Float:Z };

enum _:API_FORWARDS {
    AFK_START_CHECK,
    AFK_START_PRE,
    AFK_START_POST,
    AFK_END_PRE,
    AFK_END_POST,
    AFK_TIMER_THINK
};

const TASKID__AFK_CHECK = 1000;
const TASKID__ONGROUND_CHECK = 2000;

// Automatically create a config in "configs/plugins"
#define AUTO_CREATE_CONFIG

// 0.1, 0.2, 0.25, 0.5 or 1.0
const Float:CHECK_FREQUENCY = 0.5;

new Float:g_savedPlayerViewAngle[MAX_PLAYERS + 1][XYZ];
new Float:g_AFKTime[MAX_PLAYERS + 1];
new bool:g_isPlayerAFK[MAX_PLAYERS + 1];

new g_forwardsPointers[API_FORWARDS];
new g_return;

new Float:afk_time;

new g_AMXXVersion;

public stock const PluginName[]         = "Universal AFK Manager";
public stock const PluginVersion[]      = "0.1.0 alpha";
public stock const PluginAuthor[]       = "Nordic Warrior";
public stock const PluginURL[]          = "https://github.com/Nord1cWarr1or/Universal-AFK-Manager";
public stock const PluginDescription[]  = "Sample text";

public plugin_init() {
    if (g_AMXXVersion < 1100) {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }

    // RegisterHookChain(RG_CBasePlayer_Spawn, "RG_OnPlayerSpawn_Post", .post = true);
    // RegisterHookChain(RG_CBasePlayer_Killed, "RG_OnPlayerKilled_Post", .post = true);

    CreateCVars();
    CreateForwards();

    register_dictionary("uafk_manager.txt");

#if defined AUTO_CREATE_CONFIG
    AutoExecConfig();
#endif
}

public plugin_precache() {
    g_AMXXVersion = get_amxx_verint();
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
}

public client_putinserver(id) {
    if (is_user_bot(id) || is_user_hltv(id)) {
        return;
    }

    set_task_ex(CHECK_FREQUENCY, "AFKCheck", id + TASKID__AFK_CHECK, .flags = SetTask_Repeat);
}

public client_disconnected(id) {
    ResetData(id);
}

public AFKCheck(id) {
    id -= TASKID__AFK_CHECK;

    if (!is_user_connected(id)) {
        log_amx("wtf?");
        ResetData(id);
        return;
    }

    if (is_user_alive(id)) {
        AFKCheckAlive(id);
    } else {
        AFKCheckDead(id);
    }
}

AFKCheckAlive(const id) {
    new Float:currentPlayerViewAngle[XYZ];
    get_entvar(id, var_v_angle, currentPlayerViewAngle);

    if (get_gametime() - Float:get_member(id, m_fLastMovement) > CHECK_FREQUENCY
        && !get_entvar(id, var_button)
        && xs_vec_equal(currentPlayerViewAngle, g_savedPlayerViewAngle[id])
    ) {
        g_AFKTime[id] += CHECK_FREQUENCY;

        if (floatfract(g_AFKTime[id]) == 0.0) {
            ExecuteForward(g_forwardsPointers[AFK_TIMER_THINK], g_return, id, g_AFKTime[id]);
        }

        if (g_AFKTime[id] >= afk_time && !g_isPlayerAFK[id]) {
            AFKStart(id);
        }
    } else {
        g_AFKTime[id] = 0.0;

        if (g_isPlayerAFK[id]) {
            AFKEnd(id);
        }
    }

    xs_vec_copy(currentPlayerViewAngle, g_savedPlayerViewAngle[id]);
}

AFKCheckDead(const id) {
    new TeamName:playerTeam = get_member(id, m_iTeam);

    if (playerTeam == TEAM_CT || playerTeam == TEAM_TERRORIST) {
        return;
    }

    if (get_gametime() - Float:get_member(id, m_fLastMovement) > CHECK_FREQUENCY && !get_entvar(id, var_button)) {
        g_AFKTime[id] += CHECK_FREQUENCY;

        if (g_AFKTime[id] >= afk_time && !g_isPlayerAFK[id]) {
            AFKStart(id);
        }
    } else {
        g_AFKTime[id] = 0.0;

        if (g_isPlayerAFK[id]) {
            AFKEnd(id);
        }
    }
}

AFKStart(const id) {
    ExecuteForward(g_forwardsPointers[AFK_START_PRE], g_return, id);

    if(g_return == PLUGIN_HANDLED) {
        return;
    }

    g_isPlayerAFK[id] = true;

    ExecuteForward(g_forwardsPointers[AFK_START_POST], g_return, id);
}

AFKEnd(const id) {
    ExecuteForward(g_forwardsPointers[AFK_END_PRE], g_return, id);

    if(g_return == PLUGIN_HANDLED) {
        return;
    }

    g_isPlayerAFK[id] = false;
    g_AFKTime[id] = 0.0;

    ExecuteForward(g_forwardsPointers[AFK_END_POST], g_return, id);
}

ResetData(const id) {
    remove_task(id + TASKID__AFK_CHECK);

    g_isPlayerAFK[id] = false;
    g_AFKTime[id] = 0.0;
}


CreateForwards() {
    // g_forwardsPointers[AFK_START_CHECK] = CreateMultiForward("player_start_afk_check", ET_IGNORE, FP_CELL);
    g_forwardsPointers[AFK_START_PRE] = CreateMultiForward("player_start_afk_pre", ET_STOP, FP_CELL);
    g_forwardsPointers[AFK_START_POST] = CreateMultiForward("player_start_afk_post", ET_IGNORE, FP_CELL);
    g_forwardsPointers[AFK_END_PRE] = CreateMultiForward("player_end_afk_pre", ET_STOP, FP_CELL);
    g_forwardsPointers[AFK_END_POST] = CreateMultiForward("player_end_afk_post", ET_IGNORE, FP_CELL);
    g_forwardsPointers[AFK_TIMER_THINK] = CreateMultiForward("player_afk_think", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives() {
    register_native("afk_get_status", "native_afk_get_status");
    register_native("afk_set_status", "native_afk_set_status");
    register_native("afk_get_timer", "native_afk_get_timer");
    register_native("afk_set_timer", "native_afk_set_timer");
    // register_native("afk_rewrite_origin_and_angles", "native_afk_rewrite_origin_and_angles");
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

    if (status) {
        AFKStart(id);
    } else {
        AFKEnd(id);
    }
}

public Float:native_afk_get_timer(plugin, params) {
    enum { arg_player = 1 };

    new id = get_param(arg_player);

    return g_AFKTime[id];
}

public native_afk_set_timer(plugin, params) {
    enum { arg_player = 1, arg_new_time };

    new id = get_param(arg_player);
    new Float:time = get_param_f(arg_new_time);

    g_AFKTime[id] = time;
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
