function output_file = run(cfg)

BayesoptEnable = true;

if BayesoptEnable
    [~,hostname] = system('hostname');
    hostname = string(strtrim(hostname));
    address = resolvehost(hostname,"address");
    portNumber=5000;
    % Created Server
    server = tcpserver(address,portNumber,"Timeout",300)
    %     pythonScript = 'C:/Users/youse/PycharmProjects/bayesopt4ros/src/bayesopt4ros/main.py';

    %     % Call the Python script
    %     [status, result] = system(['python ', pythonScript]);

    % Check the result
    %     if status == 0
    %         disp('Python script executed successfully:');
    %         disp(result);
    %     else
    %         disp('Error executing Python script:');
    %         disp(result);

    while true
        if server.Connected > 0
            % Break out of the loop
            disp("connected")
            break;
        end

        % Sleep for a short interval before checking again
        pause(0.1);
    end
    read(server, 1 , 'double');
    disp("model ready");
end
numberOfSteps = 0;



% Used Abbreviations
%   ws:     abbreviation of working set, the struct which acts as "RAM".
%           Contains only current status; every step is saved in log
%               all variables are assumed to be simulation data, exceptions
%               are declared (e.g. controller internal data with postfix
%               "_controller")
%   cp:     abbreviation of checkpoint, the points which define the track path
%   cfg:    configuration
%   scn:    scenario
%   vhs:    vehicles

%% Initialization
timer_overall = tic;

if verLessThan('matlab', '9.10')
    warning('This is an old MATLAB version. Not all features of the software will work')
end

% initialization of objects etc.
cfg = config.init_config(cfg);
cfg.race.n_laps = 15;
bayesoptvehicle = 6; %index of vehicle that will use bayesopt parameter tuning
parameter_training_frequency = 10; %frequency of updating parameters
random_param_frequency = 140; %frequency of randomzing opp params
%cfg = config.init_config(scenarios(41));
% initialize working and logging structures
step_sim = 0;
ws = sim.init_ws(cfg);
log = sim.init_log(ws, cfg);
upcomingCorners = [];
c = 1;
while c < length(cfg.scn.track)
    if cfg.scn.track(c).isTurn
        upcomingCorners(end+1) = c;
        while cfg.scn.track(c).isTurn
            c = c + 1;
        end
    end
    c = c + 1;
end
disp(upcomingCorners);
% init controls
ctl_race_ongoing = true; % true until user ends or first vehicle finishes
global ctl_abort ctl_pause
init_control_keys(cfg.plot.plots_to_draw);

%% Execute Control & Simulation Loop
disp('########################')
disp('#- Starting race loop -#')
% try
LastCheckPoint = ws.vhs{bayesoptvehicle}.cp_curr;
egoPosition = ws.vhs{bayesoptvehicle}.pos;
firstIter = true;
LastCheckPointOpp = 0;
BayestimeSum = 0.0;
BayesSteps = 0;
BayestimeMax = -1.0;
BayestimeMin = 10000.0;
uQ = 1.13;
lQ = 0.95;
uR = 1.01;
lR = 0.99;
uB = 1.05;
lB = 0.95;

lap10 = 6;
lap15 = 6;

rand_Q = (lQ-uQ).*rand(1) + uQ
rand_R = (lR-uR).*rand(1) + uR
rand_B = (lB-uB).*rand(1) + uB

