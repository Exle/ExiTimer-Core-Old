/**
 * =============================================================================
 * [ExiTimer] Core
 * Timer for source engine games.
 *
 * File: exitimer/chat.sp
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

#define MAX_BUFFER_LENGTH	1024

Handle ExiForward_OnSendMessage,
	ExiForward_OnSendMessagePost;

void ExiChat_AskPluginLoad2()
{
	CreateNative("ExiTimer_Message",	Native_Message);
	CreateNative("ExiTimer_MessageAll",	Native_MessageAll);
}

void ExiChat_OnPluginStart()
{
	ExiForward_OnSendMessage		= CreateGlobalForward("ExiTimer_OnSendMessage",		ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);
	ExiForward_OnSendMessagePost	= CreateGlobalForward("ExiTimer_OnSendMessagePost",	ET_Ignore, Param_Cell, Param_String, Param_Cell);
}

void ExiChat_Message(int client, const char[] format, any ...)
{
	if (!IsClientInGame(client))
	{
		return;
	}

	char buffer[MAX_BUFFER_LENGTH];

	SetGlobalTransTarget(client);
	VFormat(buffer, MAX_BUFFER_LENGTH, format, 3);

	ExiChat_SendMessage(client, buffer);
}

void ExiChat_SendMessage(int client, char[] message, int author = 0)
{
	if (!author)
	{
		author = client;
	}

	{
		char buffer[MAX_BUFFER_LENGTH];

		Action results;
		Call_StartForward(ExiForward_OnSendMessage);
		Call_PushCell(client);
		Call_PushString(message);
		Call_PushStringEx(buffer, MAX_BUFFER_LENGTH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(author);
		int error = Call_Finish(results);

		if (error != SP_ERROR_NONE)
		{
			ThrowNativeError(error, "[ExiChat] Error forward \'ExiTimer_OnSendMessage\'");
			return;
		}
		else if (results == Plugin_Changed)
		{
			strcopy(message, MAX_BUFFER_LENGTH, buffer);
		}
		else if (results == Plugin_Stop || results == Plugin_Handled)
		{
			return;
		}
	}

	Format(message, MAX_BUFFER_LENGTH, "%s\x01%s", ExiVar_Engine == Engine_CSGO ? " " : "", message);

	Handle msg = StartMessageOne("SayText2", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") != FeatureStatus_Available || GetUserMessageId("SayText2") == INVALID_MESSAGE_ID)
	{
		PrintToChat(client, message);
		return;
	}

	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(msg);

		pb.SetInt("ent_idx", author);
		pb.SetBool("chat", true);
		pb.SetString("msg_name", message);
		pb.AddString("params", "");
		pb.AddString("params", "");
		pb.AddString("params", "");
		pb.AddString("params", "");
	}
	else
	{
		BfWrite bf = UserMessageToBfWrite(msg);

		bf.WriteByte(author);
		bf.WriteByte(true);
		bf.WriteString(message);
	}

	EndMessage();

	Call_StartForward(ExiForward_OnSendMessagePost);
	Call_PushCell(client);
	Call_PushString(message);
	Call_PushCell(author);
	Call_Finish();
}

// NATIVES
public int Native_Message(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}

	SetGlobalTransTarget(client);

	char buffer[MAX_BUFFER_LENGTH];
	GetNativeString(2, buffer, MAX_BUFFER_LENGTH);
	FormatNativeString(0, 2, 3, MAX_BUFFER_LENGTH, _, buffer);

	ExiChat_SendMessage(client, buffer);
}

public int Native_MessageAll(Handle plugin, int numParams)
{
	char buffer[MAX_BUFFER_LENGTH];

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
		{
			continue;
		}

		SetGlobalTransTarget(client);

		GetNativeString(1, buffer, MAX_BUFFER_LENGTH);
		FormatNativeString(0, 1, 2, MAX_BUFFER_LENGTH, _, buffer);

		ExiChat_SendMessage(client, buffer);
	}
}