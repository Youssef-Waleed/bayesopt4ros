function cfg_vh = vehicle_lin_Liniger(cfg_vh)
% adapts vehicle to linear Liniger model
cfg_vh.description = [cfg_vh.description '\nwith linear model & params from ST Liniger'];

%% somewhat optimized (HockenheimShort, SL & SCR)
cfg_vh.p.Q = 1; % weight for maximization of position on track
cfg_vh.p.R = diag([.1 .1]); % weight for control changes over time
cfg_vh.p.trust_region_size = 1.6; % [m] adds/subtracts to position (SL only)

%% Model
% CAVE: model params should match across controller and simulation model
cfg_vh.model_controller_handle = @model.vehicle.Linear;
cfg_vh.modelParams_controller = model.vehicle.Linear.getParamsSingleTrackLiniger(cfg_vh.p.dt_controller, cfg_vh.dataFileSingleTrackAMax);
cfg_vh.model_simulation_handle = cfg_vh.model_controller_handle;
% CAVE FIXME linear models get simulated differently --> using
% `dt_controller` instead of `dt_simulation` for now
cfg_vh.modelParams_simulation = model.vehicle.Linear.getParamsSingleTrackLiniger(cfg_vh.p.dt_controller, cfg_vh.dataFileSingleTrackAMax);