while ctl_race_ongoing
    fprintf('------------------------- Step %i -------------------------\n', step_sim);

    step_sim = step_sim + 1;
    timer_loop = tic;

    %% Controller Execution
    for i = 1:length(cfg.scn.vhs)
        %% Measuring
        % "measure reality" (simulation) to models
        %   only required for linear control combined with single-track
        %   simulation models
        if cfg.scn.vhs{i}.isControlModelLinear && ~cfg.scn.vhs{i}.isSimulationModelLinear
            % convert  states from Single Track to Linear
            ws.vhs{i}.x_0_controller = model.vehicle.state_st2lin(ws.vhs{i}.x_0);
        else
            ws.vhs{i}.x_0_controller = ws.vhs{i}.x_0;
        end

        %% Controller Execution
        % prepare vehicle working set
        vhs = cell(1, length(ws.vhs));
        for k = 1:length(ws.vhs)
            vhs{k}.x_0 = ws.vhs{k}.x_0_controller;
            vhs{k}.X_opt = ws.vhs{k}.X_controller;
            if k == i
                vhs{k}.U_opt = ws.vhs{k}.U_controller;
            end
            vhs{k}.cp_curr = ws.vhs{k}.cp_curr;
        end
        %------------------------------------Sending__Reward__and__context------------------------------------------------

        %fetch context and send it to python model for vehicle 1 every
        %10 time steps

        %get leading and following opponents



        if i==bayesoptvehicle && BayesoptEnable

            leading_idx = -1;
            following_idx = -1;

            for v = 1:(length(ws.vhs))
                if v == bayesoptvehicle
                    continue;
                end
                if abs(ws.vhs{v}.pos-ws.vhs{bayesoptvehicle}.pos) == 1
                    if ws.vhs{v}.pos < ws.vhs{bayesoptvehicle}.pos
                        leading_idx = v;
                    else
                        following_idx = v;
                    end
                end
                if ws.vhs{v}.pos == ws.vhs{bayesoptvehicle}.pos
                    leading_idx = v;
                    following_idx = v;
                end

            end
            % %---------single----opp--context-------------------------------------------
            %                 % get nearest opponent
            %                 minDist = 10000;
            %                 nearest_idx = -1;
            %
            %                 for v = 1:(length(ws.vhs))
            %                     if v == bayesoptvehicle
            %                         continue;
            %                     end
            %                     if abs(ws.vhs{v}.cp_curr-ws.vhs{bayesoptvehicle}.cp_curr) < minDist
            %                         minDist = abs(ws.vhs{v}.cp_curr-ws.vhs{bayesoptvehicle}.cp_curr);
            %                         nearest_idx = v;
            %                     end
            %                 end
            % %--------------------------------------------------------------------------
%             if mod(numberOfSteps,random_param_frequency) == 0
%                 rand_Q = (lQ-uQ).*rand(1) + uQ;
%                 rand_R = (lR-uR).*rand(1) + uR;
%                 rand_B = (lB-uB).*rand(1) + uB;
%             end
            if mod(numberOfSteps,parameter_training_frequency) == 0
                Bayestime = tic;
                %disp(leading_idx);
                %disp(following_idx);

%--------------------fetch info about upcoming corner-------------------------
                closestCornerIdx = -1;
                cpDiff = 10000; %arbitrarly big number
                for c = 1:length(upcomingCorners)

                    if cpDiff < 0 %reset when last corner is passed
                        cpDiff = 10000;
                    end

                    if  upcomingCorners(c) > ws.vhs{bayesoptvehicle}.cp_curr && ((upcomingCorners(c) - ws.vhs{bayesoptvehicle}.cp_curr) < cpDiff)
                        cpDiff = upcomingCorners(c) - ws.vhs{bayesoptvehicle}.cp_curr;
                        closestCornerIdx = upcomingCorners(c);
                    end

                    if (upcomingCorners(c) + length(cfg.scn.track) - ws.vhs{bayesoptvehicle}.cp_curr) < cpDiff
                        cpDiff = upcomingCorners(c) + length(cfg.scn.track) - ws.vhs{bayesoptvehicle}.cp_curr;
                        closestCornerIdx = upcomingCorners(c);
                    end
                end
