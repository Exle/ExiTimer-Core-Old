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

#if defined exitimer_menu_included
	#endinput
#endif
#define _exitimer_menu_included

typedef DisplayCallBack = function bool(int client, const char[] name, char[] buffer, int maxlength);
typedef ItemCallBack = function void(int client, char[] name);

forward void ExiTimer_OnAdminMenuReady();
forward void ExiTimer_OnClientMenuReady();

native void ExiTimer_ReDisplayAdminMenu(int client);
native void ExiTimer_ReDisplayClientMenu(int client);

native bool ExiTimer_AddToAdminMenu(const char[] name, ItemCallBack callback, DisplayCallBack display_callback);
native bool ExiTimer_AddToClientMenu(const char[] name, ItemCallBack callback, DisplayCallBack display_callback);

native bool ExiTimer_AddedToAdminMenu(const char[] name);
native bool ExiTimer_AddedToClientMenu(const char[] name);

native void ExiTimer_UnRegisterMe();

public SharedPlugin __pl_exitimer_menu = 
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
public __pl_exitimer_menu_SetNTVOptional()
{
	MarkNativeAsOptional("ExiTimer_ReDisplayAdminMenu");
	MarkNativeAsOptional("ExiTimer_ReDisplayClientMenu");
	MarkNativeAsOptional("ExiTimer_AddToAdminMenu");
	MarkNativeAsOptional("ExiTimer_AddToClientMenu");
	MarkNativeAsOptional("ExiTimer_AddedToAdminMenu");
	MarkNativeAsOptional("ExiTimer_AddedToClientMenu");
	MarkNativeAsOptional("ExiTimer_UnRegisterMe");
}
#endif