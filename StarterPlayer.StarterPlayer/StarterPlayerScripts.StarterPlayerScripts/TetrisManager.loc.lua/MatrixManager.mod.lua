local Valkyrie = _G.ValkyrieC;
local Color3 = Valkyrie:GetComponent "Colour";
local IntentService = Valkyrie:GetComponent "IntentService";

local GameContainer = game.Players.LocalPlayer.PlayerGui.Tetris.GameContainer;
local MinoContainer = GameContainer.MainFieldContainer.Matrix.MinoContainer;
local PendingLinesDisplay = GameContainer.MainFieldContainer.PendingLinesContainer.PendingLinesDisplay;
local UIManager 	= require(script.Parent.UIManager);
local Config 		= require(script.Parent.Config);

local ud2incr = UDim2.new(0, 0, .05, 0);
local zud2 = UDim2.new(0,0,0,0);

local MatrixManager = {};

function MatrixManager.Change(GameState, i, j, IgnoreNonSolid)
	if j > 20 then return; end
	local Row = GameState.Matrix[j];
	local MatrixMino = Row[i];
	local Mino = GameState.Minos[j][i];
	if MatrixMino.Occupied or not IgnoreNonSolid and (MatrixMino.Ghost or MatrixMino.Active) then
		Mino.BackgroundColor3 = MatrixMino.Color;
		Mino.Visible = true;
		Mino.Ghost.Visible = MatrixMino.Ghost and not MatrixMino.Active;
	else
		Mino.Visible = false;
	end
	
	if GameState.ShouldBroadcast then
		IntentService:BroadcastRPCIntent("ServerChange", i, j, MatrixMino);
	end
end

function MatrixManager.InitMatrix(GameState, OverrideMinoContainer)
	local MinoContainer = OverrideMinoContainer or MinoContainer;
	MinoContainer.DeathText.Visible = false;
	GameState.Minos.MinoContainer = MinoContainer;
	for i = 1, 23 do
		GameState.Matrix[i] = {};
		if i <= 20 then
			GameState.Minos[i] = {Row = MinoContainer[21-i]};
		end
		for j = 1, 10 do
			GameState.Matrix[i][j] = {Color = Color3.Brown[500], Occupied = false, Ghost = false, Active = false};
			if i <= 20 then
				GameState.Minos[i][j] = MinoContainer[21-i][j];
				MatrixManager.Change(GameState, j, i);
			end
		end
	end
	
	MatrixManager.UpdatePendingLines(GameState);
end

function MatrixManager.DoesFit(GameState, Shape, Position)
	local Height = math.max(Shape[1][2], Shape[2][2], Shape[3][2], Shape[4][2]);
	for i = 1, 4 do
		local Row = GameState.Matrix[-Shape[i][2] + Position[2]];
		if not Row then
			return false;
		end
		
		local Mino = Row[Position[1] + Shape[i][1]];
		if not Mino or Mino.Occupied then
			return false;
		end
	end
	return true;
end

function MatrixManager.FindLowestPosition(GameState, Shape, Offset, OffsetTop)
	OffsetTop = OffsetTop or 20;
	local Height = math.max(Shape[1][2], Shape[2][2], Shape[3][2], Shape[4][2]);
	local DidFit, MayFit = OffsetTop, OffsetTop - 1;

	while MatrixManager.DoesFit(GameState, Shape, {Offset, MayFit}) do
		DidFit = MayFit;
		MayFit = MayFit - 1;
	end

	return DidFit < OffsetTop and {Offset, DidFit};
end

