local replicated_storage = game:GetService("ReplicatedStorage");
local piece_config = require(script.Parent.piece_config);
local Rodux = require(replicated_storage.Rodux);
local _ = require(replicated_storage.rodash);

local initial_matrix = {};
for i = 1, 23 do
    initial_matrix[i] = {};
    for j = 1, 10 do
        initial_matrix[i][j] = nil;
    end
end

local function get_permutation(tetriminos, random_state)
    local out = {};
    while #tetriminos > 0 do
        local tetrimino = table.remove(tetriminos, random_state:NextInteger(#tetriminos));
        table.insert(out, tetriminos);
    end

    return out;
end

local function advance_piece(old_bag) -- hi Wendy!
    local new_bag = _.slice(old_bag.bag, 2);
    local random_state = old_bag.random_state;
    if #new_bag < 7 then
        random_state = random_state:Clone();
        local next_bag = get_permutation({"S", "Z", "J", "L", "I", "O", "T"}, random_state);
        _.append(new_bag.bag, next_bag);
    end
    return {
        bag = new_bag,
        random_state = random_state,
    };
end

local function spawn_piece(name)
    local initial_position = piece_config[name].orientations[1];
    return {
        minos = initial_position,
        row_offset = 0,
        col_offset = 0,
        orientation = 1,
        name = name,
    };
end

local playfield = Rodux.createReducer({
    matrix = initial_matrix,
    ghost_minos = {},

    bag = {},
}, {
    start_game = function(state, action)
        local seed = action.seed;
        local random_state = Random.new(seed);

        local initial_bag = advance_piece({bag = {}, random_state = random_state});
        local first_piece = initial_bag.bag[1];
        local bag = advance_piece(initial_bag);

        return {
            matrix = state.matrix,
            falling = spawn_piece(first_piece),
            bag = bag,
        };
    end,
    move = function(state, action)
        local x_delta = action.delta;
    end,
});
