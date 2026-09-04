#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: resolves GVAR(reconcilePromise) (see fnc_flushReconcile.sqf)
 * with the server's verdict. Registered against QGVAR(reconcileResult) in
 * XEH_postInit.sqf. All the actual "ok"/"revert"/"strip" handling lives in
 * fnc_reconcileResult.sqf, run as the promise's continuation - this just
 * hands it the result.
 *
 * Guarded against a null (already-completed) handle rather than assuming a
 * second terminate call is a safe no-op - undocumented as far as this addon
 * has found, and not something that's been possible to verify at runtime
 * (2.22 promise handles are very recent).
 *
 * Arguments:
 * 0: "ok", "revert" or "strip" <STRING>
 * 1: Refusal message ("revert") or magazine classnames to strip ("strip") <STRING or ARRAY>
 *
 * Return Value:
 * None
 */

// isNil first, not a typed default on getVariable - unsure a dedicated "null
// script handle" literal (the way objNull/grpNull/configNull etc. work) even
// exists to default to safely, and isNil sidesteps needing one: it only cares
// whether the variable was ever set, not what type its value is.
if (isNil QGVAR(reconcilePromise)) exitWith {};
if (isNull GVAR(reconcilePromise)) exitWith {};

GVAR(reconcilePromise) terminate _this;
