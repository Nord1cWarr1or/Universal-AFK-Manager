#if defined _uafkm_handler_included
    #endinput
#endif
#define _uafkm_handler_included
 
/**
 * Called when a player becomes AFK (Pre)
 *
 * @param id            Player index
 * @param spectator     If true, the player is spectator
 *
 * @return          Return PLUGIN_HANDLED to prevent
 *                  a player from becoming AFK
 */
forward player_start_afk_pre(const id, bool:spectator);

/**
 * Called when a player becomes AFK (Post)
 *
 * @param id            Player index
 * @param spectator     If true, the player is spectator
 *
 * @noreturn
 */
forward player_start_afk_post(const id, bool:spectator);

/**
 * Called when a player returns from AFK (Pre)
 *
 * @param id            Player index
 * @param spectator     If true, the player is spectator
 *
 * @return          Return PLUGIN_HANDLED to prevent
 *                  a player from leaving AFK
 */
forward player_end_afk_pre(const id, bool:spectator);

/**
 * Called when a player returns from AFK (Post)
 *
 * @param id            Player index
 * @param spectator     If true, the player is spectator
 *
 * @noreturn
 */
forward player_end_afk_post(const id, bool:spectator);

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
 * @param status	True to set a player in AFK
 *                  false to return a player from AFK
 *
 * @noreturn
 */
native afk_set_status(const id, bool:status);
