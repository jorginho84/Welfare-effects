clear all

local user Cec

if "`user'" == "andres"{
	cd 				"/Users/andres/Dropbox/jardines_elpi"
	global db 		"/Users/andres/Dropbox/jardines_elpi/data"
	global codes 	"/Users/andres/Dropbox/jardines_elpi/codes"
	global code_dir	"/Users/andres/Dropbox/jardines_elpi/Codes"
}
 
else if "`user'" == "Jorge-server"{
  global db "/home/jrodriguez/childcare/data"
  global codes "/home/jrodriguez/childcare/codes"
          
}

else if "`user'" == "Pablo"{
	cd "C:\Users\Pablo\Dropbox\Datos Jardines Chile"
	global db 		"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Data\ELPI"
	global codes 	"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Do\Códigos ELPI"
}


else if "`user'"=="Antonia"{
	global des "/Volumes/AKAC20/CC/CC_Jardines/Datos-Jardines"
	cd "$des"
	global db "$des/Data"
	global results "$des/resultados-anto"
	global code_dir "$des/codes-dir"
}

else if "`user'" == "Jorge"{
	global db "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Data"
	global results "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Results"
	global code_dir "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Codes"
          
}

if "`user'" == "Cec"{
	global des		"C:\Users\Cecilia\Mi unidad\Uandes\Jardines_elpi"
	cd "$des"
	global db 		"$des/Data"
// 	global results 	"$des/results"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
// 	global code_dir	"$des"
}


/*

Line 875: calls geodata.

Set local run_geo = 1 if want to run geodata.do

*/

local run_geo = 0


********************************************************************************
**# ********************* * *CLEAN ELPI 2010* * ********************************
********************************************************************************

*-------------------------------------------*
*----------"Entrevistada" database----------*
*-------------------------------------------*
use "$db/elpi_original/Entrevistada_2010", clear
merge m:1 folio using "$db/Datos Comunales/Base_Cod_Comuna_ELPI2010"

	* Keep useful variables
	keep folio region area a4 a11 g1 g2 g7a g9 g31 fexp_enc comuna_lab comuna_cod
	ren a4 			dum_mother //1=yes 2=no
	ren a11 		dum_father //1=yes 2=no

	* Risks, code risk=1, no risk=0
	ren g1 			preg_control
	recode preg_control (9=.) (2=1)(1=0)
	label var preg_control "Risk: no pregnancy controls"
	ren g7a 		dum_smoke
	recode dum_smoke (8=.)(2=0)
	label var dum_smoke "Risk: smoked during pregnancy"
	ren g9 			dum_alc			
	recode dum_alc (8=.)(3=1)(2=1) (1=0)
	label var dum_alc "Risk: alcohol during pregnancy"
	ren g31 		dum_sano		
	recode dum_sano (9=.) (1=0) (2=1)
	label var dum_sano "Risk: no health controls"
	ren g2 			q_control	
	recode q_control (9 = .)
	ren fexp_enc 	FE_enc
	
	label define sino 1 "Sí" 0 "No", modify
	label values preg_control dum_smoke dum_alc dum_sano sino
	
	sort folio
	tempfile db1
		save `db1.dta', replace

*-------------------------------------------*
*----------"Evaluaciones" database----------*
*-------------------------------------------*
use "$db/elpi_original/Evaluaciones_2010", clear
sort folio
keep folio edad_meses eedp_pt batelle_pt_total tepsi_pt_t tvip_pt asq_pb_6m  asq_pb_12m asq_pb_18m cbcl1_pt_t wais_pt_num wais_pt_vo bfi_pb_ext bfi_pb_ama bfi_pb_res bfi_pb_neu bfi_pb_ape peso_nino_selec talla_nino_selec fexp_test

ren (eedp_pt batelle_pt_total tepsi_pt_t tvip_pt asq_pb_6m asq_pb_12m asq_pb_18m cbcl1_pt_t wais_pt_num wais_pt_vo bfi_pb_ext bfi_pb_ama bfi_pb_res bfi_pb_neu  bfi_pb_ape) /*
*/ (EEDP_t BATTELLE_t TEPSI_t TVIP_t ASQ_bruto_6 ASQ_bruto_12 ASQ_bruto_18 CBCL1_t WAIS_t_num WAIS_t_vo BFI_EXT_bruto BFI_AMA_bruto BFI_RES_bruto BFI_NEU_bruto BFI_APE_bruto)
ren (peso_nino_selec talla_nino_selec fexp_test) (PESO TALLA FE_test)

merge 1:1 folio using `db1.dta'
tab _merge
rename _merge merge_evaluaciones
tempfile scores
	save `scores.dta', replace

*------------------------------------*
*----------"Hogar" database----------*
*------------------------------------*
use "$db/elpi_original/Hogar_2010", clear

recode a19 (999 = .)

	recode b2c (88 99 = .) (19 = 0) (9 = 8) //19 significa ninguno, 8 es el máximo.
	recode b2n (88 99 = .) (19 = 0) //19 significa ninguno
	* Generate "escolaridad"
	gen ESC = 0 			if inlist(b2n,0,1,2,3,4,7) //Preschool Ed diferencial /ninguno.
	replace ESC = b2c 		if inlist(b2n,5,6) //Básica /Preparatoria
	replace ESC = b2c + 8 	if inlist(b2n,9,11) //Media cient humanista o técnico
	replace ESC = b2c + 6 	if inlist(b2n,8,10) //Humanidades o tecnica (antiguo)
	replace ESC = 12 		if ESC >= 12 & !missing(ESC) //12 años de escolaridad es lo máximo. 
	replace ESC = b2c + 12 	if inlist(b2n,12,13) //CFT
	replace ESC = b2c + 12 	if inlist(b2n,14,15,16,17) //IP, Uni.
	replace ESC = 18 		if ESC >= 19 & !missing(ESC)
	replace ESC = b2c + 17 	if inlist(b2n,18) //Postgrado
	replace ESC = 21 		if ESC > 21 & !missing(ESC)
	
	*Se corrigen los valores missing
	replace ESC = 0 		if missing(b2c) & inlist(b2n,5,6)
	replace ESC = 8 		if missing(b2c) & inlist(b2n,9,11) 
	replace ESC = 6 		if missing(b2c) & inlist(b2n,8,10)
	replace ESC = 12 		if missing(b2c) & inlist(b2n,12,13,14,15,16,17)
	replace ESC = 17 		if missing(b2c) & b2n == 18
		
	replace ESC = . if inlist(b2n,88,99)
	replace ESC = . if inlist(b2c,88,99)
	replace ESC = . if ESC > a19 //Hay un caso de niña con 6 años que tiene escolaridad 7.
	
	* ESC madre (o madrastra) y padre (o padrastro)
	gen m_sch = ESC if inlist(a16, 1, 3) | (a16 == 5 & a18 == 2) //Madre o madrastra
	gen f_sch = ESC if inlist(a16, 2, 4) | (a16 == 5 & a18 == 1) //Padre o padrastro

	* Generate "nivel educacional"
	gen educ = .
	replace educ = 1 if b2n <= 7 //"less than hs"
	replace educ = 1 if b2n == 8  & b2c <= 2
	replace educ = 2 if b2n >  8  & b2n <= 11 //"hs"
	replace educ = 2 if b2n == 8  & b2c >  2
	replace educ = 3 if b2n == 12 | b2n == 14 | b2n == 16 //less than college
	replace educ = 4 if b2n == 13 | b2n == 15 | b2n == 17 | b2n == 18 //college
	label define educ 1 "Less than highschool" 2 "Highschool" 3 "Less than college" 4 "College"
	label val educ educ
	
	* Educ madre y padre
	gen m_educ = educ if inlist(a16, 1, 3) | (a16 == 5 & a18 == 2) //Madre/madrastra
	gen f_educ = educ if inlist(a16, 2, 4) | (a16 == 5 & a18 == 1) //Padre/padrastro
	
	*Generate Mother and Father at home. No considera madrastra-padrastro.
	gen f_home = inlist(a16, 2, 4)	//1 if father is at home
	gen m_home = inlist(a16, 1, 3)	//1 if mother is at home
	
	*Generate Mother is the main carer dummy
	gen m_maincarer = (orden == 1 & inlist(a16, 1, 3))
	
	*Generate mother age
	gen m_age = a19 if inlist(a16, 1, 3)
	replace m_age = . if m_age == 999
	
	*Child's gender
	gen gender = a18 if a16 == 13
	
	* Variables aux de presencia de hermano/as y participación en cc de hermano.
	gen dum_siblings = (a16 == 6) // 1 if child has sibling(s)
	gen dum_young_siblings = (a16 == 6 & a19 <= 4) // 1 if child has sibling(s) younger than 4 years old.
	gen dum_sibling_part = (dum_young_siblings == 1 & b1==1 & b2n<=5) // 1 if child has siblings younger than 4 and they go to cc (pre-k or lower).
	
collapse (count) n_integrantes = orden (min) *_sch *_educ m_age gender (max) *_home m_maincarer dum_siblings dum_young_siblings dum_sibling_part (sum) tot_sib = dum_siblings (mean) d11m, by(folio fexp_hog)
	
	replace dum_sibling_part = . if dum_young_siblings == 0

	*Generate dummy that both parents live with children (no matter the civil status)
	gen married = (f_home == 1 & m_home == 1)

	ren fexp_hog FE_hog
	ren d11m  monthly_Y

label var n_integrantes "Number of people in the home"
label var m_sch "Mother's years of schooling"
label var m_educ "Mother's educational level"
label var f_sch "Father's years of schooling'"
label var f_educ "Father's educational level"
label var f_home "1 if Father at Home"
label var m_home "1 if Mother at Home"
label var married "1 if both parents live with child"
label var m_maincarer "1 if Mother is the main carer"
label var m_age "Mother's Age"
label var gender "Gender of child (1=male)"
label var dum_siblings "1 if child has sibling(s)"
label var dum_young_siblings "1 if child has sibling(s) 4 years old or younger"
label var dum_sibling_part "1 if child's young sibling(s) goes to cc (P-K or lower)"
label var tot_sib "Number of siblings in the household"

merge 1:1 folio using `scores.dta'
tab _merge
rename _merge merge_hogar
tempfile households
	save `households.dta', replace

*-----------------------------------------------*
*----------"Cuidado Infantil" database----------*
*-----------------------------------------------*
use "$db/elpi_original/Cuidado_infantil_2010", clear

keep folio orden j1 j2 j4 j9 j10 j11mes j11sem j14 j15 j15cod j27 

ren (orden j1 j2 j4 j9 j10 j14 j15 j15cod j27) (tramo dum_work weeks_work mean_hours who_childcare dum_center cc_near type_center other_type nut_status)

* NS/NR is considered a missing value.
foreach v of varlist dum_work cc_near weeks_work dum_center type_center nut_status cc_near {
    recode `v' (9 = .)
}
recode mean_hours (999 = .)
recode who_childcare (99 = .)
recode other_type (99 = .)
recode j11mes (99 = .)
recode j11sem (99 = .)

