%Simulation Powergrid Version 1
clear h
%the three different states could be rewritten into another matrix/array? But maybe this makes reading hard
% initial Parameters
global b_capacity
global b_weight
global fuel_energy
global turbine_eff %efficiency of fuel conversation to thrust
global plane_weight
global soc %state of charge
global usable_batt %usable battery energy

%input matrices for the three flight phases
% first value determines the duration of the flight phase in seconds; second line: first value stands for availabe electric power in kW
% second value stand for availabe fuel-based power in kW; third line: first value represents power consumption by electric motors
% second value represents power consumption by fuel-powered motors in kW, third value all other electric power
%same format for all matrices, power consuption in kW; no changes during flight phases assumed
global T
global C
global L

global battery_energy_cost %cost of one kWh in cents
global fuel_energy_cost %cost of one kg of kerosine/ fuel

%initializing co2 emission variables for calculating entire CO2 emissions
global batt_co2_emis
global fuel_co2_emis

global time_step
global max_fuel_burn
global drag_coefficient
global lift_coefficient
global wing_area
global eps_effi
global air_density
global sim_poss
global kerosene_weight
global op_cost_hour
global cruise_speed
global threshold
global eff_fuel2el
%initial values

T = [ 300 0 0; 750 1170 0; 525 350 75] ;
C = [ 1800 0 0; 750 1170 0; 300 250 100];
L = [ 300 0 0; 750 1170 0; 100 150 50];

sim_poss = 1; %1 for possible, zero for not possible
%battery
b_weight = 2018; %battery weight in kg
b_capacity = 504.5; %usable battery capacity in kWh, so the efficiency is already calculated into
soc = 0.9;
usable_batt = b_capacity * soc; %initial availabe energy in battery

%fuel
fuel_energy = 7129.29; %usable energy provided by fuel in kWh (kerosene_weight * 11.9 * turbine_eff)
turbine_eff = 0.3; %Cps efficiency

plane_weight = 4603;
battery_energy_cost = 20; %battery energy costs in cents per kWh
fuel_energy_cost = 50; % in cents per kWh
batt_co2_emis = 486; % in g/kWh
fuel_co2_emis = 255; % in g/kWh
time_step = 0.5; 
max_fuel_burn = 0.083; %in kg/s
drag_coefficient = 0.05; 
lift_coefficient = 1.4;
wing_area = 33.2; % in m^2
eps_effi = 0.8;
air_density = 0.5895; %kg/m^3
kerosene_weight = fuel_energy / 11.9 / turbine_eff; %kg
op_cost_hour = 300; %€/h 
cruise_speed = 315; %km/h
threshold = 0.2 %SOC of the battery when only fuel based energy is used 

%a surplus (more energy availabe than used) of fuel based energy is converted to electric energy and stored in batteries 
eff_fuel2el = 0.5; %conversation efficiency, remains the same during all flight phases

%Gui Functionality
%initializing figure element
f = figure('Name', 'Main GUI Window');

%initializing plot section of main GUI window
h.ax = axes ("position", [0.1 0.4 0.5 0.5]);

%GUI elements initialization
%print Figure Button
h.print_pushbutton = uicontrol ("style", "pushbutton", "units", "normalized", "string", "Print plot", "position", [0.75 0.53 0.2 0.09], "callback", @updateGUI);

%open plot in new figure
h.newplotfigure_pushbutton = uicontrol ("style", "pushbutton", "units", "normalized", "string", "Open plot", "position", [0.75 0.64 0.2 0.09], "callback", @updateGUI);  
                           
%grid checkbox
h.grid_checkbox = uicontrol ("style", "checkbox", "units", "normalized", "string", "show grid","value", 0, "position", [0.05 0.2 0.35 0.09], "callback", @updateGUI);

%minor grid togglebutton
h.minor_grid_toggle = uicontrol ("style", "togglebutton", "units", "normalized", "string", "Minor grid", "value", 0, "position", [0.25 0.2 0.18 0.09], "callback", @updateGUI);

%simulation executable led
%creates the led depending on the simulation possible state
ellipse_position = [0.95 0.773 0.02 0.03];

h.sim_exe_led = annotation('ellipse',ellipse_position,'facecolor', [1 1 1]);


%creates label for led
h.sim_exe_label = uicontrol ("style", "text", "units", "normalized", "string", "Executed:", "horizontalalignment", "left", "position", [0.75 0.75 0.16 0.08]);

