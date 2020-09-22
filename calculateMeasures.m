function calculateMeasures (obj_handle, event)
  global battery_energy_cost 
  global fuel_energy_cost
  global y_fuel
  global fuel_energy
  global el_consumed_sum
  global sim_poss
  global batt_co2_emis
  global fuel_co2_emis
  global usable_batt
  global T
  global C
  global L 
  global kerosene_weight
  global b_weight
  global op_cost_hour
  global power_ratio
  global energy_ratio
  global comb_ener_dens

  h = guidata (obj_handle);
  
  %used up energy of fuel
  fuel_sum = fuel_energy - y_fuel(4);
  
  switch(gcbo)
    case{h.batt_cost_box} %write battery costs
      temp = get(gcbo, 'string');
      battery_energy_cost = str2num(temp);
    
    case{h.fuel_cost_box} %write fuel costs
      temp = get(gcbo, 'string');
      fuel_energy_cost = str2num(temp); %reminder: costs per kg kerosene
      
    case{h.batt_co2_box} %write batt co2 costs
      batt_co2_emis = str2num(get(gcbo, 'string'));
      
    case{h.fuel_co2_box} %write fuel co2 costs
      fuel_co2_emis = str2num(get(gcbo, 'string'));

    case{h.other_cost_box} %write other costs
      op_cost_hour = str2num(get(gcbo, 'string')); 
      
    %calculate Button
    case{h.calculate}
      if sim_poss
        %costs
        fuel_cost = fuel_sum * fuel_energy_cost / 11.9 /100; %kWh/kg specific energy of kerosene

        %electric based energy, only takes the preloaded energy into account, so rechargement during flight does not account in this section
        el_costs = el_consumed_sum * battery_energy_cost /100;
        
        %write these two values in the overall cost fields
        set(h.overall_cost_fuel_display, 'string', num2str(fuel_cost)) %fuel costs
        set(h.overall_cost_batt_display, 'string', num2str(el_costs)) %electrical energy costs
        
        %emissions
        fuel_co2_sum = fuel_sum * fuel_co2_emis / 1000; %returns overall emitted CO2 by fuel in kg
        el_co2_sum = el_consumed_sum * batt_co2_emis / 1000; %returns overall emitted CO2 by batteries in kg
        
        set(h.overall_emis_fuel_display, 'string', num2str(fuel_co2_sum)) %fuel emissions
        set(h.overall_emis_batt_display, 'string', num2str(el_co2_sum)) %electrical emissions
        
        %total emissions
        tot_co2 = fuel_co2_sum + el_co2_sum
        set(h.total_co2_display, 'string', num2str(tot_co2))
        
        %degree of hybridization
        %energy ratio; this ratio compares the total installed electrical energy to the total energy (including fuel); the values represents the state of hybridization 
        %before takeoff in this implementation
        energy_ratio = usable_batt / (usable_batt + fuel_energy);
        set(h.installed_energy_display, 'string', num2str(energy_ratio))
        
        %power ratio
        %similar to the energy ratio, but this time the total installed (usefull) electrical power is divided by the total installed power
        %in this implementation the maximum of installed power in all three flight phases is used
        %generating an array with all installed power ratios
        installed_power_el = [T(2,1) C(2,1) L(2,1)];
        installed_power_fuel = [T(2,2) C(2,2) L(2,2)];
        
        max_power_el = max(installed_power_el);
        max_power_fuel = max(installed_power_fuel);
        power_ratio = max_power_el / (max_power_el + max_power_fuel);
        set(h.installed_power_display, 'string', num2str(power_ratio))
        
        %combined energy density calculation, the combined energy density is calculated based on the usable energy of the battery and the kerosene energy adjusted by the efficiency
        comb_ener_dens = (usable_batt + fuel_energy) / (b_weight + kerosene_weight); %kWh/kg
        set(h.combined_dens_display, 'string', num2str(comb_ener_dens))
        
        %total operating costs
        total_energy_costs = fuel_cost + el_costs; 
        operating_costs = op_cost_hour * ((T(1,1)+C(1,1)+L(1,1))/3600);
        total_op_cost = total_energy_costs + operating_costs;
        
        set(h.total_cost_display, 'string', num2str(total_op_cost))
      end
end