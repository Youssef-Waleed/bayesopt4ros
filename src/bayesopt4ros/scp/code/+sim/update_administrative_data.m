function ws = update_administrative_data(cfg, ws)
% updates administrative data of working set to current status of 
%   simulation data
%   - current checkpoints, position, lap
%   - update blocking & obstacles tables

%% Current CP, position and lap
% Get current checkpoints (corresponding to x_0) and current laps
for i = 1:length(cfg.scn.vhs)
    % update checkpoints
    cp_curr = controller.track_SL.find_closest_checkpoint_index(...
        ws.vhs{i}.x_0(cfg.scn.vhs{i}.model_controller.idx_pos), cfg.scn.track_center);
    ws.vhs{i}.cp_prev = ws.vhs{i}.cp_curr;
    ws.vhs{i}.cp_curr = cp_curr;

    % if new lap
    %   CAVE may not be the most robust lap detection - depending on
    %   vehicle speed & discretization
    if (ws.vhs{i}.cp_prev ~= ws.vhs{i}.cp_curr) && ...
        (ws.vhs{i}.cp_prev > 0.9 * length(cfg.scn.track)) && ... % was in last 10% of lap
        (ws.vhs{i}.cp_curr < 0.1 * length(cfg.scn.track)) % now is in first 10% of lap
        % advance lap counter
        ws.vhs{i}.lap_count = ws.vhs{i}.lap_count + 1;
        % printing in red
        fprintf(2, '########## Vehicle %i has finished lap %i ##########\n', i, ws.vhs{i}.lap_count)
    end
end

% Determine relative positions of racing vehicles corresponding to
% current checkpoints and current laps
for i = 1:length(cfg.scn.vhs)
    ws.vhs{i}.pos = 1;
    for j = 1:length(cfg.scn.vhs)
        if (ws.vhs{i}.cp_curr < ws.vhs{1,j}.cp_curr) && ...
                (ws.vhs{i}.lap_count == ws.vhs{1,j}.lap_count) || ...
                (ws.vhs{i}.lap_count < ws.vhs{1,j}.lap_count)
            ws.vhs{i}.pos = ws.vhs{i}.pos + 1;
        end
    end
end

%% Determine obstacle relationship
% Set obstacle-matrix entry to 1 if vehicle of row has to respect
% vehicle in column as an obstacle, depending on the relativ
% positioning on the race track.
CP_halfTrack = length(cfg.scn.track)/2; % get checkpoint index at half of the track
for i = 1:length(cfg.scn.vhs) % ego vehicle
    for j = 1:length(cfg.scn.vhs) % opposing vehicles
        if (i ~= j) && (...
                ( (ws.vhs{i}.cp_curr < ws.vhs{1,j}.cp_curr) && ...
                ( (ws.vhs{1,j}.cp_curr - ws.vhs{i}.cp_curr) < CP_halfTrack ) ) || ...
                ( (ws.vhs{i}.cp_curr >= ws.vhs{1,j}.cp_curr) && ...
                ( (ws.vhs{i}.cp_curr - ws.vhs{1,j}.cp_curr) > CP_halfTrack ) ) || ...
                (ws.vhs{i}.cp_curr == ws.vhs{1,j}.cp_curr) )
           ws.obstacleTable(i,j) = 1;
        else
           ws.obstacleTable(i,j) = 0;
        end
    end
end

%% Determine Defending Relationship -> Blocking
for i = 1:length(cfg.scn.vhs) % ego vehicle
    for j = 1:length(cfg.scn.vhs) % opposing vehicles
       if (i ~= j) && ...
               ( norm(ws.vhs{i}.x_0(3:4)) < norm(ws.vhs{1,j}.x_0(3:4)) ) && ...
               ( ws.obstacleTable(i,j) == 0 ) && ...
               ( ( norm(ws.vhs{i}.x_0(1:2) - ws.vhs{1,j}.X_controller(1:2,1)) <= 0.1 ) )%|| ...
                 % outcomment if future trajectory points should be considered
                 %( norm(ws.vhs{i}.x_0(1:2) - ws.vhs{j}.X_controller(1:2, 2)) <= 0.3 ) || ...
                 %( norm(ws.vhs{i}.x_0(1:2) - ws.vhs{j}.X_controller(1:2, 3)) <= 0.3 ) )
           ws.blockingTable(i,j) = 1;
       else
           ws.blockingTable(i,j) = 0;
       end
    end
end