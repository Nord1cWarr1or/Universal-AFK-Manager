#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <xs>

enum _:XYZ { Float:X, Float:Y, Float:Z };

enum _:API_FORWARDS {
    // AFK_START_CHECK,
    AFK_TIMER_THINK
};

const TASKID__AFK_CHECK = 1000;
const TASKID__ONGROUND_CHECK = 2000;

// 0.1, 0.2, 0.25, 0.5 or 1.0
const Float:CHECK_FREQUENCY = 0.5;

new Float:g_savedPlayerViewAngle[MAX_PLAYERS + 1][XYZ];
new Float:g_AFKTime[MAX_PLAYERS + 1];

new g_forwardsPointers[API_FORWARDS];
new g_return;

public stock const PluginName[]         = "Universal AFK Manager";
public stock const PluginVersion[]      = "0.1.0 alpha";
public stock const PluginAuthor[]       = "Nordic Warrior";
public stock const PluginURL[]          = "https://github.com/Nord1cWarr1or/Universal-AFK-Manager";
public stock const PluginDescription[]  = "Sample text";

public plugin_init() {
    if (get_amxx_verint() < 1100) {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }

    // RegisterHookChain(RG_CBasePlayer_Spawn, "RG_OnPlayerSpawn_Post", .post = true);
    // RegisterHookChain(RG_CBasePlayer_Killed, "RG_OnPlayerKilled_Post", .post = true);

    CreateForwards();
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
        AFKCheckSpectator(id);
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
            ExecuteForward(g_forwardsPointers[AFK_TIMER_THINK], g_return, id, g_AFKTime[id], false);
        }
    } else {
        g_AFKTime[id] = 0.0;
    }

    xs_vec_copy(currentPlayerViewAngle, g_savedPlayerViewAngle[id]);
}

AFKCheckSpectator(const id) {
    new TeamName:playerTeam = get_member(id, m_iTeam);

    if (playerTeam == TEAM_CT || playerTeam == TEAM_TERRORIST) {
        return;
    }

    if (get_gametime() - Float:get_member(id, m_fLastMovement) > CHECK_FREQUENCY && !get_entvar(id, var_button)) {
        g_AFKTime[id] += CHECK_FREQUENCY;

        if (floatfract(g_AFKTime[id]) == 0.0) {
            ExecuteForward(g_forwardsPointers[AFK_TIMER_THINK], g_return, id, g_AFKTime[id], true);
        }
    } else {
        g_AFKTime[id] = 0.0;
    }
}

ResetData(const id) {
    remove_task(id + TASKID__AFK_CHECK);
    g_AFKTime[id] = 0.0;
}


CreateForwards() {
    // g_forwardsPointers[AFK_START_CHECK] = CreateMultiForward("player_start_afk_check", ET_IGNORE, FP_CELL);
    g_forwardsPointers[AFK_TIMER_THINK] = CreateMultiForward("player_afk_think", ET_IGNORE, FP_CELL, FP_FLOAT, FP_CELL);
}

public plugin_natives() {
    register_native("afk_get_timer", "native_afk_get_timer");
    register_native("afk_set_timer", "native_afk_set_timer");
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