function MatrixManager.GhostAtPosition(GameState, PieceData, GhostPosition, ActivePosition)
	local Shape = PieceData.Orientations[GameState.CurrentPiece.Orientation or 1];
	local MinoPositions = {};
	local ActivePositions = {};
	for i = 1, 4 do
		table.insert(MinoPositions, {Shape[i][1] + GhostPosition[1], -Shape[i][2] + GhostPosition[2]});
		local Mino = GameState.Matrix[MinoPositions[i][2]][MinoPositions[i][1]];

		Mino.Ghost = true;
		Mino.Occupied = false;
		Mino.Color = PieceData.Color;
		MatrixManager.Change(GameState, unpack(MinoPositions[i]));

		table.insert(ActivePositions, {Shape[i][1] + ActivePosition[1], -Shape[i][2] + ActivePosition[2]});
		local Mino = GameState.Matrix[ActivePositions[i][2]][ActivePositions[i][1]];

		Mino.Ghost = false;
		Mino.Occupied = false;
		Mino.Active = true;
		Mino.Color = PieceData.Color;
		MatrixManager.Change(GameState, unpack(ActivePositions[i]));
	end

	return MinoPositions, ActivePositions;
end

function MatrixManager.RemoveGhost(GameState)
	for i = 1, 4 do
		local GhostMinoCoords = GameState.CurrentPiece.GhostMinos[i];
		local CurrentPositionMino = GameState.Matrix[GhostMinoCoords[2]][GhostMinoCoords[1]];

		CurrentPositionMino.Ghost = false;
		CurrentPositionMino.Color = Color3.Grey[900];
		MatrixManager.Change(GameState, GhostMinoCoords[1], GhostMinoCoords[2]);
		
		local ActiveMinoCoords = GameState.CurrentPiece.ActiveMinos[i];
		local CurrentPositionMino = GameState.Matrix[ActiveMinoCoords[2]][ActiveMinoCoords[1]];

		CurrentPositionMino.Active = false;
		CurrentPositionMino.Color = Color3.Grey[900];
		MatrixManager.Change(GameState, ActiveMinoCoords[1], ActiveMinoCoords[2]);
	end
end

function MatrixManager.MoveGhost(GameState, Position, ActivePosition)
	local PieceData = GameState.CurrentPiece.Shape;

	MatrixManager.RemoveGhost(GameState);
		
	GameState.CurrentPiece.GhostMinos, GameState.CurrentPiece.ActiveMinos = MatrixManager.GhostAtPosition(GameState, PieceData, Position, ActivePosition);
	GameState.CurrentPiece.Position = ActivePosition;
	GameState.CurrentPiece.Offset = Position[1];
	GameState.CurrentPiece.OffsetTop = ActivePosition[2];
end

local insert = table.insert;

function MatrixManager.UpdatePendingLines(GameState)
	local PendingLines = GameState.PendingLines;
	local NumLines = 0;
	
	for i = 1, #PendingLines do
		NumLines = NumLines + PendingLines[i].Lines;
	end
	
	PendingLinesDisplay.Size = UDim2.new(1,0,math.min(NumLines/20,1),0);
end

function MatrixManager.AddGarbage(GameState, Lines, HoleIndex, From)
	local OldBroadcast = GameState.ShouldBroadcast;
	GameState.ShouldBroadcast = false;
	for i = 1, Lines do
		for i = 1, 10 do
			if GameState.Matrix[20][i].Occupied then
				GameState.ShouldBroadcast = OldBroadcast;
				return GameState:Die(From);
			end
		end
		
		local LastLine = table.remove(GameState.Matrix);
		local LastMinoLine = table.remove(GameState.Minos);
		table.insert(GameState.Matrix, 1, LastLine);
		table.insert(GameState.Minos, 1, LastMinoLine);
		
		local Row = GameState.Minos[1].Row;
		Row.Position = UDim2.new(0,0,.95,0);
		Row.Name = "20";
		
		for i = 2, 20 do
			local Row = GameState.Minos[i].Row;
			Row.Position = Row.Position - ud2incr;
			Row.Name = Row.Name - 1;
		end
		
		for i = 1, 10 do
			if i == HoleIndex then
				LastLine[i].Occupied = false;
				LastLine[i].Ghost = false;
				LastLine[i].Active = false;
			else
				LastLine[i].Occupied = true;
				LastLine[i].Ghost = false;
				LastLine[i].Active = false;
				
				LastLine[i].Color = Color3.Gray[500];
			end
			MatrixManager.Change(GameState, i, 1);
		end
	end
	
	GameState.ShouldBroadcast = OldBroadcast;	
	
	if GameState.ShouldBroadcast then
		IntentService:BroadcastRPCIntent("ServerReceivedGarbage", Lines, HoleIndex);
	end
	
	return true;