%-----------------------------------------------------------------------------------------------------------------

                ego_progress = (ws.vhs{bayesoptvehicle}.cp_curr + ws.vhs{bayesoptvehicle}.lap_count*length(cfg.scn.track)) - LastCheckPoint;
                LastCheckPoint = ws.vhs{bayesoptvehicle}.cp_curr + ws.vhs{bayesoptvehicle}.lap_count*length(cfg.scn.track);
                %if ego vehicle already in first place, compare progress with nearest following opponent
                if leading_idx == -1
                    opp_progress = (ws.vhs{following_idx}.cp_curr + ws.vhs{following_idx}.lap_count*length(cfg.scn.track)) - LastCheckPointOpp;
                    LastCheckPointOpp = ws.vhs{following_idx}.cp_curr + ws.vhs{following_idx}.lap_count*length(cfg.scn.track);
                else
                    opp_progress = (ws.vhs{leading_idx}.cp_curr + ws.vhs{leading_idx}.lap_count*length(cfg.scn.track)) - LastCheckPointOpp;
                    LastCheckPointOpp = ws.vhs{leading_idx}.cp_curr + ws.vhs{leading_idx}.lap_count*length(cfg.scn.track);
                end

                if firstIter == true   % On first iteration, send a neutral reward

                    firstIter = false;
                    Reward = 1.0;

                else

                    % if ego postion stays the same, reward gaining on
                    % distance on nearest opponent

                    if ws.vhs{bayesoptvehicle}.pos == egoPosition

                        Reward = ego_progress/opp_progress;

                    else

                        % if position changes, reward advacing and punish
                        % falling behind

                        if ws.vhs{bayesoptvehicle}.pos > egoPosition
                            Reward = -3.0;
                        else
                            Reward = 3.0;
                        end
                        egoPosition = ws.vhs{bayesoptvehicle}.pos;
                        if ws.vhs{bayesoptvehicle}.lap_count <= 10
                            lap10 = 6 - ws.vhs{bayesoptvehicle}.pos;
                        else
                            lap15 = 6 - ws.vhs{bayesoptvehicle}.pos;
                        end
                    end
                end
                % %---------single----opp--context-------Reward------------------------------------
                %                     ego_progress = (ws.vhs{bayesoptvehicle}.cp_curr + ws.vhs{bayesoptvehicle}.lap_count*length(cfg.scn.track)) - LastCheckPoint;
                %                     LastCheckPoint = ws.vhs{bayesoptvehicle}.cp_curr + ws.vhs{bayesoptvehicle}.lap_count*length(cfg.scn.track);

                %                     if egoPosition == ws.vhs{bayesoptvehicle}.pos
                %                         Reward = ego_progress;
                %                     else
                %                         if egoPosition > ws.vhs{bayesoptvehicle}.pos
                %                             Reward = -2.0;
                %                         else
                %                             Reward = 2.0;
                %                         end
                %                     end
                %                     egoPosition = ws.vhs{bayesoptvehicle}.pos;
                %------------------------------------------------------------------------
                disp(Reward);
                flush(server);
                write(server, Reward, 'double');
%      fetch positional data
                p_x = ws.vhs{bayesoptvehicle}.x_0(1,:);
                p_y = ws.vhs{bayesoptvehicle}.x_0(2,:);
                v_x = ws.vhs{bayesoptvehicle}.x_0(3,:);
                v_y = ws.vhs{bayesoptvehicle}.x_0(4,:);

%                 procedure when nearest 2 vehicles are considered
                if leading_idx == -1
                    last = length(ws.vhs);
                    for v = 1:length(ws.vhs)
                        if ws.vhs{v}.pos == length(ws.vhs)
                            last = v;
                        end
                    end
                    p_L_rel = [ws.vhs{last}.x_0(1,:)-p_x,ws.vhs{last}.x_0(2,:)-p_y];
                    v_L_rel = [ws.vhs{last}.x_0(3,:)-v_x,ws.vhs{last}.x_0(4,:)-v_y];
                else
                    p_L_rel = [ws.vhs{leading_idx}.x_0(1,:)-p_x,ws.vhs{leading_idx}.x_0(2,:)-p_y];
                    v_L_rel = [ws.vhs{leading_idx}.x_0(3,:)-v_x,ws.vhs{leading_idx}.x_0(4,:)-v_y];
                end

                if following_idx == -1
                    first = 1;
                    for v = 1:length(ws.vhs)
                        if ws.vhs{v}.pos == 1
                            first = v;
                        end
                    end
                    p_F_rel = [ws.vhs{first}.x_0(1,:)-p_x,ws.vhs{first}.x_0(2,:)-p_y];
                    v_F_rel = [ws.vhs{first}.x_0(3,:)-v_x,ws.vhs{first}.x_0(4,:)-v_y];
                else
                    p_F_rel = [ws.vhs{following_idx}.x_0(1,:)-p_x,ws.vhs{following_idx}.x_0(2,:)-p_y];
                    v_F_rel = [ws.vhs{following_idx}.x_0(3,:)-v_x,ws.vhs{following_idx}.x_0(4,:)-v_y];
                end

                Pos = 0.0;

                if leading_idx == -1
                    Pos = 1.0;
                end

                if following_idx == -1
                    Pos = -1.0;
                end
%                 context = [cpDiff,(1/cfg.scn.track(closestCornerIdx).kappa)]; %Context for Corner models
                context = [p_L_rel,v_L_rel,p_F_rel,v_F_rel,Pos,cpDiff,cfg.scn.track(closestCornerIdx).kappa]; %Context for Combined models
