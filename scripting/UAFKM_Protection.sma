#include <amxmodx>
#include <reapi>

#include <uafkm_handler>

public stock const PluginName[]         = "UAFKM: Protection";
public stock const PluginVersion[]      = "0.1.0";
public stock const PluginAuthor[]       = "Nordic Warrior";
public stock const PluginURL[]          = "https://github.com/Nord1cWarr1or/Universal-AFK-Manager";
public stock const PluginDescription[]  = "Sample text";

public plugin_init() {
    if (get_amxx_verint() < 1100) {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }
}

public player_start_afk_pre(const id)
{
    if (get_entvar(id, var_waterlevel) == 2) {
        return PLUGIN_HANDLED;
    }

    if (get_entvar(id, var_takedamage) == DAMAGE_NO) {
        return PLUGIN_HANDLED;
    }

    set_entvar(id, var_takedamage, DAMAGE_NO);
    set_entvar(id, var_solid, SOLID_NOT);
    set_member(id, m_bIsDefusing, true);

    return PLUGIN_CONTINUE;
}

public player_end_afk_post(const id) {
    set_entvar(id, var_takedamage, DAMAGE_AIM);
    set_entvar(id, var_solid, SOLID_SLIDEBOX);
    set_member(id, m_bIsDefusing, false);
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
