/**
 * =============================================================================
 * [ExiTimer] Core
 * Timer for source engine games.
 *
 * File: exitimer/logging.sp
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

void ExiLog_AskPluginLoad2()
{
	CreateNative("ExiTimer_Log",		NativeLog_Log);
	CreateNative("ExiTimer_LogError",	NativeLog_LogError);
}

void ExiLog_Write(bool error = false, const char[] format, any ...)
{
	char buffer[512],
		ExiVar_LogPath[PLATFORM_MAX_PATH];

	FormatTime(buffer, 512, "%d.%m.%Y.log");
	BuildPath(Path_SM, ExiVar_LogPath, PLATFORM_MAX_PATH, DIR ... "logs/%s_%s", error ? "error" : "log", buffer);

	VFormat(buffer, 512, format, 3);
	LogToFile(ExiVar_LogPath, buffer);
}

// NATIVES
public int NativeLog_Log(Handle plugin, int numParams)
{
	char buffer[512];
	FormatNativeString(0, 1, 2, 512, _, buffer);
	ExiLog_Write(_, buffer);
}

public int NativeLog_LogError(Handle plugin, int numParams)
{
	char buffer[512];
	FormatNativeString(0, 1, 2, 512, _, buffer);
	ExiLog_Write(true, buffer);
}