*Recode to have No = 0
recode dum_work (2 = 0) (8 = .)
recode cc_near (2 = 0)
recode dum_center (2 = 0)
recode cc_near (2 = 0) 

gen time_center = j11mes*4 + j11sem
replace time_center = 0 if missing(time_center) & dum_center == 0
drop j11mes j11sem

label define sino 1 "Sí" 0 "No", modify //Se genera nueva label porque luego LABB cambia.
label val dum_work dum_center cc_near sino
 
reshape wide dum_work weeks_work mean_hours who_childcare dum_center time_center type_center nut_status other_type cc_near, i(folio) j(tramo)

	foreach i in 1 2 3 4 5 6 7 8 {		
		label var dum_work`i' "Trabajó o no en el tramo `i'"  
		label var weeks_work`i' "Semanas trabajadas en el tramo `i'"
		label var mean_hours`i' "Promedio semanal horas trabajadas en el tramo `i'"
		label var who_childcare`i' "Quién cuidó al niñ@ en el tramo `i'"
		label var dum_center`i' "Envió o no al niñ@ a un establecimiento en el tramo `i'"
		label var type_center`i' "Tipo de establecimiento educacional en el tramo `i'"
		label var other_type`i' "Otro tipo de establecimiento educacional en el tramo `i'"
		label var nut_status`i' "Estado nutricional en el tramo `i'"
		label var cc_near`i' "Was there a center nearby?"
		label var time_center`i' "Time went to cc (weeks) tramo `i'"
		}
		
merge 1:1 folio using `households.dta'
tab _merge
rename _merge merge_cuidado
drop merge_hogar merge_cuidado

rename * *_2010
rename folio_2010 folio
tempfile Data2010
save `Data2010.dta', replace	

	
********************************************************************************
**# ********************* * *CLEAN ELPI 2012* * ********************************
********************************************************************************

*-------------------------------------------*
*----------"Entrevistada" database----------*
*-------------------------------------------*
use "$db/elpi_original/Entrevistada_2012", clear
merge m:1 folio using "$db/Datos Comunales/Base_Cod_Comuna_ELPI2012"

	* keep useful variables	
	keep folio region area a2 b37 b38 b8 b12 b41 fexp_enc0 fexp_encP comuna_cod comuna_lab muestra
	gen dum_mother = (a2==1)
	
	ren b37 		preg_control
	recode preg_control (9=.)(8=.)(2=1)(1=0)
	label var preg_control "Risk: no pregnancy controls"
	ren b8 			dum_smoke
	recode dum_smoke (8=.)(2=0)
	label var dum_smoke "Risk: smoked during pregnancy"
	ren b12 		dum_alc
	recode dum_alc (8=.)(3=1)(2=1) (1=0)
	label var dum_alc "Risk: alcohol during pregnancy"
	ren b41 		dum_sano
	recode dum_sano (9=.) (1=0) (2=1)
	label var dum_sano "Risk: no health controls"
	ren b38 		q_control		//ojo NS/NR, different from 2010 version
	*q_control takes values from 0 to 80 (2010 está en secciones, se igual a 2010)
	recode q_control (1/2 = 1) (3/4 = 2) (5/7 = 3) (8/80 = 4) (88 99 = .)
	label define q_control 1 "Menos de 3" 2 "Entre 3 y 4" 3 "Entre 5 y 7" 4 "8 o más", modify
	label val q_control q_control
	
	ren fexp_enc0 	FE_enc
	ren fexp_encP 	FE_P
	sort folio
	tempfile db1b
		save `db1b.dta', replace
	
*-------------------------------------------*
*----------"Evaluaciones" database----------*
*-------------------------------------------*
use "$db/elpi_original/Evaluaciones_2012", clear
sort folio
keep folio edad_meses batelle_pt_total tvip_pt asq_pb_6m  asq_pb_12m asq_pb_18m cbcl1_pt_t cbcl2_pt_t wais_pt_num wais_pt_vo bfi_pb_ext  bfi_pb_ama bfi_pb_res bfi_pb_neu bfi_pb_ape peso_nino_selec talla_nino_selec fexp_test0 fexp_testP 

ren (batelle_pt_total tvip_pt asq_pb_6m asq_pb_12m asq_pb_18m cbcl1_pt_t cbcl2_pt_t wais_pt_num wais_pt_vo bfi_pb_ext bfi_pb_ama bfi_pb_res bfi_pb_neu bfi_pb_ape) (BATTELLE_t TVIP_t ASQ_bruto_6 ASQ_bruto_12 ASQ_bruto_18 CBCL1_t CBCL2_t WAIS_t_num WAIS_t_vo BFI_EXT_bruto BFI_AMA_bruto BFI_RES_bruto BFI_NEU_bruto BFI_APE_bruto)
rename (peso_nino_selec talla_nino_selec fexp_test0 fexp_testP) (PESO TALLA FE_test FE_test_P)

merge 1:1 folio using `db1b.dta'
tab _merge
rename _merge merge_evaluaciones
tempfile scoresb
	save `scoresb.dta', replace
	

*--------------------------------------*
*----------"Hogares" database----------*
*--------------------------------------*
use "$db/elpi_original/Hogar_2012", clear

recode i1 (999 = .)

	* Generate "escolaridad"
	recode j2c (88 99 = .) (19 = 0) (9 = 8) //19 es ninguno, 8 se asume máximo.
	recode j2n (88 99 = .) (21 = 0) //21 significa ninguno
	
	gen ESC = 0 			if inlist(j2n,0,1,2,3,4,5,6,9) //Diferencial, ninguno, Preschool 
	replace ESC = j2c 		if inlist(j2n,7,8) //Basica o preparatoria
	replace ESC = j2c + 8 	if inlist(j2n,11,13) //Media cient-humanista o técnico
	replace ESC = j2c + 6 	if inlist(j2n,10,12) //Humanidades o tecnica (antiguo)
	replace ESC = 12 		if ESC >= 12 & !missing(ESC) //12 años si terminó el colegio
	replace ESC = j2c + 12 	if inlist(j2n,14,15) //CFT
	replace ESC = j2c + 12 	if inlist(j2n,16,17,18,19) //IP U
	replace ESC = j2c + 17 	if inlist(j2n,20)
	replace ESC = 21 		if ESC > 21 & !missing(ESC) //Máximo años de escolaridad
	
	*Se corrigen los valores missing
	replace ESC = 0 		if missing(j2c) & inlist(j2n,7,8)
	replace ESC = 8 		if missing(j2c) & inlist(j2n,11,13) 
	replace ESC = 6 		if missing(j2c) & inlist(j2n,10,12)
	replace ESC = 12 		if missing(j2c) & inlist(j2n,14,15,16,17,18,19)
	replace ESC = 17 		if missing(j2c) & j2n == 20
		
	replace ESC = . if inlist(j2n,88,99)
	replace ESC = . if inlist(j2c,19,99,99)
	
	* ESC madre (o madrastra) y padre (o padrastro)
	gen m_sch = ESC if inlist(i2, 1, 3) | (i2 == 5 & i4 == 2)	//Madre o madrastra
	gen f_sch = ESC if inlist(i2, 2, 4) | (i2 == 5 & i4 == 1)	//Padre o padrastro
	
	* Generate "nivel educacional"
	gen educ = .
	replace educ = 1 if j2n <= 9 // less than hs
	replace educ = 1 if j2n == 10 & j2c <= 2
	replace educ = 2 if j2n >  10 & j2n <= 13 //highschool
	replace educ = 2 if j2n == 10 & j2c >  2
	replace educ = 3 if j2n == 14 | j2n == 14 | j2n == 16 //less than college
	replace educ = 4 if j2n == 13 | j2n == 15 | j2n == 17 | j2n == 18 //college
	label define educ 1 "Less than highschool" 2 "Highschool" 3 "Less than college" 4 "College"
	label val educ educ
	
	* Educ madre y padre
	gen m_educ = educ if inlist(i2, 1, 3) | (i2 == 5 & i4 == 2)	//Madre o madrastra
	gen f_educ = educ if inlist(i2, 2, 4) | (i2 == 5 & i4 == 1) //Padre o padrastro

	*Generate Mother and Father at home. No considera madrastra-padrastro.
	gen f_home = inlist(i2, 2, 4)	//1 if father is at home
	gen m_home = inlist(i2, 1, 3)	//1 if mother is at home
	
	*Generate Mother is the main carer dummy
	gen m_maincarer = (orden == 1 & inlist(i2, 1, 3))

	*Generate mother age
	gen m_age = i1 if inlist(i2, 1, 3)
	replace m_age = . if m_age >= 200	
	
	*Child's gender
	gen gender = i4 if i2 == 13
	
	* Variables aux de presencia de hermano/as y participación en cc de hermano.
	gen dum_siblings = (i2 == 6) // 1 if child has siblings
	gen dum_young_siblings = (i2 == 6 & i1 <= 4) // 1 if child has sibling younger than 4 years old.
	gen dum_sibling_part = (dum_young_siblings == 1 & j1==1 & j2n<=5) // 1 if child has siblings younger than 4 and they go to cc (pre-k or lower).

collapse (count) n_integrantes = orden (min) *_sch *_educ m_age gender (max) *_home m_maincarer dum_siblings dum_young_siblings dum_sibling_part (sum) tot_sib = dum_siblings (mean) l11_monto, by(folio fexp_hog0 fexp_hogP)
	
	replace dum_sibling_part = . if dum_young_siblings == 0

	*Generate dummy that both parents live with children (no matter the civil status)
	gen married = (f_home == 1 & m_home == 1)
	
	ren (fexp_hog0 fexp_hogP) (FE_hog FE_hog_P)
	ren l11_monto monthly_Y

label var n_integrantes "Number of people in the home"
label var m_sch "Mother's years of schooling"
label var m_educ "Mother's educational level"
label var f_sch "Father's years of schooling'"
label var f_educ "Fathar's educational level"
label var f_home "1 if Father at Home"
label var m_home "1 if Mother at Home"
label var married "1 if both parents live with child"
label var m_maincarer "1 if Mother is the main carer"
label var m_age "Mother's Age"
label var gender "Gender of child (1=male)"
label var dum_siblings "1 if child has sibling(s)"
label var dum_young_siblings "1 if child has sibling(s) 4 years old or younger"
label var dum_sibling_part "1 if child's young sibling(s) goes to cc (P-K or lower)"
label var tot_sib "Number of siblings in the household"

merge 1:1 folio using `scoresb.dta'
rename _merge merge_hogar
tempfile householdsb
	save `householdsb.dta', replace
	
*-----------------------------------------------*
*----------"Cuidado Infantil" database----------*
*-----------------------------------------------*
use "$db/elpi_original/Cuidado_infantil_2012", clear

keep folio e1 e3 e6 e7 e11_1 e12 tramo e8meses e8semanas 
ren (e1 e3 e6 e7 e11_1 e12) (dum_work care_at_work who_childcare dum_center cc_near type_center)

label define sino 1 "Sí" 0 "No", modify

*Recode to have No = 0 & missing values = .
recode dum_work (2 = 0) (9 = .)
recode care_at_work (2 = 0) (8 9 = .)
recode dum_center (2 = 1) (3 = 1) (4 = 0) 
recode e8meses (99 = .)
gen time_center = e8meses*4 + e8semanas 
replace time_center = 0 if dum_center == 0 & missing(time_center)
drop e8meses e8semanas
recode cc_near (2 = 1) (3 4 = 0) (9=.)
recode type_center (88 = .) //(9 = otra; 88 = NC)
label val dum_work care_at_work dum_center cc_near sino

sort folio tramo
drop if folio[_n] == folio[_n-1] & tramo[_n] == tramo[_n-1]
reshape wide dum_work care_at_work who_childcare dum_center cc_near type_center time_center /*
*/ , i(folio) j(tramo)


	foreach i in 1 2 3 4 5 6 7 8 9 10 {		
		label var dum_work`i' "Trabajó o no en el tramo `i'"  
		label var care_at_work`i' "Existe/existía un centro de cuidado en su lugar de trabajo en el tramo `i'"
		label var who_childcare`i' "Quién cuidó al niñ@ en el tramo `i'"
		label var dum_center`i' "Envió o no al niñ@ a un establecimiento en el tramo `i'"
		label var cc_near`i' "Was there a center nearby?"
		label var type_center`i' "Tipo de establecimiento educacional en el tramo `i'"
		label var time_center`i' "Time went to cc (weeks) tramo `i'"
		}
		
