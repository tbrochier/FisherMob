/**
 *  peche
 *  Author: ABah
 *  Description: 03/03/16
 */
model peche


global
{
/** Insert the global definitions, variables and actions here */
	float renteTotalePeche <- 100000000.0;
	int nbPecheur <- 10;
	float biomasseTotale <- 0.0 update: 0.0;
	float biomasseTotaleSenegal <- 0.0 update: 0.0;
	float biomasseTotaleMauritanie <- 0.0 update: 0.0;
	float biomasseTotaleGuinee <- 0.0 update: 0.0;
	
	float prix <- 1000000.0;
	float prixVariable <- 100000.0;
	float demandeMax <- 100000.0 parameter:true category:'Global';
	float demande;
	float beta <- 0.001 parameter:true category:'Global';
	float capturesTotale <- 0.0 update: 0.0;
	
	float beneficeTotal <- 0.0 update: 0.0;
	float effortPecheGlobal <- 0.0 update: 0.0;
	float seuilBenefice<-200000.0 parameter:true category:'Global';
	
	int pecheursSenegal<-0 update: 0;
	int pecheursGuinee <- 0 update: 0;
	int pecheursMauritanie <- 0 update: 0;
	float k<-10000.0 parameter:true category:'Global';
	float r<-0.1 parameter:true category:'Global';
	
	
	float phi <- 0.01 parameter:true category:'Global';
	float phiPrix <- 0.1 parameter:true category:'Global';
	float nbNouveauxPecheurs;
	float capturabilite <- 0.01 parameter:true category:'Global'; 
	bool pecheurFixe<- true;
	bool prixFixe<-true;
	bool laMigration<-true;
	
	
	float coutPeche <- 200000.0 parameter:true category:'Global';
	float facteurCoutMigration<-10.0 parameter:true category:'Global';
	float biomass_max;
	init
	{
		create pecheur number: nbPecheur;
		biomass_max <- peche_grid max_of each.biomasse;
	}

	reflex dynamiqueBiomasse
	{
		ask peche_grid
		{
			do dynamiqueBiomassePatch;
		}

	}

	reflex dynamiqueBiomasseGlobale
	{
		ask peche_grid
		{
			do dynamiqueBiomasseGlobale;
		}

	}

	reflex dynamiqueCaptures
	{
		ask pecheur
		{
			capturesTotale <- capturesTotale + mesCaptures;
		}

	}

// ************************************************************************reflexe pour le calcul du prix variable***********************************
	reflex dynamiquePrix
	{
	if prixFixe = false{
		demande<- demandeMax/(1+ (beta*prixVariable));    
		prixVariable<- prixVariable + phiPrix* (demande - capturesTotale); }}
	
//*************************************************************************************************************************************************************		

	reflex dynamiqueBenefice
	{
		ask pecheur
		{
			beneficeTotal <- beneficeTotal + benefice;
		}

	}

	reflex dynamiqueBiomasseSenegal
	{
		ask peche_grid
		{
			do dynamiqueBiomasseSenegal;
		}

	}

	reflex dynamiqueBiomasseGuinee
	{
		ask peche_grid
		{
			do dynamiqueBiomasseGuinee;
		}

	}

	reflex dynamiqueBiomasseMauritanie
	{
		ask peche_grid
		{
			do dynamiqueBiomasseMauritanie;
		}

	}
   
   
	reflex calculePecheurs
	{
		list<pecheur> mesPecheurs <- (pecheur where (not dead(each)));
		ask mesPecheurs
		{
			do calculPecheurs;
		}

	}

	reflex departArriveePecheurs 
	{
		if pecheurFixe=false{
		nbNouveauxPecheurs <- ((beneficeTotal) / coutPeche) * phi;
		
		
		int nombrePecheurs<- round(nbNouveauxPecheurs); write nombrePecheurs;
		if nombrePecheurs > 0
		{
			create pecheur number: nombrePecheurs;
		} else
		{ list<pecheur> pecheursVivants <-(pecheur where (not dead(each)));
			
			ask abs(nombrePecheurs) among pecheursVivants
			
			{ 
				do die;
			}

		}

	}}

// reflex *************************************************************************************************************************************************************************************************
string result_path <- "PecheResults_"+#now +".csv";
reflex save_result{
	if (not file(result_path).exists) {
		save "Cycle,CoutPeche,FacteurCoutMigration,DemandeMax,beta,PhiPrix,phi,r,k,Capturabilite,CapturesTotales,Demande,BiomasseGuinee,BiomasseSenegal,BiomasseMauritanie,PecheursSenegal,PecheursMauritanie,PecheursGuinee,BeneficeTotal,PrixVariable"to: result_path ;
		
		}
		save[
			 cycle,
			 coutPeche,
			 facteurCoutMigration,
			 demandeMax,
			 beta,
			 phiPrix,
			 phi,			
			 r,
			 k,
			  capturabilite,
			capturesTotale,
			demande,
			biomasseTotaleGuinee,
			biomasseTotaleSenegal,
			biomasseTotaleMauritanie,
			pecheursSenegal,
			pecheursMauritanie,			
			pecheursGuinee,
			beneficeTotal,
			prixVariable
			]		          		
	   		to: result_path type: "csv";
	}

}

