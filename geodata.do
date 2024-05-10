clear all

local user Jorge

if "`user'" == "andres"{
	global db 		"/Users/andres/Dropbox/jardines_elpi/data"
	global codes 	"/Users/andres/Dropbox/jardines_elpi/codes"
	global km		"/Users/andres/Dropbox/jardines_elpi/Data/geodata/Output" //???
}

else if "`user'" == "Jorge-server"{ 
  global db "/home/jrodriguez/childcare/data"
  global codes "/home/jrodriguez/childcare/codes"
  global km "/home/jrodriguez/childcare/data"
}

else if "`user'" == "Jorge"{
	global db "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Data"
	global results "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Results"
 
     
}

else if "`user'" == "Pablo"{
	cd "C:\Users\Pablo\Dropbox\Datos Jardines Chile"
	global db 		"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Data\ELPI"
	global codes 	"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Do\Códigos ELPI"
	global km		"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Data\geodata\Output"
	global temp		"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Data\ELPI\temp"
}

else if "`user'"=="Antonia"{
	global des "/Volumes/AKAC20/CC/CC_Jardines/Datos-Jardines"
	cd "$des"
	global db "$des/Data"
	global results "$des/resultados-anto"
}

set more off

*Generate distances db
foreach year in 2010 2012{
forval i=1/15 {
	import dbase "$db/Dist2020/Distancias_`year'/D0`i'_`year'.dbf", clear
	tempfile d`i'_`year'
	save `d`i'_`year''
}
use `d1_`year''
forval i=2/15 {
	append using `d`i'_`year''
}
rename InputID folio
rename TargetID  id
rename Distance distancia_establecimiento
save "$db/ELPI`year'_distances.dta", replace

}

/*Geodata variables without specifying type of center*/
foreach elpi_year in 2010 2012{
	foreach y in 2006 2007 2008 2009 2010 2011 2012 2013 2014 {	
	
		use "$db/establecimientos3", clear
		drop if fuente == "MINEDUC"
		keep if year == `y'
		drop _merge
		tempfile year`y'
		save `year`y''


		use "$db/ELPI`elpi_year'_distances", clear
		merge m:1 id using `year`y''		
		tab _merge		
		keep if _merge == 3 //merge 2 are schools in year `y' far from everyone
							//merge 1: distances with jardines not created yet
		drop _merge

		/*# of centers in a radius*/
		preserve
		keep if distancia_establecimiento <=6000
		foreach k in 300 500 1000 5000{
			by folio, sort: egen N_centers`k'_y`y'_aux = count(distancia_establecimiento) if distancia_establecimiento<(`k')
			by folio, sort: egen N_centers`k'_y`y' = min(N_centers`k'_y`y'_aux)
			by folio, sort: replace N_centers`k'_y`y' = 0 if N_centers`k'_y`y' == .
		}

		collapse (mean) N_centers300_y`y' N_centers500_y`y' N_centers1000_y`y' N_centers5000_y`y', by(folio)

		tempfile N_year`y'
		save `N_year`y''

		restore

		/*distance to closest*/
		collapse (min) dist_min_y`y' = distancia_establecimiento, by(folio)
		tempfile min_year`y'
		save `min_year`y''

	}

	use `N_year2006', clear
	forvalues y=2007/2014{
		merge 1:1 folio using `N_year`y''
		drop _merge
	}
	tempfile Ns_aux
	save `Ns_aux'

	use `min_year2006', clear
	forvalues y=2007/2014{
		merge 1:1 folio using `min_year`y''
		drop _merge
	}

	*merging distance and #of centers by folio	
	merge 1:1 folio using `Ns_aux'
	drop _merge


	save "$db/ELPI_N_Centers_`elpi_year'", replace

}

/*Geodata variables by type of center*/
use "$db/establecimientos3", clear

sort id year
bys id: replace cap_sc = cap_sc[_n-1] if cap_sc[_n] == .
bys id: replace cap_ms = cap_ms[_n-1] if cap_ms[_n] == .

