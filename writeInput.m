function writeInput (obj_h, event)
  h = guidata(obj_h);
  global T
  global C
  global L
  global b_capacity
  global b_weight
  global fuel_energy
  global turbine_eff
  global plane_weight
  global kerosene_weight
  global eff_fuel2el
  
  switch(gcbo)
  
  %takeoff cases
    case {h.tao_duration_box} %duration of take-off
      temp = get(gcbo, 'string');
      T(1,1) = str2num(temp);
    
    case {h.tao_elprov_box} %provided electrical energy
      temp = get(gcbo, 'string');
      T(2,1) = str2num(temp);
     
    case {h.tao_fuelprov_box} %provided fuel energy
      temp = get(gcbo, 'string');
      T(2,2) = str2num(temp);
      
    case {h.tao_eltaken_box} %taken electrical energy
      temp = get(gcbo, 'string');
      T(3,1) = str2num(temp);
      
    case {h.tao_fueltaken_box} %taken fuel energy
      temp = get(gcbo, 'string');
      T(3,2) = str2num(temp);

    case {h.tao_othertaken_box} %taken other energy
      temp = get(gcbo, 'string');
      T(3,3) = str2num(temp);
      
      
   %cruise cases
    case {h.cruise_duration_box} %duration of cruise
      temp = get(gcbo, 'string');
      C(1,1) = str2num(temp);
    
    case {h.cruise_elprov_box} %provided electrical energy
      temp = get(gcbo, 'string');
      C(2,1) = str2num(temp);
     
    case {h.cruise_fuelprov_box} %provided fuel energy
      temp = get(gcbo, 'string');
      C(2,2) = str2num(temp);
      
    case {h.cruise_eltaken_box} %taken electrical energy
      temp = get(gcbo, 'string');
      C(3,1) = str2num(temp);
      
    case {h.cruise_fueltaken_box} %taken fuel energy
      temp = get(gcbo, 'string');
      C(3,2) = str2num(temp);

    case {h.cruise_othertaken_box} %taken other energy
      temp = get(gcbo, 'string');
      C(3,3) = str2num(temp);
      
      
    %landing cases
    case {h.landing_duration_box} %duration of landing
      temp = get(gcbo, 'string');
      L(1,1) = str2num(temp);
    
    case {h.landing_elprov_box} %provided electrical energy
      temp = get(gcbo, 'string');
      L(2,1) = str2num(temp);
     
    case {h.landing_fuelprov_box} %provided fuel energy
      temp = get(gcbo, 'string');
      L(2,2) = str2num(temp);
      
    case {h.landing_eltaken_box} %taken electrical energy
      temp = get(gcbo, 'string');
      L(3,1) = str2num(temp);
      
    case {h.landing_fueltaken_box} %taken fuel energy
      temp = get(gcbo, 'string');
      L(3,2) = str2num(temp);

    case {h.landing_othertaken_box} %taken other energy
      temp = get(gcbo, 'string');
      L(3,3) = str2num(temp);
      
      
  %energy sources
    case {h.battery_capa_box} %battery capacity
      temp = get(gcbo, 'string');
      b_capacity = str2num(temp);
      
    case {h.battery_weight_box} %battery weight
      temp = get(gcbo, 'string');
      b_weight = str2num(temp);
      
    case {h.kerosene_weight_box} %kerosene energy 
      kerosene_weight = str2num(get(gcbo, 'string'));
      fuel_energy = kerosene_weight * 11.9 * turbine_eff; %one kg of kerosene yields 11.9 kWh/kg, all resulting energy can be used to generate thrust
      
    case {h.turbine_eff_box} %turbine efficiency
      temp = get(gcbo, 'string');
      turbine_eff = str2num(temp);
      
    case {h.fuel2el_box}
      temp = get(gcbo, 'string');
      eff_fuel2el = str2num(temp)
  end
end