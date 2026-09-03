#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Statement for the "Sort by stock" sort (registered via ace_arsenal_fnc_addSort
 * in XEH_postInit.sqf) - sorts items by pool stock rather than anything ACE
 * natively tracks.
 *
 * Uses a plain positive value (unlimited stock as a large sentinel), not a
 * negated one - ACE's sort is fundamentally TEXT-based (confirmed from
 * fnc_sortPanel.sqf: lbSortBy ["TEXT", ...]), and negative numbers don't
 * compare correctly as fixed-width text ("-0015.00" doesn't sort before
 * "-0010.00" the way -15 < -10 numerically would suggest - the first pass
 * used negation for this and produced exactly that bug, [15] landing after
 * [10] under a descending sort). Higher stock = higher value here; the UI's
 * own ascending/descending toggle (unrelated to what we return) decides
 * whether that reads as "most available first" or "least available first".
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
if (_stock == -1) exitWith {999999999};

_stock