drop if fuente == "MINEDUC"

gen center_02 = 0
replace center_02 = 1 if mat_sc != 0

gen center_34 = 0
replace center_34 = 1 if mat_ms != 0

tempfile est_aux
save `est_aux'

foreach typec in "02" "34"{
	foreach elpi_year in 2010 2012{
		foreach y in 2006 2007 2008 2009 2010 2011 2012 2013 2014 {	
		
			use `est_aux', clear
			keep if year == `y' & center_`typec' == 1

			drop _merge
			tempfile year`y'
			save `year`y''


			use "$db/ELPI`elpi_year'_distances", clear
			merge m:1 id using `year`y''
			keep if _merge == 3
			drop _merge

		
			/*# of centers in a radius*/
			preserve
			keep if distancia_establecimiento <= 6000
			foreach k in 300 500 1000 5000{
				*N_centers
				by folio, sort: egen N_centers`k'_y`y'_`typec'_aux = count(distancia_establecimiento) if distancia_establecimiento<(`k')
				by folio, sort: egen N_centers`k'_y`y'_`typec' = min(N_centers`k'_y`y'_`typec'_aux)
				by folio, sort: replace N_centers`k'_y`y'_`typec' = 0 if N_centers`k'_y`y'_`typec' == .
				
				*Matricula y capacidad
				if `typec' == 02{
					bys folio: egen mat`k'_y`y'_`typec'_aux = mean(mat_sc) if distancia_establecimiento<(`k')
					bys folio: egen cap`k'_y`y'_`typec'_aux = mean(cap_sc) if distancia_establecimiento<(`k')
					bys folio: egen totmat`k'_y`y'_`typec'_aux = total(mat_sc) if distancia_establecimiento<(`k')
					bys folio: egen totcap`k'_y`y'_`typec'_aux = total(cap_sc) if distancia_establecimiento<(`k')
					}
				if `typec' == 34{
					bys folio: egen mat`k'_y`y'_`typec'_aux = mean(mat_ms) if distancia_establecimiento<(`k')
					bys folio: egen cap`k'_y`y'_`typec'_aux = mean(cap_ms) if distancia_establecimiento<(`k')
					bys folio: egen totmat`k'_y`y'_`typec'_aux = total(mat_ms) if distancia_establecimiento<(`k')
					bys folio: egen totcap`k'_y`y'_`typec'_aux = total(cap_ms) if distancia_establecimiento<(`k')
					}
					
				foreach v in mat cap totcap totmat {
				bys folio: egen `v'`k'_y`y'_`typec' = min(`v'`k'_y`y'_`typec'_aux)
				bys folio: replace `v'`k'_y`y'_`typec' = 0 if `v'`k'_y`y'_`typec' == .
				}
				}

			collapse (mean) N_centers300_y`y'_`typec' N_centers500_y`y'_`typec' N_centers1000_y`y'_`typec' N_centers5000_y`y'_`typec' ///
							mat300_y`y'_`typec' mat500_y`y'_`typec' mat1000_y`y'_`typec' mat5000_y`y'_`typec' ///
							totmat300_y`y'_`typec' totmat500_y`y'_`typec' totmat1000_y`y'_`typec' totmat5000_y`y'_`typec' ///
							totcap300_y`y'_`typec' totcap500_y`y'_`typec' totcap1000_y`y'_`typec' totcap5000_y`y'_`typec' ///
							cap300_y`y'_`typec' cap500_y`y'_`typec' cap1000_y`y'_`typec' cap5000_y`y'_`typec', by(folio)
			tempfile N_year`y'
			save `N_year`y''
			restore
			
			preserve
			replace distancia_establecimiento = . if (mat_sc > cap_sc & center_02 == 1) | (mat_ms > cap_ms & center_34 == 1) 
			foreach k in 300 500 1000 5000{
				*N_centers con cupos disponibles
				by folio, sort: egen N_cen_cup`k'_y`y'_`typec'_aux = count(distancia_establecimiento) if distancia_establecimiento<(`k')
				by folio, sort: egen N_cen_cup`k'_y`y'_`typec' = min(N_cen_cup`k'_y`y'_`typec'_aux)
				by folio, sort: replace N_cen_cup`k'_y`y'_`typec' = 0 if N_cen_cup`k'_y`y'_`typec' == .
				
				}

			collapse (mean) N_cen_cup300_y`y'_`typec' N_cen_cup500_y`y'_`typec' N_cen_cup1000_y`y'_`typec' N_cen_cup5000_y`y'_`typec', by(folio)
			merge 1:1 folio using `N_year`y''
			drop _merge
			save `N_year`y'', replace
			restore

			preserve
			/*distance to closest*/ 
				bys folio: egen min`y'_`typec'_aux = min(distancia_establecimiento)
				if `typec' == 02{
							gen mat_min`y'_`typec'_aux = mat_sc if min`y'_`typec'_aux == distancia_establecimiento
							gen cap_min`y'_`typec'_aux = cap_sc if min`y'_`typec'_aux == distancia_establecimiento
							}
				if `typec' == 34{
							gen mat_min`y'_`typec'_aux = mat_ms if min`y'_`typec'_aux == distancia_establecimiento
							gen cap_min`y'_`typec'_aux = cap_ms if min`y'_`typec'_aux == distancia_establecimiento
							}
							
				
			collapse (min) dist_min_y`y'_`typec' = distancia_establecimiento mat_min`y'_`typec'=mat_min`y'_`typec'_aux cap_min`y'_`typec'=cap_min`y'_`typec'_aux, by(folio)
			tempfile min_year`y'
			save `min_year`y''
			restore
			preserve
							replace distancia_establecimiento = . if (mat_sc < cap_sc & center_02 == 1) | (mat_ms < cap_ms & center_34 == 1) 
			collapse (min) dist_min_cupos_y`y'_`typec' = distancia_establecimiento, by(folio)
			merge 1:1 folio using `min_year`y''
			drop _merge
			save `min_year`y'', replace
			restore
			
			preserve //Claramente, aqui se demora mucho pq son datos de toda la region.. restringir??
				if `typec' == 02{
							gen sat`y'_`typec'_aux 		= mat_sc/cap_sc
							gen cap_dist`y'_`typec'_aux = cap_sc/distancia_establecimiento 
							gen sat_dist`y'_`typec'_aux = mat_sc/(cap_sc*distancia_establecimiento)
							}
				if `typec' == 34{
							gen sat`y'_`typec'_aux 		= mat_ms/cap_ms
							gen cap_dist`y'_`typec'_aux = cap_ms/distancia_establecimiento
							gen sat_dist`y'_`typec'_aux = mat_ms/(cap_ms*distancia_establecimiento)
							}
			collapse (min)  sat_y`y'_`typec'		= sat`y'_`typec'_aux ///
					 (mean) cap_weight_y`y'_`typec' = cap_dist`y'_`typec'_aux ///
					 (mean) sat_weight_y`y'_`typec' = sat_dist`y'_`typec'_aux, by(folio) cw
			merge 1:1 folio using `min_year`y''
			drop _merge
			save `min_year`y'', replace
			restore	

		}

		use `N_year2006', clear
		forvalues y=2007/2014{
			merge 1:1 folio using `N_year`y''
			drop _merge
		}
		tempfile Ns_aux
		save `Ns_aux'

		use `min_year2006', clear
		forvalues y=2007/2014{
			merge 1:1 folio using `min_year`y''
			drop _merge
		}

		*merging distance and #of centers by folio	
		merge 1:1 folio using `Ns_aux'
		drop _merge

		save "$db/ELPI_N_Centers_`elpi_year'_`typec'center", replace

	}

}