end

function MatrixManager.Delete(GameState, DeletedIndex)
	local Row = GameState.Minos[DeletedIndex].Row;

	for i = DeletedIndex, 20 do
		local RowA = GameState.Minos[i].Row;
		RowA.Name = RowA.Name + 1;
		RowA.Position = RowA.Position + ud2incr;
	end
	Row.Position = zud2;
	Row.Name = "1";
	for i = 1, 10 do
		Row[i].Visible = false;
	end
	
	if GameState.ShouldBroadcast then
		IntentService:BroadcastRPCIntent("ServerDelete", DeletedIndex);
	end
end

function MatrixManager.ClearFullLine(GameState, Line)
	for i = 1, 10 do -- Is the line full?
		local Mino = GameState.Matrix[Line][i];
		if not Mino.Occupied then
			return false;
		end
	end
	
	MatrixManager.Delete(GameState, Line);
	
	table.remove(GameState.Matrix, Line);
	table.remove(GameState.Minos, Line);
	local NewLine = {};
	local NewMinoLine = {};
	for i = 1, 10 do
		insert(NewLine, {Color = Color3.Brown[500], Occupied = false, Ghost = false, Active = false});
		insert(NewMinoLine, GameState.Minos.MinoContainer[1][i]);
	end
	NewMinoLine.Row = GameState.Minos.MinoContainer[1];
	
	insert(GameState.Matrix, NewLine);
	insert(GameState.Minos, NewMinoLine);
	
	return true;
end

local function GetSpin(LineCount, Height, IsImmobileLR, IsImmobileUp, DidKick)
	if IsImmobileLR and IsImmobileUp then
		if LineCount == Height or LineCount == 0 then
			return "Regular";
		elseif LineCount < Height and DidKick then
			return "Mini";
		end
	elseif IsImmobileLR and DidKick then
		return "EZ";
	end
	
	return false;
end

local function GetClearString(LineCount, SpinStatus, PieceName, Combo, B2B, PC)
	local ClearString = {};
	if SpinStatus == "Regular" then
		table.insert(ClearString, PieceName .. "-spin");
	elseif SpinStatus == "Mini" then
		table.insert(ClearString, PieceName .. "-spin Mini");
	elseif SpinStatus == "EZ" then
		table.insert(ClearString, PieceName .. "-spin EZ");
	end
	
	if B2B and LineCount > 0 then
		table.insert(ClearString, 1, "B2B");
	end
	
	if Combo > 1 and LineCount > 0 then
		table.insert(ClearString, 1, "[" .. Combo .. "]");
	end
	
	if LineCount > 0 then
		table.insert(ClearString, _G.LineData.ClearNames[LineCount]);
	end
	
	if PC then
		table.insert(ClearString, " + PC");
	end
	
	return table.concat(ClearString, " ");
end

local ComboTable = {0,0,1,1,2,2,3,3,4,4,4,5}; -- Credit to NullPoMino

