#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Detects whether the loaded Antistasi variant is TEH-Antistasi-Ultimate,
 * i.e. whether the bullet-pile system (JNA tab 27) is present. CE and
 * Ultimate don't define this function at all.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * TEH's bullet-pile system is loaded <BOOL>
 *
 * Example:
 * [] call FUNC(isTEH)
 */

!isNil "JN_fnc_arsenal_tehBulletPileMigration"
