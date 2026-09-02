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
