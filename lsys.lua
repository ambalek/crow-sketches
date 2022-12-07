-- L System Note Generator
-- luacheck: globals init metro output justvolts pulse
-- ❓ A quick and dirty L-System note generator attempt

local rules = {
  A = { "C", "F", "G" },
  C = { "G", "F", "E" },
  E = { "F", "G", "B", "C" },
  F = { "G", "F" },
  G = { "C", "G", "F" }
}

local scale = { 0, 2, 4, 5, 7, 9, 11 }
local seq_index = 1
local note_index = 1
local sequences = { { "C" } }
local max_sequences = 8
local max_note_length = 32
local seq
local last_token

local function remove_oldest_sequence()
  if #sequences > max_sequences then
    print("remove_oldest_sequence")
    seq_index = seq_index - 1
    table.remove(sequences, 1) -- Removes first element from array
  end
end

local function token_to_volts(token)
  local token_volts = {
    C = 1,
    D = 9 / 8,
    E = 5 / 4,
    F = 4 / 3,
    G = 3 / 2,
    A = 5 / 3,
    B = 15 / 8,
  }
  -- Add a random octave
  return justvolts(token_volts[token] + math.random(0, 1))
end

local function random_timing()
  local random_timings = {
    0.5,
    1.0,
    4.0,
    6.0,
  }
  return random_timings[math.random(#random_timings)]
end

local function play_token(token)
  if token then
    if token ~= last_token then
      print("play_token: " .. token)
      output[1].volts = token_to_volts(token)
      -- I tune 1v to whatever scale I want, for example C
      -- output[1].volts = 1.0
      output[2](pulse(2.0))
    end
    last_token = token
  end
end

local function run_sequences()
  local current_sequence = sequences[seq_index]

  if note_index == #sequences[seq_index] then
    note_index = 1
    sequences[seq_index + 1] = {}
    for i = 1, #current_sequence do
      print("current_sequence[i]: " .. i .. " / " .. current_sequence[i] .. " seq_index: " .. seq_index)
      for j = 1, #rules[current_sequence[i]] do
        table.insert(sequences[seq_index + 1], rules[current_sequence[i]][j])
      end
    end
    for i = 1, #sequences[seq_index + 1] do
      print("note: " .. sequences[seq_index + 1][i])
    end
    if #sequences[seq_index + 1] > max_note_length then
      for _ = 1, #sequences[seq_index + 1] - max_note_length do
        table.remove(sequences[seq_index + 1], 1)
      end
    end
  end

  local current_token = sequences[seq_index][note_index]
  play_token(current_token)

  if seq_index < #sequences then
    seq_index = seq_index + 1
  end
  note_index = note_index + 1
  remove_oldest_sequence()
end

local function reclock()
  local time = random_timing()
  print("reclock engaged: " .. time)
  if seq then
    seq:stop()
    metro.free(seq.id)
  end
  seq = metro.init {
    event = run_sequences,
    time = time,
    count = -1
  }
  seq:start()
end

local function conditional_reclock()
  reclock()
end

function init()
  output[1].scale(scale, 12, 1.0)
  reclock()

  local reclock_timer = metro.init {
    event = conditional_reclock,
    time = 14,
    count = -1
  }
  reclock_timer:start()
end