merge 1:1 folio using `householdsb.dta'
rename _merge merge_cuidado

tempfile householdsb_aux
	save `householdsb_aux', replace

*-----------------------------------------------*
*----------"Historia Laboral" database----------*
*-----------------------------------------------*

use "$db/elpi_original/Historia_Laboral_2012", clear
keep folio orden d1i* d1t*  d2 d3 d10 d12* d13 d8

rename * *_
rename folio_ folio
rename orden_ orden

reshape wide d1i* d1t*  d2_ d3_ d10_ d12_ d12t_ d13_ d8, i(folio) j(orden)

merge 1:1 folio using `householdsb_aux'
tab _merge
rename _merge merge_historia

drop merge_hogar merge_cuidado merge_historia

rename * *_2012
rename folio_2012 folio

rename (d1i*_2012 d1t*_2012 d2*_2012 d3*_2012 d10*_2012 d12*_2012 d13*_2012 d8*_2012) (d1i* d1t* d2* d3* d10* d12* d13* d8*)

merge 1:1 folio using `Data2010.dta'
rename _merge merge_2010_2012

gen merge_elpi = .
replace merge_elpi = 1 if merge_2010_2012 == 3
replace merge_elpi = 2 if merge_2010_2012 == 1
replace merge_elpi = 3 if merge_2010_2012 == 2

label var merge_elpi "ELPI cohorts"
label define elpi_lbl 1 "Panel" 2 "ELPI 2012 cohorts" 3 "ELPI 2010 cohorts"
label values merge_elpi elpi_lbl

tempfile Data2012_2010
save `Data2012_2010.dta', replace

save "$db/ELPI_Panel.dta", replace


********************************************************************************
**# ********************* * *CLEAN ELPI 2017* * ********************************
********************************************************************************


*-------------------------------------------*
*----------"Entrevistada" database----------*
*-------------------------------------------*
use "$db/elpi_original/Entrevistada_2017", clear
	sort folio	

	* Has sibling(s)
	gen siblings_aux = (h1 == 8)
	bys folio: egen tot_sib = sum(siblings_aux)
	bysort folio: egen dum_siblings = max(siblings_aux) 
	
	*Generate "dum_young_siblings"
	gen aux_sib2 = (h1 == 8 & h3 <= 4)
	bys folio: egen tot_young_sib = sum(aux_sib2)
	gen dum_young_siblings = (tot_young_sib > 0)
	
	*Generate "dum_sibling_part" Sibling participation in center
	gen dum_sibling_part = (dum_young_siblings == 1 & e1 == 1 & e4 <= 3) //4 corresponde a prekinder y kinder
	replace dum_sibling_part = . if dum_young_siblings == 0
	
	*Dummy Mother/Father at home
	gen m_home_aux = (h1 == 2 | h1 == 4) 			//1 or 0 no other values
	bysort folio: egen m_home=max(m_home_aux)		//1 if there is a mother at home

	gen f_home_aux= (h1 == 3 | h1 == 5) 		//1 or 0 no other values
	bysort folio: egen f_home=max(f_home_aux)	//1 if there is a father at home
	
	*Generate dummy that both parents live with children (no matter the civil status)
	gen married = (f_home == 1 & m_home == 1)
	
	*Generate numero integrantes del hogar
	bys folio: egen n_integrantes = count(folio)
	
label var n_integrantes "Number of people in the home"
label var f_home "1 if Father at Home"
label var m_home "1 if Mother at Home"
label var married "1 if both parents live with child"
label var dum_siblings "1 if child has sibling(s)"
label var dum_young_siblings "1 if child has sibling(s) 4 years old or younger"
label var dum_sibling_part "1 if child's young sibling(s) goes to cc (P-K or lower)"
	
	* keep useful variables	
	ren idregion 	region 
	ren c7 			dum_smoke		//ojo NS/NR		
	ren c11 		dum_alc			//ojo NS/NR, not a dummy
	ren c15			dum_drug		//ojo NS/NR, not a dummy
	ren c18 		preg_control	//ojo NS/NR
	ren c19			q_control		//ojo NS/NR, different from 2010 version
	ren sn17a 		q_sano			//ojo NS/NR
	gen dum_sano = (q_sano>0) if q_sano!=.
	gen birth_weight=c30a*1000+c30b	
	ren ytotcorh	monthly_Y
	
	foreach v of varlist dum_smoke dum_alc dum_drug{
	    recode `v' (8 = .)
	}
	recode preg_control (9 = .)
	recode q_sano (88 = .)
	recode q_control (1/2 = 1) (3/4 = 2) (5/7 = 3) (8/99 = 4) 
	label define q_control 1 "Menos de 3" 2 "Entre 3 y 4" 3 "Entre 5 y 7" 4 "8 o más", modify //Para hacer pregunta equivalente con ELPI 2010
	label val q_control q_control
*--------------------------------------*
*----------"Hogares" database----------*
*--------------------------------------*
*Hogares and entrevistada are in same dataset for 2017

	* Generate "escolaridad"
	recode e4 (88 = .)
	recode e4_curso (9 10 = 8) //Se asume que máximo es 8
	
	gen ESC = 0 if inlist(e4,1,2,3,4,5) //No educ, preeschool, ed diferencial.
	replace ESC = e4_curso 		if inlist(e4,6,7) //Primaria o preparatoria/ basica.
	replace ESC = e4_curso + 8 	if inlist(e4,9,11) //Media  cient humanista o técnico
// 	replace ESC = 12 			if ESC == 13 | ESC==14
	replace ESC = e4_curso+6 	if inlist(e4,8,10) //Humanidades o tecnico comercial.
	replace ESC = 12 			if ESC > 12 & !missing(ESC)
	replace ESC = e4_curso+12 	if inlist(e4,12,13) //Técnico prof
	replace ESC = 15 			if ESC > 15 & !missing(ESC) 
	replace ESC = e4_curso+12 	if inlist(e4,14,15) //Univ
	replace ESC = 18 			if ESC >= 19 & !missing(ESC) 
	replace ESC = e4_curso+17 	if inlist(e4,16,17) // Postgrado. Ojo con e4_curso (5-10)
	replace ESC = 21 			if ESC > 21 & !missing(ESC)	
	replace ESC = . 			if missing(e4)
	//Missings are . in this dataset
	
	*Se corrigen los missing
	replace ESC = 12 if e4 == 12 & missing(ESC)
	replace ESC = 14 if e4 == 13 & missing(ESC)
	replace ESC = 12 if e4 == 14 & missing(ESC)
	replace ESC = 16 if e4 == 15 & missing(ESC)
	replace ESC = 16 if e4 == 16 & missing(ESC)
	replace ESC = 21 if e4 == 17 & missing(ESC)
	
	
	* Generate "nivel educacional"
	rename educ nivel_educ
	gen educ = .
	replace educ = 1 if e4 <= 7 // less than hs
	replace educ = 1 if e4 == 8  & e4_curso <= 2
	replace educ = 2 if e4 >  8  & e4 <= 11 //highschool
	replace educ = 2 if e4 == 8  & e4_curso >  2
	replace educ = 3 if e4 == 12 | e4 == 14 //less than college
	replace educ = 4 if e4 == 13 | e4 == 15 | e4 == 16 | e4 == 17 //college
	label define educ2 1 "Less than highschool" 2 "Highschool" 3 "Less than college" 4 "College"
	label val educ educ2
	
	* Generate "mother_age"
	gen  m_age_aux=h3 if h1 == 2 | h1 == 4			
	by folio: egen m_age=min(m_age_aux) 	

	* Generate "mother_sch"
	gen  m_sch_aux=ESC if h1 == 2 | h1 == 4			
	by folio: egen m_sch=min(m_sch_aux) 		
	
	*Generate "mother educ"
	gen m_educ_aux = educ if h1 == 2 | h1 == 4		
	bys folio: egen m_educ = min(m_educ_aux) 	
	
	* Generate "father_sch"
	gen  f_sch_aux = ESC if h1 == 3  | h1 == 5 | h1 == 7	
	by folio: egen f_sch=min(f_sch_aux) 		
	
	*Generate "father educ"
	gen f_educ_aux = educ if h1 == 3 | h1 == 5 | h1 == 7	
	bys folio: egen f_educ = min(f_educ_aux) 	
	
	*Child gender
	gen gender_aux = h2 if h1 == 1
	bys folio: egen gender = min(gender_aux)
	

label var m_sch "Mother's years of schooling"
label var m_educ "Mother's educational level"
label var f_sch "Father's years of schooling'"
label var f_educ "Father's educational level"
label var m_age "Mother's Age"
label var gender "Gender of child (1=male)"

*-----------------------------------------------*
*----------"Cuidado Infantil" database----------*
*-----------------------------------------------*
*Same database for 2017
ren (en10a en10b_b)	(dum_center12345 dum_center67)	//e7 antigua
recode dum_center12345 	(9=.) (2=0)
recode dum_center67 	(9=.) (2=0)

