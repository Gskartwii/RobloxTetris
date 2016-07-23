local RemoteManager = {};

local Valkyrie = _G.ValkyrieC;
local IntentService = Valkyrie:GetComponent "IntentService";
local ReturningIntents = Valkyrie:GetComponent "ReturningIntents";
local Util = Valkyrie:GetComponent "Util";
local MatrixManager = require(script.Parent.MatrixManager);
local MatrixContainer = game.Players.LocalPlayer.PlayerGui.Tetris.GameContainer;

local PlayerMatrices = {};
local PlayerBinds = {};
local PlayerChangeQueue = {};

function RemoteManager.BindRemote(GameState, Player)
	while PlayerBinds[Player] and #PlayerBinds[Player] > 0 do
		table.remove(PlayerBinds[Player]):disconnect();
	end
	PlayerBinds[Player] = {};
	PlayerChangeQueue[Player] = {};
	table.insert(PlayerBinds[Player], IntentService:RegisterRPCIntent("ClientChange", function(Sender, X, Y, Data)
		if Sender == Player then
			if PlayerChangeQueue[Player] then
				table.insert(PlayerChangeQueue, {Type = "Change", X = X, Y = Y, Data = Data});
			else
				GameState.Matrix[Y][X] = Data;
				MatrixManager.Change(GameState, X, Y);
			end
		end
	end));
	
	table.insert(PlayerBinds[Player], IntentService:RegisterRPCIntent("ClientDelete", function(Sender, Y)
		if Sender == Player then
			if PlayerChangeQueue[Player] then
				table.insert(PlayerChangeQueue, {Type = "Delete", Y = Y});
			else
				MatrixManager.ClearFullLine(GameState, Y);
			end
		end
	end));
	
	table.insert(PlayerBinds[Player], IntentService:RegisterRPCIntent("ClientSendGarbage", function(Receiver, Sender, Lines, HoleIndex)
		if Receiver == Player then
			if PlayerChangeQueue[Player] then
				table.insert(PlayerChangeQueue, {Type = "PendingLines", Lines = Lines, HoleIndex = HoleIndex});
			else
				table.insert(GameState.PendingLines, {Lines = Lines, HoleIndex = HoleIndex, From = Sender});
			end
		end
	end));
	
	table.insert(PlayerBinds[Player], IntentService:RegisterRPCIntent("ClientReceivedGarbage", function(Receiver, Lines, HoleIndex, From)
		if Receiver == Player then
			if PlayerChangeQueue[Player] then
				table.insert(PlayerChangeQueue, {Type = "Garbage", Lines = Lines, HoleIndex = HoleIndex, From = From});
			else
				MatrixManager.AddGarbage(GameState, Lines, HoleIndex);
			end
		end
	end));
	
	table.insert(PlayerBinds[Player], IntentService:RegisterRPCIntent("ClientDied", function(Victim, Killer)
		if Victim == Player then
			if PlayerChangeQueue[Player] then
				table.insert(PlayerChangeQueue, {Type = "Died", Killer = Killer});
			else
				GameState:Die(Killer);
			end
		end
	end));
	
	pcall(function() -- If it fails, the intent has not been set up yet
		local PlayerMatrix = ReturningIntents:CallReturningIntentRemote("ServerGetPlayerMatrix", Player).ServerMatrixBind.ClientMatrixBind;
		if not PlayerMatrix or #PlayerMatrix < 20 then return; end
		GameState.Matrix = PlayerMatrix;
		for i = 1, 10 do
			for j = 1, 20 do
				MatrixManager.Change(GameState, i, j, true);
			end
		end
	end);
	
	if PlayerChangeQueue[Player] then
		for i = 1, #PlayerChangeQueue[Player] do
			local Change = PlayerChangeQueue[Player][i];
			
			if Change.Type == "Change" then
				GameState.Matrix[Change.Y][Change.X] = Change.Data;
				MatrixManager.Change(GameState, Change.X, Change.Y);
			elseif Change.Type == "Delete" then
				MatrixManager.ClearFullLine(GameState, Change.Y);
			elseif Change.Type == "PendingLines" then
				table.insert(GameState.PendingLines, {Lines = Change.Lines, HoleIndex = Change.HoleIndex});
			elseif Change.Type == "Garbage" then
				MatrixManager.AddGarbage(GameState, Change.Lines, Change.HoleIndex);
			elseif Change.Type == "Died" then
				GameState:Die(Change.Killer);
			end
		end
		PlayerChangeQueue[Player] = nil;
	end
