repeat wait() until _G.ValkyrieC;
local Valkyrie = _G.ValkyrieC;
local Color3 = _G.ValkyrieC:GetComponent "Colour";
local Font = _G.ValkyrieC:GetComponent "Fonts";
local IntentService = _G.ValkyrieC:GetComponent "IntentService";

local JLSZTKickBases = {
	{{ 0, 0},{ 0, 0},{ 0, 0},{ 0, 0},{ 0, 0}}; -- 0
	{{ 0, 0},{ 1, 0},{ 1,-1},{ 0, 2},{ 1, 2}}; -- R
	{{ 0, 0},{ 0, 0},{ 0, 0},{ 0, 0},{ 0, 0}}; -- 2
	{{ 0, 0},{-1, 0},{-1,-1},{ 0, 2},{-1, 2}}; -- L
};
local IKickBases = {
	{{ 0, 0},{-1, 0},{ 2, 0},{-1, 0},{ 2, 0}}; -- 0
	{{-1, 0},{ 0, 0},{ 0, 0},{ 0, 1},{ 0,-2}}; -- R
	{{-1, 1},{ 1, 1},{-2, 1},{ 1, 0},{-2, 0}}; -- 2
	{{ 0, 1},{ 0, 1},{ 0, 1},{ 0,-1},{ 0, 2}}; -- L
};
local OKickBases = {
	{{ 0, 0}};
	{{ 0,-1}};
	{{-1,-1}};
	{{-1, 0}};
};
local JLSZTKicks, IKicks, OKicks = {}, {}, {};

local function CalculateKickData(Base, Target)
	for i = 1, #Base do
		Target[i] = {};
		for j = 1, #Base do
			Target[i][j] = {};
			for k = 1, #Base[j] do
				Target[i][j][k] = {Base[i][k][1] - Base[j][k][1], Base[i][k][2] - Base[j][k][2]};
			end
		end
	end
end

CalculateKickData(JLSZTKickBases, JLSZTKicks);
CalculateKickData(IKickBases, IKicks);
CalculateKickData(OKickBases, OKicks);

local JLSZTRenderDiff = {0, 0};
local IRenderDiff = {-1, -1.5};
local ORenderDiff = {-.5, 0};

_G.PieceData = {
	J = {
		Orientations = {
			{{0,0}, {0,1}, {1,1}, {2,1}};
			{{2,0}, {1,0}, {1,1}, {1,2}};
			{{2,2}, {2,1}, {1,1}, {0,1}};
			{{0,2}, {1,2}, {1,1}, {1,0}};
		}, 
		Kicks = JLSZTKicks,
		RenderDiff = JLSZTRenderDiff,
		SpawnDiff = JLSZTKickBases[2][1],
		Color = Color3.Indigo[500]
	};
	L = {
		Orientations = {
			{{2,0}, {0,1}, {1,1}, {2,1}};
			{{2,2}, {1,0}, {1,1}, {1,2}};
			{{0,2}, {2,1}, {1,1}, {0,1}};
			{{0,0}, {1,2}, {1,1}, {1,0}};
		}, 
		Kicks = JLSZTKicks,
		RenderDiff = JLSZTRenderDiff,
		SpawnDiff = JLSZTKickBases[2][1],
		Color = Color3.Orange[500]
	};
	T = {
		Orientations = {
			{{1,0}, {0,1}, {1,1}, {2,1}};
			{{2,1}, {1,0}, {1,1}, {1,2}};
			{{1,2}, {2,1}, {1,1}, {0,1}};
			{{0,1}, {1,2}, {1,1}, {1,0}};
		}, 
		Kicks = JLSZTKicks,
		RenderDiff = JLSZTRenderDiff,
		SpawnDiff = JLSZTKickBases[2][1],
		Color = Color3.Purple[500]
	};
	I = {
		Orientations = {
			{{1,2}, {2,2}, {3,2}, {4,2}};
			{{2,1}, {2,2}, {2,3}, {2,4}};
			{{0,2}, {1,2}, {2,2}, {3,2}};
			{{2,0}, {2,1}, {2,2}, {2,3}};
		}, 
		Kicks = IKicks,
		RenderDiff = IRenderDiff,
		SpawnDiff = IKickBases[2][1],
		Color = Color3.LightBlue[500]
	};
	O = {
		Orientations = {
			{{1,0}, {1,1}, {2,0}, {2,1}};
			{{1,1}, {1,2}, {2,1}, {2,2}};
			{{0,1}, {0,2}, {1,1}, {1,2}};
			{{0,0}, {0,1}, {1,0}, {1,1}};
		}, 
		Kicks = OKicks,
		RenderDiff = ORenderDiff,
		SpawnDiff = OKickBases[2][1],
		Color = Color3.Yellow[500]
	};
	Z = {
		Orientations = {
			{{0,0}, {1,0}, {1,1}, {2,1}};
			{{2,0}, {2,1}, {1,1}, {1,2}};
			{{2,2}, {1,2}, {1,1}, {0,1}};
			{{0,2}, {0,1}, {1,1}, {1,0}};
		}, 
		Kicks = JLSZTKicks,
		RenderDiff = JLSZTRenderDiff,
		SpawnDiff = JLSZTKickBases[2][1],
		Color = Color3.Red[500]
	};
	S = {
		Orientations = {
			{{0,1}, {1,1}, {1,0}, {2,0}};
			{{1,0}, {1,1}, {2,1}, {2,2}};
			{{2,1}, {1,1}, {1,2}, {0,2}};
			{{1,2}, {1,1}, {0,1}, {0,0}};
		}, 
		Kicks = JLSZTKicks,
		RenderDiff = JLSZTRenderDiff,
		SpawnDiff = JLSZTKickBases[2][1],
		Color = Color3.Green[500]
	};
}

_G.LineData = {
	ClearNames = {
		[0] = "",
		"Single",
		"Double",
		"Triple",
		"Four"
	}
};

--Valkyrie:GetComponent"Overlay".Open();

game.Players.LocalPlayer.PlayerGui:SetTopbarTransparency(0);
local InitGame = require(script.RemoteManager).Init;
local GameManager = require(script.GameManager);
game.Players.LocalPlayer.CharacterAdded:connect(function() InitGame({Matrix = {}, Minos = {}, PendingLines = {}, Die = GameManager.Die, FirstTime = true}, GameManager.Die, GameManager.RunGame) end);
InitGame({Matrix = {}, Minos = {}, PendingLines = {}, Die = GameManager.Die, FirstTime = true}, GameManager.Die, GameManager.RunGame);
IntentService:BroadcastRPCIntent("ServerLoaded");
