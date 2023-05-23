#if defined _uafkm_core_included
	#endinput
#endif
#define _uafkm_core_included

// /**
//  * Called when a check of afk for a single player has begun
//  *
//  * @param id        Player index
//  *
//  * @noreturn
//  */
// forward player_start_afk_check(const id);

/**
 * Called every second when player is AFK
 *
 * @note Starts to be called from the first second when
 *       a player is AFK
 *
 * @param id            Player index
 * @param time          Current AFK time
 * @param spectator     The player is spectator
 *
 * @noreturn
 */
forward player_afk_think(const id, Float:time, bool:spectator);

/**
 * Gets the AFK timer of a player
 *
 * @param id        Player index
 *
 * @return          AFK time in seconds
 */
native Float:afk_get_timer(const id);

/**
 * Sets the AFK timer of a player
 *
 * @param id        Player index
 * @param time    New timer value
 *
 * @noreturn
 */
native afk_set_timer(const id, Float:time);
