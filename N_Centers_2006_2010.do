*Define user
local user Jorge

else if "`user'" == "Jorge"{
	global dir "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare"
	global res "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Results"
	*	global str "C:\Users\Pablo\Desktop\EJES_2015"
    

}

 

else if "`user'" == "Pablo"{
	global dir "C:\Users\Pablo\Dropbox\Datos Jardines Chile"
	global res "C:\Users\Pablo\Dropbox\Datos Jardines Chile\Results"
}


	

	*1. Número de establecimientos
	use "$dir/Data/establecimientos3.dta", clear	
		
		preserve
		*drop if dependencia==4 // sacamos los particulares pagados
		keep if d_sj == 1
		tab fuente d_sj if mat_ms == 0 & mat_sc != 0
		tab fuente d_sj if mat_sc == 0 & mat_ms != 0
		tab fuente d_sj if mat_ms != 0 & mat_sc != 0
		
		collapse (sum) d_sj mat_sc mat_ms mat_het, by(year fuente)
		
		tw (line d_sj year if fuente == "MINEDUC" & year>=2006 & year<=2014,  lwidth(thick) lpattern(shortdash) color(black*.8)) ///
		   (line d_sj year if fuente == "INTEGRA" & year>=2006 & year<=2014, lwidth(thick) lpattern(dash) color(sand*.8)) ///
		   (line d_sj year if fuente == "JUNJI" & year>=2006 & year<=2014,  lwidth(thick)  lpattern(solid) color(blue*.8)) ///
			///
		   , yti(Number of centers) xti(Year) ///
		   ylabel(, nogrid)  ///
		   graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) ///
		   plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white)) ///
		   scheme(s2mono) scale(1.2) ///
		   legend(label (1 MINEDUC) label (2 INTEGRA) label (3 JUNJI))

		   graph export "$res/Descriptive/n_jardines.pdf", as(pdf) replace
		   
		restore
stop!!
		
	*2. Número de matriculados en jardines JUNJI
	use "$dir\Data\establecimientos3.dta", clear
			 
		*drop if dependencia==4 // sacamos los particulares pagados
		keep if d_sj == 1
			
		gen mat_ji=mat_sc+mat_ms+mat_het
		collapse (sum) d_sj mat_ji mat_sc mat_ms, by(year fuente)
			
		line mat_ji year if fuente == "JUNJI" & year>=2006 & year<=2014, lpattern(dash) ///
		   lwidth(vthick) yti(Número de matriculados JUNJI) xti(Año) ///
		   ti(Número de matriculados en jardines JUNJI) 

		graph export "$res\Descriptive\mat_junji.pdf", as(pdf) replace

		
	*3. Número de cupos en jardines JUNJI
	use "$dir\Data\establecimientos3.dta", clear
			 
		*drop if dependencia==4 // sacamos los particulares pagados
		keep if d_sj == 1
			
		gen cap_ji=cap_sc+cap_ms
		collapse (sum) d_sj cap_ji cap_sc cap_ms , by(year fuente)
			
		line cap_ji year if fuente == "JUNJI" & year>=2006 & year<=2014, lpattern(dash) ///
		   lwidth(vthick) yti(Número de cupos JUNJI) xti(Año) ///
		   ti(Número de cupos en jardines JUNJI) 

		graph export "$res\Descriptive\cup_junji.pdf", as(pdf) replace
		
	*4. Matrículas/cupos en jardines JUNJI
	use "$dir\Data\establecimientos3.dta", clear
			 
		*drop if dependencia==4 // sacamos los particulares pagados
		keep if d_sj == 1
			
		gen cap_ji=cap_sc+cap_ms
		gen mat_ji=mat_sc+mat_ms+mat_het
		collapse (sum) d_sj cap_ji cap_sc cap_ms mat_ji mat_sc mat_ms, by(year fuente)
		gen double m_k_ji=mat_ji/cap_ji
			
		line m_k_ji year if fuente == "JUNJI" & year>=2006 & year<=2014, lpattern(dash) ///
		   lwidth(vthick) yti(Matrículas/Cupos JUNJI) xti(Año) ///
		   ti(Matrículas/Cupos en jardines JUNJI) 

		graph export "$res\Descriptive\m_k_junji.pdf", as(pdf) replace
