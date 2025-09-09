#include <amxmodx>
#include <amxmisc>
#include <reapi>

enum any: API_FORWARDS {
    AFK_TIMER_THINK
};

// 0.1, 0.2, 0.25, 0.5 or 1.0
const Float: CHECK_FREQUENCY = 0.5;

new Float: player_afk_timer[MAX_PLAYERS + 1];

new forward_pointers[API_FORWARDS];
new return_value;

public stock const PluginName[]         = "Universal AFK Manager";
public stock const PluginVersion[]      = "0.1.0 alpha";
public stock const PluginAuthor[]       = "Nordic Warrior";
public stock const PluginURL[]          = "https://github.com/Nord1cWarr1or/Universal-AFK-Manager";
public stock const PluginDescription[]  = "Sample text";

public plugin_init() {
    if (get_amxx_verint() < 1100) {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }

    create_forwards();
}

public client_putinserver(id) {
    if (is_user_bot(id) || is_user_hltv(id)) {
        return;
    }

    set_task_ex(CHECK_FREQUENCY, "afk_check", id, .flags = SetTask_Repeat);
}

public client_disconnected(id) {
    reset_data(id);
}

public afk_check(id) {
    if (!is_user_connected(id)) {
        reset_data(id);
        return;
    }

    new TeamName: player_team = get_member(id, m_iTeam);
    new bool: is_spectator = bool: (!is_user_alive(id) && (player_team == TEAM_UNASSIGNED || player_team == TEAM_SPECTATOR));

    if (get_gametime() - Float: get_member(id, m_fLastMovement) > CHECK_FREQUENCY) {
        player_afk_timer[id] += CHECK_FREQUENCY;

        if (floatfract(player_afk_timer[id]) == 0.0) {
            ExecuteForward(forward_pointers[AFK_TIMER_THINK], return_value, id, player_afk_timer[id], is_spectator);
        }
    } else {
        player_afk_timer[id] = 0.0;
        ExecuteForward(forward_pointers[AFK_TIMER_THINK], return_value, id, player_afk_timer[id], is_spectator);
    }
}

reset_data(const id) {
    remove_task(id);
    player_afk_timer[id] = 0.0;
}

create_forwards() {
    forward_pointers[AFK_TIMER_THINK] = CreateMultiForward("player_afk_think", ET_IGNORE, FP_CELL, FP_FLOAT, FP_CELL);
}

public plugin_natives() {
    register_native("afk_get_timer", "native_afk_get_timer");
    register_native("afk_set_timer", "native_afk_set_timer");
}

public Float: native_afk_get_timer(plugin, params) {
    enum { arg_player = 1 };

    new id = get_param(arg_player);

    return player_afk_timer[id];
}

public native_afk_set_timer(plugin, params) {
    enum { arg_player = 1, arg_new_time };

    new id = get_param(arg_player);
    new Float:time = get_param_f(arg_new_time);

    player_afk_timer[id] = time;
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
