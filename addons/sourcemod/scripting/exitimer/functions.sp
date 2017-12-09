/**
 * =============================================================================
 * [ExiTimer] Core
 * Timer for source engine games.
 *
 * File: exitimer/functions.sp
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

void ExiFunctions_State(bool start = true)
{
	if ((ExiVar_Started = start))
	{
		Call_StartForward(ExiForward_OnStart);
		Call_Finish();

		ExiMap_OnMapStart();
	}
	else
	{
		Call_StartForward(ExiForward_OnEnd);
		Call_Finish();

		OnMapEnd();
	}
}

void ExiFunctions_MapState(bool start = true)
{
	if ((ExiVar_MapStarted = start))
	{
		Call_StartForward(ExiForward_OnMapStart);
		Call_PushCell(ExiVar_MapId);
		Call_PushString(ExiVar_MapName);
		Call_Finish();
	}
	else
	{
		Call_StartForward(ExiForward_OnMapEnd);
		Call_PushCell(ExiVar_MapId);
		Call_PushString(ExiVar_MapName);
		Call_Finish();

		ExiFunctions_TimerState(false);
	}
}

void ExiFunctions_TimerState(bool start = true)
{
	ExiDB_ChangeState((ExiVar_Enabled = start));

	Call_StartForward(ExiForward_OnChangeState);
	Call_PushCell(ExiVar_Enabled);
	Call_Finish();
}

void ExiFunctions_CreateDir(const char[] path_dir, any ...)
{
	char buffer[PLATFORM_MAX_PATH];
	VFormat(buffer, PLATFORM_MAX_PATH, path_dir, 2);

	BuildPath(Path_SM, buffer, PLATFORM_MAX_PATH, DIR ... "%s", buffer);

	if (!DirExists(buffer))
	{
		CreateDirectory(buffer, 755);
	}
}