grid peche_grid width: 1 height: 20 neighbors: 4
{
	list<peche_grid> neighbours <- self neighbors_at 4;
	string pays <- ''; //M pour Mauritanie, S pour Senegal, G pour Guinee
	float biomasse <- k; //biomasse globale en tonne par patch
	float delta <- 20000.0;
	float coutMigration;
	rgb color update: rgb(0,0,255 * int(biomass_max/biomasse));
	init
	{
		loop i from: 0 to: 5
		{
			peche_grid[i].pays <- 'M';
			ask peche_grid[i]
			{
				color <- rgb(0, 0, 200);
				coutMigration <- coutPeche * facteurCoutMigration;
			}

		}

		loop i from: 6 to: 14
		{
			peche_grid[i].pays <- 'S';
			ask peche_grid[i]
			{
				color <- # blue;
				coutMigration <- 0.0;
			}

		}

		loop i from: 15 to: 19
		{
			peche_grid[i].pays <- 'G';
			ask peche_grid[i]
			{
				color <- rgb(0, 0, 200);
				coutMigration <- coutPeche * facteurCoutMigration;
			}

		}

	}

	action dynamiqueBiomassePatch
	{
		biomasse <- (biomasse + (r * biomasse * (1 - biomasse / k)));
	}

	action dynamiqueBiomasseGlobale
	{
		biomasseTotale <- (biomasse + biomasseTotale);
	}

	action dynamiqueBiomasseSenegal
	{
		if pays = 'S'
		{
			biomasseTotaleSenegal <- (biomasse + biomasseTotaleSenegal);
		}

	}

	action dynamiqueBiomasseGuinee
	{
		if pays = 'G'
		{
			biomasseTotaleGuinee <- (biomasse + biomasseTotaleGuinee);
		}

	}

	action dynamiqueBiomasseMauritanie
	{
		if pays = 'M'
		{
			biomasseTotaleMauritanie <- (biomasse + biomasseTotaleMauritanie);
		}

	}
	
	

}

