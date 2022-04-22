#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <xs>

#define GetCvarDesc(%0) fmt("%L", LANG_SERVER, %0)

enum _:XYZ { Float:X, Float:Y, Float:Z };

enum _:API_FORWARDS
{
    AFK_START_CHECK,
    AFK_START_PRE,
    AFK_START_POST,
    AFK_END_PRE,
    AFK_END_POST,
    AFK_TIMER_THINK
};

const TASKID__AFK_CHECK = 19452;
const TASKID__ONGROUND_CHECK = 19453;

#define AUTO_CREATE_CONFIG

// 0.1, 0.2, 0.25, 0.5 or 1.0
const Float:CHECK_FREQUENCY = 0.25;

new Float:g_flSavedPlayerOrigin[MAX_PLAYERS + 1][XYZ];
new Float:g_flSavedPlayerAngles[MAX_PLAYERS + 1][XYZ];
new Float:g_flAFKTime[MAX_PLAYERS + 1];
new bool:g_bIsPlayerAFK[MAX_PLAYERS + 1];

new g_iForwardsPointers[API_FORWARDS];
new g_iReturn;

new Float:afk_time;

public stock const PluginName[]         = "Universal AFK Manager";
public stock const PluginVersion[]      = "0.1.0 alpha";
public stock const PluginAuthor[]       = "Nordic Warrior";
public stock const PluginURL[]          = "https://github.com/Nord1cWarr1or/Universal-AFK-Manager";
public stock const PluginDescription[]  = "Sample text";

public plugin_init()
{
    if(get_amxx_verint() < 1100)
    {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }

    RegisterHookChain(RG_CBasePlayer_Spawn,     "RG_OnPlayerSpawn_Post",    .post = true);
    RegisterHookChain(RG_CBasePlayer_Killed,    "RG_OnPlayerKilled_Post",   .post = true);

    CreateCVars();
    CreateForwards();

    register_dictionary("uafk_manager.txt");

#if defined AUTO_CREATE_CONFIG
    AutoExecConfig();
#endif
}

public RG_OnPlayerSpawn_Post(const id)
{
    if(!is_user_alive(id))
        return;

    set_task_ex(0.1, "OnGroundCheck", TASKID__ONGROUND_CHECK + id, .flags = SetTask_Repeat);
}

public OnGroundCheck(id)
{
    id -= TASKID__ONGROUND_CHECK;

    if(!is_user_alive(id))
    {
        remove_task(id + TASKID__ONGROUND_CHECK);
        return;
    }

    if(get_entvar(id, var_flags) & FL_ONGROUND)
    {
        remove_task(id + TASKID__ONGROUND_CHECK);
        set_task_ex(CHECK_FREQUENCY, "AFKCheck", id + TASKID__AFK_CHECK, .flags = SetTask_Repeat);

        ExecuteForward(g_iForwardsPointers[AFK_START_CHECK], g_iReturn, id);
    }
}

public AFKCheck(id)
{
    id -= TASKID__AFK_CHECK;

    // TODO: Check for spectator afk
    if(!is_user_alive(id))
        return;

    static Float:flCurrentPlayerOrigin[XYZ], Float:flCurrentPlayerAngles[XYZ];

    get_entvar(id, var_origin, flCurrentPlayerOrigin);
    get_entvar(id, var_angles, flCurrentPlayerAngles);

    if(xs_vec_equal(flCurrentPlayerOrigin, g_flSavedPlayerOrigin[id])
        && xs_vec_equal(flCurrentPlayerAngles, g_flSavedPlayerAngles[id])
        && !get_entvar(id, var_button)
    )
    {
        g_flAFKTime[id] += CHECK_FREQUENCY;

        if(!floatfract(g_flAFKTime[id]))
        {
            ExecuteForward(g_iForwardsPointers[AFK_TIMER_THINK], g_iReturn, id, g_flAFKTime[id]);
        }

        if(g_flAFKTime[id] >= afk_time)
        {
            if(!g_bIsPlayerAFK[id])
            {
                AFKStart(id);
            }
        }
    }
    else
    {
        if(g_bIsPlayerAFK[id])
        {
            AFKEnd(id);
        }

        g_flAFKTime[id] = 0.0;
    }

    // TODO: Rework this.
    xs_vec_copy(flCurrentPlayerOrigin, g_flSavedPlayerOrigin[id]);
    xs_vec_copy(flCurrentPlayerAngles, g_flSavedPlayerAngles[id]);
}

