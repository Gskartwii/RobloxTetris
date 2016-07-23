local Valkyrie 			= _G.ValkyrieC;

local InputModule 		= Valkyrie:GetComponent "ValkyrieInput";
local IntentService 	= Valkyrie:GetComponent "IntentService";
local Util				= Valkyrie:GetComponent "Util";

local QueueManager 		= require(script.Parent.QueueManager);
local MatrixManager 	= require(script.Parent.MatrixManager);
local Config 			= require(script.Parent.Config);
local UIManager 		= require(script.Parent.UIManager);
local RemoteManager 	= require(script.Parent.RemoteManager);

local GameManager 		= {};
local Actions 			= {};

local GameInstance;

function GameManager.CreateActions()
	Actions.HardDropAction = InputModule:CreateAction("TetrisHardDrop", function()
		local a = tick();
		GameInstance.ShouldBroadcast = true;
		if not MatrixManager.LockGhost(GameInstance) then
			return;
		end
		GameInstance.ShouldBroadcast = false;
		
		MatrixManager.SpawnPiece(GameInstance, QueueManager.Next(GameInstance));
		GameInstance.HeldLast = false;
		GameInstance.LeftDASDebounce = false;
		GameInstance.RightDASDebounce = false;
		
		local b = tick();
		if b - a > 1/60 then
			warn("HardDrop took", b - a);
		end
	end);
	
	Actions.LeftAction = InputModule:CreateAction("TetrisLeft", function()
		local a = tick();
		
		GameInstance.RightDASDebounce = true;
		
		MatrixManager.MovePiece(GameInstance, -1, 0);
		
		local b = tick();
		if b - a > 1/60 then
			warn("Left took", b - a);
		end
		wait((Config.DASDebounce or 10)/60);
		GameInstance.RightDASDebounce = false;
	end);
		
	Actions.RightAction = InputModule:CreateAction("TetrisRight", function()
		local a = tick();
		
		GameInstance.LeftDASDebounce = true;

		MatrixManager.MovePiece(GameInstance, 1, 0);

		local b = tick();
		if b - a > 1/60 then
			warn("Right took", b - a);
		end
		wait((Config.DASDebounce or 10)/60);
		GameInstance.LeftDASDebounce = false;
	end);
	
	Actions.DASLeftAction = InputModule:CreateAction("TetrisDASLeft", function()
		if GameInstance.LeftDASDebounce then return; end
		local a = tick();
		
		MatrixManager.DASLeft(GameInstance);
		
		local b = tick();
		if b - a > 1/60 then
			warn("DASLeft took", b - a);
		end
	end);
	Actions.DASRightAction = InputModule:CreateAction("TetrisDASRight", function()
		if GameInstance.RightDASDebounce then return; end
		local a = tick();
		
		MatrixManager.DASRight(GameInstance);
		
		local b = tick();
		if b - a > 1/60 then
			warn("DASRight took", b - a);
		end
	end);
	
	Actions.RotLeftAction = InputModule:CreateAction("TetrisRotLeft", function()
		local a = tick();
		
		MatrixManager.RotatePiece(GameInstance, -1);
		
		local b = tick();
		if b - a > 1/60 then
			warn("RotLeft took", b - a);
		end
	end);
	Actions.RotRightAction = InputModule:CreateAction("TetrisRotRight", function()
		local a = tick();		
		
		MatrixManager.RotatePiece(GameInstance, 1);
		
		local b = tick();
		if b - a > 1/60 then
			warn("RotRight took", b - a);
		end
	end);
	
	Actions.HoldAction = InputModule:CreateAction("TetrisHold", function()
		local a = tick();
		
		if QueueManager.HoldPiece(GameInstance) then
			GameInstance.HeldLast = true;
		end
		
		local b = tick();
		if b - a > 1/60 then
			warn("Hold took", b - a);
		end
	end);
	
	Actions.SoftDropAction = InputModule:CreateAction("TetrisSoftDrop", function()
		local a = tick();
		
		for i = 1, (Config.SoftDropGravityNumerator or 5) do
			if not MatrixManager.MovePiece(GameInstance, 0, -1) then
				break;
			end
		end
		
		local b = tick();
		if b - a > 1/60 then
			warn("SoftDrop took", b - a);
		end
	end);
end

function GameManager.RebindActions(GameInstance)
	if not Actions.HardDropAction then
		GameManager.CreateActions(GameInstance);
	else
		for _, Action in next, Actions do
			Action:UnbindAll();
		end
	end
	Actions.HardDropAction:BindControl(Config.HardDrop or InputModule.InputSources.Keyboard.Space, InputModule.InputDirections.Begin);

	Actions.LeftAction:BindControl(Config.Left or InputModule.InputSources.Keyboard.Left, InputModule.InputDirections.Begin);
	Actions.RightAction:BindControl(Config.Right or InputModule.InputSources.Keyboard.Right, InputModule.InputDirections.Begin);
	
	Actions.DASLeftAction:BindHold(Config.DASLeft or Config.Left or InputModule.InputSources.Keyboard.Left, (Config.DAS or 8)/60, (Config.DASGravityDenominator or 1)/60);
	Actions.DASRightAction:BindHold(Config.DASRight or Config.Right or InputModule.InputSources.Keyboard.Right, (Config.DAS or 8)/60, (Config.DASGravityDenominator or 1)/60);
	
	Actions.RotLeftAction:BindControl(Config.RotLeft or InputModule.InputSources.Keyboard.KeypadZero, InputModule.InputDirections.Begin);
	Actions.RotRightAction:BindControl(Config.RotRight or InputModule.InputSources.Keyboard.Up, InputModule.InputDirections.Begin);
	
	Actions.HoldAction:BindControl(Config.Hold or InputModule.InputSources.Keyboard.Shift, InputModule.InputDirections.Begin);
	
	Actions.SoftDropAction:BindHold(Config.SoftDrop or InputModule.InputSources.Keyboard.Down, (Config.SoftDropDelay or 0)/60, (Config.SoftDropGravityDenominator or 1)/60);
end

function GameManager.Die(GameInstance, Killer)
	if GameInstance.ShouldBroadcastDeath then
		for _, Action in next, Actions do
			Action:UnbindAll();
		end
		
		IntentService:BroadcastRPCIntent("ServerDied", Killer);
	end
	
	local DeathText 	= GameInstance.Minos.MinoContainer.DeathText;
	DeathText.Text 		= Killer and ("KO'd by " .. Killer.Name) or "Blocked out"; 
	DeathText.Visible 	= true;
end

function GameManager.RunGame(RandomSeed)
	math.randomseed(RandomSeed or tick());
	
	GameInstance = {Matrix = {}, Minos = {}, CurrentPiece = {}, Counter = 1, Queue = {}, QueueCounter = 0, Combo = 0, RebindActions = GameManager.RebindActions, PendingLines = {}, Die = GameManager.Die, ShouldBroadcastDeath = true};
	MatrixManager.InitMatrix(GameInstance);
	QueueManager.Init(GameInstance);

	MatrixManager.SpawnPiece(GameInstance, QueueManager.Next(GameInstance));
	UIManager.Init(GameInstance);
	
	local Ready = false;
	local StartGameIntent = IntentService:RegisterRPCIntent("ClientStartGame", function() Ready = true; end);
	
	RemoteManager.Init(GameInstance, GameManager.Die, GameManager.RunGame);
	
	repeat wait(); until Ready
	
	GameManager.RebindActions(GameInstance);
end

return GameManager;