%Simulate Button
h.simulate_button = uicontrol ("style", "pushbutton", "units", "normalized", "string", "SIMULATE", "position", [0.75 0.85 0.2 0.09], 'callback', @updateGUI); 

%threshold field; determines when it should be switched from using battery energy to only fuel instead
h.threshold_label = uicontrol ("style", "text", "units", "normalized", "string", "Battery Threshold (SOC) (0-1):", "horizontalalignment", "left", "position", [0.05 0.1 0.45 0.08]);
h.threshold_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.5 0.105 0.09 0.06], "callback", @updateGUI);

%plot battery
h.plot_battery_button = uicontrol ("style", "pushbutton", "units", "normalized", "string", "Plot battery", "position", [0.75 0.42 0.2 0.09], 'callback', @updateGUI);

%sets background colour to grey; gcf returns a figure handle
set (gcf, "color", get(0, "defaultuicontrolbackgroundcolor")) %changes the background colour of the window
guidata (gcf, h); %assigns the ui elements to the figure frame


%input figure
figure('Name', 'Input Variables')

%takeoff Section
%labels
inpu.takeoff_intro_label = uicontrol ("style", "text", "units", "normalized", "string", "Takeoff", "horizontalalignment", "left", "position", [0.01 0.94 0.3 0.08], 'FontWeight', 'bold');
inpu.tao_duration_label = uicontrol ("style", "text", "units", "normalized", "string", "Duration (s):", "horizontalalignment", "left", "position", [0.01 0.87 0.25 0.08]);
inpu.tao_elprov_label = uicontrol ("style", "text", "units", "normalized", "string", "Provided el power (kW):", "horizontalalignment", "left", "position", [0.01 0.8 0.35 0.08]);
inpu.tao_fuelprov_label = uicontrol ("style", "text", "units", "normalized", "string", "Provided fuel power (kW):", "horizontalalignment", "left", "position", [0.01 0.73 0.35 0.08]);
inpu.tao_eltaken_label = uicontrol ("style", "text", "units", "normalized", "string", "Consumed power (el)(kW):", "horizontalalignment", "left", "position", [0.01 0.66 0.4 0.08]);
inpu.tao_fueltaken_label = uicontrol ("style", "text", "units", "normalized", "string", "Consumed power (fuel)(kW):", "horizontalalignment", "left", "position", [0.01 0.59 0.42 0.08]);
inpu.tao_othertaken_label = uicontrol ("style", "text", "units", "normalized", "string", "Consumed pow (other)(kW):", "horizontalalignment", "left", "position", [0.01 0.52 0.42 0.08]);

%input boxes
inpu.tao_duration_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.875 0.09 0.06], "callback", @writeInput); %duration of takeoff
inpu.tao_elprov_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.805 0.09 0.06], 'callback', @writeInput); %provided electric energy
inpu.tao_fuelprov_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.735 0.09 0.06], 'callback', @writeInput); %provided fuel energy
inpu.tao_eltaken_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.665 0.09 0.06], 'callback', @writeInput); %el energy taken
inpu.tao_fueltaken_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.595 0.09 0.06], 'callback', @writeInput); %fuel energy taken
inpu.tao_othertaken_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.525 0.09 0.06], 'callback', @writeInput); %other energy taken


%cruise section
%labels
inpu.cruise_intro_label = uicontrol ("style", "text", "units", "normalized", "string", "Cruise", "horizontalalignment", "left", "position", [0.52 0.94 0.3 0.08], 'FontWeight', 'bold');
inpu.cruise_duration_label = uicontrol ("style", "text", "units", "normalized", "string", "Duration (s):", "horizontalalignment", "left", "position", [0.52 0.87 0.25 0.08]);
inpu.cruise_elprov_label = uicontrol ("style", "text", "units", "normalized", "string", "Provided el power (kW):", "horizontalalignment", "left", "position", [0.52 0.8 0.35 0.08]);
inpu.cruise_fuelprov_label = uicontrol ("style", "text", "units", "normalized", "string", "Provided fuel power (kW):", "horizontalalignment", "left", "position", [0.52 0.73 0.35 0.08]);
inpu.cruise_eltaken_label = uicontrol ("style", "text", "units", "normalized", "string", "Consumed power (el)(kW):", "horizontalalignment", "left", "position", [0.52 0.66 0.4 0.08]);
inpu.cruise_fueltaken_label = uicontrol ("style", "text", "units", "normalized", "string", "Consumed power (fuel)(kW):", "horizontalalignment", "left", "position", [0.52 0.59 0.42 0.08]);
inpu.cruise_othertaken_label = uicontrol ("style", "text", "units", "normalized", "string", "Consumed pow (other)(kW):", "horizontalalignment", "left", "position", [0.52 0.52 0.42 0.08]);