ren (en9a en9b)	(cc_near12345 cc_near67) //e11_1 antigua
recode cc_near12345 	(2=0) (9=.)
recode cc_near67 		(2=0) (9=.)

ren (en15a en15b) (type_center12345 type_center67) //e12 antigua

foreach v of varlist en11a* en11b* {
    recode `v' (99 = .)
}
gen time_center12345 = en11a_m*4 + en11a_s
replace time_center12345 = 0 if time_center12345 == . & dum_center12345 == 0 
gen time_center67 = en11b_m*4 + en11b_s
replace time_center67 = 0 if time_center67 == . & dum_center67 == 0
drop en11a* en11b*

ren cl3a 	dum_work_new1
ren cl3b 	dum_work_new2
ren cl3c 	dum_work_new3
ren cl3d 	dum_work_new4
ren cl3e 	dum_work_new5
ren cl3f 	dum_work_new6
ren cl3g 	dum_work_new7
ren cl3h	dum_work_new8
forval t = 1/8{
	recode dum_work_new`t' (2=0)
}
egen dum_work12345 = rowmax(dum_work_new1 dum_work_new2 dum_work_new3 dum_work_new4 dum_work_new5)
egen dum_work67 = rowmax(dum_work_new6 dum_work_new7)

forval t = 1/8{
	ren dum_work_new`t' 	dum_work`t'
}

keep if h1==1|h1==2

rename (o1 o10 y1) (work_aux hours_w_aux wage_aux)

keep folio f_sch f_educ m_sch m_educ gender birth_weight dum_center12345 dum_center67 dum_work12345 dum_work67 cc_* dum_siblings tot_sib dum_young_siblings f_home dum_smoke dum_alc dum_sano dum_drug preg_control h1 m_age region idcomuna married n_integrantes fexp_enc0_2 fexp_eva0_2 fexp_hog0_2 time_center12345 time_center67 monthly_Y dum_work* work_aux hours_w_aux wage_aux espanel

recode work_aux (2 = 0) (8 = .)
recode wage_aux (9 = .)
replace wage_aux = 0 if work_aux == 0 
**#//Tal vederíamos reemplazar dork = 1 if hours > 0?. Lo mismo si wage > 0
recode hours_w_aux (88 = .)
replace hours_w_aux = 0 if work_aux == 0


foreach j in work_ hours_w_ wage_ {
by folio: egen `j'a=mean(`j')
}

**********d_work**********
rename work_a d_work_a
**********wage************

local usd2017=649.33
replace wage_a=round(wage_a/`usd2017',1)

**********hours***********
replace hours_w_a=. if hours_w_a==88 //Code NA
replace hours_w_a=0 if d_work_a==0 //Code hours of unemployed as 0
replace hours_w_a=68 if hours_w_a>=68 & hours_w_a!=. //Full+part time job=68 hrs
**#Me parece que "Full+part time job=68 hrs" no se hace para ELPI 2010 y 2012

drop work_aux wage_aux hours_w_aux


by folio: gen seq=_n
keep if h1==1			//nos quedamos con los niños focales
	
tempfile db2017
		save `db2017'

*-------------------------------------------*
*----------"Evaluaciones" database----------*
*-------------------------------------------*

use "$db/elpi_original/Evaluaciones_2017", clear
sort folio

keep folio edad_mesesr battelle_pt_total tvip_pb asq_pb_12m asq_pb_18m cbcl1_pt_inter_t cbcl2_pt_inter_t

ren battelle_pt_total 	BATTELLE_t
ren tvip_pb				TVIP_t
ren asq_pb_12m			ASQ_bruto_12
ren asq_pb_18m			ASQ_bruto_18
ren cbcl1_pt_inter_t	CBCL1_t
ren cbcl2_pt_inter_t	CBCL2_t

merge 1:1 folio using `db2017.dta'
tab _merge //1500 children without evaluations
rename _merge merge_evaluaciones	//we might use mother's work as outcome, so we don't drop children without tests

tempfile db2017eval
	save `db2017eval'

	
********************************************************************************
**# ******************** * *PANEL: 2010, 2012, 2017* ***************************
********************************************************************************

rename * *_2017
rename folio_2017 folio

// merge 1:1 folio using `Data2012_2010.dta'
merge 1:1 folio using "$db/ELPI_Panel.dta"
rename _merge merge_2010_2012_2017
stp

*-----------------------------------------*
*---Birth year and month; School cohort---*
*-----------------------------------------*

gen birth_year = . 
gen birth_month = .

replace birth_year = 2010 - floor(edad_meses_2010/12)
replace birth_year = 2012 - floor(edad_meses_2012/12) if birth_year == .
replace birth_year = 2017 - floor(edad_mesesr_2017/12) if birth_year == .
replace birth_year = 2006 if birth_year < 2006 //11 datos

replace birth_month = 12 - (edad_meses_2010 - floor(edad_meses_2010/12)*12)
replace birth_month = 12 - (edad_meses_2012 - floor(edad_meses_2012/12)*12) if birth_month ==. 
replace birth_month = 12 - (edad_mesesr_2017 - floor(edad_mesesr_2017/12)*12) if birth_month ==. 

gen cohort = birth_year

gen cohort_school = .
replace cohort_school = birth_year - 1 if birth_month < 4
replace cohort_school = birth_year if birth_month >= 4


*---------------------------------------------------------*
*---Child care dummies across the three rounds database---*
*---------------------------------------------------------*
// forv t=1/6{
// tab dum_center`t'_2010, 
// tab dum_center`t'_2010, nol m
// tab dum_center`t'_2012, 
// tab dum_center`t'_2012, nol m
// }
// tab dum_center12345_2017, m
// tab dum_center67_2017, m
//
// forv t=1/8{
// sum dum_center`t'_2010
// sum dum_center`t'_2012
// }
// sum dum_center12345_2017
// sum dum_center67_2017


*dummy childcare
forvalues t=1/7{
	gen d_cc_t`t' = .
	replace d_cc_t`t' = 1 if dum_center`t'_2010 == 1
	replace d_cc_t`t' = 0 if dum_center`t'_2010 == 0 // | dum_center`t'_2010 == 9

	*search in 2012 if no history
	replace d_cc_t`t' = 1 if dum_center`t'_2012 == 1 & (dum_center`t'_2010 == .)
	replace d_cc_t`t' = 0 if dum_center`t'_2012 == 0 & (dum_center`t'_2010 == .)
}

*Two dummies for two age categories
gen d_cc_02 = .
replace d_cc_02=0 if d_cc_t1 == 0 | d_cc_t2 == 0 | d_cc_t3 == 0 | d_cc_t4 == 0 | d_cc_t5 == 0
replace d_cc_02=1 if d_cc_t1 == 1 | d_cc_t2 == 1 | d_cc_t3 == 1 | d_cc_t4 == 1 | d_cc_t5 == 1

// egen d_cc_02_2 = rowmax(d_cc_t1 d_cc_t2 d_cc_t3 d_cc_t4 d_cc_t5) //Variable está bien creada.

replace d_cc_02=dum_center12345_2017 if d_cc_02==.


gen d_cc_34 = .
replace d_cc_34=0 if d_cc_t6 == 0 | d_cc_t7 == 0
replace d_cc_34=1 if d_cc_t6 == 1 | d_cc_t7 == 1
// egen d_cc_02_34_2 = rowmax(d_cc_t6 d_cc_t7)

replace d_cc_34=dum_center67_2017 if d_cc_34==.

label var d_cc_02 "Child goes to cc center in ages 0 to 2"
label var d_cc_34 "Child goes to cc center in ages 3 to 4"


*------------------------------------------------------*
*------Did child attend cc center enough time?---------*
*------------------------------------------------------*
// Si time_center <= 20% semanas del tramo, no atendió. Asistencia bruta promedio sg CASEN es 54%. 

/*
tramo 1: 0-3 meses
tramo 2: 3-6
tramo 3: 6-12
tramo 4: 12-18
tramo 5: 18-24
tramo 6: 2-3 años
tramo 7: 3-4 
tramo 8: 4-5 
*/

foreach y in 2010 2012{
    forval t = 1/2{
	    replace dum_center`t'_`y' = 0 if time_center`t'_`y' < 3*4/5 & !missing(dum_center`t'_`y')
	}
	forval t = 3/5{
	    replace dum_center`t'_`y' = 0 if time_center`t'_`y' < 6*4/5 & !missing(dum_center`t'_`y')
	}
	forval t = 1/2{
	    replace dum_center`t'_`y' = 0 if time_center`t'_`y' < 12*4/5 & !missing(dum_center`t'_`y')
	}
}

	replace dum_center12345 = 0 if time_center12345_2017 <= 24*4/5 //24 meses max
	replace dum_center67 = 0 if time_center67_2017 <= 24*4/5 //24 meses max tb.

forvalues t=1/7{
	gen d_cc_t`t'_v2	 = dum_center`t'_2010
	replace d_cc_t`t'_v2 = dum_center`t'_2012 if dum_center`t'_2010 == .
}

egen d_cc_02_v2 = rowmax(d_cc_t1_v2 d_cc_t2_v2 d_cc_t3_v2 d_cc_t4_v2 d_cc_t5_v2)
replace d_cc_02_v2 = dum_center12345_2017 if d_cc_02_v2==.

egen d_cc_34_v2 = rowmax(d_cc_t6_v2 d_cc_t7_v2)
replace d_cc_34_v2=dum_center67_2017 if d_cc_34_v2==.

label var d_cc_02_v2 "Child goes to cc center in ages 0 to 2, 20% of the time or more"
label var d_cc_34_v2 "Child goes to cc center in ages 3 to 4, 20% of the time or more"

*------------------------------------------------------*
*-------------Was there a center nearby?---------------*
*------------------------------------------------------*

forval t = 1/8{
	gen cc_near`t' = cc_near`t'_2010
	replace cc_near`t' = cc_near`t'_2012 if cc_near`t' == .
}
gen cc_near_02 = .
replace cc_near_02 = 0 if cc_near1 == 0 | cc_near2 == 0 | cc_near3 == 0 | cc_near4 == 0 | cc_near5 == 0
replace cc_near_02 = 1 if cc_near1 == 1 | cc_near2 == 1 | cc_near3 == 1 | cc_near4 == 1 | cc_near5 == 1
replace cc_near_02 = cc_near12345_2017 if cc_near_02==.

gen cc_near_34 = .
replace cc_near_34 = 0 if cc_near6 == 0 | cc_near7 == 0 
replace cc_near_34 = 1 if cc_near6 == 1 | cc_near7 == 1 
replace cc_near_34 = cc_near67_2017 if cc_near_34==.

