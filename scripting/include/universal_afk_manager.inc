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
 * @param flTime    Current AFK time
 *
 * @noreturn
 */
forward player_afk_think(const id, Float:flTime);

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
 * @param bStatus   True to set a player in AFK
 *                  false to return a player from AFK
 *
 * @noreturn
 */
native afk_set_status(const id, bool:bStatus);

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
 * @param flTime    New timer value
 *
 * @noreturn
 */
native afk_set_timer(const id, Float:flTime);

/**
 * Updates players`s origin & angle 
 *
 * @param id        Player index
 *
 * @noreturn
 */
native afk_rewrite_origin_and_angles(const id);


/**
 * Gets AMXX version from core
 *
 * @return			AMXX version,
 *					where:
 *					182 - AMXMODX 1.8.2
 *					183 - AMXMODX 1.8.3
 *					190 - AMXMODX 1.9.0
 *					1100 - AMXMODX 1.10.0
 */
native uafkm_get_amxx_version()
