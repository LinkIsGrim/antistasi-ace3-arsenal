#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Statement for the "Sort by stock" sort (registered via ace_arsenal_fnc_addSort
 * in XEH_postInit.sqf) - sorts items by pool stock rather than anything ACE
 * natively tracks. Returns a negated value so the default (ascending) sort
 * shows the most available first, matching what a player expects from
 * "sort by stock" - reversed from the first pass, which sorted least-available
 * first by default.
 *
 * Unlimited stock (-1) sorts as the most negative, so it reads as "most
 * available" ahead of any finite count under the same ascending sort.
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
if (_stock == -1) exitWith {-999999};

-_stock