%input boxes
inpu.cruise_duration_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.91 0.875 0.09 0.06], 'callback', @writeInput); %cruise duration
inpu.cruise_elprov_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.91 0.805 0.09 0.06], 'callback', @writeInput); %el energy provided
inpu.cruise_fuelprov_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.91 0.735 0.09 0.06], 'callback', @writeInput); %fuel energy provided
inpu.cruise_eltaken_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.91 0.665 0.09 0.06], 'callback', @writeInput); %el energy taken
inpu.cruise_fueltaken_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.91 0.595 0.09 0.06], 'callback', @writeInput); %fuel energy taken
inpu.cruise_othertaken_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.91 0.525 0.09 0.06], 'callback', @writeInput); %other energy taken


%landing section
%labels
inpu.landing_intro_label = uicontrol ("style", "text", "units", "normalized", "string", "Landing", "horizontalalignment", "left", "position", [0.01 0.42 0.3 0.08], 'FontWeight', 'bold');
inpu.landing_duration_label = uicontrol ("style", "text", "units", "normalized", "string", "Duration (s):", "horizontalalignment", "left", "position", [0.01 0.35 0.3 0.08]);
inpu.landing_elprov_label = uicontrol ("style", "text", "units", "normalized", "string", "Provided el power (kW):", "horizontalalignment", "left", "position", [0.01 0.28 0.35 0.08]);
inpu.landing_fuelprov_label = uicontrol ("style", "text", "units", "normalized", "string", "Provided fuel power (kW):", "horizontalalignment", "left", "position", [0.01 0.21 0.35 0.08]);
inpu.landing_eltaken_label = uicontrol ("style", "text", "units", "normalized", "string", "Consumed power (el)(kW):", "horizontalalignment", "left", "position", [0.01 0.14 0.4 0.08]);
inpu.landing_fueltaken_label = uicontrol ("style", "text", "units", "normalized", "string", "Consumed power (fuel)(kW):", "horizontalalignment", "left", "position", [0.01 0.07 0.45 0.08]);
inpu.landing_othertaken_label = uicontrol ("style", "text", "units", "normalized", "string", "Consumed pow (other)(kW):", "horizontalalignment", "left", "position", [0.01 0 0.4 0.08]);

%input boxes
inpu.landing_duration_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.355 0.09 0.06], 'callback', @writeInput); %landing duration
inpu.landing_elprov_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.285 0.09 0.06], 'callback', @writeInput); %%el energy provided
inpu.landing_fuelprov_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.215 0.09 0.06], 'callback', @writeInput); %fuel energy provided
inpu.landing_eltaken_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.145 0.09 0.06], 'callback', @writeInput); %el energy taken
inpu.landing_fueltaken_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.075 0.09 0.06], 'callback', @writeInput); %fuel energy taken
inpu.landing_othertaken_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.41 0.005 0.09 0.06], 'callback', @writeInput); %other energy taken


%Energy sources
%labels; CPS relates to conventional propulsion system
inpu.energy_src_label = uicontrol ("style", "text", "units", "normalized", "string", "Energy Sources", "horizontalalignment", "left", "position", [0.52 0.42 0.3 0.08], 'FontWeight', 'bold'); %heading of section
inpu_battery_capa_label = uicontrol ("style", "text", "units", "normalized", "string", "Battery Capacity (kWh):", "horizontalalignment", "left", "position", [0.52 0.35 0.35 0.08]); %battery capacity label
inpu.battery_weight_label = uicontrol ("style", "text", "units", "normalized", "string", "Battery Weight (kg):", "horizontalalignment", "left", "position", [0.52 0.28 0.3 0.08]); %battery weight
inpu.battery_SOC_tao = uicontrol ("style", "text", "units", "normalized", "string", "SOC takeoff(0-1):", "horizontalalignment", "left", "position", [0.52 0.21 0.3 0.08]); %battery State of Charge at start of journey
inpu.kerosene_weight_label = uicontrol ("style", "text", "units", "normalized", "string", "Kerosene Weight (kg):", "horizontalalignment", "left", "position", [0.52 0.14 0.3 0.08]); %kerosene weight
inpu.turbine_eff_label = uicontrol ("style", "text", "units", "normalized", "string", "CPS efficiency (0-1):", "horizontalalignment", "left", "position", [0.52 0.07 0.33 0.08]); %turbine efficiency
inpu.fuel2el_label = uicontrol ("style", "text", "units", "normalized", "string", "Fuel2El efficiency (0-1):", "horizontalalignment", "left", "position", [0.52 0.0 0.33 0.08]);