species pecheur skills: [moving]
{
	
	float mesCaptures <- 0.0 update: 0.0;
	float benefice <- 0.0 update: 0.0;
	int compteur_deplacement<-0;
	//float effortPeche<-2.5;
	string etat;
	peche_grid myPlace;
	init
	{
		myPlace <- one_of((peche_grid as list) where (each.pays = 'S'));
		location <- myPlace.location;
		etat <- myPlace.pays;
	}

	reflex stepZonePeche 
	{ 
		
		benefice <- ((capturabilite * myPlace.biomasse * prixVariable) - (((coutPeche) + (myPlace.coutMigration))));
		if benefice < seuilBenefice
		{
			
			 if compteur_deplacement>3 { do die;}

			if laMigration = true{
			myPlace <- one_of(myPlace.neighbours);}
			else{myPlace <- one_of((myPlace.neighbours) where (each.pays = 'S'));}
			location <- myPlace.location;
			benefice<-0.0;
			compteur_deplacement<- compteur_deplacement +1;
		} else{
			do pecher;
		}

	}

	action pecher
	{ 
		mesCaptures <- (capturabilite * myPlace.biomasse); 
		myPlace.biomasse <- ((myPlace.biomasse) - mesCaptures);
		compteur_deplacement<-0;
	}

	action calculPecheurs
	{
		if (myPlace.pays = 'S')
		{
			pecheursSenegal <- pecheursSenegal + 1;
		}

		if (myPlace.pays = 'G')
		{
			pecheursGuinee <- pecheursGuinee + 1;
		}

		if (myPlace.pays = 'M')
		{
			pecheursMauritanie <- pecheursMauritanie + 1;
		}

		
	}

	aspect default
	{
		draw circle(0.5) color: rgb('red');
	}

}

experiment peche type: gui
{
/** Insert here the definition of the input and output of the model */
	parameter 'Nombre Pecheurs' var: nbPecheur category: 'Modele Pecheur';
	parameter 'Prix Initial' var: prixVariable category: 'Modele Pecheur';
	parameter "Nombre Pecheurs Fixe" var:pecheurFixe <- true category: 'Modele Pecheur';
	parameter "Prix Fixe" var: prixFixe <- true category: 'Modele Pecheur';
	parameter "Migration" var:laMigration <- true category: 'Modele Pecheur';
	
	
	
	output
	{
		display Peche refresh: every(1) type:opengl
		{
			grid peche_grid;
			species pecheur aspect: default;
			graphics "MesGraphes"
			{
				draw (peche_grid[0].pays) at: peche_grid[0].location size: 4 color: # yellow;
				draw peche_grid[6].pays at: peche_grid[6].location size: 4 color: # yellow;
				draw peche_grid[15].pays at: peche_grid[15].location size: 4 color: # yellow;
			}

		}

		display capturesTotal refresh: every(1)
		{
			chart "Captures Totales" type: series background: rgb("lightGray") style: stack
			{
				data "Captures" value: capturesTotale color: rgb("green");
				data "Demande" value: demande color: rgb("red");
			}

		}

		display courbes_Biomasse_Pays refresh: every(1)
		{
			chart "Biomasse Totale" type: series background: rgb("lightGray") style: stack
			{
			//data "Biomasse" value: biomasseTotale color: rgb("green");
				data "Biomasse Guinee" value: biomasseTotaleGuinee color: rgb("green");
				data "Biomasse Senegal" value: biomasseTotaleSenegal color: rgb("red");
				data "Biomasse MAuritanie" value: biomasseTotaleMauritanie color: rgb("blue");
			}

		}

		
		display courbes_Pecheurs refresh: every(1)
		{
			chart "Nombre de Pecheur" type: series background: rgb("lightGray") style: exploded
			{
				data "Pecheurs Senegl" value: (pecheursSenegal) color: rgb("red");
				data "Pecheurs Mauritanie" value: pecheursMauritanie color: rgb("green");
				data "Pecheurs Guinee" value: pecheursGuinee color: rgb("blue");
				//data "Pecheurs " value: nbPecheurs color: rgb("blue");
			}

		}

		display courbes_Pecheur refresh: every(1)
		{
			chart "Benefice" type: series background: rgb("lightGray") style: exploded
			{
				data "Benefice" value: beneficeTotal color: rgb("red");
			}

		}

		display courbes_Cout_Moyen refresh: every(1)
		{
			chart "Prix Variable" type: series background: rgb("lightGray") style: exploded
			{
				data "Prix" value: prixVariable color: rgb("red");
			}

		}

		
	}

}