%                 corner context
%                 context = [p_L_rel,v_L_rel,p_F_rel,v_F_rel,Pos]; %Context for relative models
%                   context = [1]; %incase of using BO instead of CBO to get average optimal parameters

                %---------------------single--opp--context--------------------
                %                     p_rel = [ws.vhs{nearest_idx}.x_0(1,:)-p_x,ws.vhs{1}.x_0(2,:)-p_y];
                %                     v_rel = [ws.vhs{nearest_idx}.x_0(3,:)-v_x,ws.vhs{1}.x_0(4,:)-v_y];
                %
                %                     context = [p_rel,v_rel];
                disp(context);

                %Send the array data
                flush(server);
                write(server, context, 'double');
                flush(server);
                disp('context sent to client.');

                while true
                    if server.NumBytesAvailable > 0
                        break;
                    end
                end

                New_Parameters = read(server, 3 , 'double');
                disp(New_Parameters)
                new_Q = New_Parameters(1);
                new_R = New_Parameters(2);
                new_B = New_Parameters(3);
                disp("bayesopt time:");
                BayesSteps = BayesSteps + 1;
                Bayestime = toc(Bayestime);
                disp(Bayestime);
                BayestimeSum = BayestimeSum + Bayestime;
                disp("AVG bayesopt_time:");
                disp(BayestimeSum/BayesSteps);
                if Bayestime > BayestimeMax
                    BayestimeMax = Bayestime;
                end
                if Bayestime < BayestimeMin
                    BayestimeMin = Bayestime;
                end
                disp("Max bayesopt_time:");
                disp(BayestimeMax);
                disp("Min bayesopt_time:");
                disp(BayestimeMin);
            end


            numberOfSteps = numberOfSteps + 1;
        end

        %--------------give_recieved_parameters_to_solver_if_it's_Bayes_vehicle's_turn----------------------------------

        if i == bayesoptvehicle && BayesoptEnable
            ws.vhs{i}.controller_output = controller.run_SCP(cfg,...
                vhs, ws.obstacleTable, ws.blockingTable, i, new_Q, new_R, new_B);
