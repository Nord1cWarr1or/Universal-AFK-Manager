#if defined _universal_afk_manager_included
	#endinput
#endif
#define _universal_afk_manager_included

/**
 * Called when a check of afk for a single player has begun
 *
 * @param id        Player index
 *
 * @noreturn
 */
forward player_start_afk_check(const id);

/**
 * Called when a player becomes AFK (Pre)
 *
 * @param id        Player index
 *
 * @return			Return PLUGIN_HANDLED to prevent
 *					a player from becoming AFK
 */
forward player_start_afk_pre(const id);

/**
 * Called when a player becomes AFK (Post)
 *
 * @param id        Player index
 *
 * @noreturn
 */
forward player_start_afk_post(const id);

/**
 * Called when a player returns from AFK (Pre)
 *
 * @param id        Player index
 *
 * @return			Return PLUGIN_HANDLED to prevent
 *					a player from leaving AFK
 */
forward player_end_afk_pre(const id);

/**
 * Called when a player returns from AFK (Post)
 *
 * @param id        Player index
 *
 * @noreturn
 */
forward player_end_afk_post(const id);

/**
 * Called every second when player is AFK
 *
 * @note Starts to be called from the first second when
 *       a player is AFK, independent of "afk_time" CVar
 *
 * @param id        Player index
 * @param time    Current AFK time
 *
 * @noreturn
 */
forward player_afk_think(const id, Float:time);

/**
 * Gets the AFK status of a player
 *
 * @param id        Player index
 *
 * @return          True if player is AFK, false otherwise
 */
native bool:afk_get_status(const id);

/**
 * Sets the AFK status of a player
 *
 * @param id        Player index
 * @param status   True to set a player in AFK
 *                  false to return a player from AFK
 *
 * @noreturn
 */
native afk_set_status(const id, bool:status);

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
