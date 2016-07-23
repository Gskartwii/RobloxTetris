local Randomizer = {};

math.randomseed(os.time());

local Pieces 	 = {"L", "J", "T", "I", "O", "S", "Z"};

function Randomizer.MakeBag()
	local Bag 	 = {};
	local Used 	 = {};
	
	for i = 1, 7 do
		local NewPiece;
		repeat NewPiece = math.random(7); until not Used[NewPiece]
		Used[NewPiece] = true;
		table.insert(Bag, Pieces[NewPiece]);
	end
	
	return Bag;
end

return Randomizer;