%input boxes
inpu.battery_capa_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.85 0.355 0.09 0.06], 'callback', @writeInput); %battery capacity
inpu.battery_weight_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.85 0.285 0.09 0.06], 'callback', @writeInput); %battery weight
inpu.batter_SOC_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.85 0.215 0.09 0.06], 'callback', @writeInput);
inpu.kerosene_weight_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.85 0.145 0.09 0.06], 'callback', @writeInput); %kerosene weight
inpu.turbine_eff_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.85 0.075 0.09 0.06], 'callback', @writeInput); %turbine efficiency
inpu.fuel2el_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.85 0.005 0.09 0.06], 'callback', @writeInput);

set (gcf, "color", get(0, "defaultuicontrolbackgroundcolor"))
guidata(gcf, inpu);


%Insight Panel
figure('name', 'Insights')

%input cost labels
insight.cost_label = uicontrol ("style", "text", "units", "normalized", "string", "Costs", "horizontalalignment", "left", "position", [0.01 0.94 0.3 0.06], 'FontWeight', 'bold');
insight.batt_cost_label = uicontrol ("style", "text", "units", "normalized", "string", "Battery costs (cent/kWh):", "horizontalalignment", "left", "position", [0.01 0.88 0.345 0.06]);
insight.fuel_cost_label = uicontrol ("style", "text", "units", "normalized", "string", "Fuel costs (cent/kg):", "horizontalalignment", "left", "position", [0.01 0.82 0.3 0.06]);
insight.other_cost_label = uicontrol ("style", "text", "units", "normalized", "string", "Operation costs (€/h):", "horizontalalignment", "left", "position", [0.01 0.76 0.3 0.06]); %other operating costs per hour, average during whole flight

%input cost boxes 
insight.batt_cost_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.51 0.885 0.09 0.06], 'callback', @calculateMeasures);
insight.fuel_cost_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.51 0.825 0.09 0.06], 'callback', @calculateMeasures);
insight.other_cost_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.51 0.765 0.09 0.06], 'callback', @calculateMeasures);

%overall costs battery
insight.overall_cost_batt_label = uicontrol ("style", "text", "units", "normalized", "string", "Overall energy costs battery (€):", "horizontalalignment", "left", "position", [0.01 0.67 0.43 0.06]);
insight.overall_cost_batt_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.45 0.669 0.2 0.06]);

%overall costs fuel
insight.overall_cost_fuel_label = uicontrol ("style", "text", "units", "normalized", "string", "Overall energy costs fuel (€):", "horizontalalignment", "left", "position", [0.01 0.61 0.4 0.06]);
insight.overall_cost_fuel_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.45 0.609 0.2 0.06]);

%total costs flight
insight.total_cost_label = uicontrol ("style", "text", "units", "normalized", "string", "Total costs flight (€):", "horizontalalignment", "left", "position", [0.65 0.88 0.4 0.06]);
insight.total_cost_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.7 0.819 0.2 0.06]);

%input CO2
insight.co2_heading = uicontrol ("style", "text", "units", "normalized", "string", "CO2 Emissions", "horizontalalignment", "left", "position", [0.01 0.51 0.3 0.06], 'FontWeight', 'bold');
insight.batt_co2_label = uicontrol ("style", "text", "units", "normalized", "string", "Battery CO2 emissions (g/kWh):", "horizontalalignment", "left", "position", [0.01 0.45 0.45 0.06]);
insight.fuel_co2_label = uicontrol ("style", "text", "units", "normalized", "string", "Fuel CO2 emissions (g/kWh):", "horizontalalignment", "left", "position", [0.01 0.39 0.45 0.06]);

%input CO2 boxes
insight.batt_co2_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.51 0.455 0.09 0.06], 'callback', @calculateMeasures);
insight.fuel_co2_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.51 0.395 0.09 0.06], 'callback', @calculateMeasures);

%overall CO2 batt
insight.overall_emis_batt_label = uicontrol ("style", "text", "units", "normalized", "string", "Overall CO2 emissions battery (kg):", "horizontalalignment", "left", "position", [0.01 0.30 0.48 0.06]);
insight.overall_emis_batt_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.5 0.299 0.15 0.06]);

