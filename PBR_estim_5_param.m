clear;

%% PARAMETRII
L = 0.054;      % Adâncimea PBR [m]
Ea = 200;       % Coeficient de absorbție a masei [m²/kg]
Es = 870;       % Coeficient de împrăștiere a masei [m²/kg]
b = 0.0008;     % Fracțiunea de împrăștiere inversă [-]

% Inițializare parametrii pentru optimizare
params_initial = [0.17, 135, 0.149, 0.245, 0.01];   % [mumax, Ks, Kn, Ynx, mud]
lb = [0, 0, 0, 0, 0];   % Limite inferioare pentru parametri
ub = [1, 300, 10, 1, 0.1]; % Limite superioare pentru parametri

%% INTRĂRI
I0 = 500;       % Intensitatea luminii incidente [µmol photon/m²/s]
D = 0;          % Dilutie
Nin = 1;        % Nitratul la intrare [g/L]
X0 = 0.1;       % Condiție inițială pentru X
N0 = 2;         % Concentrația inițială de N (nitrat)

%% DATE EXPERIMENTALE
texp =    [0   24  48  72  96  120 144 168];
Biomass = [0.1 0.7 1.3 1.7 2.1 2.4 2.6 2.8];

% Plot date experimentale
figure;
subplot(2,1,1)
plot(texp, Biomass, 'ok', 'MarkerFaceColor', 'k');
xlabel('Timp (ore)'); ylabel('Concentrația de biomasă (g/L)')
title('Date experimentale - Biomasă')
hold on; grid; grid minor

%% ESTIMAREA PARAMETRILOR
options = optimset('Display', 'iter', 'TolFun', 1e-8, 'TolX', 1e-8);
[param_optim, fval] = fminsearch(@(params) objectiveFunction(params, texp, Biomass), params_initial, options);

% Afișarea rezultatelor
disp('Parametrii optimizați:');
disp(param_optim);
disp('Valoarea funcției obiectiv:');
disp(fval);

% Setarea parametrilor optimizați în workspace
assignin('base', 'mumax', param_optim(1));
assignin('base', 'Ks', param_optim(2));
assignin('base', 'Kn', param_optim(3));
assignin('base', 'Ynx', param_optim(4));
assignin('base', 'mud', param_optim(5));

%% Simularea și Plotarea modelului optimizat
StopTime = 300;
simIn = Simulink.SimulationInput('PBR_process');
simIn = simIn.setModelParameter("StopTime", num2str(StopTime));
simIn = simIn.setBlockParameter("PBR_process/Light", "Value", num2str(I0));
simOutOpt = sim(simIn);

% Plot model optimizat (Biomasă)
subplot(2,1,1)
plot(simOutOpt.tout, simOutOpt.yout{1}.Values.Data, 'g')
legend('Date experimentale', 'Model optimizat')

% Plot model optimizat (Azot)
subplot(2,1,2)
plot(simOutOpt.tout, simOutOpt.yout{2}.Values.Data, 'g')
xlabel('Timp (ore)'); ylabel('Concentrația de azot anorganic (g/L)')
title('Model optimizat - Azot')
legend('Model optimizat')
hold on; grid; grid minor

% Parametrii optimizați
disp(['mumax_opt = ', num2str(param_optim(1))]);
disp(['Ks_opt = ', num2str(param_optim(2))]);
disp(['Kn_opt = ', num2str(param_optim(3))]);
disp(['Ynx_opt = ', num2str(param_optim(4))]);
disp(['mud_opt = ', num2str(param_optim(5))]);
disp(['Error_min = ', num2str(fval)]);

% Plotare parametrii inițiali și optimizați
param_names = {'mumax', 'Ks', 'Kn', 'Ynx', 'mud'};
param_initial = params_initial;
param_optimized = param_optim;

