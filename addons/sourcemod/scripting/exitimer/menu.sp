/**
 * =============================================================================
 * [ExiTimer] Core
 * Timer for source engine games.
 *
 * File: exitimer/menu.sp
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

#define MENUADMIN	0
#define MENUCLIENT	1
#define MENUCOUNT	2

ArrayList ExiMenu[MENUCOUNT];

Handle	ExiForward_OnAdminMenuReady,
		ExiForward_OnClientMenuReady;

void ExiMenu_AskPluginLoad2()
{
	CreateNative("ExiTimer_ReDisplayAdminMenu",	Native_ReDisplayAdminMenu);
	CreateNative("ExiTimer_ReDisplayClientMenu",Native_ReDisplayClientMenu);
	CreateNative("ExiTimer_AddToAdminMenu",		Native_AddToAdminMenu);
	CreateNative("ExiTimer_AddToClientMenu",	Native_AddToClientMenu);
	CreateNative("ExiTimer_UnRegisterMe",		Native_UnRegisterMe);
	CreateNative("ExiTimer_AddedToAdminMenu",	Native_AddedToAdminMenu);
	CreateNative("ExiTimer_AddedToClientMenu",	Native_AddedToClientMenu);
}

void ExiMenu_OnPluginStart()
{
	ExiMenu[MENUADMIN] = ExiMenu[MENUCLIENT] = new ArrayList();

	ExiForward_OnAdminMenuReady		= CreateGlobalForward("ExiTimer_OnAdminMenuReady",	ET_Ignore);
	ExiForward_OnClientMenuReady	= CreateGlobalForward("ExiTimer_OnClientMenuReady",	ET_Ignore);
}

void ExiMenu_OnPluginEnd()
{
	delete ExiMenu[MENUADMIN];
	delete ExiMenu[MENUCLIENT];

	delete ExiForward_OnAdminMenuReady;
	delete ExiForward_OnClientMenuReady;
}

public void OnAllPluginsLoaded()
{
	Call_StartForward(ExiForward_OnAdminMenuReady);
	Call_Finish();

	Call_StartForward(ExiForward_OnClientMenuReady);
	Call_Finish();
}

bool ExiMenu_AddMenuItem(int type, Handle plugin, Function callback, Function display_callback, const char[] name)
{
	DataPack dp = new DataPack();

	dp.WriteCell(plugin);
	dp.WriteFunction(callback);
	dp.WriteFunction(display_callback);
	dp.WriteString(name);

	return view_as<bool>(ExiMenu[type].Push(dp));
}

int ExiMenu_FindCopy(ArrayList array, Handle plugin, char[] str)
{
	DataPack dp;
	Handle plugin_Handle;
	char buffer[64];

	for (int i; i < array.Length; ++i)
	{
		(dp = array.Get(i)).Reset();
		plugin_Handle = dp.ReadCell();
		dp.Position = view_as<DataPackPos>(4);
		dp.ReadString(buffer, 64);

		if (plugin == plugin_Handle && strcmp(str, buffer) == 0)
		{
			return i;
		}
	}

	return -1;
}

void ExiMenu_ReDisplayMenu(int menuid, int client)
{
	if (ExiMenu[menuid].Length == 0)
	{
		ReplyToCommand(client, "%s %t", ExiVar_ChatPrefix, "Empty Menu");
		return;
	}

	Menu menu = new Menu(ExiMenu_Handle);
	menu.SetTitle("%T", !menuid ? "Timer Management" : "Timer Settings", client);

	char buffer[128], id[16];
	FormatEx(buffer, 128, "%T", ExiVar_Enabled ? "Disable" : "Enable", client);
	menu.AddItem("a", buffer);

	DataPack dp;
	Handle plugin;
	Function callback, display_callback;

	for (int i = 0; i < ExiMenu[menuid].Length; i++)
	{
		(dp = ExiMenu[menuid].Get(i)).Reset();
		plugin = dp.ReadCell();
		callback = dp.ReadFunction();
		display_callback = dp.ReadFunction();

		if (plugin == null || callback == INVALID_FUNCTION || display_callback == INVALID_FUNCTION)
		{
			continue;
		}

		dp.ReadString(buffer, 64);

		ExiMenu_GetDisplayItem(plugin, display_callback, client, buffer, buffer, 64);
		FormatEx(id, 16, "%s%d", !menuid ? "a" : "c", i);

		menu.AddItem(id, buffer);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ExiMenu_Handle(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char buffer[64];
			menu.GetItem(param2, buffer, 64);
			int menuid = (buffer[0] != 'a');

			if (!menuid && !param2)
			{
				ExiFunctions_TimerState((ExiVar_Enabled = !ExiVar_Enabled));
				ExiMenu_ReDisplayMenu(menuid, param1);
				return;
			}

			DataPack dp = ExiMenu[menuid].Get(StringToInt(buffer));
			dp.Reset();

			Handle plugin = dp.ReadCell();
			Function callback = dp.ReadFunction();

			if (plugin == null || callback == INVALID_FUNCTION)
			{
				return;
			}

			dp.ReadFunction();
			dp.ReadString(buffer, 64);

			Call_StartFunction(plugin, callback);
			Call_PushCell(param1);
			Call_PushString(buffer);
			Call_Finish();
		}
	}
}

bool ExiMenu_GetDisplayItem(Handle plugin, Function display_callback, int client, const char[] name, char[] buffer, int maxlen)
{
	bool result = false;
	buffer[0] = '\0';

	if (plugin != null && display_callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, display_callback);
		Call_PushCell(client);
		Call_PushString(name);
		Call_PushStringEx(buffer, maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(maxlen);
		Call_Finish(result);
	}

	if (!buffer[0])
	{
		strcopy(buffer, maxlen, name);
	}

	return result;
}

// NATIVES
public int Native_ReDisplayAdminMenu(Handle plugin, int numParams)
{
	ExiMenu_ReDisplayMenu(MENUADMIN, GetNativeCell(1));
}

public int Native_ReDisplayClientMenu(Handle plugin, int numParams)
{
	ExiMenu_ReDisplayMenu(MENUCLIENT, GetNativeCell(1));
}

public int Native_AddToAdminMenu(Handle plugin, int numParams)
{
	char name[64];
	GetNativeString(1, name, 64);
	if (!name[0])
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Empty name");
		return -1;
	}
	else if (ExiMenu_FindCopy(ExiMenu[MENUADMIN], plugin, name) != -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Name \"%s\" is already registered", name);
		return -1;
	}

	return ExiMenu_AddMenuItem(MENUADMIN, plugin, GetNativeCell(2), GetNativeCell(3), name);
}

public int Native_AddToClientMenu(Handle plugin, int numParams)
{
	char name[64];
	GetNativeString(1, name, 64);
	if (!name[0])
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Empty name");
		return -1;
	}
	else if (ExiMenu_FindCopy(ExiMenu[MENUCLIENT], plugin, name) != -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Name \"%s\" is already registered", name);
		return -1;
	}

	return ExiMenu_AddMenuItem(MENUADMIN, plugin, GetNativeCell(2), GetNativeCell(3), name);
}

public int Native_UnRegisterMe(Handle plugin, int numParams)
{
	DataPack dp;
	for (int q; q < MENUCOUNT; q++)
	{
		for (int i; i < ExiMenu[q].Length; i++)
		{
			(dp = ExiMenu[q].Get(i));
			if (dp.ReadCell() == plugin)
			{
				ExiMenu[q].Erase(i--);
			}
		}
	}
}

public int Native_AddedToAdminMenu(Handle plugin, int numParams)
{
	char buffer[64];
	GetNativeString(1, buffer, 64);
	return ExiMenu_FindCopy(ExiMenu[MENUADMIN], plugin, buffer) != -1;
}

public int Native_AddedToClientMenu(Handle plugin, int numParams)
{
	char buffer[64];
	GetNativeString(1, buffer, 64);
	return ExiMenu_FindCopy(ExiMenu[MENUCLIENT], plugin, buffer) != -1;
}