gen cc_near_3 = .
replace cc_near_3 = 0 if cc_near6 == 0 
replace cc_near_3 = 1 if cc_near6 == 1 
replace cc_near_3 = cc_near67_2017 if cc_near_3==.

label var cc_near_02 "1 if there was a center nearby at ages 0-2"
label var cc_near_34 "1 if there was a center nearby at ages 3-4"
label var cc_near_3 "1 if there was a center nearby at age 3"


*---------------------------------------------*
*----------Tests across three rounds----------*
*---------------------------------------------*

gen test=.
gen test_year = .
replace test=BATTELLE_t_2017
replace test_year = 2017 if test != .
replace test=BATTELLE_t_2012 if test==. & (birth_year==2005|birth_year==2006|birth_year==2007|birth_year==2008)
replace test_year = 2012 if test != . & test_year == .
replace test=BATTELLE_t_2010 if test==. & (birth_year==2005|birth_year==2006)
replace test_year = 2010 if test != . & test_year == .

label var test "test BATELLE"
label var test_year "Año de aplicación test BATELLE"


*------------------------------------------------*
*----------Controls across three rounds----------*
*------------------------------------------------*

local precontrols m_sch m_educ f_home f_sch f_educ preg_control dum_smoke dum_alc gender dum_sano m_age dum_siblings tot_sib dum_young_siblings married 

foreach var in `precontrols'{
    di "`var'"
gen `var'=`var'_2010
replace `var'=`var'_2012 if `var'==.
replace `var'=`var'_2017 if `var'==.
}

foreach var in comuna_cod WAIS_t_num WAIS_t_vo {
    di "`var'"
gen `var'=`var'_2010
replace `var'=`var'_2012 if `var'==.
}


forvalues t=1/8{
	gen dum_work_t`t' = dum_work`t'_2010 
	replace dum_work_t`t' = dum_work`t'_2012 if dum_work_t`t' ==. 
	replace dum_work_t`t' = dum_work`t'_2017 if dum_work_t`t' ==. 
	label var dum_work_t`t' "Madre trabajaba en tramo `t' (pregunta ELPI)"
}
	gen dum_work_t9  = dum_work9_2012
	gen dum_work_t10 = dum_work10_2012

egen risk=rowmean(preg_control dum_smoke dum_alc dum_sano)
// sum  risk m_sch f_home m_age dum_siblings comuna_cod WAIS_t_num WAIS_t_vo

tempfile ELPI_Panel
save `ELPI_Panel'

*save "$db/ELPI_Panel.dta", replace

********************************************************************************
**************************** * *GEODATA* * *************************************
********************************************************************************

// if `run_geo' == 1 {
// 	qui: do "$code_dir/geodata.do"
// }


*---------------------------------------------------*
*---------------CALLING ELPI DATABASE---------------*
*---------------------------------------------------*

foreach elpi_year in 2010 2012{
	global bases Centers_`elpi_year'_34center
	foreach base in $bases{
		use "$db/ELPI_N_`base'", clear
		foreach var of varlist _all {
			rename `var' `var'_`elpi_year'
		}
		rename folio_`elpi_year' folio
		tempfile `base'_temp
		save ``base'_temp'
		di "``base'_temp' saved"
	}
}

use `ELPI_Panel', clear //23245 obs
merge 1:1 folio using `Centers_2012_34center_temp'
rename _merge merge_centers34_2012
merge 1:1 folio using `Centers_2010_34center_temp'
rename _merge merge_centers34_2010

tab merge_centers34_2010 merge_centers34_2012, mi

/*Note: our assumption is that when there are no distances, that 
means that the distances are very long, not that there are variables missing
thus, our assumption implies that we should never drop observations based
on them not having distances*/

*tempfile data_2012
*save `data_2012'
*Now, 2010
*use "$db/ELPI_Panel", clear
*keep if merge_elpi == 3 // Deja a los que están sólo en 2010
						// Cohort baja a 5000 obs
// merge 1:1 folio using `Centers_2010_temp'
// rename _merge merge_centers_2010
// merge 1:1 folio using `Centers_2010_02center_temp'
// rename _merge merge_centers02_2010
// merge 1:1 folio using `Centers_2010_34center_temp'
// rename _merge merge_centers34_2010

*N_centers300_y2006_34_2012 dist_min_y2007_34_2012
*merge 1:1 folio using `data_2012' //THIS IS VERY BAD, weird behavior 
*drop _merge

*Agregando los folios que no tienen coordenadas
merge 1:1 folio using "$db/folios_sin_coordenadas"
drop _merge

foreach elpi_year in 2010 2012{
foreach y in 2006 2007 2008 2009 2010 2011 2012 2013 2014{
foreach x in 300 500 1000 5000{
	foreach v in mat cap totmat totcap{
	replace `v'`x'_y`y'_02_`elpi_year' = 0 if `v'`x'_y`y'_02_`elpi_year' == . & mis != 1 & N_centers`x'_y`y'_02_`elpi_year' == .
	replace `v'`x'_y`y'_34_`elpi_year' = 0 if `v'`x'_y`y'_34_`elpi_year' == . & mis != 1 & N_centers`x'_y`y'_34_`elpi_year' == . //AH

}
	replace N_centers`x'_y`y'_`elpi_year'	 = 0 if N_centers`x'_y`y'_`elpi_year'    == . & mis != 1
	replace N_centers`x'_y`y'_02_`elpi_year' = 0 if N_centers`x'_y`y'_02_`elpi_year' == . & mis != 1
	replace N_centers`x'_y`y'_34_`elpi_year' = 0 if N_centers`x'_y`y'_34_`elpi_year' == . & mis != 1
	
	replace N_cen_cup`x'_y`y'_02_`elpi_year' = 0 if N_cen_cup`x'_y`y'_02_`elpi_year' == . & mis != 1
	replace N_cen_cup`x'_y`y'_34_`elpi_year' = 0 if N_cen_cup`x'_y`y'_34_`elpi_year' == . & mis != 1

}
}
}


local close_2007 2010
local close_2008 2010
local close_2009 2010
local close_2010 2010
local close_2011 2012  //misma distancia
local close_2012 2012
local close_2013 2012
local close_2014 2012

