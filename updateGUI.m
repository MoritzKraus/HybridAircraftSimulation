function updateGUI (object_handle, event)
  global T
  global C
  global L
  global b_capacity
  global b_weight
  global fuel_energy
  global turbine_eff
  global x_el
  global y_el
  global x_fuel
  global y_fuel
  global sim_poss
  global soc %state of charge
  global usable_batt %usable battery energy
  global total_percentage
  global soc
  global threshold
  global eff_fuel2el
  global time_step
  global el_consumed_sum     %overall consumed electrical energy
  global eps_effi
  
  hand = guidata(object_handle);
  recalc = true;

  switch(gcbo)
  %open the new figure
    case{hand.newplotfigure_pushbutton}

      %defining new figure and importing global variables
      recalc = false;
      temp = figure('Name','Single Plot');
      
      x1 = x_el;
      y1 = y_el;
      
      x2 = x_fuel;
      y2 = y_fuel;

      plot(x1, y1, "--g")
      hold on
      a = plotyy(x2,y2, x2, total_percentage)
      hold on
      plot([min(xlim()),max(xlim())],[0,0], 'k--')
      %grid ( "on");
      
      %take the values of the push buttons into account
      i = get(hand.grid_checkbox, "value");
      m = get(hand.minor_grid_toggle, "value");
      
      if i
          grid ("on")
      else
          grid("off")
      end
      
      if m
          grid ("minor","on")
      else
          grid("minor","off")
      end
      
      %formatting Plot
      title('Energy Level Battery and Fuel Tanks')
      xlabel('Time passed in seconds')
      ylabel(a(2),'Percentage Energy')
      ylabel('Energy in kWh')
      legend({'Electric Energy', 'Fuel-based energy'}, 'Location','northeast')
     
    %saves plot of main GUI window
    case {hand.print_pushbutton}
        recalc = false;
        ellipse_position = [0.95 0.773 0.02 0.03];
        %temp = get(hand.sim_exe_led, 'facecolor')
        sim_exe_led2 = annotation('ellipse',ellipse_position,'facecolor', [1 1 1], 'color', [1 1 1]);
        %saved plots are only readable for some reason when saved in Octave, Matlab saves are not supported by Windows apparently
        
        %setting ellipse to white
%%        set(hand.sim_exe_led, 'facecolor', [1 1 1])
%%        set(hand.sim_exe_led, 'color', [1 1 1])
        filter = {'*.png';'Portable Network Graphics *.png';'*.fig';'*.*'};
        fn =  uiputfile (filter);
        print (fn);
        
        %hand.sim_exe_led = annotation('ellipse',ellipse_position,'facecolor', temp, 'color', [0 0 0]);
