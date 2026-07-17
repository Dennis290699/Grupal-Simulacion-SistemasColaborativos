model InfeccionRedesGIS_BDI

species sala {
	string nombre;

	aspect default {
		draw shape color: rgb(165, 75, 75, 100) border: #black;
	}
}

global {
	file nodos_file <- file("../includes/nodos.shp");
	file conexiones_file <- file("../includes/conexiones.shp");
	file salas_file <- file("../includes/salas.shp");
	file planta_file <- file("../includes/planta.shp");
	geometry shape <- envelope(nodos_file);
	float firewall_strength <- 0.7;
	float containment_threshold <- 30.0;
	bool emergency_containment <- false;
	int cooldown_min <- 0;
	int cooldown_max <- 1;
	float initial_patch_level <- 10.0;
	string scenario_label <- "Personalizado";
	int num_escenario <- 0;
	float agente_autoaislamiento_prob <- 15.0;
	bool es_batch <- false;

	// Rutas exactas conectadas a tu carpeta pública de Vue
	string log_general_path <- "../front/public/results/log_general.csv";
	string log_general_hist_path <- "../front/public/results/log_general_hist.csv";
	string log_eventos_path <- "../front/public/results/log_eventos.csv";
	string log_eventos_hist_path <- "../front/public/results/log_eventos_hist.csv";
	string log_informes_path <- "../front/public/results/log_informes.csv";
	int ciclo_inicio_infeccion <- -1;
	int ciclo_fin_contencion <- -1;
	bool contencion_total <- false;
	bool infeccion_total <- false;
	bool informe_guardado <- false;
	float sensibilidad_deteccion <- 20.0;
	float umbral_minimo_deteccion <- 15.0;
	float umbral_emergencia <- 100.0; // % mínimo de red infectada antes de que el SOC pueda detectar algo
	int max_ciclos <- 700;
	int ciclos_sin_cambio <- 0; // contador de estancamiento
	int limite_estancamiento <- 100; // si no cambia en 100 ciclos, corta
	bool estancado <- false;
	int infectados_anterior <- -1;
	float base_infection_prob <- 0.35;

	init {
		create planta from: planta_file;
		if num_escenario = 1 {
			firewall_strength <- 0.1;
			initial_patch_level <- 5.0;
			containment_threshold <- 5.0;
			agente_autoaislamiento_prob <- 0.0;
			umbral_minimo_deteccion <- 70.0;
			base_infection_prob <- 1.0;
			scenario_label <- "E1 - Real 2017";
		} else if num_escenario = 2 {
			firewall_strength <- 0.9;
			initial_patch_level <- 5.0;
			containment_threshold <- 10.0;
			umbral_minimo_deteccion <- 25.0;
			umbral_emergencia <- 85.0;
			scenario_label <- "E2 - Solo firewall";
		} else if num_escenario = 3 {
			firewall_strength <- 0.1;
			initial_patch_level <- 80.0;
			containment_threshold <- 20.0;
			umbral_minimo_deteccion <- 20.0;
			umbral_emergencia <- 75.0;
			scenario_label <- "E3 - Solo parches";
		} else if num_escenario = 4 {
			firewall_strength <- 0.5;
			initial_patch_level <- 30.0;
			containment_threshold <- 80.0;
			umbral_minimo_deteccion <- 10.0; // SOC activo, detecta temprano
			umbral_emergencia <- 60.0;
			scenario_label <- "E4 - SOC activo";
		} else if num_escenario = 5 {
			firewall_strength <- 1.0;
			initial_patch_level <- 100.0;
			containment_threshold <- 90.0;
			umbral_minimo_deteccion <- 5.0; // red segura, detección casi inmediata
			umbral_emergencia <- 40.0; // interviene mucho antes
			scenario_label <- "E5 - Red segura";
		} else {
			// modo manual (num_escenario = 0)
			if int(firewall_strength * 10.0) = 1 and int(initial_patch_level) = 5 and int(containment_threshold) = 5 {
				scenario_label <- "E1 - Real 2017";
			} else if int(firewall_strength * 10.0) = 9 and int(initial_patch_level) = 5 and int(containment_threshold) = 10 {
				scenario_label <- "E2 - Solo firewall";
			} else if int(firewall_strength * 10.0) = 1 and int(initial_patch_level) = 80 and int(containment_threshold) = 20 {
				scenario_label <- "E3 - Solo parches";
			} else if int(firewall_strength * 10.0) = 5 and int(initial_patch_level) = 30 and int(containment_threshold) = 80 {
				scenario_label <- "E4 - SOC activo";
			} else if int(firewall_strength * 10.0) = 10 and int(initial_patch_level) = 100 and int(containment_threshold) = 90 {
				scenario_label <- "E5 - Red segura";
			} 
		}

		if !file_exists(log_informes_path) {
			string encabezado_informe <- "escenario,nivel_max_parche,ciclo_inicio_infeccion,ciclo_fin_contencion,ciclo_final,numero_infectados,numero_asalvo,nivel_firewall,nivel_contencion";
			save encabezado_informe to: log_informes_path rewrite: true;
		}

		create sala from: salas_file {
			nombre <- string(read("nombre"));
		}

		create computer from: nodos_file {
			id <- int(read("id"));
			nombre <- string(read("nombre"));
			string tipoNodo <- string(read("tipo"));
			is_server <- tipoNodo = "server";
			is_internet <- tipoNodo = "internet";
			is_firewall <- tipoNodo = "firewall";
			is_switch <- tipoNodo = "switch";
			infected <- is_internet;
			isolated <- false;
			patch_level <- min(100, int(initial_patch_level + rnd(10)));
			if tipoNodo = "pc" or is_server or is_switch or is_firewall {
				open_ports <- [445, 3389, 80];
			} else {
				open_ports <- [];
			}
		}

		create connection from: conexiones_file {
			int o <- int(read("origen"));
			int d <- int(read("destino"));
			list<computer> so <- computer where (each.id = o);
			list<computer> de <- computer where (each.id = d);
			if !empty(so) and !empty(de) {
				source <- first(so);
				target <- first(de);
			}
		}

		int t_nodos <- length(computer);
		int t_salas <- length(sala);
		int t_pcs <- length(computer where (not each.is_server and not each.is_internet and not each.is_firewall and not each.is_switch));
		int t_switches <- length(computer where each.is_switch);
		int t_firewalls <- length(computer where each.is_firewall);

		// LOG 1: General Live
		string encabezado_gen <- "total_nodos,total_salas,total_pcs,total_switches,total_firewall,firewall_strength,containment_threshold";
		save encabezado_gen to: log_general_path rewrite: true;
		string datos_gen <- string(t_nodos) + "," + string(t_salas) + "," + string(t_pcs) + "," + string(t_switches) + "," + string(t_firewalls) + "," + string(firewall_strength) + "," + string(containment_threshold);
		save datos_gen to: log_general_path rewrite: false;

		// LOG 2: Eventos Live
		string encabezado_evt <- "ciclo,nodo,evento,desde,probabilidad,patch_lv,infectados_total,intencion";
		save encabezado_evt to: log_eventos_path rewrite: true;

		// LOG 3 y 4: Históricos Acumulativos
		if !file_exists(log_general_hist_path) {
			string encabezado_hist_gen <- "escenario,firewall_strength,initial_patch_level,containment_threshold,total_nodos,total_salas,total_pcs,total_switches,total_firewall";
			save encabezado_hist_gen to: log_general_hist_path rewrite: true;
		}

		if !file_exists(log_eventos_hist_path) {
			string encabezado_evt_hist <- "ciclo,nodo,evento,desde,probabilidad,patch_lv,infectados_total,intencion,escenario";
			save encabezado_evt_hist to: log_eventos_hist_path rewrite: true;
		}

		string datos_hist_gen <- scenario_label + "," + string(firewall_strength) + "," + string(initial_patch_level) + "," + string(containment_threshold) + "," + string(t_nodos) + "," + string(t_salas) + "," + string(t_pcs) + "," + string(t_switches) + "," + string(t_firewalls);
		save datos_hist_gen to: log_general_hist_path rewrite: false;

		// LOGS ESTÁTICOS DE TOPOLOGÍA
		save "id,nombre,tipo" to: "../front/public/results/log_nodos.csv" rewrite: true;
		loop n over: computer {
			string tipo_nodo <- "pc";
			if n.is_internet {
				tipo_nodo <- "internet";
			} else if n.is_firewall {
				tipo_nodo <- "firewall";
			} else if n.is_switch {
				tipo_nodo <- "switch";
			} else if n.is_server {
				tipo_nodo <- "server";
			}
			save string(n.id) + "," + n.nombre + "," + tipo_nodo to: "../front/public/results/log_nodos.csv" rewrite: false;
		}

		save "origen,destino,tipo_origen,tipo_destino" to: "../front/public/results/log_topologia.csv" rewrite: true;
		loop c over: connection {
			string tipo_source <- "pc";
			string tipo_target <- "pc";
			if c.source.is_internet {
				tipo_source <- "internet";
			} else if c.source.is_firewall {
				tipo_source <- "firewall";
			} else if c.source.is_switch {
				tipo_source <- "switch";
			} else if c.source.is_server {
				tipo_source <- "server";
			}

			if c.target.is_internet {
				tipo_target <- "internet";
			} else if c.target.is_firewall {
				tipo_target <- "firewall";
			} else if c.target.is_switch {
				tipo_target <- "switch";
			} else if c.target.is_server {
				tipo_target <- "server";
			}

			save c.source.nombre + "," + c.target.nombre + "," + tipo_source + "," + tipo_target to: "../front/public/results/log_topologia.csv" rewrite: false;
		} 
	}

	reflex BDI_global_perception {
		if containment_threshold > 0 {
			int total_nodos <- length(computer where !each.is_internet);
			int total_infectados <- length(computer where (each.infected and !each.is_internet));
			float tasa <- (total_nodos > 0) ? (float(total_infectados) / float(total_nodos) * 100.0) : 0.0;
			if tasa >= umbral_emergencia and !emergency_containment {
				emergency_containment <- true;
				string fila_alerta <- string(cycle) + ",-,ALERTA_CRITICA,-,-,-," + string(length(computer where each.infected)) + ",-";
				save fila_alerta to: log_eventos_path rewrite: false;
				save fila_alerta + "," + scenario_label to: log_eventos_hist_path rewrite: false;
				ask computer where !each.is_internet {
					isolated <- true;
					intention <- "isolated";
					string fila_emergencia <- string(cycle) + "," + nombre + ",AISLADO_EMERGENCIA,-,-," + string(patch_level) + "," + string(length(computer where each.infected)) + ",isolated";
					save fila_emergencia to: log_eventos_path rewrite: false;
					save fila_emergencia + "," + scenario_label to: log_eventos_hist_path rewrite: false;
				}
			}
		}
	}

	reflex BDI_global_containment {
		int total_lan <- length(computer where !each.is_internet);
		int infectados_count <- length(computer where (each.infected and !each.isolated and !each.is_internet));
		if infectados_count > 0 and total_lan > 0 {
			float tasa_infeccion <- float(infectados_count) / float(total_lan) * 100.0;
			if tasa_infeccion >= umbral_minimo_deteccion {
				float prob_deteccion <- containment_threshold;
				float eficacia_contencion <- containment_threshold; 
				
				if rnd(100) < prob_deteccion {
					ask computer where (each.infected and !each.is_internet) {
						if rnd(100) < eficacia_contencion {
							isolated <- true;
							intention <- "isolated";
							string fila_defensa <- string(cycle) + "," + nombre + ",Aislamiento_Contencion,Global,0.0," + string(patch_level) + "," + string(length(computer where each.infected)) + ",isolated";
							save fila_defensa to: log_eventos_path rewrite: false;
							save fila_defensa + "," + scenario_label to: log_eventos_hist_path rewrite: false;
						}
					}
				}
			}
		}
	}

	reflex emergency_check {
		if containment_threshold > 0 {
			int infectados <- length(computer where (each.infected and !each.is_internet));
			int total <- length(computer where !each.is_internet);
			if infectados = total and !emergency_containment {
				emergency_containment <- true;
				ask computer where !each.is_internet {
					isolated <- true;
					intention <- "isolated";
				}
			}
		}
	}

	reflex verificar_contencion_total {
		if ciclo_inicio_infeccion != -1 and !contencion_total {
			int infectados_activos <- length(computer where (each.infected and !each.isolated and !each.is_internet));
			
			if infectados_activos = 0 {
				contencion_total <- true;
				ciclo_fin_contencion <- cycle;
				write "CONTENCION TOTAL - No quedan vectores de transmisión activos en la LAN.";
			}
		}
	}

	reflex verificar_infeccion_total {
		if ciclo_inicio_infeccion != -1 and !infeccion_total {
			int total_lan <- length(computer where !each.is_internet);
			int infectados_lan <- length(computer where (each.infected and !each.is_internet));
			if total_lan > 0 and infectados_lan = total_lan {
				infeccion_total <- true;
				write "INFECCION TOTAL - La LAN ha sido completamente comprometida.";
			}
		}
	}

	reflex detectar_estancamiento {
		if !contencion_total and !estancado and ciclo_inicio_infeccion != -1 {
			int infectados_totales_lan <- length(computer where (each.infected and !each.is_internet));
			
			if infectados_totales_lan = infectados_anterior {
				ciclos_sin_cambio <- ciclos_sin_cambio + 1;
			} else {
				ciclos_sin_cambio <- 0;
			}

			infectados_anterior <- infectados_totales_lan;
			
			if ciclos_sin_cambio >= limite_estancamiento {
				estancado <- true;
				write "SIMULACION ESTANCADA - El virus no ha logrado propagarse a nuevos nodos en " + limite_estancamiento + " ciclos.";
			}
		}
	}

reflex guardar_informe_y_detener {
		if (contencion_total or infeccion_total or estancado or cycle >= max_ciclos) {
			
			if estancado and !infeccion_total and ciclo_fin_contencion = -1 {
				ciclo_fin_contencion <- cycle;
			}
			
			if !informe_guardado {
				informe_guardado <- true;
				int total_lan <- length(computer where !each.is_internet);
				int infectados_lan <- length(computer where (each.infected and !each.is_internet));
				int asalvo_lan <- total_lan - infectados_lan;
				int max_parche <- (total_lan > 0) ? max(computer where !each.is_internet collect each.patch_level) : 0;
				
				int ciclo_envio_contencion <- ciclo_fin_contencion;
				if infeccion_total {
					ciclo_envio_contencion <- -1;
				}
				
				string fila_informe <- scenario_label + "," + string(max_parche) + "," + string(ciclo_inicio_infeccion) + "," + string(ciclo_envio_contencion) + "," + string(cycle) + "," + string(infectados_lan) + "," + string(asalvo_lan) + "," + string(int(firewall_strength * 100)) + "," + string(int(containment_threshold));
				save fila_informe to: log_informes_path rewrite: false;
				
				write "INFORME GUARDADO - Escenario: " + scenario_label + " | Fin Contención: " + string(ciclo_envio_contencion);
			}
			
			string motivo <- "";
			if contencion_total { motivo <- "Contención Total (0 activos)"; }
			else if infeccion_total { motivo <- "Infección Total (Colapso)"; }
			else if estancado { motivo <- "Estancamiento de propagación"; }
			else { motivo <- "Límite de ciclos (" + max_ciclos + ")"; }
			
			write "Terminando simulación en ciclo " + cycle + " por: " + motivo;
			
			// --- COMPROBACIÓN ROBUSTA DE ENTORNO GUI vs BATCH ---
			// Si el experimento tiene vistas/displays definidos en su salida, es una simulación visual.
if es_batch {
            do die;
        } else {
            do pause;
        }
		}
	}
	
}

