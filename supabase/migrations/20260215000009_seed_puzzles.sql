-- Seed data: 14 days of CONDUIT puzzles (140 total)
-- 10 puzzles per day: 5 schematic (5x5) + 5 design (7x7)
-- Grid data is randomly scrambled; solution data holds the solved state.
-- Applied via Supabase apply_migration as 'seed_conduit_puzzles'

DO $$
DECLARE
  v_set_ids text[] := ARRAY[
    '4bb6e0b6-2af5-42e2-afce-8e2d455cec75',
    'f92e850f-e21c-4a0c-ac9d-b386a8cd5461',
    '758a9143-553f-498e-a211-a3d41bb056e2',
    '51114bda-f1ef-4484-ac03-714d23a78d36',
    '67711bd1-9e6c-4d96-98f8-54e6f5413de0',
    'fc782202-6aaa-41b1-a051-a36003677f2d',
    '0cf1041a-15d4-428f-8e8a-c4cedfde54a4',
    '831d4c37-799a-4e8d-96e5-900e83ec8a46',
    '789e0ca4-6f1f-4162-b5d9-1421244ae27f',
    '989821f7-7e08-4d65-820b-ac92a88722d8',
    'ed74c22d-b539-4048-a91e-3d0d9624faef',
    '27ac9887-0558-4bd5-adec-4114c72826cd',
    '3c8e6b10-185c-482d-a27a-c386b147ca24',
    '7cc2ba2b-fd08-425f-91cf-18db290379f4'
  ];
  v_modes text[] := ARRAY['schematic', 'design'];
  v_slot_tasks text[] := ARRAY[
    'Divide the development zone into service corridors for the conduit network.',
    'Mark the routing zones, ensuring no conduits cross restricted areas.',
    'Draft the connection blueprint showing all pipe junctions.',
    'Route the main conduit lines through the street grid.',
    'Connect the final service line and bring the system online.'
  ];
  v_set_id text;
  v_mode text;
  v_slot int;
  v_size int;
  v_diff numeric;
  v_grid jsonb;
  v_solution jsonb;
  v_cells jsonb;
  v_sol_cells jsonb;
  v_cell_types text[] := ARRAY['straight', 'corner', 'tee', 'end'];
  v_rotations int[] := ARRAY[0, 90, 180, 270];
BEGIN
  FOR i IN 1..14 LOOP
    v_set_id := v_set_ids[i];
    
    FOREACH v_mode IN ARRAY v_modes LOOP
      IF v_mode = 'schematic' THEN
        v_size := 5;
        v_diff := 3.0;
      ELSE
        v_size := 7;
        v_diff := 6.0;
      END IF;
      
      FOR v_slot IN 1..5 LOOP
        v_sol_cells := '[]'::jsonb;
        v_cells := '[]'::jsonb;
        
        FOR r IN 0..(v_size-1) LOOP
          FOR c IN 0..(v_size-1) LOOP
            DECLARE
              v_type text;
              v_rot int;
              v_scramble_rot int;
              v_is_even_row boolean := (r % 2 = 0);
              v_is_first boolean := (r = 0 AND c = 0);
              v_is_last boolean := (r = v_size - 1 AND 
                ((v_size % 2 = 1 AND c = v_size - 1) OR (v_size % 2 = 0 AND c = 0)));
            BEGIN
              IF v_is_first THEN
                v_type := 'corner'; v_rot := 90;
              ELSIF v_is_last THEN
                IF r = v_size - 1 AND c = v_size - 1 AND v_size % 2 = 1 THEN
                  v_type := 'end'; v_rot := 270;
                ELSIF r = v_size - 1 AND c = 0 AND v_size % 2 = 0 THEN
                  v_type := 'end'; v_rot := 90;
                ELSE
                  v_type := 'end'; v_rot := 0;
                END IF;
              ELSIF r = 0 AND c = v_size - 1 THEN
                v_type := 'corner'; v_rot := 180;
              ELSIF r = 0 AND c > 0 AND c < v_size - 1 THEN
                v_type := 'straight'; v_rot := 90;
              ELSIF c = v_size - 1 AND v_is_even_row AND r < v_size - 1 THEN
                v_type := 'corner'; v_rot := 180;
              ELSIF c = 0 AND NOT v_is_even_row AND r < v_size - 1 THEN
                v_type := 'corner'; v_rot := 270;
              ELSIF c = v_size - 1 AND NOT v_is_even_row AND r < v_size - 1 THEN
                v_type := 'corner'; v_rot := 90;
              ELSIF c = 0 AND v_is_even_row AND r > 0 AND r < v_size - 1 THEN
                v_type := 'corner'; v_rot := 0;
              ELSE
                v_type := 'straight'; v_rot := 90;
              END IF;
              
              v_scramble_rot := v_rotations[1 + floor(random() * 4)::int];
              
              v_sol_cells := v_sol_cells || jsonb_build_object('type', v_type, 'rotation', v_rot);
              v_cells := v_cells || jsonb_build_object('type', v_type, 'rotation', v_scramble_rot);
            END;
          END LOOP;
        END LOOP;
        
        v_grid := jsonb_build_object('width', v_size, 'height', v_size, 'cells', v_cells);
        v_solution := jsonb_build_object('width', v_size, 'height', v_size, 'cells', v_sol_cells);
        
        INSERT INTO puzzles (puzzle_set_id, puzzle_type, mode, slot_number, 
                            difficulty_score, grid_data, solution_data, task_description)
        VALUES (v_set_id::uuid, 'conduit', v_mode, v_slot,
                v_diff + (random() * 2 - 0.5),
                v_grid, v_solution, v_slot_tasks[v_slot]);
      END LOOP;
    END LOOP;
  END LOOP;
END $$;
