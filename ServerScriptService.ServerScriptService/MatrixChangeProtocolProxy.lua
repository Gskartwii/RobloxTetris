local PRIVATEVALKYRIEAUTHID = 462647523;

local Valkyrie = require(PRIVATEVALKYRIEAUTHID);

math.randomseed(tick());

local IntentService = _G.Valkyrie:GetComponent "IntentService";
local ReturningIntents = _G.Valkyrie:GetComponent "ReturningIntents";

local Players = {};
local Loaded  = {};
local InGame  = false;

IntentService:RegisterRPCIntent("ServerChange", function(Sender, ...)
	IntentService:BroadcastRPCIntent("ClientChange", "All", Sender, ...);
end);

IntentService:RegisterRPCIntent("ServerDelete", function(Sender, ...)
	IntentService:BroadcastRPCIntent("ClientDelete", "All", Sender, ...);
end);

IntentService:RegisterRPCIntent("ServerSendGarbage", function(Sender, Lines)
	local Players = game.Players:GetPlayers();
	for i = 1, #Players do
		if Players[i] == Sender then
			table.remove(Players, i);
		end
	end
	local Receiver = Players[math.random(#Players)];
	
	IntentService:BroadcastRPCIntent("ClientSendGarbage", "All", Receiver, Sender, Lines, math.random(10));
end);

IntentService:RegisterRPCIntent("ServerReceivedGarbage", function(Sender, Lines, HoleIndex)
	IntentService:BroadcastRPCIntent("ClientReceivedGarbage", "All", Sender, Lines, HoleIndex);
end);

local function AskClientsPrepare()
	Players = {};

	repeat wait() until #Loaded == game.Players.NumPlayers
	IntentService:BroadcastRPCIntent("ClientPrepare", "All", math.random());
end

IntentService:RegisterRPCIntent("ServerDied", function(Sender, Killer)
	IntentService:BroadcastRPCIntent("ClientDied", "All", Sender, Killer);
	
	for i = 1, #Players do
		if Players[i] == Sender then
			table.remove(Players, i);
		end
	end
		
	if #Players < 2 then
		InGame = false;
		
		wait(5);
		
		AskClientsPrepare();
		
		repeat wait(); until #Players >= #game.Players:GetPlayers();

		IntentService:BroadcastRPCIntent("ClientStartGame", "All");
		InGame = true;
	end
end);

ReturningIntents:RegisterReturningIntentRemote("ServerGetPlayerMatrix", "ServerMatrixBind", function(Sender, Target)
	return ReturningIntents:CallReturningIntentRemote("ClientGetPlayerMatrix", Target, Sender);
end);

IntentService:RegisterRPCIntent("ServerReady", function(Sender)
	if InGame then return; end
	
	for i = 1, #Players do
		if Players[i] == Sender then
			return;
		end
	end
	table.insert(Players, Sender);
end);

IntentService:RegisterRPCIntent("ServerLoaded", function(Sender)
	for i = 1, #Loaded do
		if Loaded[i] == Sender then
			return;
		end
	end
	
	table.insert(Loaded, Sender);
end)

game.Players.PlayerRemoving:connect(function(Player)
	IntentService:BroadcastRPCIntent("ClientDied", "All", Player, {Name = "quitting"}); -- Hax
	
	for i = 1, #Players do
		if Players[i] == Player then
			table.remove(Players, i);
		end
	end
	
	for i = 1, #Loaded do
		if Loaded[i] == Player then
			table.remove(Loaded, i);
		end
	end
		
	if #Loaded < 2 then
		InGame = false;
		repeat wait(); until game.Players.NumPlayers >= 2;
		
		AskClientsPrepare();
		
		repeat wait(); until #Players >= game.Players.NumPlayers;

		IntentService:BroadcastRPCIntent("ClientStartGame", "All");
		InGame = true;
	end
end);

repeat wait(); until game.Players.NumPlayers >= 2

AskClientsPrepare();
repeat wait(); until #Players >= 2;
IntentService:BroadcastRPCIntent("ClientStartGame", "All");
InGame = true;