gen 	min_center_toddler_34 = .
foreach dist in 300 500 1000 5000{
gen 	N_centers_toddler`dist'_34 = .
gen 	mat_centers_toddler`dist'_34 = .
gen		cap_centers_toddler`dist'_34 = .
}

foreach x in 02 34{
gen 	min_center_`x' = .
gen 	mat_min_`x' =  .
gen 	cap_min_`x' =    .
gen min_center_cupos_`x' = .
gen 	satur_`x' =       .
gen 	cap_weight_`x' = .
gen 	satur_weight_`x' =   .
gen 	min_center_pregnant_`x' = .

foreach dist in 300 500 1000 5000{
gen 	N_centers`dist'_`x'=.
gen 	mat_centers`dist'_`x' = .
gen 	cap_centers`dist'_`x' = .
gen 	totmat_centers`dist'_`x' = .
gen 	totcap_centers`dist'_`x' = .
gen 	N_centers_cupos`dist'_`x'=.
gen 	N_centers_pregnant`dist'_`x' = .
gen 	mat_centers_pregnant`dist'_`x' = .
gen 	cap_centers_pregnant`dist'_`x' = .

foreach c in 2006 2007 2008 2009 2010 2011 2012 2013{

local yr_02 = `c'+1
local yr_34 = `c'+3
if `yr_34' >= 2014 local yr_34 = 2014

*sacar a los q no tienen distancia de aca para q no se reemplacen tantas veces! poner los años afuera

replace N_centers`dist'_`x'=N_centers`dist'_y`yr_`x''_`x'_`close_`yr_`x''' 	if cohort_school==`c'
replace N_centers`dist'_`x'=N_centers`dist'_y`yr_`x''_`x'_2012 			if cohort_school==`c' & N_centers`dist'_`x'==. 
replace N_centers`dist'_`x'=N_centers`dist'_y`yr_`x''_`x'_2010 			if cohort_school==`c' & N_centers`dist'_`x'==. 

replace min_center_`x'=dist_min_y`yr_`x''_`x'_`close_`yr_`x''' 			if cohort_school==`c'
replace min_center_`x'=dist_min_y`yr_`x''_`x'_2010 						if cohort_school==`c' & min_center_`x'==.
replace min_center_`x'=dist_min_y`yr_`x''_`x'_2012 						if cohort_school==`c' & min_center_`x'==.

replace mat_centers`dist'_`x'=mat`dist'_y`yr_`x''_`x'_`close_`yr_`x''' 	if cohort_school==`c'
replace mat_centers`dist'_`x'=mat`dist'_y`yr_`x''_`x'_2012 				if cohort_school==`c' & mat_centers`dist'_`x'==. 
replace mat_centers`dist'_`x'=mat`dist'_y`yr_`x''_`x'_2010 				if cohort_school==`c' & mat_centers`dist'_`x'==. 

replace cap_centers`dist'_`x'=cap`dist'_y`yr_`x''_`x'_`close_`yr_`x''' 	if cohort_school==`c'
replace cap_centers`dist'_`x'=cap`dist'_y`yr_`x''_`x'_2012 				if cohort_school==`c' & cap_centers`dist'_`x'==. 
replace cap_centers`dist'_`x'=cap`dist'_y`yr_`x''_`x'_2010 				if cohort_school==`c' & cap_centers`dist'_`x'==. 

replace totmat_centers`dist'_`x'=totmat`dist'_y`yr_`x''_`x'_`close_`yr_`x''' if cohort_school==`c'
replace totmat_centers`dist'_`x'=totmat`dist'_y`yr_`x''_`x'_2012 			 if cohort_school==`c' & totmat_centers`dist'_`x'==. 
replace totmat_centers`dist'_`x'=totmat`dist'_y`yr_`x''_`x'_2010 			 if cohort_school==`c' & totmat_centers`dist'_`x'==. 

replace totcap_centers`dist'_`x'=totcap`dist'_y`yr_`x''_`x'_`close_`yr_`x''' 	if cohort_school==`c'
replace totcap_centers`dist'_`x'=totcap`dist'_y`yr_`x''_`x'_2012 				if cohort_school==`c' & totcap_centers`dist'_`x'==. 
replace totcap_centers`dist'_`x'=totcap`dist'_y`yr_`x''_`x'_2010 				if cohort_school==`c' & totcap_centers`dist'_`x'==. 

replace mat_min_`x'=mat_min`yr_`x''_`x'_`close_`yr_`x''' 					if cohort_school==`c'
replace mat_min_`x'=mat_min`yr_`x''_`x'_2010 								if cohort_school==`c' & mat_min_`x'==.
replace mat_min_`x'=mat_min`yr_`x''_`x'_2012 								if cohort_school==`c' & mat_min_`x'==.

replace cap_min_`x'=cap_min`yr_`x''_`x'_`close_`yr_`x''' 					if cohort_school==`c'
replace cap_min_`x'=cap_min`yr_`x''_`x'_2010 								if cohort_school==`c' & cap_min_`x'==.
replace cap_min_`x'=cap_min`yr_`x''_`x'_2012 								if cohort_school==`c' & cap_min_`x'==.

replace min_center_cupos_`x'=dist_min_cupos_y`yr_`x''_`x'_`close_`yr_`x''' 	if cohort_school==`c'
replace min_center_cupos_`x'=dist_min_cupos_y`yr_`x''_`x'_2010 				if cohort_school==`c' & min_center_cupos_`x'==.
replace min_center_cupos_`x'=dist_min_cupos_y`yr_`x''_`x'_2012 				if cohort_school==`c' & min_center_cupos_`x'==.

replace satur_`x'=sat_y`yr_`x''_`x'_`close_`yr_`x'''						if cohort_school==`c'
replace satur_`x'=sat_y`yr_`x''_`x'_2010									if cohort_school==`c' & satur_`x'==.
replace satur_`x'=sat_y`yr_`x''_`x'_2012									if cohort_school==`c' & satur_`x'==.

replace cap_weight_`x'=cap_weight_y`yr_`x''_`x'_`close_`yr_`x'''			if cohort_school==`c'
replace cap_weight_`x'=cap_weight_y`yr_`x''_`x'_2010						if cohort_school==`c'& cap_weight_`x'==.
replace cap_weight_`x'=cap_weight_y`yr_`x''_`x'_2012						if cohort_school==`c'& cap_weight_`x'==.

replace satur_weight_`x'=sat_weight_y`yr_`x''_`x'_`close_`yr_`x'''			if cohort_school==`c'
replace satur_weight_`x'=sat_weight_y`yr_`x''_`x'_2010						if cohort_school==`c' & satur_weight_`x'==.
replace satur_weight_`x'=sat_weight_y`yr_`x''_`x'_2012						if cohort_school==`c' & satur_weight_`x'==.

replace N_centers_cupos`dist'_`x'=N_cen_cup`dist'_y`yr_`x''_`x'_`close_`yr_`x''' if cohort_school==`c'
replace N_centers_cupos`dist'_`x'=N_cen_cup`dist'_y`yr_`x''_`x'_2012 			if cohort_school==`c' & N_centers_cupos`dist'_`x'==. 
replace N_centers_cupos`dist'_`x'=N_cen_cup`dist'_y`yr_`x''_`x'_2010 			if cohort_school==`c' & N_centers_cupos`dist'_`x'==. 

local yr_p_02 = `c'
local yr_p_34 = `c'

replace min_center_pregnant_`x'=dist_min_y`yr_p_`x''_`x'_`close_`yr_`x''' 	if cohort_school==`c'
replace min_center_pregnant_`x'=dist_min_y`yr_p_`x''_`x'_2010 				if cohort_school==`c' & min_center_pregnant_`x'==.
replace min_center_pregnant_`x'=dist_min_y`yr_p_`x''_`x'_2012 				if cohort_school==`c' & min_center_pregnant_`x'==.

replace N_centers_pregnant`dist'_`x'=N_centers`dist'_y`yr_p_`x''_`x'_`close_`yr_`x''' if cohort_school==`c'
replace N_centers_pregnant`dist'_`x'=N_centers`dist'_y`yr_p_`x''_`x'_2012 			if cohort_school==`c' & N_centers_pregnant`dist'_`x'==. 
replace N_centers_pregnant`dist'_`x'=N_centers`dist'_y`yr_p_`x''_`x'_2010 			if cohort_school==`c' & N_centers_pregnant`dist'_`x'==. 

replace mat_centers_pregnant`dist'_`x'=mat`dist'_y`yr_p_`x''_`x'_`close_`yr_`x''' 	if cohort_school==`c'
replace mat_centers_pregnant`dist'_`x'=mat`dist'_y`yr_p_`x''_`x'_2012 				if cohort_school==`c' & mat_centers_pregnant`dist'_`x'==. 
replace mat_centers_pregnant`dist'_`x'=mat`dist'_y`yr_p_`x''_`x'_2010 				if cohort_school==`c' & mat_centers_pregnant`dist'_`x'==. 

replace cap_centers_pregnant`dist'_`x'=cap`dist'_y`yr_p_`x''_`x'_`close_`yr_`x''' 	if cohort_school==`c'
replace cap_centers_pregnant`dist'_`x'=cap`dist'_y`yr_p_`x''_`x'_2012 				if cohort_school==`c' & cap_centers_pregnant`dist'_`x'==. 
replace cap_centers_pregnant`dist'_`x'=cap`dist'_y`yr_p_`x''_`x'_2010 				if cohort_school==`c' & cap_centers_pregnant`dist'_`x'==. 

replace min_center_toddler_34=dist_min_y`yr_02'_34_`close_`yr_34'' 				if cohort_school==`c'
replace min_center_toddler_34=dist_min_y`yr_02'_34_2010 						if cohort_school==`c' & min_center_toddler_34==.
replace min_center_toddler_34=dist_min_y`yr_02'_34_2012 						if cohort_school==`c' & min_center_toddler_34==.

replace N_centers_toddler`dist'_34=N_centers`dist'_y`yr_02'_34_`close_`yr_34''  if cohort_school==`c'
replace N_centers_toddler`dist'_34=N_centers`dist'_y`yr_02'_34_2012 			if cohort_school==`c' & N_centers_toddler`dist'_34==. 
replace N_centers_toddler`dist'_34=N_centers`dist'_y`yr_02'_34_2010 			if cohort_school==`c' & N_centers_toddler`dist'_34==. 

replace mat_centers_toddler`dist'_34=mat`dist'_y`yr_02'_34_`close_`yr_34'' 		if cohort_school==`c'
replace mat_centers_toddler`dist'_34=mat`dist'_y`yr_02'_34_2012 				if cohort_school==`c' & mat_centers_toddler`dist'_34==. 
replace mat_centers_toddler`dist'_34=mat`dist'_y`yr_02'_34_2010 				if cohort_school==`c' & mat_centers_toddler`dist'_34==. 

replace cap_centers_toddler`dist'_34=cap`dist'_y`yr_02'_34_`close_`yr_34'' 		if cohort_school==`c'
replace cap_centers_toddler`dist'_34=cap`dist'_y`yr_02'_34_2012 				if cohort_school==`c' & cap_centers_toddler`dist'_34==. 
replace cap_centers_toddler`dist'_34=cap`dist'_y`yr_02'_34_2010 				if cohort_school==`c' & cap_centers_toddler`dist'_34==. 

}
}
}

foreach x in 2006 2007 2008 2009 2010 2011 2012 2013 2014{
foreach m in 300 500 1000 5000{
	drop N_centers`m'_y`x'* cap`m'_y`x'* mat`m'_y`x'*
}
	drop mat_min`x'* cap_min`x'* cap_weight_y`x'*
}
	drop dist_min_* sat_* N_cen_cup*



********************************************************************************
*************************** * *VARIABLES* * ************************************
********************************************************************************

tempfile data_elpi_aux
save `data_elpi_aux'

keep folio d1i* d1t* d2* d12* d13* d8* cohort* birth_year birth_month
reshape long d1ia_ d1im_ d1ta_ d1tm_ d2_ d12_ d12t_ d13_ d8_, i(folio) j(order)
tempfile hist_laboral
save `hist_laboral'

use "$db/dolar_anual.dta", clear
rename periodo d1ia_ //se ocupa el dolar del ano inicio del trabajo.
merge 1:m d1ia_ using `hist_laboral'
drop if _merge == 1

replace d12_ =  . if d12_ ==  99
replace d13_ =  . if d13_ == 999
replace d13_ = 68 if d13_ >=  68 & d13_ !=. //45 + 23 = 68 (full +  part time)

replace d12t_ =   32000 if d12t_ ==  1
replace d12t_ =   98000 if d12t_ ==  2
replace d12t_ =  191000 if d12t_ ==  3
replace d12t_ =  300000 if d12t_ ==  4
replace d12t_ =  400000 if d12t_ ==  5
replace d12t_ =  550000 if d12t_ ==  6
replace d12t_ =  750000 if d12t_ ==  7
replace d12t_ =  950000 if d12t_ ==  8
replace d12t_ = 1150000 if d12t_ ==  9
replace d12t_ = 1250000 if d12t_ == 10 //No tiene tope maximo. Se asume minimo.
replace d12t_ = .       if d12t_ == 99 

replace d12_ = d12t_ if d12_ == .
replace d12_ = 0 	 if d12_ == . & inrange(d2_,2,5)
replace d13_ = 0 	 if d13_ == . & inrange(d2_,2,5)

replace d12_ = d12_/dolar_obs //para entregar salarios en dolares. VER SI NECESITAMOS TAMBIEN EN PESOS

forvalues t=1/10{
	gen ocu_t`t' = .
	gen wage_t`t' = .
	gen hours_w_t`t' = .
	*gen contract_t`t'=.  
	gen tramo_t`t'=.      //ANTO
}

gen ocu_t01 = .
gen ocu_t02 = .
gen wage_baseline = .
gen wage_t02 = .
gen hours_w_baseline = .
gen hours_w_t02 = .

************************************************************************************************************
************************************************************************************************************
sort folio order
*******Formatear fechas de inicio, fin y cumpleaños*****
egen    job_s     = concat(d1ia_ d1im_)
gen     job_start = date(job_s, "YM")
replace job_start = . if job_s==".."

egen    job_e     = concat(d1ta_ d1tm_)
gen     job_end   = date(job_e, "YM")
replace job_end   = . if job_e==".."
replace job_end   = job_end + 29 //to close the 30 day gap between periods

egen bday_=concat(birth_year birth_month)
gen bday=date(bday_, "YM")
replace bday=. if bday_==".."

drop job_s job_e bday_

*------------------------------------------------------*
*------------------NEW SEGMENTS------------------------*
*------------------------------------------------------*
	
forval t=1/10{
gen t`t'_start =.
gen t`t'_end   =.
gen t`t'_length=.
gen weight_t`t'=.
*bys folio: egen count_t`t'=count(tramo_t`t')
}

*Genero variables que me indiquen cuando debería inicial y terminar cada tramo (en fechas)
{
replace t1_start = bday           
replace t1_end   = bday + (3*30)

replace t2_start = bday + (3*30)  
replace t2_end   = bday + (6*30)    

replace t3_start = bday + (6*30)  
replace t3_end   = bday + (12*30)   

replace t4_start = bday + (12*30) 
replace t4_end   = bday + (18*30)  

replace t5_start = bday + (18*30) 
replace t5_end   = bday + (24*30)    

replace t6_start = bday + (24*30) 
replace t6_end   = bday + (36*30)    

replace t7_start = bday + (36*30) 
replace t7_end   = bday + (48*30)   

replace t8_start = bday + (48*30)
replace t8_end   = bday + (60*30)   

replace t9_start = bday + (60*30) 
replace t9_end   = bday + (72*30)   

replace t10_start= bday + (72*30) 
replace t10_end  = bday + (84*30)   
 
}


