#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Statement for the "Antistasi Stock" sort (registered via
 * ace_arsenal_fnc_addSort in XEH_postInit.sqf) - sorts items by pool stock
 * rather than anything ACE natively tracks. Unlimited stock (-1) sorts as
 * a large sentinel so it reads as "most available" under a descending sort,
 * matching how a player would expect "unlimited" to rank.
 *
 * Arguments:
 * 0: Item config <CONFIG>
 * 1: Item classname <STRING>
 * 2: Quantity currently carried <NUMBER> (ACE's own, unused - we sort by
 *    pool stock, not what the player happens to be holding)
 *
 * Return Value:
 * Sort value <NUMBER>
 */

params [["_itemCfg", configNull, [configNull]], ["_class", "", [""]]];

private _stock = (_class call FUNC(poolFind)) select 1;
if (_stock == -1) exitWith {999999};

_stock
