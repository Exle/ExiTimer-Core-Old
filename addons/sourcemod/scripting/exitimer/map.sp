/**
 * =============================================================================
 * [ExiTimer] Core
 * Timer for source engine games.
 *
 * File: exitimer/map.sp
 * Author: Exle / http://steamcommunity.com/profiles/76561198013509278/
 * =============================================================================
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

Handle	ExiForward_OnMapStart,
		ExiForward_OnMapEnd;

bool ExiVar_MapStarted;

int ExiVar_MapId;
char ExiVar_MapName[64];

void ExiMap_AskPluginLoad2()
{
	CreateNative("ExiTimer_MapIsStarted",		NativeMap_MapIsStarted);
	CreateNative("ExiTimer_GetCurrentMapId",	NativeMap_GetCurrentMapId);
	CreateNative("ExiTimer_GetCurrentMapName",	NativeMap_GetCurrentMapName);
}

void ExiMap_OnPluginStart()
{
	ExiForward_OnMapStart	= CreateGlobalForward("ExiTimer_OnMapStart",	ET_Ignore, Param_Cell, Param_String);
	ExiForward_OnMapEnd		= CreateGlobalForward("ExiTimer_OnMapEnd",		ET_Ignore, Param_Cell, Param_String);
}

void ExiMap_OnPluginEnd()
{
	delete ExiForward_OnMapStart;
	delete ExiForward_OnMapEnd;
}

void ExiMap_OnMapStart()
{
	if (ExiVar_Started && !ExiVar_MapStarted)
	{
		ExiMap_GetCurrent(ExiVar_MapName, 64);
		ExiDB_OnMapStart();
	}
}

void ExiMap_OnMapEnd()
{
	if (ExiVar_Started && ExiVar_MapStarted)
	{
		ExiFunctions_MapState(false);
	}

	ExiVar_MapId = 0;
	ExiVar_MapName[0] = '\0';
}

void ExiMap_GetCurrent(char[] buffer, int maxlen)
{
	GetCurrentMap(buffer, maxlen);
	GetMapDisplayName(buffer, buffer, maxlen);
}

// NATIVES
public int NativeMap_MapIsStarted(Handle plugin, int numParams)
{
	return ExiVar_MapStarted;
}

public int NativeMap_GetCurrentMapId(Handle plugin, int numParams)
{
	return ExiVar_MapId;
}

public int NativeMap_GetCurrentMapName(Handle plugin, int numParams)
{
	SetNativeString(1, ExiVar_MapName, GetNativeCell(2));
}