function cfg_vh = base_vehicle(cfg)
% base configuration for any vehicle
%   contains all possible options
cfg_vh.description = 'base vehicle';

% required for ST to lin Liniger conversion
cfg_vh.dataFileSingleTrackAMax = [cfg.dataPath 'singleTrackAMax.mat'];

%% Controller: General Optimization
% cfg_vh.p.SCP_iterations = 2;
% % SL 1, SCR 2, Botz 1
% 
% % CAVE: needs at least 2 p.SCP_iterations
% cfg_vh.p.isBlockingEnabled = true;
% cfg_vh.p.areObstaclesConsidered = true;
% 
% cfg_vh.p.Hp = 20; % Number of prediction steps
% % SL 40, SCR 20, Botz 20, Liniger 40
% cfg_vh.p.dt_controller = 0.5; % [s] size of prediction step for controller
% % SL 0.15, SCR 0.5, Botz 0.1, Liniger 0.02
% 
% % simulation step size is only relevant, if a controller to transform
% %   inputs from controller to simulation model is neccessary.
% %   in other cases, MATLAB's ODE solvers choose step-sizes by themselves
% cfg_vh.p.dt_simulation = cfg_vh.p.dt_controller/10; % [s] size of simulation step
% 
% cfg_vh.p.S = 1e5; % weight for slack
% % SL 10, SCR 1e5, Botz 1e40, (Liniger 250)
% cfg_vh.p.Q = 10; % weight for maximization of position on track
% % SL 1, SCR 1, Botz 1, (Liniger 0.1 ... 10)
% cfg_vh.p.R = 10 * diag([10 .1]); % weight for control changes over time
% % SL 0.01, SCR 0.01, Botz 500, (Liniger 0.01 ... 1)
% cfg_vh.p.B = 10;
% 
% 
% %% Contoller: Miscellaneous Modelling
% % Acceleration: number of tangents around the ellipses
% cfg_vh.p.n_acceleration_limits = 16;
% 
% % Linearization (SL): size of Trust Region for position
% % FIXME scale trust region size with track
% cfg_vh.p.trust_region_size = 0.1;  % [m] adds/subtracts to position (SL only)
% % large trust region sizes yields more numerical issues or errors
% % SL 50, SCR not required, Botz 0.06
% 
% %% Controller: Approximation Method
% % arbitrary IDs, saved for later usage
% cfg_vh.approximationSL = 10; cfg_vh.approximationSCR = 20;
% % choose approximation
% cfg_vh.approximation = cfg_vh.approximationSCR; % 'approximationSL' or 'approximationSL'

cfg_vh.p.SCP_iterations = 1;
% SL 1, SCR 2, Botz 1

% CAVE: needs at least 2 p.SCP_iterations
cfg_vh.p.isBlockingEnabled = true;
cfg_vh.p.areObstaclesConsidered = true;

cfg_vh.p.Hp = 20; % Number of prediction steps
% SL 40, SCR 20, Botz 20, Liniger 40
cfg_vh.p.dt_controller = 0.15; % [s] size of prediction step for controller
% SL 0.15, SCR 0.5, Botz 0.1, Liniger 0.02

% simulation step size is only relevant, if a controller to transform
%   inputs from controller to simulation model is neccessary.
%   in other cases, MATLAB's ODE solvers choose step-sizes by themselves
cfg_vh.p.dt_simulation = cfg_vh.p.dt_controller/10; % [s] size of simulation step

cfg_vh.p.S = 10; % weight for slack
% SL 10, SCR 1e5, Botz 1e40, (Liniger 250)
cfg_vh.p.Q = 1; % weight for maximization of position on track
% SL 1, SCR 1, Botz 1, (Liniger 0.1 ... 10)
cfg_vh.p.R = 10 * diag([10 0.01]); % weight for control changes over time
% SL 0.01, SCR 0.01, Botz 500, (Liniger 0.01 ... 1)



%% Contoller: Miscellaneous Modelling
% Acceleration: number of tangents around the ellipses
cfg_vh.p.n_acceleration_limits = 16;

% Linearization (SL): size of Trust Region for position
% FIXME scale trust region size with track
cfg_vh.p.trust_region_size = 0.1;  % [m] adds/subtracts to position (SL only)
% large trust region sizes yields more numerical issues or errors
% SL 50, SCR not required, Botz 0.06

%% Controller: Approximation Method
% arbitrary IDs, saved for later usage
cfg_vh.approximationSL = 10; cfg_vh.approximationSCR = 20;
% choose approximation
cfg_vh.approximation = cfg_vh.approximationSL; % 'approximationSL' or 'approximationSL'
 
%% Model
% CAVE: model params should match across controller and simulation model
cfg_vh.model_controller_handle = @model.vehicle.Linear;
cfg_vh.modelParams_controller = model.vehicle.SingleTrack.getParamsLinigerRC_1_43_WithLinigerBounds();
cfg_vh.model_simulation_handle = cfg_vh.model_controller_handle;
cfg_vh.modelParams_simulation = model.vehicle.SingleTrack.getParamsLinigerRC_1_43_WithLinigerBounds();

%% Geometric
% xStart [pos_x pox_y v_x v_y yaw dyaw/dt] will be initialized to match model states
% grid start positions for 1 to 8 vehicles
cfg_vh.x_starts = [...
    [0.1  0.05 0 0 0 0]'...
    [0.5 -0.05 0 0 0 0]'...
    [0.9  0.05 0 0 0 0]'...
    [1.3 -0.05 0 0 0 0]'...
    [1.7  0.05 0 0 0 0]'...
    [2.1 -0.05 0 0 0 0]'...
    [2.5  0.05 0 0 0 0]'...
    [2.8 -0.05 0 0 0 0]'];
cfg_vh.x_start = cfg_vh.x_starts(:, 1);

% FIXME adapt to scale. Define in vehicle model
cfg_vh.lengthVal = 0.075; % obstacle's size measured along its direction of movement [m]
cfg_vh.widthVal = 0.045; % obstacle's size measured at right angels to its direction of movement[m]

% obstacles are modeled as rotated rectangles that can move with
% constant speed and direction.
cfg_vh.distSafe = 'Circle'; % Chose either 'Circle' or 'Ellipse' or 'CircleImpr' or 'EllipseImpr' 
cfg_vh.distSafe2CenterVal_1 = round(sqrt((cfg_vh.lengthVal/2)^2 + (cfg_vh.widthVal/2)^2),2,'significant');
cfg_vh.distSafe2CenterVal_2 = [0.09;0.06]; % Definition of ellipsis (two semi-axis)
end