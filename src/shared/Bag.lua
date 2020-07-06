local replicated_storage = game:GetService("ReplicatedStorage");
local Rodux = require(replicated_storage.Rodux);

local function get_permutation(tetriminos, random_state)
	local out = {};
	while #tetriminos > 0 do
    	local tetrimino = table.remove(tetriminos, random_state:NextInteger(#tetriminos));
    	table.insert(out, tetriminos);
	end

	return out;
end

local NextPieceReducer = Rodux.createReducer({
	bag = {}, -- invariant: after initialization, this table will never have less than 7 pieces
	random_state = nil,
}, {
	initialize_randomizer = function(state, action)
		local random_state = Random.new(action.seed);

		return {
			bag = get_permutation({"S", "Z", "J", "L", "I", "O", "T"}, random_state),
			random_state = random_state,
		};
	end,
	advance_piece = function(state, action)
		local new_bag = {select(2, unpack(state.bag))};
		local random_state = state.random_state;
		if #new_bag < 7 then
    		random_state = random_state:Clone();
    		local next_bag = get_permutation({"S", "Z", "J", "L", "I", "O", "T"}, random_state);
    		table.move(next_bag, 1, #next_bag, #new_bag, new_bag);
		end
		return {
			bag = new_bag,
			random_state = random_state,
		}
	end,
});

return NextPieceReducer;