%overall CO2 fuel
insight.overall_emis_fuel_label = uicontrol ("style", "text", "units", "normalized", "string", "Overall CO2 emissions fuel (kg):", "horizontalalignment", "left", "position", [0.01 0.24 0.48 0.06]);
insight.overall_emis_fuel_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.5 0.239 0.15 0.06]);

%total CO2 emissions
insight.total_co2_label = uicontrol ("style", "text", "units", "normalized", "string", "Total CO2 emissions \nflight (kg):", "horizontalalignment", "left", "position", [0.65 0.5 0.48 0.1]);
insight.total_co2_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.7 0.42 0.15 0.06]);

%Degree of Hybridization; is based on CONCEPTUAL STUDIES OF FUTURE HYBRID-ELECTRIC REGIONAL AIRCRAFT, more covered in the written thesis
insight.degree_hybrid_label = uicontrol ("style", "text", "units", "normalized", "string", "Degree of hybridization", "horizontalalignment", "left", "position", [0.01 0.14 0.48 0.06], 'FontWeight', 'bold');
insight.installed_power_label = uicontrol ("style", "text", "units", "normalized", "string", "Ratio installed Power:", "horizontalalignment", "left", "position", [0.01 0.08 0.48 0.06]);
insight.installed_power_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.45 0.079 0.2 0.06]);
insight.installed_energy_label = uicontrol ("style", "text", "units", "normalized", "string", "Ratio installed Energy:", "horizontalalignment", "left", "position", [0.01 0.01 0.48 0.06]);
insight.installed_energy_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.45 0.009 0.2 0.06]);

%combined energy density of energy storage (kerosine and battery combined)
insight.combined_dens_label = uicontrol ("style", "text", "units", "normalized", "string", "Combined energy \ndensity (kWh/kg):", "horizontalalignment", "left", "position", [0.65 0.7 0.6 0.1]);
insight.combined_dens_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.7 0.62 0.2 0.06]);

%calculate Button
insight.calculate = uicontrol ("style", "pushbutton", "units", "normalized", "string", "CALCULATE", "position", [0.65 0.05 0.32 0.09], 'callback', @calculateMeasures);

set (gcf, "color", get(0, "defaultuicontrolbackgroundcolor"))
guidata(gcf, insight);

%Power/ ESAR figure
figure('name', 'Metrics')

metric.key_figures = uicontrol ("style", "text", "units", "normalized", "string", "Key figures", "horizontalalignment", "left", "position", [0.01 0.94 0.48 0.06], 'FontWeight', 'bold');
%total EPS efficiency
metric.overall_eps_effi_label = uicontrol ("style", "text", "units", "normalized", "string", "Efficiency EPS (0-1):", "horizontalalignment", "left", "position", [0.01 0.74 0.48 0.06]); %total efficiency of electric propulsion system
metric.overall_eps_effi_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.4 0.74 0.09 0.06], 'callback', @calculateMetrics); 

%wing area
metric.wing_area_label = uicontrol ("style", "text", "units", "normalized", "string", "Wing Area (m^2):", "horizontalalignment", "left", "position", [0.01 0.81 0.48 0.06]);
metric. wing_area_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.4 0.81 0.09 0.06], 'callback', @calculateMetrics);

%plane weight
metric.plane_weight_label = uicontrol ("style", "text", "units", "normalized", "string", "Plane weight (kg):", "horizontalalignment", "left", "position", [0.01 0.88 0.33 0.06]);
metric.plane_weight_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.4 0.88 0.15 0.06], 'callback', @calculateMetrics);

%lift coefficient
metric.lift_coeff_label = uicontrol ("style", "text", "units", "normalized", "string", "Lift coefficient:", "horizontalalignment", "left", "position", [0.01 0.67 0.33 0.06]);
metric.lift_coeff_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.4 0.67 0.09 0.06], 'callback', @calculateMetrics);

%drag coefficient
metric.drag_coeff_label = uicontrol ("style", "text", "units", "normalized", "string", "Drag coefficient:", "horizontalalignment", "left", "position", [0.01 0.6 0.33 0.06]);
metric.drag_coeff_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.4 0.6 0.09 0.06], 'callback', @calculateMetrics);

