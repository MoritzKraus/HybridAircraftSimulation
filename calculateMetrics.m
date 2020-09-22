function calculateMetrics (obj_h, event)
  global time_step
  global plane_weight
  global max_fuel_burn
  global drag_coefficient
  global air_density
  global wing_area
  global lift_coefficient
  global C
  global T
  global m_plot
  global time
  global esar_plot
  global eps_effi
  global b_weight
  global kerosene_weight
  global cruise_speed
  global power_ratio
  global turbine_eff
  global power_plot
  global energy_ratio
  global b_capacity
  global sim_poss
  global comb_ener_dens
  
  h = guidata (obj_h);
  recalc = false;
  
  switch(gcbo)
    case{h.overall_eps_effi_box} %write total EPS efficiency
      eps_effi = str2num(get(gcbo, 'string'));
      
    case{h.wing_area_box}
      wing_area = str2num(get(gcbo, 'string'));
      
    %plane weight
    case{h.plane_weight_box}
      temp = str2num(get(gcbo, 'string'));
      plane_weight = temp;
    
    case{h.lift_coeff_box} %lift coefficient
      lift_coefficient = str2num(get(gcbo, 'string'));
      
    case{h.drag_coeff_box} %drag coefficient
      drag_coefficient = str2num(get(gcbo, 'string'));
      
    case{h.cruise_height_box} %air density at cruise height; expected to be constant
      %air_density = str2num(get(gcbo, 'string'));
      cruise_height = str2num(get(gcbo, 'string'));
      t_c = 288.15 + ((-6.5) * cruise_height);
      p_c = 101.325 * (t_c/288.15).^(5.26);
      
     air_density = p_c / (0.287 * t_c);
      
    case{h.fuel_burn_box} %max fuel burn
      max_fuel_burn = str2num(get(gcbo, 'string'));

    case{h.time_step_box}
      time_step = str2num(get(gcbo, 'string'));
      
    case{h.calc_button}
      recalc = true;
    case{h.cruise_speed_box}
      cruise_speed = str2num(get(gcbo, 'string'));
    
    case{h.plot_weight_button}
      figure('Name', 'Plane mass plot');
      plot(time, m_plot)
      
      %formatting plot
      title('Plane mass in cruise')
      xlabel('time in s')
      ylabel('Mass in kg')
      
    case{h.esar_button}
      figure('Name','Energy specific air range plot');
      plot(time, esar_plot)
      
      %formatting plot
      title('ESAR during cruise') %explanation in the thesis, why ESAR is time-dependant
      xlabel('time in s')
      ylabel('ESAR in 1/N')
      
    case{h.plot_power_button}
      figure('Name', 'Required power to stay in cruise')
      plot(time, power_plot)
      
      %formatting plot
      title('Required power to stay in cruise')
      xlabel('time in s')
      ylabel('Required power in kW')
  end
  
  %calculation
    if(recalc & sim_poss)
      help_len = C(1,1) / time_step;
      
      %will be used later to plot the mass 
      m_plot = [];
      time = [];
      
      %fuel burnt during take-off
      tao_burnt = T(2,2) * (T(1,1)/3600) / 11.9 / turbine_eff %kerosene energy density
      
      m = plane_weight + b_weight + kerosene_weight -tao_burnt; %temp mass
      power_av = 1;
      
      %plot ESAR
      esar_plot = [];
      
      %plot required power
      power_plot = [];
      
      %required power exceed boolean
      power_req_ex = 1;
      
      avg_effi = ((power_ratio * eps_effi) + ((1-power_ratio)*turbine_eff)); %this is the average efficiency from energy source to thrust
      
      for i=1:help_len
        %calculate power need and mass lost
        %required power to stay in cruise in Watts
        p_req = sqrt((2 * (m*9.81).^3 * drag_coefficient.^2) / (air_density * wing_area * lift_coefficient.^3)) / 1000; %required power in kW
        
        %cheching if supplied power is enough to stay in cruise; else power_req_ex to false
        if (p_req/avg_effi) >= (C(2,2)+C(2,1))
          power_av = 1;
          power_req_ex = 0;
        else
          power_av = ((p_req/turbine_eff) / (C(2,1)+C(2,2)) * (C(2,2)/(C(2,1)+ C(2,2))));
        end
        
        %calculate ESAR over time, lift-to-drag ratio is espected to be constant during cruise
        esar = (avg_effi * (lift_coefficient/drag_coefficient)) / (m * 9.81);
        
        fuel_burnt = max_fuel_burn * time_step * power_av; %return value is in kg
        remaining_fuel = kerosene_weight - fuel_burnt; 
        
        if remaining_fuel <= 0 %if all fuel is burnt, no mass change
          fuel_burnt = 0;
        end
        
        m = m - fuel_burnt; %new plane mass
        
        m_plot(i) = m;
        time(i) = time_step * i;
        esar_plot(i) = esar;
        power_plot(i) = p_req;
      end
      
      %calculate TSPC
      tspc = cruise_speed / avg_effi;
      set(h.tspc_display, 'string', num2str(tspc))
      
      
      %calculate range
      lift_drag = lift_coefficient / drag_coefficient; %no dimensions
      fuel_coefficient = (11.9 * 1000 * 3600) / 9.81;  %Hfuel g assumed to be constant; J/m/s^2 --> m
      log_factor = log((plane_weight + kerosene_weight + b_weight)/(b_weight + plane_weight)) %no dimensions
      log_factor2 = log((kerosene_weight+plane_weight)/plane_weight)
      
      efficiency_coefficient = (1-power_ratio) * turbine_eff + eps_effi * power_ratio %no dimensions
      hy_range = lift_drag * ((comb_ener_dens * 1000 * 3600)/9.81) * efficiency_coefficient * log_factor /1000 %km should be
      set(h.range_display, 'string', num2str(hy_range))
      
      %calculate range all electric; hypothetical range of the aircraft with no fuel loaded, but fuel propulsion system still in place
      %based on Analysis and design of hybrid electric regional turboprop aircraft
      batt_dens = (b_capacity * 1000 * 3600)/b_weight
      el_range = eps_effi * lift_drag * (batt_dens/9.81) * (b_weight/(b_weight+ plane_weight))/1000;
      set(h.elrange_display, 'string', num2str(el_range))
      
      %calculate conventional range
      con_range = turbine_eff * fuel_coefficient * lift_drag * log((kerosene_weight+plane_weight)/plane_weight) /1000;
      set(h.conrange_display, 'string', num2str(con_range))
      
      %set power exceed led according to power_req_ex boolean state
      ellipse_position_bool = [0.965 0.465 0.02 0.03];
      
      if power_req_ex == 1
        h.power_exceed_led = annotation('ellipse',ellipse_position_bool,'facecolor', [0 1 0]);
      else
        h.power_exceed_led = annotation('ellipse',ellipse_position_bool,'facecolor', [1 0 0]);
      end
    end
end