-- Player completions: one record per player per puzzle completed
CREATE TABLE player_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id),
  puzzle_id UUID NOT NULL REFERENCES puzzles(id),
  difficulty_played TEXT NOT NULL CHECK (difficulty_played IN ('apprentice', 'resident', 'architect')),
  solve_seconds INTEGER NOT NULL,
  hints_used INTEGER DEFAULT 0,
  completed_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE player_completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Players can insert own completions"
  ON player_completions FOR INSERT
  WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Players can read own completions"
  ON player_completions FOR SELECT
  USING (auth.uid() = player_id);

CREATE UNIQUE INDEX idx_player_puzzle_unique ON player_completions(player_id, puzzle_id);
