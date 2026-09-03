#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Replacement for ACE's native "Sort alphabetically" (registered via
 * ace_arsenal_fnc_addSort in XEH_postInit.sqf, after removing the native
 * one via ace_arsenal_fnc_removeSort). ACE's own alphabetical sort has no
 * statement at all (ACE_Arsenal_Sorts.hpp: statement = QUOTE({})) - it's a
 * sentinel meaning "just sort the control's own rendered row text", which
 * breaks once fnc_decorate.sqf prefixes that text with a stock label.
 * Reading the config's real displayName directly sidesteps that entirely.
 *
 * Arguments:
 * 0: Item config <CONFIG>
 *
 * Return Value:
 * Display name <STRING>
 */

params [["_itemCfg", configNull, [configNull]]];

getText (_itemCfg >> "displayName")
