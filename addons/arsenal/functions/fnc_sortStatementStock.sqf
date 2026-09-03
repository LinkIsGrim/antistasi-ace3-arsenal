#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Statement for the "Sort by stock" sort (registered via ace_arsenal_fnc_addSort
 * in XEH_postInit.sqf) - sorts items by pool stock rather than anything ACE
 * natively tracks.
 *
 * Uses a plain positive value (not a negated one) for the same reason as
 * before - ACE's sort is fundamentally TEXT-based (confirmed from
 * fnc_sortPanel.sqf: lbSortBy ["TEXT", ...]), and negative numbers don't
 * compare correctly as fixed-width text. But inverted (low value = high
 * stock) from the first pass, which put least-available first under
 * "Descending" - empirically backwards from what "Descending" should mean
 * for a stock sort (confirmed in testing, root cause in the ACE/engine
 * sort-direction plumbing not otherwise identified). Unlimited stock maps
 * to 0, the lowest possible value, so it still reads as "most available"
 * under the same direction as any large finite stock count.
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
if (_stock == -1) exitWith {0};

1000000000 - (0 max _stock)