species planta {
	aspect default {
		draw shape color: #red;
	}
}

species computer {
	int id;
	string nombre;
	bool is_server <- false;
	bool is_internet <- false;
	bool is_firewall <- false;
	bool is_switch <- false;
	bool infected <- false;
	bool isolated <- false;
	bool detected <- false;
	bool bel_amenaza_cercana <- false;
	bool bel_red_comprometida <- false;
	bool bel_soy_vulnerable <- false;
	int bel_vecinos_infectados <- 0;
	float bel_riesgo <- 0.0;
	bool des_sobrevivir <- true;
	bool des_infectar <- false;
	bool des_aislarse <- false;
	bool des_parchear <- false;
	string intention <- "normal";
	list<int> open_ports <- [];
	int patch_level <- 0;
	int cooldown <- 0;

	reflex BDI_perception {
		list<connection> links <- connection where (each.source = self or each.target = self);
		int infectados <- 0;
		loop c over: links {
			computer vecino <- (c.source = self) ? c.target : c.source;
			if vecino.infected {
				infectados <- infectados + 1;
			}
		}

		bel_vecinos_infectados <- infectados;
		bel_amenaza_cercana <- infectados > 0;
		bel_riesgo <- float(infectados) * 25.0;
		bel_soy_vulnerable <- (!empty(open_ports)) and (patch_level < 50);
		int total <- length(computer where !each.is_internet);
		int glob <- length(computer where (each.infected and !each.is_internet));
		bel_red_comprometida <- (total > 0) and ((float(glob) / float(total)) > 0.5);
	}

	reflex BDI_deliberation {
		des_infectar <- infected;
		des_aislarse <- bel_amenaza_cercana or bel_red_comprometida;
		des_parchear <- bel_soy_vulnerable and bel_amenaza_cercana;
		des_sobrevivir <- true;
	}

	reflex BDI_planning {
		if isolated {
			intention <- "isolated";
			return;
		}

		if is_internet {
			intention <- infected ? "spread" : "normal";
			return;
		}

		if des_aislarse and des_sobrevivir and bel_riesgo > 50.0 {
			if rnd(100) < agente_autoaislamiento_prob {
				intention <- "isolate";
				return;
			}
		}

		if des_parchear and !infected {
			intention <- "patch";
			return;
		}

		if des_infectar {
			intention <- "spread";
			return;
		}

		intention <- "normal";
	}

	reflex BDI_execute {
		if cooldown > 0 {
			cooldown <- cooldown - 1;
		}

		if intention = "isolated" {
			return;
		}

		if intention = "isolate" {
			isolated <- true;
			intention <- "isolated";
			string fila_aislado <- string(cycle) + "," + nombre + ",AISLADO,-,-," + string(patch_level) + "," + string(length(computer where each.infected)) + ",isolated";
			save fila_aislado to: log_eventos_path rewrite: false;
			save fila_aislado + "," + scenario_label to: log_eventos_hist_path rewrite: false;
			return;
		}

		if intention = "patch" {
			patch_level <- min(100, patch_level + 10);
			if patch_level >= 50 {
				bel_soy_vulnerable <- false;
				des_parchear <- false;
			}

			string fila_parcheo <- string(cycle) + "," + nombre + ",PARCHEO,-,-," + string(patch_level) + "," + string(length(computer where each.infected)) + ",patch";
			save fila_parcheo to: log_eventos_path rewrite: false;
			save fila_parcheo + "," + scenario_label to: log_eventos_hist_path rewrite: false;
			return;
		}

		if intention = "spread" {
			do spread_action;
			return;
		}
	}

	action spread_action {
		if cooldown > 0 or isolated {
			return;
		}

		list<connection> links <- connection where (each.source = self or each.target = self);
		if empty(links) {
			return;
		}

		connection c <- one_of(links);
		computer destino <- (c.source = self) ? c.target : c.source;
		if destino.is_internet or destino.isolated or destino.infected {
			return;
		}

		float p <- base_infection_prob;
		if destino.is_firewall {
			p <- p * (1.0 - firewall_strength);
		}

		if 445 in destino.open_ports {
			p <- p * (1.0 - destino.patch_level / 150.0);
		}

		if flip(p) {
			destino.infected <- true;
			destino.detected <- false;
			if world.ciclo_inicio_infeccion = -1 {
				world.ciclo_inicio_infeccion <- cycle;
			}

			string fila_evento <- string(cycle) + "," + destino.nombre + ",Infeccion_Exitosa," + self.nombre + "," + string(p) + "," + string(destino.patch_level) + "," + string(length(computer where each.infected)) + "," + self.intention;
			save fila_evento to: log_eventos_path rewrite: false;
			save fila_evento + "," + scenario_label to: log_eventos_hist_path rewrite: false;
		}

		cooldown <- rnd(cooldown_max) + cooldown_min;
	}

	aspect default {
		float tam <- 45000.0;
		if isolated {
			draw circle(tam) color: #black;
			draw string(nombre) at: location color: #white font: font("SansSerif", 10, #bold) anchor: #center;
		} else if infected {
			draw circle(tam) color: #red;
		} else if is_firewall {
			draw square(tam) color: #blue;
		} else if is_switch {
			draw square(tam) color: #gray;
		} else if is_internet {
			draw circle(tam) color: #yellow;
		} else if is_server {
			draw square(tam) color: #purple;
		} else {
			draw circle(tam) color: #green;
		}

		if !isolated {
			draw string(nombre) at: location color: #black font: font("SansSerif", 8, #bold) anchor: #center;
		} 
	} 
}

