local UIManager 	= {};

local Valkyrie 		= _G.ValkyrieC;
local GameContainer = game.Players.LocalPlayer.PlayerGui.Tetris.GameContainer;
local RewardDisplay = GameContainer.MainFieldContainer.RewardDisplay;
local Config 		= GameContainer.Config;
local ConfigButton 	= Config.UpdateConfig;

local RunService	= game:GetService "RunService";
local ConfigTable	= require(script.Parent.Config);

local ValkyrieInput	= Valkyrie:GetComponent "ValkyrieInput";

local RenderStepConnection, UpdateConfigAction, CurrentGameState;

function UIManager.SetRewardText(GameState, Text)
	if Text == "" then
		return;
	end
	
	GameState.RewardDisplayCounter = 0;
	RewardDisplay.Text = Text;
end

function UIManager.Init(GameState)
	RewardDisplay.Text = "";
	GameState.RewardDisplayCounter = 0;
	
	if RenderStepConnection then
		RenderStepConnection:disconnect();
	end

	RenderStepConnection = RunService.RenderStepped:connect(function(DeltaTime)
		GameState.RewardDisplayCounter = GameState.RewardDisplayCounter + DeltaTime;
		if GameState.RewardDisplayCounter >= 3 then
			RewardDisplay.Text = "";
			GameState.RewardDisplayCounter = 0;
		end
	end);
	CurrentGameState = GameState;
	
	if not UpdateConfigAction then
		UpdateConfigAction = ValkyrieInput:CreateAction("TetrisUpdateConfig", function()
			ConfigTable.DAS							= tonumber(Config:FindFirstChild("DASDelayValue", true).Text);
			ConfigTable.DASDebounce					= tonumber(Config:FindFirstChild("DASDebounceValue", true).Text);
			ConfigTable.DASGravityDenominator		= tonumber(Config:FindFirstChild("DASGravityDenominatorValue", true).Text);
			ConfigTable.DASGravityNumerator			= tonumber(Config:FindFirstChild("DASGravityNumeratorValue", true).Text);
			ConfigTable.SoftDropDelay				= tonumber(Config:FindFirstChild("SoftDropDelayValue", true).Text);
			ConfigTable.SoftDropGravityDenominator	= tonumber(Config:FindFirstChild("SoftDropGravityDenominatorValue", true).Text);
			ConfigTable.SoftDropGravityNumerator	= tonumber(Config:FindFirstChild("SoftDropGravityNumeratorValue", true).Text);
			
			CurrentGameState:RebindActions();
		end);
	end
	UpdateConfigAction:BindButtonPress(ConfigButton);
end

return UIManager;