for i = 1:length(param_names)
    figure;
    
    % Simulăm modelul pentru parametrii inițiali și optimizați
    assignin('base', 'mumax', param_initial(1));
    assignin('base', 'Ks', param_initial(2));
    assignin('base', 'Kn', param_initial(3));
    assignin('base', 'Ynx', param_initial(4));
    assignin('base', 'mud', param_initial(5));
    simOutInit = sim(simIn);
    
    assignin('base', 'mumax', param_optim(1));
    assignin('base', 'Ks', param_optim(2));
    assignin('base', 'Kn', param_optim(3));
    assignin('base', 'Ynx', param_optim(4));
    assignin('base', 'mud', param_optim(5));
    simOutOpt = sim(simIn);
    
    % Grafic pentru Biomasă
    subplot(2,1,1)
    plot(texp, Biomass, 'ok', 'MarkerFaceColor', 'k');
    hold on;
    plot(simOutInit.tout, simOutInit.yout{1}.Values.Data, 'b');
    plot(simOutOpt.tout, simOutOpt.yout{1}.Values.Data, 'g');
    xlabel('Timp (ore)');
    ylabel('Concentrația de biomasă (g/L)');
    title(['Parametru: ', param_names{i}, ' - Biomasă']);
    legend('Date experimentale', 'Initial', 'Optimized');
    grid on;
    
    % Grafic pentru Azot
    subplot(2,1,2)
    plot(simOutInit.tout, simOutInit.yout{2}.Values.Data, 'b');
    hold on;
    plot(simOutOpt.tout, simOutOpt.yout{2}.Values.Data, 'g');
    xlabel('Timp (ore)');
    ylabel('Concentrația de azot anorganic (g/L)');
    title(['Parametru: ', param_names{i}, ' - Azot']);
    legend('Initial', 'Optimized');
    grid on;
end

% Grafic 3D pentru toți parametrii
figure;
bar3([param_initial; param_optimized]);
set(gca, 'XTickLabel', param_names);
title('Parametrii inițiali și optimizați');
legend({'Initial', 'Optimized'});

% Adăugare tabel cu parametrii inițiali și optimizați
param_data = [param_initial; param_optimized]';
figure;
uitable('Data', param_data, 'RowName', param_names, 'ColumnName', {'Initial', 'Optimized'}, ...
        'Units', 'Normalized', 'Position', [0, 0, 1, 1]);
title('Tabel cu parametrii inițiali și optimizați');

% Funcția obiectivă
function error = objectiveFunction(params, texp, Biomass)
    % Extrage parametrii
    mumax = params(1);
    Ks = params(2);
    Kn = params(3);
    Ynx = params(4);
    mud = params(5);
    
    % Simularea modelului cu parametrii curenți
    StopTime = 300; % Poți ajusta timpul de simulare după necesitate
    simIn = Simulink.SimulationInput('PBR_process');
    simIn = simIn.setModelParameter("StopTime", num2str(StopTime));
    simIn = simIn.setBlockParameter("PBR_process/Growth Rate/Kinetic Model (Monod)/Gain", "Gain", num2str(mumax));
    simIn = simIn.setBlockParameter("PBR_process/Growth Rate/Kinetic Model (Monod)/Constant", "Value", num2str(Ks));
    simIn = simIn.setBlockParameter("PBR_process/Growth Rate/Kinetic Model (Monod)/Constant1", "Value", num2str(Kn));
    simIn = simIn.setBlockParameter("PBR_process/Gain", "Gain", num2str(Ynx));
    simIn = simIn.setBlockParameter("PBR_process/Growth Rate/Gain", "Gain", num2str(mud));
    simOut = sim(simIn);

    % Extrage rezultatele simulării
    t_sim = simOut.tout;
    x_sim = simOut.yout{1}.Values.Data;
    
    % Interpolarea rezultatelor pentru a se potrivi cu punctele de timp observate
    x_interpolated = interp1(t_sim, x_sim, texp);
    
    % Calcularea erorii ca sumă a pătratelor diferențelor
    error = sum((Biomass - x_interpolated).^2);
end