species connection {
	computer source;
	computer target;

	aspect default {
		draw line([source.location, target.location]) color: #orange width: 2;
	}
}

experiment Infeccion type: gui  {
	parameter "Escenario Predefinido (0=Manual)" var: num_escenario among: [0, 1, 2, 3, 4, 5] category: "Escenarios";
	parameter "Nivel de Contencion (%)" type: float var: containment_threshold min: 0.0 max: 100.0 category: "Seguridad BDI";
	parameter "Fuerza Firewall (0-1)" type: float var: firewall_strength min: 0.0 max: 1.0 category: "Seguridad BDI";
	parameter "Nivel de Parche Inicial (%)" type: float var: initial_patch_level min: 0.0 max: 100.0 category: "Seguridad BDI";
	parameter "Prob. Auto-Aislamiento (%)" type: float var: agente_autoaislamiento_prob min: 0.0 max: 100.0 category: "Seguridad BDI";
	parameter "Umbral Mínimo Detección (%)" type: float var: umbral_minimo_deteccion min: 0.0 max: 100.0 category: "Seguridad BDI";
	output {
		display mapa_red {
			species planta;
			species sala;
			species connection;
			species computer;
		}

		monitor "Infectados" value: length(computer where each.infected);
		monitor "Sanos" value: length(computer where (!each.infected and !each.is_internet));
		monitor "Aislados" value: length(computer where each.isolated);
	}
}

experiment EjecutarEscenariosPredefinidos type: batch repeat: 25 parallel: true until: (contencion_total or infeccion_total or estancado or cycle > max_ciclos) {
	parameter "Escenario" var: num_escenario among: [1, 2, 3, 4, 5];
	parameter "Batch mode" var: es_batch init: true;
}

experiment EjecutarPersonalizado type: batch repeat: 50 parallel: true until: (contencion_total or infeccion_total or estancado or cycle > max_ciclos) {
	parameter "Escenario Predefinido (0=Manual)" var: num_escenario init: 0;
	parameter "Nivel de Contencion (%)" var: containment_threshold init: 5.0;
	parameter "Fuerza Firewall (0-1)" var: firewall_strength init: 0.1;
	parameter "Nivel de Parche Inicial (%)" var: initial_patch_level init: 5.0;
	parameter "Prob. Auto-Aislamiento (%)" var: agente_autoaislamiento_prob init: 0.0;
	parameter "Umbral Mínimo Detección (%)" type: float var: umbral_minimo_deteccion init: 15.0;
	parameter "Umbral Emergencia (%)" type: float var: umbral_emergencia init: 80.0;
	parameter "Batch mode" var: es_batch init: true;
}