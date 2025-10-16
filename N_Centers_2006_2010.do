*Define user
local user Jorge

if "`user'" == "Jorge"{
	global dir "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare"
	global res "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Results"
	*	global str "C:\Users\Pablo\Desktop\EJES_2015"
    

}

else if "`user'" == "Pablo"{
	global dir "C:\Users\Pablo\Dropbox\Datos Jardines Chile"
	global res "C:\Users\Pablo\Dropbox\Datos Jardines Chile\Results"
}

	if "`c(username)'" == "ccorrea"{
	global dir		"G:\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$dir/Data"
	global results 	"$dir/Tex/figures_tables"
	global codes 	"C:\Users\ccorrea\OneDrive - Universidad de los Andes\Documentos\GitHub\Welfare-effects"
}

	if "`c(username)'" == "Cecilia"{
	global dir		"G:\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$dir/Data"
	global results 	"$dir/Tex/figures_tables"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
}

*----------------------------------------------------------------------	

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
		   legend(label (1 MINEDUC) label (2 INTEGRA) label (3 JUNJI) position(12))

// 		   graph export "$res/Descriptive/n_jardines.pdf", as(pdf) replace
			graph export "$results/n_jardines.pdf", as(pdf) replace
		   
		restore
		
		
		preserve
		drop if dependencia==4 // sacamos los particulares pagados
		keep if d_sj == 1

		gen dsj_1 = 1
		gen dsj_2 = 1 if inlist(fuente,"MINEDUC","INTEGRA","JUNJI PRIV ")
		gen dsj_3 = 1 if inlist(fuente,"MINEDUC","JUNJI PRIV ")
		gen dsj_4 = 1 if inlist(fuente,"JUNJI PRIV ")

	collapse (sum) dsj_* , by(year)
	keep if  year>=2006 & year<=2014
	tw (area dsj_1 year, sort) (area dsj_2 year) (area dsj_3 year) (area dsj_4 year), legend(order(1 "JUNJI AD" 2 "INTEGRA" 3 "MINEDUC" 4 "JUNJI VTF" )) /*scheme(plotplainblind)*/ scheme(s2color) graphregion(fcolor(white))
		graph export "$results/n_jardines_area.pdf", as(pdf) replace
	
		restore