%               ws.vhs{i}.controller_output = controller.run_SCP(cfg,...
%                  vhs, ws.obstacleTable, ws.blockingTable, i, 2.3, 1.04, 0.5);
        else
            ws.vhs{i}.controller_output = controller.run_SCP(cfg,...
                vhs, ws.obstacleTable, ws.blockingTable, i, rand_Q, rand_R, rand_B);
        end

        % save payload (predicted trajectories) for easier access
        i_scp = find([ws.vhs{i}.controller_output.t_opt], 1, 'last');
        ws.vhs{i}.X_controller = ws.vhs{i}.controller_output(i_scp).X_opt;
        ws.vhs{i}.U_controller = ws.vhs{i}.controller_output(i_scp).U_opt;
        ws.vhs{i}.u_1 = ws.vhs{i}.U_controller(:, 1);

    end
    %% Visualization
    % Visualization plots x_0 (current state) of last time step and
    % predictions of Hp states x calculated in the current time step.
    % In other words - the visualization takes place before the
    % simulation/application of the control inputs.
    if cfg.plot.is_enabled
        for i = 1:length(cfg.plot.plots_to_draw)
            cfg.plot.plots_to_draw{i}.plot(cfg, ws);
        end
        drawnow
    end

    %% Simulation
    % compute input response / advance to next state/x_0
    for i = 1:length(cfg.scn.vhs)
        % if only simulation for main vehicle ("equipped" with
        % multiple controllers), copy it's x_0 to other vehicles
        % (which are only to compare controllers at each step)
        if cfg.scn.is_main_vehicle_only && i > 1
            % don't simulate
            continue
        end

        isCtrLin = cfg.scn.vhs{i}.isControlModelLinear;
        isSimLin = cfg.scn.vhs{i}.isSimulationModelLinear;
        % three cases:
        % Controller Model  Simulation Model
        %      Linear            Linear
        %      Linear         Single Track
        %   Single Track      Single Track
        if isSimLin && isCtrLin
            % equals to controller output `ws.vhs{i}.x_0 = ws.vhs{i}.controller_output.x(:,1)`;
            ws.vhs{i}.x_0_next = ws.vhs{i}.x_0 + cfg.scn.vhs{i}.model_simulation.ode(ws.vhs{i}.x_0, ws.vhs{i}.u_1);
            ws.vhs{i}.x_sim = nan;
        elseif ~isSimLin && isCtrLin
            [ws.vhs{i}.x_0_next,ws.vhs{i}.x_sim] = sim.simulate_ode(ws.vhs{i}.x_0, ws.vhs{i}.u_1, cfg.scn.vhs{i});
        elseif ~isSimLin && ~isCtrLin
            [ws.vhs{i}.x_0_next,ws.vhs{i}.x_sim] = sim.simulate_ode(ws.vhs{i}.x_0, ws.vhs{i}.u_1, cfg.scn.vhs{i});
        else
            % should never happen: why choose worse simulation model than controller?
            error('Combination of controller and simulation vehicle model types not supported')
        end
    end



    %% Log
    if cfg.log.level >= cfg.log.LOG
        % saving ws for vehicles seperately for easier access
        log.lap{end + 1} = rmfield(ws, 'vhs');

        for i = 1:length(cfg.scn.vhs)
            log.vehicles{i}(end + 1) = ws.vhs{i};
        end
    end


    %% Advance
    for i = 1:length(cfg.scn.vhs)
        % if only simulation for main vehicle ("equipped" with
        % multiple controllers), copy it's x_0 to other vehicles
        % (which are only to compare controllers at each step)
        if cfg.scn.is_main_vehicle_only && i > 1
            % copy trajectory of main vehicle to other controllers
            if ~cfg.scn.vhs{i}.isSimulationModelLinear
                ws.vhs{i}.x_0_next = ws.vhs{1}.x_0_next;
                ws.vhs{i}.X_controller = ws.vhs{1}.X_controller;
            else
                ws.vhs{i}.x_0_next = model.vehicle.state_st2lin(ws.vhs{1}.x_0_next);
                ws.vhs{i}.X_controller = model.vehicle.state_st2lin(ws.vhs{1}.X_controller);
            end
        end
    end

    % shift controller data acc. to simulation advance
    ws = controller.shift_prev_data(length(cfg.scn.vhs), ws);

    % updates adminstrative data of working set to current simulation
    % state
    ws = sim.update_administrative_data(cfg, ws);

    %% Execution control
    % Check if race finished (every vehicle reached n_laps finish line
    ctl_race_ongoing = false;
    for i = 1:length(cfg.scn.vhs)
        if ws.vhs{i}.lap_count < cfg.race.n_laps
            ctl_race_ongoing = true;
            break;
        end
    end

    %% enact user inputs
    if cfg.plot.is_enabled
        if ctl_pause; disp('Pause...'); end
        while true % pseudo do..while loop
            if ctl_abort % ..stop race
                disp('Aborted');
                ctl_race_ongoing = false;
                break;
            end
            if ~ctl_pause; break; end
            pause(0.1)
        end
    end
    fprintf('Loop time %4.0fms\n', toc(timer_loop) * 1000)
end

% catch ME
%     warning('#- Error in race loop -#')
% end
disp('#-  Ending race loop  -#')
disp('########################')
fprintf('Overall loop time %.2fs\n', toc(timer_overall))

%% Save
if cfg.log.level >= cfg.log.LOG
    % save all workspace variables, but not figures
    disp('Saving workspace')

    % remove figure handles, so they won't get saved
    cfg.plot.plots_to_draw = NaN;
    output_file = [cfg.outputPath '/log.mat'];
    save(output_file)
end

% if error occured in race loop
if exist('ME', 'var')
    warning('Error in race loop ocurred, rethrowing:')
    rethrow(ME)
end

%% Evaluation
% % Run example evaluation scipts
% evaluation.plot_t_opts()
% evaluation.plot_track_with_speed()

% % export all currently open figures (especially for CodeOcean)
% utils.exportAllFigures(cfg);
% fprintf(2, 'Result files (graphics, figures, logs) were saved in "%s"\n', cfg.outputPath)
end


function init_control_keys(plots_to_draw)
% initalize control keys on given plots
global ctl_abort ctl_pause
ctl_pause = false;
ctl_abort = false;

% Plot control: SPACE to pause, ESC to abort
    function key_press_callback(~,eventdata)
        if strcmp(eventdata.Key, 'escape')
            ctl_abort = true;
        elseif strcmp(eventdata.Key, 'space')
            ctl_pause = ~ctl_pause;
        end
    end

% enable callbacks on every plot
for i = 1:length(plots_to_draw)
    set(plots_to_draw{i}.figure_handle, ...
        'WindowKeyPressFcn', @key_press_callback);
end
end