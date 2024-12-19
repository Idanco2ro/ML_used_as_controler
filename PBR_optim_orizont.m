clear; close all; clc;

%% PARAMETRI

L = 0.054;      % Adâncimea PBR [m]
Ea = 200;       % Coeficientul de absorbție în masă [m2/kg]
Es = 870;       % Coeficientul de dispersie în masă [m2/kg]
b = 0.0008;     % Fracțiunea de dispersie înapoi [-]

mumax = 0.21692;
Ks = 101.2637;
Kn = 0.13236;
Ynx = 0.043508;
mud = 0.010177;

%% INTRĂRI

I0 = 500;       % INTRARE - intensitatea luminii incidente [µmol photon/m2/s]
D = linspace(0,0.1,100);

Nin = 2;        % nitratul la intrare [g/L]
X0 = 0.1;       % condiția inițială pentru X
N0 = 1.5;       % concentrația inițială de N (nitrat)

%% Diferite orizonturi de optimizare
StopTimes = [300, 250, 200, 150, 100, 50, 10];
culori = ['r', 'g', 'b', 'm', 'c', 'k', 'cyan']; % Am înlocuit galbenul cu cyan

figure;
for k = 1:length(StopTimes)
    StopTime = StopTimes(k);
    
    % Inițializarea array-urilor pentru stocarea rezultatelor simulării
    X = zeros(length(D), 1);
    N = zeros(length(D), 1);
    P = zeros(length(D), 1);
    
    for i = 1:length(D)
        simIn = Simulink.SimulationInput('PBR_process_prod'); 
        simIn = simIn.setModelParameter('StopTime', num2str(StopTime));
        simIn = simIn.setBlockParameter('PBR_process_prod/Dilution', 'Value', num2str(D(i))); 
        simOut = sim(simIn);
        
        X(i) = simOut.yout{1}.Values.Data(end);
        N(i) = simOut.yout{2}.Values.Data(end);
        P(i) = simOut.yout{3}.Values.Data(end);
    end
    
    % Găsirea ratei de diluție optime
    D_opt = fminbnd(@(D) optimizare(D, StopTime), 0, 0.1);
    [P_opt, X_ref] = optimizare(D_opt, StopTime);
    
    % Plotarea rezultatelor
    subplot(311)
    plot(D, X, 'o', 'Color', culori(k)); hold on
    plot(D_opt, X_ref, 'o', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
    line([D_opt D_opt], [0 X_ref], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.5)
    xlabel('Diluția (1/oră)'); ylabel('Concentrația de biomasă (g/L)')
    hold on; grid on; grid minor
    
    subplot(312)
    plot(D, N, 'o', 'Color', culori(k)); hold on
    xlabel('Diluția (1/oră)'); ylabel('Concentrația de azot anorganic (g/L)')
    hold on; grid on; grid minor
    
    subplot(313)
    plot(D, P, 'o', 'Color', culori(k)); hold on
    plot(D_opt, -P_opt, 'o', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
    line([D_opt D_opt], [0 -P_opt], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.5)
    xlabel('Diluția (1/oră)'); ylabel('Productivitate (g/L/h)')
    hold on; grid on; grid minor
    
    % Afișarea referinței optime pentru control
    fprintf('Referința optimă pentru StopTime = %d este X_ref = %.4f\n', StopTime, X_ref);
end

subplot(311)
legend(arrayfun(@(x) ['StopTime = ', num2str(x)], StopTimes, 'UniformOutput', false));

subplot(312)
legend(arrayfun(@(x) ['StopTime = ', num2str(x)], StopTimes, 'UniformOutput', false));

subplot(313)
legend(arrayfun(@(x) ['StopTime = ', num2str(x)], StopTimes, 'UniformOutput', false));

% Funcția de optimizare
function [P, X] = optimizare(D, StopTime)
    simIn = Simulink.SimulationInput('PBR_process_prod');
    simIn = simIn.setModelParameter('StopTime', num2str(StopTime));
    simIn = simIn.setBlockParameter('PBR_process_prod/Dilution', 'Value', num2str(D));
    simOut = sim(simIn);
    X = simOut.yout{1}.Values.Data(end);
    P = -simOut.yout{3}.Values.Data(end);
end