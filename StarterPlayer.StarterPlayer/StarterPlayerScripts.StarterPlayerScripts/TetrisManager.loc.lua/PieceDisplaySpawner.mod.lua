local Valkyrie = _G.ValkyrieC;
Valkyrie:LoadLibrary "Util";
Valkyrie:LoadLibrary "Design";
wrapper.fixTables = true;

Valkyrie = _G.ValkyrieC;

local PieceDisplaySpawner = {};

local PieceData = _G.PieceData;

local Cache = {};

function PieceDisplaySpawner.CreatePiece(Name)
	local LocalPieceData = PieceData[Name:upper()];
	if not Cache[Name:upper()] then 
		local Children = {};
		for i = 1, 4 do
			table.insert(Children, new 'Frame':Instance {
				BorderSizePixel  = 0;
				BackgroundColor3 = LocalPieceData.Color;
				Size			 = new 'UDim2'(.25, 0, .25, 0);
				Position 		 = new 'UDim2'(.25 * (LocalPieceData.Orientations[1][i][1] + LocalPieceData.RenderDiff[1]), 0, .25 * (LocalPieceData.Orientations[1][i][2] + LocalPieceData.RenderDiff[2]), 0);
				Name 			 = "Mino" .. i;
			});
		end
		
		Cache[Name:upper()] = new 'Frame':Instance {
			BackgroundTransparency 	= 1;
			BorderSizePixel 		= 0;
			Size 					= new 'UDim2'(0,96,0,96);
			Children 				= {
				new 'Frame':Instance {
					BackgroundTransparency = 1;
					BorderSizePixel 	   = 0;
					Size 				   = new 'UDim2'(1,-4,1,-4);
					Position			   = new 'UDim2'(0,4,0,4);
					Children 			   = Children;
				}
			};
		};
	end
	
	return Cache[Name:upper()]:Clone(); 
end

return PieceDisplaySpawner;