%cruise height
metric.cruise_height_label = uicontrol ("style", "text", "units", "normalized", "string", "Cruise Height (km):", "horizontalalignment", "left", "position", [0.01 0.53 0.33 0.06]);
metric.cruise_height_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.4 0.53 0.09 0.06], 'callback', @calculateMetrics);

%maximum fuel burn at full power(fitting definition in this case), only in cruise
metric.fuel_burn_label = uicontrol ("style", "text", "units", "normalized", "string", "Max Fuel burn (kg/s):", "horizontalalignment", "left", "position", [0.01 0.39 0.33 0.06]);
metric.fuel_burn_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.4 0.39 0.09 0.06], 'callback', @calculateMetrics);

%simulation time step
metric.time_step_label = uicontrol ("style", "text", "units", "normalized", "string", "Time Step (s):", "horizontalalignment", "left", "position", [0.01 0.46 0.33 0.06]);
metric.time_step_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.4 0.46 0.09 0.06], 'callback', @calculateMetrics);

%cruising speed in km/h, reference is the aircraft, no wind, is assumend to constant during cruise
metric.cruise_speed_label = uicontrol ("style", "text", "units", "normalized", "string", "Cruising Speed (km/h):", "horizontalalignment", "left", "position", [0.01 0.32 0.33 0.06]);
metric.cruise_speed_box = uicontrol ("style", "edit", "units", "normalized", "string", "", "position", [0.4 0.32 0.09 0.06], 'callback', @calculateMetrics);

%Energy specific air range as depicted in ELECTRICALLY POWERED PROPULSION: COMPARISON AND CONTRAST TO GAS TURBINES
metric.esar_label =  uicontrol ("style", "text", "units", "normalized", "string", "ESAR:", "horizontalalignment", "left", "position", [0.6 0.88 0.48 0.06]);
metric.esar_button = uicontrol ("style", "pushbutton", "units", "normalized", "string", "Plot ESAR", "position", [0.7 0.87 0.25 0.09], 'callback', @calculateMetrics);

%Thrust specific Power consuption as defined in ELECTRICALLY POWERED PROPULSION: COMPARISON AND CONTRAST TO GAS TURBINES
%as hybrid aircrafts have two sources of thrust, efficiency needs to adjusted, therefore the installed power degree of hybridization
metric.tspc_label = uicontrol ("style", "text", "units", "normalized", "string", "TSPC (m/s):", "horizontalalignment", "left", "position", [0.6 0.8 0.48 0.06]);
metric.tspc_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.78 0.8 0.2 0.06]);

%calculate button
metric.calc_button = uicontrol ("style", "pushbutton", "units", "normalized", "string", "CALCULATE", "position", [0.65 0.05 0.32 0.09], 'callback', @calculateMetrics);

%plot weight over time button
metric.plot_weight_button = uicontrol ("style", "pushbutton", "units", "normalized", "string", "Plot weight", "position", [0.65 0.15 0.32 0.09], 'callback', @calculateMetrics);

%plot required power over time button
metric.plot_power_button = uicontrol ("style", "pushbutton", "units", "normalized", "string", "Plot required power", "position", [0.65 0.25 0.32 0.09], 'callback', @calculateMetrics);

%hybrid range
metric.range_label = uicontrol ("style", "text", "units", "normalized", "string", "Hybrid Range(km):","horizontalalignment", "left", "position", [0.6 0.72 0.48 0.06]);
metric.range_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.85 0.72 0.15 0.06]);

%electric range
metric.elrange_label = uicontrol ("style", "text", "units", "normalized", "string", "Electric range(km):", "horizontalalignment", "left", "position", [0.6 0.64 0.48 0.06]);
metric.elrange_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.86 0.64 0.15 0.06]);

%conventional range
metric.conrange_label = uicontrol ("style", "text", "units", "normalized", "string", "Conv. range(km):", "horizontalalignment", "left", "position", [0.6 0.56 0.25 0.06]);
metric.conrange_display = uicontrol ("style", "text", "units", "normalized", "string", "", "position", [0.83 0.56 0.18 0.06]);

%power exceed led
ellipse_position_ex = [0.965 0.465 0.02 0.03];
metric.power_exceed_label = uicontrol ("style", "text", "units", "normalized", "string", "Required Power supplied!", "horizontalalignment", "left", "position", [0.6 0.45 0.335 0.06]);
metric.power_exceed_led = annotation('ellipse',ellipse_position_ex,'facecolor', [1 1 1]);

set (gcf, "color", get(0, "defaultuicontrolbackgroundcolor"))
guidata(gcf, metric);