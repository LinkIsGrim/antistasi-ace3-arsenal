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
 * The inverted constant MUST stay small (not the naive 1000000000) - ACE's
 * fnc_sortPanel.sqf feeds numeric statement results through
 * CBA_fnc_formatNumber, which does "(abs _number) toFixed _decimalPlaces",
 * a float32 operation. Float32 only has ~7 significant decimal digits of
 * precision; near 1e9 its representable step is dozens of units, larger
 * than the actual stock deltas (1-20) this is trying to distinguish, so
 * two different stock counts could round to the identical formatted value
 * (or land in engine-arbitrary relative order) - confirmed as the cause of
 * "Sort by stock" looking scrambled for every finite-stock item while
 * unlimited (a clean 0, unaffected by this) still sorted correctly.
 * 100000 keeps the whole range inside float32's precise digits for any
 * realistic stock count.
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

100000 - (0 max _stock)