AFKStart(const id)
{
    ExecuteForward(g_iForwardsPointers[AFK_START_PRE], g_iReturn, id);

    if(g_iReturn == PLUGIN_HANDLED)
        return PLUGIN_HANDLED;

    g_bIsPlayerAFK[id] = true;
    g_flAFKTime[id] = 0.0;

    ExecuteForward(g_iForwardsPointers[AFK_START_POST], g_iReturn, id);
    return PLUGIN_CONTINUE;
}

AFKEnd(const id)
{
    ExecuteForward(g_iForwardsPointers[AFK_END_PRE], g_iReturn, id);

    if(g_iReturn == PLUGIN_HANDLED)
        return PLUGIN_HANDLED;

    g_bIsPlayerAFK[id] = false;
    g_flAFKTime[id] = 0.0;

    ExecuteForward(g_iForwardsPointers[AFK_END_POST], g_iReturn, id);
    return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
    ResetData(id);
}

public RG_OnPlayerKilled_Post(const id, pevAttacker, iGib)
{
    ResetData(id);
}

ResetData(const id)
{
    remove_task(id + TASKID__AFK_CHECK);
    remove_task(id + TASKID__ONGROUND_CHECK);

    for(new i; i < XYZ; i++)
    {
        g_flSavedPlayerOrigin[id][i] = 0.0;
        g_flSavedPlayerAngles[id][i] = 0.0;
    }

    g_bIsPlayerAFK[id] = false;
    g_flAFKTime[id] = 0.0;
}

CreateForwards()
{
    g_iForwardsPointers[AFK_START_CHECK] = CreateMultiForward("player_start_afk_check", ET_IGNORE, FP_CELL);
    g_iForwardsPointers[AFK_START_PRE] = CreateMultiForward("player_start_afk_pre", ET_STOP, FP_CELL);
    g_iForwardsPointers[AFK_START_POST] = CreateMultiForward("player_start_afk_post", ET_IGNORE, FP_CELL);
    g_iForwardsPointers[AFK_END_PRE] = CreateMultiForward("player_end_afk_pre", ET_STOP, FP_CELL);
    g_iForwardsPointers[AFK_END_POST] = CreateMultiForward("player_end_afk_post", ET_IGNORE, FP_CELL);
    g_iForwardsPointers[AFK_TIMER_THINK] = CreateMultiForward("player_afk_think", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives()
{
    register_native("afk_get_status", "native_afk_get_status");
    register_native("afk_set_status", "native_afk_set_status");
    register_native("afk_get_timer", "native_afk_get_timer");
    register_native("afk_set_timer", "native_afk_set_timer");
}

public native_afk_get_status(iPlugin, iParams)
{
    enum { player = 1 };

    new id = get_param(player);

    return g_bIsPlayerAFK[id];
}

public native_afk_set_status(iPlugin, iParams)
{
    enum { player = 1, status };

    new id = get_param(player);
    new iStatus = get_param(status);

    if(iStatus)
    {
        AFKStart(id);
    }
    else
    {
        AFKEnd(id);
    }
}

public native_afk_get_timer(iPlugin, iParams)
{
    enum { player = 1 };

    new id = get_param(player);

    // warn 213
    return g_flAFKTime[id];
}

public native_afk_set_timer(iPlugin, iParams)
{
    enum { player = 1, newTime };

    new id = get_param(player);
    new Float:flNewTime = get_param_f(newTime);

    g_flAFKTime[id] = flNewTime;
}

CreateCVars()
{
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

stock get_amxx_verint()
{
    new buffer[16];
    get_amxx_verstring(buffer, charsmax(buffer));

    if(strfind(buffer, "1.10.0") != -1)
    {
        return 1100;
    }
    else if(strfind(buffer, "1.9.0") != -1)
    {
        return 190;
    }
    else if(strfind(buffer, "1.8.3") != -1)
    {
        return 183;
    }
    else if(strfind(buffer, "1.8.2") != -1)
    {
        return 182;
    }

    return 0;
}
