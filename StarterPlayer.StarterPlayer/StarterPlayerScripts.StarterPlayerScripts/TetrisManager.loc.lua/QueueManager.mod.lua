local Valkyrie = _G.ValkyrieC;

Valkyrie = _G.ValkyrieC;

local QueueManager 			= {};

local Randomizer			= require(script.Parent.Randomizer);
local PieceDisplaySpawner 	= require(script.Parent.PieceDisplaySpawner);
local MatrixManager			= require(script.Parent.MatrixManager);

local GameDisplay			= game.Players.LocalPlayer.PlayerGui.Tetris.GameContainer.MainFieldContainer;
local QueueDisplay			= GameDisplay.Queue;
local HoldDisplay			= GameDisplay.Hold;

local function RenderHoldPiece(PieceName)
	if HoldDisplay:FindFirstChild "HoldPiece" then
		HoldDisplay.HoldPiece:Destroy();
	end
	
	local NewPiece = PieceDisplaySpawner.CreatePiece(PieceName);
	NewPiece.Position = UDim2.new(0,0,0,0);
	NewPiece.Name = "HoldPiece";
	NewPiece.Parent = HoldDisplay;
end

function QueueManager.Init(GameState)
	if HoldDisplay:FindFirstChild "HoldPiece" then
		HoldDisplay.HoldPiece:Destroy();
	end
	QueueDisplay:ClearAllChildren();
end

function QueueManager.HoldPiece(GameState)
	if not GameState.Hold then
		GameState.Hold = GameState.CurrentPiece.Name;
		MatrixManager.RemoveGhost(GameState);
		
		local NewPiece = QueueManager.Next(GameState);		
		MatrixManager.SpawnPiece(GameState, NewPiece);
		
		RenderHoldPiece(GameState.Hold);
		
		return true;
	elseif not GameState.HeldLast then
		local OldHold = GameState.Hold;
		GameState.Hold = GameState.CurrentPiece.Name;
		
		MatrixManager.RemoveGhost(GameState);
		MatrixManager.SpawnPiece(GameState, OldHold); 
		
		RenderHoldPiece(GameState.Hold);
		
		return true;
	end
	return false;
end

function QueueManager.Next(GameState)
	if not GameState.Bag1 or not GameState.Bag2 then
		GameState.Bag1, GameState.Bag2 	= Randomizer.MakeBag(), Randomizer.MakeBag();
		GameState.Queue = GameState.Bag1;
	elseif GameState.Counter == 7 then
		GameState.Counter 	= 0;
		GameState.Bag1 		= GameState.Bag2;
		GameState.Bag2		= Randomizer.MakeBag();
	end
	
	if GameState.QueueCounter == 7 then
		GameState.QueueCounter = 0;
		GameState.Queue = GameState.Bag1;
	end
	
	if QueueDisplay:FindFirstChild("Piece1") then
		QueueDisplay.Piece1:Destroy();
	end
	
	local QueueDisplayPieces = QueueDisplay:GetChildren();
	for i = 1, #QueueDisplayPieces do
		local Piece = QueueDisplayPieces[i];
		if Piece.Name ~= "Sample" then
			Piece.Position = Piece.Position + UDim2.new(0,0,0,-96);
			Piece.Name = Piece.Name:gsub("%d", function(a) return tostring(tonumber(a) - 1); end);
		end
	end
		
	local ReturnedPiece;
	for i = 1, 5 do
		if not QueueDisplay:FindFirstChild("Piece" .. i) then
			local NewPiece = PieceDisplaySpawner.CreatePiece(GameState.Bag1[GameState.Counter + 1]);
			NewPiece.Position = UDim2.new(0,0,0,96*i-96);
			NewPiece.Name = "Piece" .. i;
			NewPiece.Parent = QueueDisplay;
			GameState.Counter = GameState.Counter + 1;
		end
	end
	GameState.QueueCounter = GameState.QueueCounter + 1;
	
	return GameState.Queue[GameState.QueueCounter];
end

return QueueManager;