forval t=1/10{             // end date within job period                               or start date within job period
	replace tramo_t`t'=1 if  ( (job_start<=t`t'_end) & (t`t'_end<=job_end) ) | ( (job_start<=t`t'_start) & (t`t'_start<=job_end) )
	replace tramo_t`t'=1 if  ( t`t'_end>=job_end & t`t'_start<=job_end & job_end[_n+1]==.)  //special case when last tramo ends after last job 
	replace tramo_t`t'=. if  (job_start==. & job_end==.) | bday==.
	bys folio: egen count_t`t'=count(tramo_t`t') 
	replace tramo_t`t'=1 if tramo_t`t'[_n-1]==1 & tramo_t`t'[_n+1]==1 //tramos larger than job period 
}

**********************************************
*weights 

forval t=1/10{
	replace t`t'_length=ceil((t`t'_end  -  job_start)/30)   if t`t'_start<job_start   &  t`t'_end<=job_end  &  tramo_t`t'==1 //& job_start!=.
	replace t`t'_length=ceil((job_end   -  job_start)/30)   if t`t'_start<job_start   &  t`t'_end>job_end   &  tramo_t`t'==1 //& job_start!=.
	replace t`t'_length=ceil((t`t'_end  - t`t'_start)/30)   if t`t'_start>=job_start  &  t`t'_end<=job_end  &  tramo_t`t'==1 //& job_start!=.
	replace t`t'_length=ceil((job_end   - t`t'_start)/30)   if t`t'_start>=job_start  &  t`t'_end>job_end   &  tramo_t`t'==1 //& job_start!=.
	
	replace t`t'_length=1 if t`t'_length==0 //jobs that last less than a month

}

replace weight_t1 = t1_length/3
replace weight_t2 = t2_length/3
replace weight_t3 = t3_length/6
replace weight_t4 = t4_length/6
replace weight_t5 = t5_length/6
replace weight_t6 = t6_length/12
replace weight_t7 = t7_length/12
replace weight_t8 = t8_length/12
replace weight_t9 = t9_length/12
replace weight_t10= t10_length/12

forval t=1/10{
	replace weight_t`t'=1 if count_t`t'==1
}

********************************************************************************************
********************************************************************************************


forval t = 1/10{
	
	replace ocu_t`t'	 = d2_	 if tramo_t`t' == 1
	replace wage_t`t'	 = d12_  if tramo_t`t' == 1
	*di "here"
	*replace wage_t`t'	 = d12t_ if tramo_t`t' == 1 & wage_t`t' == .
	replace hours_w_t`t' = d13_  if tramo_t`t' == 1
	}

forvalues t=1/10{
	gen d_work_t`t' = .
	replace d_work_t`t' = 1 if ocu_t`t' == 1
	replace d_work_t`t' = 0 if ocu_t`t' >= 2 & ocu_t`t' < 9
	replace d_work_t`t' = . if ocu_t`t' == 9
	label var d_work_t`t' "Madre trabajaba en tramo `t'"
	
}

label define ocu_lbl  1 "working" 2 "unemployed" 3 "searching for 1st time" ///
	4 "out of LF" 5 "less than 15yo" 9 "NA"

forvalues t=1/10{
	label values ocu_t`t' ocu_lbl
}
label values ocu_t01 ocu_lbl
label values ocu_t02 ocu_lbl

forvalues t=1/2{
	gen d_work_t0`t' = .
	replace d_work_t0`t' = 1 if ocu_t0`t' == 1
	replace d_work_t0`t' = 0 if ocu_t0`t' >= 2 & ocu_t0`t'< 9
	replace d_work_t0`t' = . if ocu_t0`t' == 9
 	label var d_work_t0`t' "Mother worked `t' year before birth "
}

gen lwage_baseline = ln(wage_baseline + 1)


preserve
**********************************************************************************