end

local function FindFreeMatrix()
	for i = 1, 6 do
		local PotentialMatrix = MatrixContainer["Matrix" .. i];
		local Free = true;
		for Player, Matrix in next, PlayerMatrices do
			if Matrix.Minos.MinoContainer == PotentialMatrix.MinoContainer then
				Free = false;
				break;
			end
		end
		if Free then
			return PotentialMatrix;
		end
	end
	
	error("Unable to find free matrix! Is the server full?");
end

local DisconnectGetPlayerMatrix;
local Connections = {};

function RemoteManager.Init(GameState, DieFunction, StartGameFunction)
	PlayerMatrices = {};
	if DisconnectGetPlayerMatrix then DisconnectGetPlayerMatrix(); end
	DisconnectGetPlayerMatrix = ReturningIntents:RegisterReturningIntentRemote("ClientGetPlayerMatrix", "ClientMatrixBind", function(Sender)
		return GameState.Matrix;
	end);
	
	while #Connections > 0 do
		table.remove(Connections):disconnect();
	end	
	table.insert(Connections, IntentService:RegisterRPCIntent("ClientPrepare", StartGameFunction));
	table.insert(Connections, IntentService:RegisterRPCIntent("ClientSendGarbage", function(Receiver, Sender, Lines, HoleIndex)
		if Receiver == game.Players.LocalPlayer then
			table.insert(GameState.PendingLines, {Lines = Lines, HoleIndex = HoleIndex, From = Sender});
			MatrixManager.UpdatePendingLines(GameState);
		end
	end));
	
	local function RunOnPlayer(Player)
		local Matrix = FindFreeMatrix();
		local GameInstance = {Matrix = {}, Minos = {}, PendingLines = {}, Die = DieFunction};
		PlayerMatrices[Player] = GameInstance;
		MatrixManager.InitMatrix(GameInstance, Matrix.MinoContainer);
		GameInstance.Minos.MinoContainer.PlayerText.Text = Player.Name;
		
		for i = 1, 10 do
			for j = 1, 20 do
				MatrixManager.Change(GameInstance, i, j);
			end
		end
		
		RemoteManager.BindRemote(GameInstance, Player);
	end
	
	local Players = game.Players:GetPlayers();
	for i = 1, #Players do
		if Players[i] ~= game.Players.LocalPlayer then
			Util.RunAsync(function() RunOnPlayer(Players[i]); end);
		end
	end
	
	table.insert(Connections, game.Players.PlayerAdded:connect(RunOnPlayer));
	table.insert(Connections, game.Players.PlayerRemoving:connect(function(Player)
		if Player ~= game.Players.LocalPlayer then
			for i = 1, #PlayerBinds[Player] do
				table.remove(PlayerBinds[Player]):disconnect();
			end
			
			local GameInstance = PlayerMatrices[Player];
			MatrixManager.InitMatrix(GameInstance, GameInstance.Minos.MinoContainer);
			for i = 1, 10 do
				for j = 1, 20 do
					MatrixManager.Change(GameInstance, i, j);
				end
			end
			GameInstance.Minos.MinoContainer.PlayerText.Text = "";
			
			PlayerMatrices[Player] = nil;
		end
	end));
	
	IntentService:BroadcastRPCIntent("ServerReady");
end

return RemoteManager;
