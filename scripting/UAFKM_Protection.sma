#include <amxmodx>
#include <reapi>

#include <universal_afk_manager>

new Float:g_flSavedAFKTime[MAX_PLAYERS + 1];

public stock const PluginName[]         = "UAFKM: Protection";
public stock const PluginVersion[]      = "0.1.0";
public stock const PluginAuthor[]       = "Nordic Warrior";
public stock const PluginURL[]          = "https://github.com/Nord1cWarr1or/Universal-AFK-Manager";
public stock const PluginDescription[]  = "Sample text";

public plugin_init()
{
    if(get_amxx_verint() < 1100)
    {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }

    RegisterHookChain(RG_CBasePlayer_Spawn, "RG_OnPlayerSpawn_Pre", .post = false);
    RegisterHookChain(RG_CBasePlayer_Killed, "RG_OnPlayerKilled_Pre", .post = false);
}

public player_start_afk_pre(const id)
{
    if(get_entvar(id, var_waterlevel) == 2)
        return PLUGIN_HANDLED;

    if(get_entvar(id, var_takedamage) == DAMAGE_NO)
        return PLUGIN_HANDLED;

    set_entvar(id, var_takedamage, DAMAGE_NO);
    set_entvar(id, var_solid, SOLID_NOT);
    set_member(id, m_bIsDefusing, true);

    return PLUGIN_CONTINUE;
}

public player_end_afk_post(const id)
{
    set_entvar(id, var_takedamage, DAMAGE_AIM);
    set_entvar(id, var_solid, SOLID_SLIDEBOX);
    set_member(id, m_bIsDefusing, false);
}

public player_start_afk_check(const id)
{
    afk_rewrite_origin_and_angles(id);
    afk_set_timer(id, g_flSavedAFKTime[id])
}

public RG_OnPlayerSpawn_Pre(const id)
{
    if(!is_user_alive(id))
        return;

    g_flSavedAFKTime[id] = afk_get_timer(id);
}

public RG_OnPlayerKilled_Pre(const id, pevAttacker, iGib)
{
    g_flSavedAFKTime[id] = afk_get_timer(id);
}

public client_disconnected(id)
{
    g_flSavedAFKTime[id] = 0.0;
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