local function GetAttack(LineCount, SpinStatus, Combo, B2B, PC)
	if LineCount < 1 then
		return 0;
	end
	local Attack = 0;
	
	if SpinStatus == "Regular" then
		Attack = LineCount * 2;
	elseif SpinStatus == "Mini" then
		Attack = (LineCount - 1) * 3;
	elseif SpinStatus ~= "EZ" and LineCount > 0 then
		Attack = LineCount - 1;
		if LineCount == 4 then
			Attack = 4;
		end
	end
	
	if PC then
		Attack = Attack + 6;
	end
	
	if not ComboTable[Combo + 1] then
		Attack = Attack + 5;
	else
		Attack = Attack + ComboTable[Combo + 1];
	end
	
	if B2B then
		Attack = Attack + 1;
	end
	
	return Attack;
end

function MatrixManager.LockGhost(GameState)
	local Shape = GameState.CurrentPiece.Shape.Orientations[GameState.CurrentPiece.Orientation];
	local IsImmobileLR =
			not	MatrixManager.DoesFit(GameState, Shape, {GameState.CurrentPiece.Offset + 1, GameState.CurrentPiece.OffsetTop})
		and not MatrixManager.DoesFit(GameState, Shape, {GameState.CurrentPiece.Offset - 1, GameState.CurrentPiece.OffsetTop});
	local IsImmobileUp = 
			not MatrixManager.DoesFit(GameState, Shape, {GameState.CurrentPiece.Offset, GameState.CurrentPiece.OffsetTop + 1});
	local Height = math.max(Shape[1][2], Shape[2][2], Shape[3][2], Shape[4][2]) - math.min(Shape[1][2], Shape[2][2], Shape[3][2], Shape[4][2]) + 1;
	local PC = true;
	
	-- TODO: Make this more efficient
	local AffectedLines = {};
	
	for ActiveIndex = 1, 4 do
		local i, j = unpack(GameState.CurrentPiece.ActiveMinos[ActiveIndex]);
		local Mino = GameState.Matrix[j][i];
		Mino.Active = false;
		MatrixManager.Change(GameState, i, j);
	end
	
	for GhostIndex = 1, 4 do
		local i, j = unpack(GameState.CurrentPiece.GhostMinos[GhostIndex]);
		local Mino = GameState.Matrix[j][i];
		Mino.Occupied = true;
		Mino.Ghost = false;
		MatrixManager.Change(GameState, i, j);
		table.insert(AffectedLines, j);
	end
	
	table.sort(AffectedLines);
	
	local LineCount = 0;
		
	for i = #AffectedLines, 1, -1 do
		if MatrixManager.ClearFullLine(GameState, AffectedLines[i]) then
			LineCount = LineCount + 1;
		end
	end
	
	local SpinStatus = GetSpin(LineCount, Height, IsImmobileLR, IsImmobileUp, GameState.CurrentPiece.LastKick);
	
	if not (LineCount == 4 or SpinStatus) and LineCount > 0 then
		GameState.B2B = false;
	end
	
	if LineCount > 0 then
		GameState.Combo = GameState.Combo + 1;

		for i = 1, 10 do -- If the bottom line is fully cleared, a PC has occurred
			if GameState.Matrix[1][i].Occupied then
				PC = false;
				break;
			end
		end
	else
		PC = false;
		GameState.Combo = 0;
	end

	UIManager.SetRewardText(GameState, GetClearString(LineCount, SpinStatus, GameState.CurrentPiece.Name, GameState.Combo, GameState.B2B, PC));
	
	local Attack = GetAttack(LineCount, SpinStatus, GameState.Combo, GameState.B2B, PC);
		
	while Attack > 0 and #GameState.PendingLines > 0 do
		local PendingLines = table.remove(GameState.PendingLines, 1);
		Attack = Attack - PendingLines.Lines;
		
		if Attack < 0 then
			table.insert(GameState.PendingLines, 1, {Lines = -Attack, HoleIndex = PendingLines.HoleIndex, From = PendingLines.From});
		end
	end
	
	if Attack > 0 and GameState.ShouldBroadcast then
		IntentService:BroadcastRPCIntent("ServerSendGarbage", Attack);
	end
	
	if LineCount < 1 then
		while #GameState.PendingLines > 0 do
			local Pending = table.remove(GameState.PendingLines, 1);
			if not MatrixManager.AddGarbage(GameState, Pending.Lines, Pending.HoleIndex, Pending.From) then
				return;
			end
		end
	end
	
	MatrixManager.UpdatePendingLines(GameState);

	if LineCount == 4 or SpinStatus then
		GameState.B2B = true;
	end
	
	return true;