%%        set(hand.sim_exe_led, 'facecolor', temp, 'color', [0 0 0])
    
    %displays a grid
    case {hand.grid_checkbox}
        recalc = false;
        v = get (gcbo, "value");
        if (v == 0)
          grid ("off")
        else
          grid("on")
        end
    
    %displays minor grid, not supported in MatLab
    case {hand.minor_grid_toggle}
      recalc = false;
      v = get (gcbo, "value");
      if (v == 0)
          grid ("minor","off")
        else
          grid("minor","on")
      end
        
    case {hand.simulate_button}
      recalc = true;
      
    %threshold
    case{hand.threshold_box}
      threshold = str2num(get(gcbo, 'string'));
      recalc = false;
    
   %zoom into battery plot
    case {hand.plot_battery_button}
      recalc = false;
      batt_fig = figure('Name','Battery Plot');
      threshlen = length(x_el);
      thresh = [];
      
      for k=1:threshlen
        thresh(k) = threshold * b_capacity;
      end
      
      plot(x_el, y_el, "--g")
      hold on
      plot(x_el, thresh)
      
      %take the values of the push buttons into account
      i = get(hand.grid_checkbox, "value");
      m = get(hand.minor_grid_toggle, "value");
      
      if i
          grid ("on")
      else
          grid("off")
      end
      
      if m
          grid ("minor","on")
      else
          grid("minor","off")
      end
      
      %formatting Plot
      title('Energy Level Battery and Threshold')
      xlabel('Time passed in seconds')
      ylabel('Energy in kWh')
      legend({'Battery Energy', 'Threshold'}, 'Location','southwest')
  end
    
    
    %Recalculate values and plot them
    if (recalc)
      el_consumed_sum = 0;
      %Takeoff
      %checking if enough battery power is provided    
      tao_len = T(1,1)/time_step;
      
      d_takeoff = T(1,1); %duration of Takeoff in seconds
      pel_takeoff_cons = (T(3,1) + T(3,3))/(eps_effi); % overall electric consumption in kW
      pfuel_takeoff_cons = T(3,2)/(turbine_eff); %overall carbon-based power consumption in kW
      
      surp_t = 0;
      e_fuel_takeoff = 0;
      %this section also checks, if enough fuel-based energy is availabe, if not sim_poss is set to 0
      if T(2,2) >= (T(3,2)/turbine_eff)
        surp_t = T(2,2) - (T(3,2)/turbine_eff); %surplus of power in kW per time_step
        surp_t = surp_t * eff_fuel2el * (tao_len/3600); %fuel energy surplus in kWh per time step
        e_fuel_takeoff = (d_takeoff/3600) * pfuel_takeoff_cons; %fuel energy used during whole take-off
      else
        %set simulation led on false
        sim_poss = 0;
      end
      
      e_el_takeoff = 0;
      
      if T(2,1) < ((T(3,1) + T(3,3))/eps_effi)
        sim_poss = 0;
      else
        e_el_takeoff = (time_step/3600) * pel_takeoff_cons; %electric energy consumed per time step
      end
      
      batt_t = usable_batt;
      takeoff_arr = [];
      takeoff_time = [];
      el_consumed_sum = 0;
      
      %for loop for takeoff-battery calculation
      for k=1 : tao_len
        soc_t = batt_t / b_capacity;
        batt_prev = batt_t;
        %only use battery if threshold is not reached
        if soc_t >= threshold
          batt_t = batt_t - e_el_takeoff + surp_t;
          el_consumed_sum = el_consumed_sum + e_el_takeoff;
        else
          batt_t = batt_t + surp_t;
        end
        
        if batt_t >= b_capacity
          batt_t = b_capacity;
        end
        
        takeoff_arr(k) = batt_t;
        takeoff_time(k) = time_step * k;
      end
      
      
      %cruise
      cruise_len = C(1,1)/time_step;
      i = el_consumed_sum;
      
      d_cruise = C(1,1); %duration of Takeoff in seconds
      pel_cruise_cons = (C(3,1) + C(3,3))/(eps_effi); % overall electric consumption in kW
      pfuel_cruise_cons = (C(3,2))/(turbine_eff); %overall carbon-based power consumption in kW
      
      surp_c = 0;
      e_fuel_cruise = 0;
      if C(2,2) >= (C(3,2)/turbine_eff)
        surp_c = C(2,2) - (C(3,2)/turbine_eff); %surplus of power in kW
        surp_c = surp_c * eff_fuel2el * (cruise_len/3600); %fuel energy surplus in kWh
        e_fuel_cruise = (d_cruise/3600) * pfuel_cruise_cons;
      else
        %set simulation led on false
        sim_poss = 0;
      end
      
      e_el_cruise = 0;
      if C(2,1) < ((C(3,1) + C(3,3))/eps_effi)
        sim_poss = 0
      else
        e_el_cruise = (time_step/3600) * pel_cruise_cons;
      end
      
      batt_c = batt_t;
      cruise_arr = [];
      cruise_time = [];
      
      for k=1 : cruise_len
        soc_c = batt_c / b_capacity;
        batt_prev = batt_c;
        
        %only use battery if threshold is not reached
        if soc_c >= threshold
          batt_c = batt_c - e_el_cruise + surp_c;
             el_consumed_sum     = el_consumed_sum     + e_el_cruise;
        else
          batt_c = batt_c + surp_c;
        end
        
        if batt_c >= b_capacity
          batt_c = b_capacity;
        end
        
        cruise_arr(k) = batt_c;
        cruise_time(k) = time_step * k + T(1,1);
      end
      
      
      %Landing
      l_len = L(1,1) / time_step;

      d_landing = L(1,1); %duration of Takeoff in seconds
      pel_landing_cons = (L(3,1) + L(3,3))/(eps_effi); % overall electric consumption in kW
      pfuel_landing_cons = L(3,2)/(turbine_eff); %overall carbon-based power consumption in kW
      
      surp_l = 0;
      e_fuel_landing = 0;
      if L(2,2) >= (L(3,2)/turbine_eff)
        surp_l = L(2,2) - (L(3,2)/turbine_eff); %surplus of power in kW
        surp_l = surp_l * eff_fuel2el * (l_len/3600); %fuel energy surplus in kWh
        e_fuel_landing = (d_landing/3600) * pfuel_landing_cons;
      else
        %set simulation led on false
        sim_poss = 0
      end
      
      e_el_landing= 0;
      if L(2,1) < ((L(3,1) + L(3,3))/eps_effi)
        sim_poss = 0
      else
        e_el_landing = (time_step/3600) * pel_landing_cons;
      end
      
      batt_l = batt_c;
      landing_arr = [];
      landing_time = [];
      
      for k=1 : l_len
        soc_l = batt_l / b_capacity;
        batt_prev = batt_l;
        
        %only use battery if threshold is not reached
        if soc_l >= threshold
          batt_l = batt_l - e_el_landing + surp_l;
          el_consumed_sum     = el_consumed_sum     + e_el_landing;
        else
          batt_l = batt_l + surp_l;
        end
        
        if batt_l >= b_capacity
          batt_l = b_capacity;
        end
        
        landing_arr(k) = batt_l;
        landing_time(k) = time_step * k + C(1,1) + T(1,1);
      end
      
      
      soc_plot = [soc, soc_t, soc_c, soc_l] * 100;
      %simulation possible check section
      %tests if enough energy is provided by the batteries during each flight phase
      %takeoff    
      %cuise
      
      
      %help array for plotting electric grid
      y_el = [usable_batt, takeoff_arr, cruise_arr, landing_arr];
      x_el = [0 , takeoff_time, cruise_time, landing_time];

      %help array for plotting fuel based energy consumption
      x_fuel = [0 , T(1,1), T(1,1)+C(1,1), T(1,1)+C(1,1)+ L(1,1)];
      y_fuel = [fuel_energy, fuel_energy - e_fuel_takeoff, fuel_energy - e_fuel_takeoff - e_fuel_cruise, fuel_energy - e_fuel_takeoff - e_fuel_cruise - e_fuel_landing];
      
      %total energy array
      total_energy = [y_el(1)+y_fuel(1), y_el(2)+y_fuel(2), y_el(3)+y_fuel(3), y_el(4)+y_fuel(4)];
      total_percentage = [1, total_energy(2)/total_energy(1), total_energy(3)/total_energy(1), total_energy(4)/total_energy(1)] * 100;
      
      %is one of the values under zero, if true: sim_poss = 0
      %check el
      for i=1:length(y_el)
        if y_el(i) <= 0
          sim_poss = 0;
        end
      end
      
      %check fuel
      for i=1:length(y_fuel)
        if y_fuel(i) <= 0
          sim_poss = 0;
        end
      end
      
      %check total energy
      for i=1:length(total_energy)
        if total_energy(i) <= 0
          sim_poss = 0;
        end
      end
      
      ellipse_position = [0.95 0.773 0.02 0.03];
      
      if sim_poss == 1
        %plotting the graphs in the main GUI window
        hand.plot = plot (x_el, y_el, 'g--');
        %guidata (f, h);
        hold on
        hand.axe = plotyy(x_fuel, y_fuel, x_fuel, total_percentage);
        ylabel(hand.axe(2), "Percentage Energy")
%%        hold on
%%        hand.plot = plot([min(xlim()),max(xlim())],[0,0], 'k--');
        %guidata (f,h);

        %Title and labels
        set (get (hand.ax, "title"), "string", 'Energy Level Battery and Fuel Tanks' )
        set (get (hand.ax, "xlabel"), "string", 'Time passed in seconds' )
        set (get (hand.ax, "ylabel"), "string", 'Energy in kWh' )
        
        hand.sim_exe_led = annotation('ellipse',ellipse_position,'facecolor', [0 1 0]);
      else
        hand.sim_exe_led = annotation('ellipse',ellipse_position,'facecolor', [1 0 0]);
      end
      
end