forval t=1/10{
	
	keep folio d_work_t`t' wage_t`t' hours_w_t`t' weight_t`t'
	collapse (sum) d_work_t`t' wage_t`t' hours_w_t`t' [pweight=weight_t`t'], by(folio)

	tempfile using tramo_t`t'
	save `tramo_t`t''
	
	restore
	preserve
}

use `tramo_t1', clear
merge 1:1 folio using `tramo_t2'
rename _merge merge12
merge 1:1 folio using `tramo_t3'
rename _merge merge13
merge 1:1 folio using `tramo_t4'
rename _merge merge14
merge 1:1 folio using `tramo_t5'
rename _merge merge15
merge 1:1 folio using `tramo_t6'
rename _merge merge16
merge 1:1 folio using `tramo_t7'
rename _merge merge17
merge 1:1 folio using `tramo_t8'
rename _merge merge18
merge 1:1 folio using `tramo_t9'
rename _merge merge19
merge 1:1 folio using `tramo_t10'
rename _merge merge10


**********************************************************************************


forvalues t=1/10{
	replace d_work_t`t'=1 if d_work_t`t'>0&d_work_t`t'!=.	
}

merge 1:1 folio using `data_elpi_aux'
drop _merge


* Center in workplace 
gen trab_aux = . 
forval i = 1/35{
	replace trab_aux = d2_`i' if d1ia_`i' <= birth_year & d1ta_`i' >= birth_year
}
	gen care_aux1 = (trab_aux == 1 & care_at_work1_2012 == 1) 
	replace care_aux1 = . if care_at_work1_2012 == .
	gen care_aux2 = (trab_aux == 1 & care_at_work2_2012 == 1)
	replace care_aux2 = . if care_at_work1_2012 == .
tab care_aux1
drop d1i* d1t* d2* d12* d13* 



gen income_t0 = monthly_Y_2010
replace income_t0 = monthly_Y_2012 if income_t0 == .
replace income_t0 = monthly_Y_2017 if income_t0 == .

*Gen Familia Elegible del jardin (income<=p60. Using p80)
local p = 80
_pctile income_t0, p(`p')
gen elegible = (income_t0 <= r(r1))
replace elegible = . if income_t0 == .
label var elegible "Less than percentile `p' of income"


*Centro publico=1 2010 "
forval i=1/7{
gen aux_public`i'_2010=(type_center`i'_2010==2|type_center`i'_2010==3|type_center`i'_2010==4)
replace aux_public`i'_2010=. if type_center`i'_2010==.|type_center`i'_2010==6|type_center`i'_2010==9
}
*Centro ppublico=1 2012
forval i=1/7{
gen aux_public`i'_2012=(type_center`i'_2012==1|type_center`i'_2012==5|type_center`i'_2012==6)
replace aux_public`i'_2012=. if type_center`i'_2012==.|type_center`i'_2012==9|type_center`i'_2012==88
}
forval i=1/7{
gen aux_public`i'=aux_public`i'_2010
replace aux_public`i'=aux_public`i'_2012 if aux_public`i'!=1
}

*Gen public_ "1 si asiste a un centro publico, 0 si no o si va a uno privado"
egen public_02=rowtotal(aux_public1 aux_public2 aux_public3 aux_public4 aux_public5)
replace public_02=. if aux_public1==. & aux_public2==. & aux_public3==. & aux_public4==. & aux_public5==.
replace public_02=1 if public_02>=1 & public_02!=.
replace public_02=0 if d_cc_02==0 //0 sino asisten a ningun centro
tab public_02, m

egen public_34=rowtotal(aux_public6 aux_public7)
replace public_34=. if aux_public6==. & aux_public7==.
replace public_34=1 if public_34>=1 & public_34!=.
replace public_34=0 if d_cc_34==0
tab public_34, m

drop aux_public*

label var public_02 "Participation in public center at age 0-2"
label var public_34 "Participation in public center at age 3-4"

*Imputar region
gen region = region_2010 
replace region = region_2012 if region==.
replace region=8 if comuna_cod==8108
label var region "Region"

*Imputar area
gen area = area_2010
replace area = area_2012 if area==.
label var area "Area"

*Tamaño de la comuna; gen comuna_cod_2 "Agrupacion de comunas"
bys comuna_cod: egen comuna_size = count(comuna_cod)
_pctile comuna_size, p(8) // percentil 25 corresponde a 121 encuestados. p50= 164 encuestados. p75= 250
generate big_comuna= (comuna_size >=r(r1)) 
gen comuna_cod_2=comuna_cod
replace comuna_cod_2=region if big_comuna==0
*RM (13)
tab comuna_cod if comuna_cod_2 == 13
tab comuna_cod area_2012 if comuna_cod_2 == 13
replace comuna_cod_2=131 if comuna_cod_2==13 & (inrange(comuna_cod,13102, 13132) | inrange(comuna_cod,13302, 13303) | comuna_cod== 13504) 
label var comuna_cod_2 "Comune group"

*Gen min_center_02_p5 "Quintil de distancia"
xtile min_center_02_p5 = min_center_02 , n(5)
xtile min_center_34_p5 = min_center_34 , n(5)
label var min_center_02_p5 "Quintile"
label var min_center_34_p5 "Quintile"

*Gen min_center_02_p10 "Decil de distancia"
xtile min_center_02_p10 = min_center_02 , n(10)
xtile min_center_34_p10 = min_center_34 , n(10)
label var min_center_02_p10 "Decil de distancia"
label var min_center_34_p10 "Decil de distancia"

*Gen min_center_02_p100 "Percentil de distancia"
xtile min_center_02_p100 = min_center_02 , n(100)
xtile min_center_34_p100 = min_center_34 , n(100)
label var min_center_02_p100 "Percentil de distancia"
label var min_center_34_p100 "Percentil de distancia"

*Married
gen 	married02 = married 
replace married02 = married_2010 if birth_year <= 2010 & married_2010 != . 
replace married02 = married_2012 if inrange(birth_year,2010,2012) & married_2012 != .
replace married02 = married_2017 if inrange(birth_year,2013,2014) & married_2017 != .

gen 	married34 = married 
replace married34 = married_2010 if birth_year <= 2010 & married_2010 != . 
replace married34 = married_2012 if inrange(birth_year,2009,2010) & married_2012 != .
replace married34 = married_2017 if inrange(birth_year,2011,2014) & married_2017 != .

****Variables de Jorge
replace min_center_34 = min_center_34/1000
replace min_center_02 = min_center_02/1000
replace min_center_pregnant_02 = min_center_pregnant_02/1000
replace min_center_pregnant_34 = min_center_pregnant_34/1000

*Dummy for one center within X kms
foreach kms in 300 500 1000{
	gen d_onec_`kms'_02 = N_centers`kms'_02	>= 1
	gen d_onec_`kms'_34 = N_centers`kms'_34	>= 1

	replace d_onec_`kms'_02 = . if N_centers`kms'_02 == .
	replace d_onec_`kms'_34 = . if N_centers`kms'_34 == .
}

*Dummy for closest center within 1 km 
foreach age in 02 34{
	gen onekm_`age' = min_center_`age' <= 1
	replace onekm_`age' = . if min_center_`age' == .

}

*Tests
foreach variable in "TVIP_t" "CBCL2_t" "CBCL1_t" "BATTELLE_t"{
	gen `variable' = `variable'_2017 if birth_year>= 2008
	replace `variable' = `variable'_2012 if inrange(birth_year,2005,2007)
}
gen CBCL_t = CBCL1_t
replace CBCL_t = CBCL2_t if CBCL_t == .


foreach variable in "TVIP_t" "CBCL_t" "BATTELLE_t"{
	rename `variable' `variable'_aux
	egen `variable' = std(`variable'_aux)
}

gen d_cc_02_34 = d_cc_02*d_cc_34
gen min_center_02_mat_centers1000_34 = min_center_02*mat_centers1000_34
gen min_center_02_34 = min_center_02*min_center_34
gen N_centers300_34_02 = N_centers300_02*N_centers300_34


gen d_cc = (d_cc_02 == 1) | (d_cc_34 == 1)
replace d_cc = . if (d_cc_02 == .) | (d_cc_34 == .)

*Diff in diff variables
*Dummy 1 for increase in local availability (baseline 
gen delta_min_02 = min_center_02 - min_center_pregnant_02
gen delta_min_34 = min_center_34 - min_center_pregnant_34

gen delta_N_centers1000_02 = N_centers1000_02 - N_centers_pregnant1000_02
gen delta_N_centers1000_34 = N_centers1000_34 - N_centers_pregnant1000_34


gen d_treated_02 = delta_N_centers1000_02 > 0
replace d_treated_02 = . if delta_N_centers1000_02 == .

gen d_treated_34 = delta_N_centers1000_34 > 0
replace d_treated_34 = . if delta_N_centers1000_34 == .


gen d_treated = d_treated_02 == 1 | d_treated_34 == 1
replace d_treated = . if d_treated_02 == . | d_treated_34 == .


gen d_c_exposed = cohort_school<=2009



*Labeling some variables
label var test "Battelle test"
label var m_sch "Mother schooling (years)"
label var m_educ "Mother education level"
label var f_sch "Father schooling (years)"
label var f_educ "Father education level"
label var f_home "Father at home"
label var gender "Gender of child"
label var preg_control "Control during pregnancy"
label var dum_smoke "Risk: smoked during pregnancy"
label var dum_alc "Risk: alcohol during pregnancy"
label var dum_sano "Risk: no health controls"
label var m_age "Age of the mother during interview"
label var dum_siblings "Child has siblings"
label var tot_sib "Number of siblings"
label var dum_young_siblings "Child has siblings younger that 4yo"
label var comuna_cod "Comune"
label var risk "Risk during pregnancy"
label var cohort_school "School cohort"
label var married "Married/Cohabiting"
label var WAIS_t_num "WAIS. Puntaje T Digits"
label var WAIS_t_vo "WAIS. Puntaje T Vocabulary"

forval i = 1/7 {
label var d_cc_t`i' "Participation in tramo `i'"
label var d_cc_t`i'_v2 "Participation in tramo `i' (more restrictive)"
}
foreach i in "02" "34" {
label var married`i' "Married/Cohabiting at age `i'"
label var d_cc_`i' "Participation at ages `i'"
label var d_cc_`i'_v2 "Participation at ages `i' (more restrictive)"
label var min_center_`i' "Distance to the nearest center at age `i'"
label var min_center_cupos_`i' "Distance to the nearest center with space at age `i'"
label var cap_min_`i' "Capacity of the nearest center at age `i'"
label var cap_weight_`i' "Weighted average of the capacity of the centers at age `i'"
label var mat_min_`i' "Enrollment of the nearest center at age `i'"
foreach m in 300 500 1000 5000{
label var N_centers`m'_`i' "Number of centers on a `m'mt radius at age `i'"
label var N_centers_cupos`m'_`i' "Number of centers with space on a `m'mt radius at age `i'"
label var cap_centers`m'_`i' "Average capacity of the centers on a `m'mt radius at age `i'"
label var mat_centers`m'_`i' "Average enrollment of the centers on a `m'mt radius at age `i'"
}
}

drop  d3_* d10_* tot*_y* h1_2017 comuna_lab_* comuna_size big_comuna 


order folio cohort_school birth_year region* *comuna* FE* fexp_* ///
wage* edad_meses* tot_sib* dum_sibl* dum_young* f_home* married* n_integrantes* ///
m_age f_educ* m_educ* f_sch* gender* m_sch* dum_work* monthly_Y* d_work* elegible* ///
dum_smoke* dum_alc* PESO_* TALLA_* q_control* ///
dum_center* d_cc_* public* min_center_* N_centers* cap_* mat_* totc* totm* ///
BATTELLE* TVIP* ASQ* CBCL* WAIS_t* risk 



*Variabes de centros cerca
gen tiene_centro02_300 = 1 if N_centers300_02 > 0 & N_centers300_02 != .
replace tiene_centro02_300 = 0 if N_centers300_02 == 0
gen tiene_centro34_300 = 1 if N_centers300_34 > 0 & N_centers300_34 != .
replace tiene_centro34_300 = 0 if N_centers300_34 == 0

gen tiene_centro02_500 = 1 if N_centers500_02 > 0 & N_centers500_02 != .
replace tiene_centro02_500 = 0 if N_centers500_02 == 0
gen tiene_centro34_500 = 1 if N_centers500_34 > 0 & N_centers500_34 != .
replace tiene_centro34_500 = 0 if N_centers500_34 == 0

gen tiene_centro02_1000 = 1 if N_centers1000_02 > 0 & N_centers1000_02 != .
replace tiene_centro02_1000 = 0 if N_centers1000_02 == 0
gen tiene_centro34_1000 = 1 if N_centers1000_34 > 0 & N_centers1000_34 != .
replace tiene_centro34_1000 = 0 if N_centers1000_34 == 0

gen tiene_centro02_5000 = 1 if N_centers5000_02 > 0 & N_centers5000_02 != .
replace tiene_centro02_5000 = 0 if N_centers5000_02 == 0
gen tiene_centro34_5000 = 1 if N_centers5000_34 > 0 & N_centers5000_34 != .
replace tiene_centro34_5000 = 0 if N_centers5000_34 == 0


*-----------------------------------------------------------------------------*
*-----------------------------SEGMENT EXPANSION-------------------------------*
*-----------------------------------------------------------------------------*

gen tramo_2017=.
replace tramo_2017=1 if edad_mesesr_2017<3
replace tramo_2017=2 if edad_mesesr_2017>=3&edad_mesesr_2017<6
replace tramo_2017=3 if edad_mesesr_2017>=6&edad_mesesr_2017<12
replace tramo_2017=4 if edad_mesesr_2017>=12&edad_mesesr_2017<18
replace tramo_2017=5 if edad_mesesr_2017>=18&edad_mesesr_2017<24
replace tramo_2017=6 if edad_mesesr_2017>=24&edad_mesesr_2017<36
replace tramo_2017=7 if edad_mesesr_2017>=36&edad_mesesr_2017<48
replace tramo_2017=8 if edad_mesesr_2017>=48&edad_mesesr_2017<60
replace tramo_2017=9 if edad_mesesr_2017>=60&edad_mesesr_2017<72
replace tramo_2017=10 if edad_mesesr_2017>=72&edad_mesesr_2017<84
replace tramo_2017=11 if edad_mesesr_2017>=84&edad_mesesr_2017<96
replace tramo_2017=12 if edad_mesesr_2017>=96&edad_mesesr_2017<108
replace tramo_2017=13 if edad_mesesr_2017>=108&edad_mesesr_2017<120
replace tramo_2017=14 if edad_mesesr_2017>=120&edad_mesesr_2017<132
replace tramo_2017=15 if edad_mesesr_2017>132 // 151 es el max 

foreach var in "d_work" "hours_w" "wage"{
forvalues j=1/15{
	gen `var'_t`j'_2017=.
	replace `var'_t`j'_2017=`var'_a_2017 if tramo_2017==`j'
}
}


foreach var in "d_work_t" "hours_w_t" "wage_t"{
forvalues j=1/10{
	replace `var'`j'=`var'`j'_2017 if `var'`j'==.
}
forvalues j=11/15{
		gen `var'`j'=`var'`j'_2017 
}
}


*----------------------------------------------------------------------------*
*----------------------------TESTS AGE SEGMENTS------------------------------*
*----------------------------------------------------------------------------*

*-----------------------*
*------V1: BY YEAR------*
*-----------------------*
/*First I create an auxiliary variable that represents the segment the kids are in each year, according to their age. 
Then, I create one variable per test, per segment and replace that variable with the test score if the auxiliary variable==segment */

rename edad_mesesr_2017 edad_meses_2017
forvalues x=1/6{
gen TVIP_age_`x'_aux=.
gen CBCL_age_`x'_aux=.
}

replace CBCL1_t_2012=CBCL2_t_2012 if CBCL1_t_2012==.
replace CBCL1_t_2017=CBCL2_t_2017 if CBCL1_t_2017==.

foreach j in "2010" "2012" "2017"{
gen age_aux_`j'=.
replace age_aux_`j'=1 if edad_meses_`j'<=36&edad_meses_`j'!=. //<=3 years
replace age_aux_`j'=2 if edad_meses_`j'>36&edad_meses_`j'<=60&edad_meses_`j'!=. //3-5 years
replace age_aux_`j'=3 if edad_meses_`j'>60&edad_meses_`j'<=84&edad_meses_`j'!=. //5-7 years
replace age_aux_`j'=4 if edad_meses_`j'>84&edad_meses_`j'<=108&edad_meses_`j'!=. //7-9 years
replace age_aux_`j'=5 if edad_meses_`j'>108&edad_meses_`j'<=132&edad_meses_`j'!=. //9-11 years
replace age_aux_`j'=6 if edad_meses_`j'>132&edad_meses_`j'!=. //>11 years (max is 12.5 years)*/


forvalues x=1/6{
replace TVIP_age_`x'_aux=TVIP_t_`j'  if age_aux_`j'==`x'
replace CBCL_age_`x'_aux=CBCL1_t_`j' if age_aux_`j'==`x'
}
}

forvalues x=1/6{
egen TVIP_age_`x'=std(TVIP_age_`x'_aux)   
egen CBCL_age_`x'=std(CBCL_age_`x'_aux)


}

drop *_age_*_aux

save "$db/data_estimate", replace






