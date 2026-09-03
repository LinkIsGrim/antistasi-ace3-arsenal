#define COMPONENT arsenal
#define COMPONENT_BEAUTIFIED Arsenal
#include "\z\skuaa3aa\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ARSENAL
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_ARSENAL
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ARSENAL
#endif

#include "\z\skuaa3aa\addons\main\script_macros.hpp"

// Antistasi's JNA tab indices (IDC_RSCDISPLAYARSENAL_TAB_*), shared across CE/Ultimate/TEH.
// Tab 27 (CARGOBULLET) only exists on TEH - never assume it's present, always feature-detect.
#define JNA_TAB_PRIMARYWEAPON   0
#define JNA_TAB_SECONDARYWEAPON 1
#define JNA_TAB_HANDGUN         2
#define JNA_TAB_UNIFORM         3
#define JNA_TAB_VEST            4
#define JNA_TAB_BACKPACK        5
#define JNA_TAB_HEADGEAR        6
#define JNA_TAB_GOGGLES         7
#define JNA_TAB_NVGS            8
#define JNA_TAB_BINOCULARS      9
#define JNA_TAB_MAP             10
#define JNA_TAB_GPS             11
#define JNA_TAB_RADIO           12
#define JNA_TAB_COMPASS         13
#define JNA_TAB_WATCH           14
#define JNA_TAB_FACE            15
#define JNA_TAB_VOICE           16
#define JNA_TAB_INSIGNIA        17
#define JNA_TAB_ITEMOPTIC       18
#define JNA_TAB_ITEMACC         19
#define JNA_TAB_ITEMMUZZLE      20
#define JNA_TAB_CARGOMAG        21
#define JNA_TAB_CARGOTHROW      22
#define JNA_TAB_CARGOPUT        23
#define JNA_TAB_CARGOMISC       24
#define JNA_TAB_ITEMBIPOD       25
#define JNA_TAB_CARGOMAGALL     26
#define JNA_TAB_CARGOBULLET     27 // TEH only - loose/partial ammo pool, no physical cargo representation, never a transfer target

#define JNA_TAB_COUNT_BASE 27 // CE / Ultimate
#define JNA_TAB_COUNT_TEH  28 // TEH (adds CARGOBULLET)

// Needed by both config.cpp (RSC classes) and any .sqf that touches the
// transfer dialog's controls - two separate preprocessing contexts, both
// need to see these.
#include "dialogues\defines.hpp"

// ACE arsenal's own panel control IDCs (ace3/addons/arsenal/defines.hpp) -
// hardcoded rather than included from ACE directly, since we don't have a
// stub for that specific file. Stable, public-facing UI structure, but a
// soft dependency on ACE not restructuring its panels.
#define ARSENAL_IDD 1127001
#define ARSENAL_IDC_LEFTLIST 13
#define ARSENAL_IDC_RIGHTLIST 14
#define ARSENAL_IDC_RIGHTLISTNB 15
#define ARSENAL_IDC_BTN_REMOVEALLSEL 39
#define ARSENAL_IDC_BTN_REMOVEALL 40

// Saturated/high-contrast on purpose - the first pass used pastel tones that
// blended into ACE's row-selection highlight, making them unreadable exactly
// when a player had an item selected. May still need live tuning.
#define ARSENAL_COLOR_FORBIDDEN [1, 0.15, 0.15, 1]
#define ARSENAL_COLOR_LIMITED [1, 0.65, 0, 1]
#define ARSENAL_COLOR_UNLIMITED [0.25, 1, 0.35, 1]
#define ARSENAL_COLOR_DEFAULT [1, 1, 1, 1]