end

function MatrixManager.SpawnPiece(GameState, PieceName)
	local IntendedPosition = MatrixManager.FindLowestPosition(GameState, _G.PieceData[PieceName].Orientations[1], 4 + _G.PieceData[PieceName].SpawnDiff[1], 21 + _G.PieceData[PieceName].SpawnDiff[2]);

	if not IntendedPosition then -- block out!
		return GameState:Die();
	end
	GameState.CurrentPiece = {Name = PieceName; Orientation = 1; Position = IntendedPosition; GhostMinos = {}; ActiveMinos = {}; Offset = 4 + _G.PieceData[PieceName].SpawnDiff[1]; OffsetTop = 20 + _G.PieceData[PieceName].SpawnDiff[2]; Shape = _G.PieceData[PieceName]};
	GameState.CurrentPiece.GhostMinos, GameState.CurrentPiece.ActiveMinos = MatrixManager.GhostAtPosition(GameState, _G.PieceData[PieceName], IntendedPosition, {IntendedPosition[1], 20});
end

function MatrixManager.MovePiece(GameState, XDirection, YDirection)
	local IntendedPosition = MatrixManager.FindLowestPosition(GameState, GameState.CurrentPiece.Shape.Orientations[GameState.CurrentPiece.Orientation], GameState.CurrentPiece.Offset + XDirection, GameState.CurrentPiece.OffsetTop + YDirection + 1);
	if not IntendedPosition then
		-- Just ignore the fact that the piece cannot be moved there
		return false;
	else
		GameState.CurrentPiece.LastKick = false;
		MatrixManager.MoveGhost(GameState, IntendedPosition, {IntendedPosition[1], GameState.CurrentPiece.OffsetTop + YDirection});
		return true;
	end
end

function MatrixManager.DASLeft(GameState)
	for i = 1, (Config.DASGravityNumerator or 20) do 
		if not MatrixManager.MovePiece(GameState, -1, 0) then
			break;
		end
	end
end
function MatrixManager.DASRight(GameState)
	for i = 1, (Config.DASGravityNumerator or 20) do 
		if not MatrixManager.MovePiece(GameState, 1, 0) then
			break;
		end
	end
end

function MatrixManager.RotatePiece(GameState, Direction)
	local OldOrientation = GameState.CurrentPiece.Orientation;
	local NewOrientation = OldOrientation + Direction;
	
	if NewOrientation == 5 then
		NewOrientation = 1;
	elseif NewOrientation == 0 then
		NewOrientation = 4;
	end
	
	local KickData = GameState.CurrentPiece.Shape.Kicks[OldOrientation][NewOrientation];
	local i, IntendedPosition = 0
	repeat
		i = i + 1;
		IntendedPosition = 
			MatrixManager.FindLowestPosition(
				GameState, 
				GameState.CurrentPiece.Shape.Orientations[NewOrientation], 
				GameState.CurrentPiece.Offset + KickData[i][1],
				GameState.CurrentPiece.OffsetTop + 1 + KickData[i][2]
			);
	until IntendedPosition or not KickData[i + 1]
	
	if not IntendedPosition then
		-- Just ignore the fact that the piece cannot be moved there
		return false;
	else
		GameState.CurrentPiece.LastKick = i > 1;
		GameState.CurrentPiece.Orientation = NewOrientation;
		MatrixManager.MoveGhost(GameState, IntendedPosition, {IntendedPosition[1], GameState.CurrentPiece.OffsetTop + KickData[i][2]});
	end
end

return MatrixManager;
