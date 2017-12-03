/**
 * =============================================================================
 * Date of update: 03.12.2017
 * Author: Exle / http://steamcommunity.com/profiles/76561198013509278/
 * =============================================================================
 *
 * This file is part of the ExiTimer/SourceMod plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#if defined exitimer_map_included
	#endinput
#endif
#define _exitimer_map_included

forward void ExiTimer_OnMapStart(int id, char[] name);
forward void ExiTimer_OnMapEnd(int id, char[] name);

native bool ExiTimer_MapIsStarted();
native int ExiTimer_GetCurrentMapId();
native void ExiTimer_GetCurrentMapName(char[] buffer, int maxlength);

public SharedPlugin __pl_exitimer_map = 
{
	name = "exitimer",
	file = "exitimer.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_exitimer_map_SetNTVOptional()
{
	MarkNativeAsOptional("ExiTimer_MapIsStarted");
	MarkNativeAsOptional("ExiTimer_GetCurrentMapId");
	MarkNativeAsOptional("ExiTimer_GetCurrentMapName");
}
#endif