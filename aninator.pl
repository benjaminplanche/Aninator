non(o, n).
non(n, o).
non(u, i).
non(i, u).



% ___________________________________________
%
% 				GESTION BDD
% ___________________________________________

% __________________
% sauvegardeDonnee\1	
%	Description :
%		Sauvegarde dans le fichier donnée en paramètre les données existantes (attributs, animaux, ...).
%	Paramètres :
%		- X : Chemin du fichier.
sauvegardeDonnee(X) :- tell(X),	% Changement de flux de sortie
	% Ecriture des prédicats dans le flux.
	listing(animal), listing(categorie), listing(attributsIncompatibles), listing(attributsImpliques), listing(attribut/4), listing(formulationQuestion), listing(formulationAffirmation), listing(formulationNegation), listing(formulationInfinitive)
	
	%Fermeture du flux.
	, nl, told, write('Sauvegarde terminée').

% __________________
% chargementDonnee\1	
%	Description :
%		Charge à partir du fichier donnée en paramètre les données (attributs, animaux, ...).
%	Paramètres :
%		- X : Chemin du fichier.
chargementDonnee(X) :- exists_file(X), !, consult(X),	% Changement de flux d'entrée
	write('Chargement terminé.'),nl.	
chargementDonnee(X) :- 	write('Erreur - La base de données n\'existe pas.'),nl.% Erreur, le fichier à charger n'existe pas
		
	
% __________________
% assertNoDoublon\1	
%	Description :
%		Insère dynamiquement de nouvelles clauses en vérifiant avant si elles n'existent pas déja.
%	Paramètres :
%		- X : Clause à ajouter.
assertNoDoublon(X) :- X, !.
assertNoDoublon(X) :- assert(X).


% __________________
% ajoutAttributs\2	
%	Description :
%		Ajout d'une liste d'attributs et leurs valeurs (oui, non, p-e) à un animal donné.
%		Si cet animal possède déja un attribut avec la valeur "Peut-être" et que la liste donnée contient cet attribut avec la valeur "Oui" ou "Non", l'ancienne valeur est écrasée (la certitude l'emporte sur l'incertitude).
%	Paramètres :
%		- NewAnimal : Animal en question.
%		- ReponsesPrec : Liste d'éléments [Attribut, Valeur] à ajouter à NewAnimal.
ajoutAttributs(_, []).
ajoutAttributs(NewAnimal, [[]|ReponsesPrec]) :- ajoutAttributs(NewAnimal, ReponsesPrec).
ajoutAttributs(NewAnimal, [[Attr, Rep]|ReponsesPrec]) :-
	attribut(Attr, Rep, Nb, NewAnimal),
	!,
	Nb1 is Nb+1,
	retract(attribut(Attr, Rep, Nb, NewAnimal)),
	assert(attribut(Attr, Rep, Nb1, NewAnimal)),
	ajoutAttributs(NewAnimal, ReponsesPrec).
ajoutAttributs(NewAnimal, [[Attr, Rep]|ReponsesPrec]) :-
	assert(attribut(Attr, Rep, 1, NewAnimal)),
	ajoutAttributs(NewAnimal, ReponsesPrec).
	
% __________________
% valAttr\4
%	Description :
%		Retourne le nombre de fois où une valeur (o, n ou p) a été affectée à un attribut pour un animal donné.
%	Paramètres :
%		- Attr : Attribut questionné.
%		- Rep : Valeur de l'attribut questionnée.
%		- Nb : Nombre d'affectations.
%		- NewAnimal : Animal questionné.
valAttr(Attr, Rep, 0, NewAnimal) :- not(attribut(Attr, Rep, _, NewAnimal)),!.
valAttr(Attr, Rep, Nb, NewAnimal) :-
	attribut(Attr, Rep, Nb, NewAnimal).

% __________________
% attribut\3
%	Description :
%		Associe un attribut et un animal à la valeur la plus souvent associée à ce couple (sachant que "p" compte 2 fois moins).
%	Paramètres :
%		- Attr : Attribut questionné.
%		- Rep : Valeur de l'attribut dominante.
%		- NewAnimal : Animal questionné.	
attribut(Attr, Rep, NewAnimal) :-
	valAttr(Attr, o, NbO, NewAnimal),
	valAttr(Attr, n, NbN, NewAnimal),
	valAttr(Attr, p, NbP, NewAnimal),
	maxValAttr(NbO, NbN, NbP, Rep).

% __________________
% maxValAttr\4
%	Description :
%		Retourne la valeur dominante à partir des nombres d'affectation pour chaque valeur
%	Paramètres :
%		- NbO, NbN, NbP : Nombre d'affections resp. o, n, et p.
%		- Rep : Valeur de l'attribut dominante.	
maxValAttr(NbO, NbN, NbP, Rep) :-
	NbO > NbN,
	NbO >= (NbP/2),
	!,
	Rep = o.
maxValAttr(NbO, NbN, NbP, Rep) :-
	NbN > NbO,
	NbN >= (NbP/2),
	!,
	Rep = n.
maxValAttr(_, _, _, Rep) :- Rep = p.


% __________________
% ajoutAttributsPop\2	
%	Description :
%		Ajout d'une liste d'attributs et leurs valeurs (oui, non, p-e) à une liste d'animaux donnée.
%		Si cet animal possède déja un attribut avec la valeur "Peut-être" et que la liste donnée contient cet attribut avec la valeur "Oui" ou "Non", l'ancienne valeur est écrasée (la certitude l'emporte sur l'incertitude).
%	Paramètres :
%		- Anim : Liste d'animaux.
%		- Attr : Liste d'éléments [Attribut, Valeur] à ajouter à NewAnimal.	
ajoutAttributsPop([], _).
ajoutAttributsPop([Anim|Pop], Attr) :-
	ajoutAttributs(Anim, Attr),
	ajoutAttributsPop(Pop, Attr).
	

% __________________
% ajoutAttrPE\2	
%	Description :
%		Ajout d'un attribut avec la valeur "Peut-être" à un animal donné si cet animal ne possède pas déja cet attribut (à n'importe quelle valeur).
%	Paramètres :
%		- Anim : Animal en question.
%		- Attr : Attribut à ajouter.
ajoutAttrPE(Anim, Attr) :- not(attribut(Attr, _, Anim)), !, assert(attribut(Attr, p, Anim)).
ajoutAttrPE(_, _) :- !.

% __________________
% ajoutAttrON\3	
%	Description :
%		Ajout d'un attribut avec la valeur "Oui" ou "Non" à un animal donné si cet animal ne possède pas déja cet attribut avec la valeur "oui" ou "non" ("peut-être" sera écrasée).
%	Paramètres :
%		- Anim : Animal en question.
%		- Attr : Attribut à ajouter.
%		- Val : Valeur de l'attribut (o ou p).
ajoutAttrON(Anim, Attr, Val) :- not(attribut(Attr, _, Anim)), !, assert(attribut(Attr, Val, Anim)).
ajoutAttrON(Anim, Attr, Val) :- attribut(Attr, p, Anim), !, retract(attribut(Attr, p, Anim)), assert(attribut(Attr, Val, Anim)).
ajoutAttrON(_, _, _) :- !.

	
	
% __________________
% listeXXX\1 (XXX = {Attr, Anim, Categ}	
%	Description :
%		Retourne sous forme de liste l'ensemble demandé (ensemble des animaux connus, des attributs, ou des catégories d'attribut).
%	Paramètres :
%		- S : Liste demandée.
listeAttr(S) :- findall(Y, attribut(Y,_,_,_), L), list_to_set(L,S).
listeAnim(S) :-  findall(Y, animal(Y), L), list_to_set(L,S).
listeCateg(S) :- findall(Y, categorie(_,Y), L), list_to_set(L,S).

% __________________
% listeCouplesAttrNonTraites\1
%	Description :
%		Retourne sous forme de liste l'ensemble des couples d'attributs n'ayant pas encore fait l'objet d'étude de relations.
%	Paramètres :
%		- S : Liste demandée.
listeCouplesAttrNonTraites(S) :- findall([X,Y], attributsIncompatibles(X,_,Y,_), LInc), findall([X,Y], attributsImpliques(X,Y,_), LImp), findall([X,Y], (categorie(X,_), categorie(Y,_), X\==Y), LTout), union(LInc, LImp, LTraites), subtract(LTout, LTraites, S).


% __________________
% listeAttrCateg\2	
%	Description :
%		Retourne sous forme de liste l'ensemble des attributs appartenant à la catégorie donnée.
%	Paramètres :
%		- ListAttr : Liste d'attributs appartenants à Categ.
%		- Categ : Catégorie.
listeAttrCateg(ListAttr, Categ) :- findall(Y, categorie(Y, Categ), L), list_to_set(L, ListAttr).

% __________________
% animauxAvecAttr\4
%	Description :
%		Retourne sous forme de liste l'ensemble des animaux possédant ou non l'attribut donné.
%	Paramètres :
%		- Attr : Attribut possédé par tous les animaux de la liste Sol.
%		- Val : Valeur de l'attribut, i.e. "possède" (o), "ne possède pas" (n), ou "possède peut-être" (p).
%		- Anim : Liste contenant l'ensemble des animaux sur lequel porte la recherche.
%		- Sol : Liste contenant le sous-ensemble de Anim avec les animaux possédant l'attribut Attr.
animauxAvecAttr(_, _, [], []).
animauxAvecAttr(Attr, Val, [X|Anim], Sol) :- not(attribut(Attr, Val, X)), animauxAvecAttr(Attr, Val, Anim, Sol).
animauxAvecAttr(Attr, Val, [X|Anim], [X|Sol]) :- attribut(Attr, Val, X), animauxAvecAttr(Attr, Val, Anim, Sol).

% __________________
% countAnimauxAvecAttr\3	
%	Description :
%		Compte le nombre d'animaux possédant l'ensemble des attributs donnés.
%	Paramètres :
%		- [[Attr1, Val1]|...] : Liste des couples <Attribut, Valeur> possédés par tous les animaux décomptés. (Valeur = valeur de l'attribut, i.e. "possède" (o), "ne possède pas" (n), ou "possède peut-être" (p).)
%		- Anim : Liste contenant l'ensemble des animaux sur lequel porte la recherche.
%		- Compt : Nombre d'animaux possédant tous les attributs de Attr.
countAnimauxAvecAttr([[Attr1, Val1]|[]], Anim, Compt) :- animauxAvecAttr(Attr1, Val1, Anim, Sol), length(Sol, Compt).
countAnimauxAvecAttr([[Attr1, Val1]|Attr], Anim, Compt) :- animauxAvecAttr(Attr1, Val1, Anim, Sol), countAnimauxAvecAttr(Attr, Sol, Compt).


% ___________________________________________
%
% 			MOTEUR D'APPRENTISSAGE
% ___________________________________________

% __________________
% majAttributs\0	
%	Description :
%		Appelle la fonction de mise à jour des attributs.
%	Paramètres :
%		- /
majAttributs :-
	listeAnim(Animaux),
	listeAttr(Attributs),
	listeCouplesAttrNonTraites(CouplesAttr),
	reflexionAttributs(Animaux, CouplesAttr, 1).

% __________________
% majAttributs\2	------------ NON UTILISEE
%	Description :
%		Met à jour la BDD en créant des clauses attributs(Attr, p, Anim) pour chaque couple Attr-Anim ne possèdant pas encore de connexion.
%	Paramètres :
%		- Animaux : Liste des animaux à mettre à jour.
%		- Attributs : Liste des attributs à mettre à jour
majAttributs([], _).
majAttributs(_, []).
majAttributs([Anim|Animaux], [Attr|Attributs]) :-
	ajoutAttrPE(Anim, Attr),
	majAttributs(Animaux, [Attr|Attributs]),
	majAttributs([Anim|Animaux], Attributs).

% __________________
% majAttributs\1	
%	Description :
%		Met à jour la BDD en créant des clauses attributs(Attr, p, Anim) pour chaque couple Attr-Anim ne possèdant pas encore de connexion.
%	Paramètres :
%		- SetAnimAttrNonConnectes : Liste des couples <Animal, Attribut> à mettre à jour.
majAttributs([]).	
majAttributs([[Anim, Attr]|SetAnimAttrNonConnectes]) :-
	ajoutAttrPE(Anim, Attr),
	majAttributs(SetAnimAttrNonConnectes).


% __________________
% reflexionAttributs\3	
%	Description :
%		Avise des relations entre des couples d'attributs (attributs incompatibles ou impliqués), vérifie auprès de l'utilisateur, et met à jour la BDD en fonction.
%	Paramètres :
%		- Anim : Liste des animaux à mettre à jour.
%		- [[Attr1, Attr2]|AttrNonTraites] : Liste de couples d'attributs à étudier.
%		- NombreAttr : Nombre max de couples à étudier (pour pas surcharger l'User de questions).
reflexionAttributs(_, _, 0) :- !.
reflexionAttributs(_, [], _).
reflexionAttributs(Anim, [[Attr1, Attr2]|AttrNonTraites], NombreAttr) :-
	!,
	categorie(Attr1, Categ1),
	formulationAffirmation(Categ1, Formule1Aff),
	formulationInfinitive(Categ1, Formule1Inf),
	formulationNegation(Categ1, Formule1Neg),
	categorie(Attr2, Categ2),
	formulationAffirmation(Categ2, Formule2Aff),
	formulationInfinitive(Categ2, Formule2Inf),
	formulationNegation(Categ2, Formule2Neg),
	reflexionAttributsIncompatibles(Anim, Attr1, Attr2, o, Formule1Aff, Formule2Inf),
	reflexionAttributsIncompatibles(Anim, Attr1, Attr2, n, Formule1Neg, Formule2Inf),
	reflexionAttributsIncompatibles(Anim, Attr2, Attr1, o, Formule2Aff, Formule1Inf),
	reflexionAttributsIncompatibles(Anim, Attr2, Attr1, n, Formule2Neg, Formule1Inf),
	reflexionAttributsImpliques(Anim, Attr1, Attr2, Formule1Aff, Formule2Inf),
	reflexionAttributsImpliques(Anim, Attr2, Attr1, Formule2Aff, Formule1Inf),
	NombreAttr1 is NombreAttr-1,
	reflexionAttributs(Anim, AttrNonTraites, NombreAttr1).
	

% __________________
% reflexionAttributsIncompatibles\6	
%	Description :
%		Avise d'une relation d'incompabilité entre 2 attributs (avoir ou non Attr1 est incompatible avec avoir Attr2 ?), vérifie auprès de l'utilisateur, et met à jour la BDD en fonction.
%	Paramètres :
%		- Anim : Liste des animaux à mettre à jour.
%		- Attr1, Attr2 : Couple d'attributs à étudier.
%		- Val : Valeur à étudier du 1er attribut (o ou n).
%		- Formule1, Formule2 : Strings pour présenter l'attribut 1 et 2.
reflexionAttributsIncompatibles(Anim, Attr1, Attr2, Val, Formule1, Formule2Inf) :-
	countAnimauxAvecAttr([[Attr1, Val], [Attr2, o]], Anim, 0),
	!,
	write('Est-ce qu\'un animal '), write(Formule1), write(Attr1), write(' ne pourra jamais '), write(Formule2Inf), write(Attr2),
	write(' (incompatibilité) ?\t("o."->Oui , "n."->Non )\n'),
	obtenirReponse(Rep, [o, n]),
	write('---------------------\n'),
	assert(attributsIncompatibles(Attr1, Val, Attr2, Rep)),
	traiterIncompatibilite(Anim, Attr1, Attr2, Val, Rep).
reflexionAttributsIncompatibles(_, _, _, _, _, _).

% __________________
% traiterIncompatibilite\5
%	Description :
%		Met à jour la BDD en fonction en cas d'incompatibilité repérée.
%	Paramètres :
%		- Anim : Liste des animaux à mettre à jour.
%		- Attr1, Attr2 : Couple d'attributs à étudier.
%		- Val : Valeur étudiée du 1er attribut (o ou n).
%		- Rep : Validation de l'User.
traiterIncompatibilite(_, _, _, _, n).	
traiterIncompatibilite(Anim, Attr1, Attr2, Val, o) :-
	animauxAvecAttr(Attr1, Val, Anim, AnimAvecAttr1),
	ajoutAttributsPop(AnimAvecAttr1, [[Attr2, n]]).

% __________________
% reflexionAttributsImpliques\5
%	Description :
%		Avise d'une relation d'implication entre 2 attributs (avoir Attr1 implique avoir Attr2 ?), vérifie auprès de l'utilisateur, et met à jour la BDD en fonction.
%	Paramètres :
%		- Anim : Liste des animaux à mettre à jour.
%		- Attr1, Attr2 : Couple d'attributs à étudier.
%		- Formule1, Formule2 : Strings pour présenter l'attribut 1 et 2.
reflexionAttributsImpliques(Anim, Attr1, Attr2, Formule1Aff, Formule2Inf) :-
	countAnimauxAvecAttr([[Attr1, o], [Attr2, n]], Anim, 0),
	!,
	write('Est-ce qu\'un animal '), write(Formule1Aff), write(Attr1), write(' doit forcément '), write(Formule2Inf), write(Attr2),
	write(' (implication) ?\t("o."->Oui , "n."->Non )\n'),
	obtenirReponse(Rep, [o, n]),
	write('---------------------\n'),
	assert(attributsImpliques(Attr1, Attr2, Rep)),
	traiterImplication(Anim, Attr1, Attr2, Rep).
reflexionAttributsImpliques(_, _, _, _, _).

% __________________
% traiterImplication\5
%	Description :
%		Met à jour la BDD en fonction en cas d'implication repérée.
%	Paramètres :
%		- Anim : Liste des animaux à mettre à jour.
%		- Attr1, Attr2 : Couple d'attributs à étudier.
%		- Val : Valeur étudiée du 1er attribut (o ou n).
%		- Rep : Validation de l'User.
traiterImplication(_, _, _, n).	
traiterImplication(Anim, Attr1, Attr2, o) :-
	animauxAvecAttr(Attr1, o, Anim, AnimAvecAttr1),
	ajoutAttributsPop(AnimAvecAttr1, [[Attr2, o]]).
	
% __________________
% ajoutIntelligentAttrIncompatibles\2
%	Description :
%		Met à jour les attributs d'un animaux en prenant en compte les relations d'incompatibilité entre attributs.
%	Paramètres :
%		- Anim : Animal à mettre à jour.
%		- [[Attr,Val]|LAttr] : Liste d'attributs et leur valeur, possédés par l'animal.
ajoutIntelligentAttrIncompatibles(_, []).
ajoutIntelligentAttrIncompatibles(Anim, [[Attr,Val]|LAttr]) :-
	findall([AttrInc,n], (attributsIncompatibles(Attr, Val, AttrInc, o), not(attribut(AttrInc, n, Anim))), ListAttrInc),
	ajoutAttributs(Anim, ListAttrInc),
	ajoutIntelligentAttrIncompatibles(Anim, ListAttrInc).
	ajoutIntelligentAttrIncompatibles(Anim, LAttr).

% __________________
% ajoutIntelligentAttrImpliques\2
%	Description :
%		Met à jour les attributs d'un animaux en prenant en compte les relations d'implication entre attributs.
%	Paramètres :
%		- Anim : Animal à mettre à jour.
%		- [[Attr,Val]|LAttr] : Liste d'attributs et leur valeur, possédés par l'animal.
ajoutIntelligentAttrImpliques(_, []).
ajoutIntelligentAttrImpliques(Anim, [Attr|LAttr]) :-
	findall([AttrImp,n], (attributsImpliques(Attr, AttrImp, o), not(attribut(AttrImp, o, Anim))), ListAttrImp),
	ajoutAttributs(Anim, ListAttrImp),
	ajoutIntelligentAttrIncompatibles(Anim, ListAttrImp).
	ajoutIntelligentAttrIncompatibles(Anim, LAttr).

% __________________
% ajoutIntelligentAttr\2
%	Description :
%		Met à jour les attributs d'un animaux en prenant en compte toutes les relations entre attributs.
%	Paramètres :
%		- Anim : Animal à mettre à jour.
%		- [[Attr,Val]|LAttr] : Liste d'attributs et leur valeur, possédés par l'animal.	
ajoutIntelligentAttr(_, []).
ajoutIntelligentAttr(Anim, ListAttr) :-
	ajoutIntelligentAttrIncompatibles(Anim, ListAttr),
	ajoutIntelligentAttrImpliques(Anim, ListAttr).
	
% reflexionAttributsExclusifs(Anim, Attr1, Attr2, Formule1Aff, Formule2Inf) :-
	% not(attributsExclusifs(Attr1, Attr2, _)),
	% !,
	% countAnimauxAvecAttr([[Attr1, o], [Attr2, n]], Anim, 0),
	% !,
	% write('Est-ce qu\'un animal '), write(Formule1Aff), write(Attr1), write(' ne pourra jamais '), write(Formule2Inf), write(Attr2),
	% write(' ?\t("o."->Oui , "n."->Non )\n'),
	% obtenirReponse(Rep, [o, n]),
	% assert(attributsExclusifs(Attr1, Attr2, Rep)),
	% traiterExclusivite(Anim, Attr1, Attr2, Rep).
% reflexionAttributsExclusifs(_, _, _, _, _).

% traiterExclusivite(_, _, _, n).	
% traiterExclusivite(Anim, Attr1, Attr2, o) :-
	% animauxAvecAttr(Attr1, o, Anim, AnimAvecAttr1),
	% ajoutAttributsPop(AnimAvecAttr1, [[Attr2, n]]),
	% animauxAvecAttr(Attr2, n, Anim, AnimAvecAttr2),
	% ajoutAttributsPop(AnimAvecAttr2, [[Attr1, o]]).
	
	
% reflexionAttributsInclusifs(Anim, Attr1, Attr2, Val, Formule1Aff, Formule2Inf) :-
	% not(attributsInclusifs(Attr1, Attr2, _)),
	% !,
	% non(Val, NonVal),
	% countAnimauxAvecAttr([[Attr1, Val], [Attr2, NonVal]], Anim, NbInclu),
	% reflexionAttributsInclusifs(Anim, Attr1, Attr2, Val, NbInclu, Formule1Aff, Formule2Inf).
% reflexionAttributsInclusifs(_, _, _, _, _, _).

% reflexionAttributsInclusifs(Anim, Attr1, Attr2, o, 0, Formule1, Formule2) :-
	% !,
	% write('<Apprentissage> Est-ce qu\'un animal "'), write(Formule1), write(Attr1), write(' doit forcément '), write(Formule2), write (Attr2), write(' ?\t("o."->Oui , "n."->Non )\n'),
	% obtenirReponse(Rep, [o, n]),
	% assert(attributsInclusifs(Attr1, Attr2, Rep)),
	% traiterInclusivite(Anim, Attr1, Attr2, Rep).
% reflexionAttributsInclusifs(Anim, Attr1, Attr2, n, 0, Formule1, Formule2) :-
	% !,
	% write('<Apprentissage> Est-ce qu\'un animal "'), write(Formule1), write(Attr1), write(' doit forcément ne pas'), write(Formule2), write (Attr2), write(' ?\t("o."->Oui , "n."->Non )\n'),
	% obtenirReponse(Rep, [o, n]),
	% assert(attributsInclusifs(Attr1, Attr2, Rep)),
	% traiterInclusivite(Anim, Attr1, Attr2, Rep).
% reflexionAttributsInclusifs(_, _, _, _, _, _, _).
	
% traiterInclusivite(_, _, _, n).	
% traiterInclusivite(Anim, Attr1, Attr2, o) :-
	% animauxAvecAttr(Attr1, o, Anim, AnimAvecAttr1),
	% ajoutAttributsPop(AnimAvecAttr1, [[Attr2, o]]).


% ___________________________________________
%
% 			MOTEUR DE RECHERCHE
% ___________________________________________

% __________________
% decoupagePop\3	
%	Description :
%		Retourne le "facteur dichotomique" de l'attribut donné sur la population donnée.
%		Par "valeur discriminante" est entendue une valeur renseignant "à quel point cet facteur divise bien la population en deux". Plus l'attribut divise la population en 2 parties égales, plus cette valeur tend vers 0.
%		Il faut savoir que pour un attribut donné, donc une question, 3 réponses/valeurs sont possibles :
%			- Oui -> Dans ce cas-là restent en lisse les animaux ayant "oui" ou "peut-être" à cet attribut.
%			- Non -> Dans ce cas-là restent en lisse les animaux ayant "non" ou "peut-être" à cet attribut.
%			- Peut-être -> Tous les animaux restent en lisse et on cherche une autre question/attribut.
%		Une question intéressante est donc une question pour laquelle le nombre d'animaux "Oui" et le nombre d'animaux "Non" sont très proches, et le nombre de "Peut-être" très faible.
%		La valeur discriminante d'un attribut est donc calculée : | NbOui - NbNnon | + 2*NbPe
%	Paramètres :
%		- Attr : Attribut étudié.
%		- Anim : Liste contenant l'ensemble des animaux sur lequel porte la recherche.
%		- ValDiscri : "capacité dichotomique" associée à Attr sur Anim.
decoupagePop(Attr, Anim, ValDiscri) :- 
	length(Anim, TotalAnim), 
	countAnimauxAvecAttr([[Attr, o]], Anim, ComptO), 
	countAnimauxAvecAttr([[Attr, n]], Anim, ComptN),
	ComptPe is TotalAnim - ComptO - ComptN,
	ValDiscri is abs(ComptO - ComptN) + 2*ComptPe.

% __________________
% meilleurAttr	
%	Description :
%		Retourne l'attribut parmi une liste, qui découpe le mieux la population donnée en 2. Retourne également l'ensemble des attributs possédés par les individus de cette population dans la liste donnée d'attribut (afin de supprimer les attributs inutiles de la liste).
%	Paramètres :
%		- ListAttr : Liste d'attributs, contenant MeilleurAttr et ListAttrPop.
%		- Anim : Liste d'animaux pour laquelle MeilleurAttr est le meilleur attribut de ListAttr, partageant le mieux cette liste en deux.
%		- MeilleurAttr : Meilleur attribut de ListAttr, i.e. partageant le mieux cette liste en deux.
%		- ListAttrPop : Intersection entre ListAttr et l'ensemble des attributs présents parmi les animaux de Anim.
meilleurAttr(ListAttr, Anim, MeilleurAttr, ListAttrPop) :- 
	length(Anim, TotalAnim),
	findall(AttrPop, (member(AttrPop, ListAttr), countAnimauxAvecAttr([[AttrPop, p]], Anim, ComptPe), ComptPe \== TotalAnim), ListAttrPop), % Génération de ListAttrPop
	findall([Ratio,Attr],
		(member(Attr,ListAttrPop), decoupagePop(Attr, Anim, Ratio)), ListRatioAttr),
	sort(ListRatioAttr, ListSort),
	nth0(0, ListSort, [_, MeilleurAttr]).
	
% __________________
% reponse\5
%	Description :
%		A partir de la réponse sur un attribut, modifie les animaux encore en lisse et les attributs restants.
%	Paramètres :
%		- [AttrQ,p/o/n] : Couple <question de l'utilisateur, réponse donnée (p - Peut-être, o - Oui, n - Non)>.
%		- Anim : Liste des animaux restant avant de prendre en compte la nouvelle restriction.
%		- Attr : Liste des attributs comprenant AttrQ.
%		- Anim1 : Liste des animaux restant après prise en compte de la nouvelle restriction.
%		- Attr1 : Liste des attributs de Attr privée de AttrQ.
reponse([], Anim, Attr, Anim, Attr) :- !.
reponse([AttrQ, p], Anim, Attr, Anim, Attr1) :- subtract(Attr, [AttrQ], Attr1).
reponse([AttrQ, o], Anim, Attr, Anim1, Attr1) :- animauxAvecAttr(AttrQ, n, Anim, AnimSans), subtract(Anim, AnimSans, Anim1), subtract(Attr, [AttrQ], Attr1).
reponse([AttrQ, n], Anim, Attr, Anim1, Attr1) :- animauxAvecAttr(AttrQ, o, Anim, AnimAvec), subtract(Anim, AnimAvec, Anim1), subtract(Attr, [AttrQ], Attr1).




% ___________________________________________
%
% 		  IA - Minimax & AlphaBeta
% ___________________________________________


% maxEvaluation([], _).
% maxEvaluation([[QuestionChild, ValChild]|Reste], [QuestionMax, ValMax]) :-
	% ValChild > ValMax,
	% !,
	% maxEvaluation(Reste, [QuestionChild, ValChild]).
% maxEvaluation([[QuestionChild, ValChild]|Reste], [QuestionMax, ValMax]) :-
	% maxEvaluation(Reste, [QuestionMax, ValMax]).

	
% minimax(mammifere, [bondir, herbivore, moustache], [chat, chien, serpent, vache, lapin], [chat, chien, serpent, vache, rat], 3, i, [X,Y]).
	
	
	
% minimax(QuestionFeuille, [], PopI, PopU, _, _, [_,Val]) :-
	% !,
	% % Calcule de la population minimale IA découpée par la question Attr :
	% reponse([QuestionFeuille, o], PopI, _, PopIOui, _),
	% reponse([QuestionFeuille, n], PopI, _, PopINon, _),
	% minPop(PopIOui, PopINon, PopI1),
	% % Calcule de la population maximale User découpée par la question Attr :
	% reponse([QuestionFeuille, o], PopU, _, PopUOui, _),
	% reponse([QuestionFeuille, n], PopU, _, PopUNon, _),
	% maxPop(PopUOui, PopUNon, PopU1),
	% length(PopI1, LI),
	% length(PopU1, LU),
	% fonctionEvaluationQuestionBattle(LI, LU, Val).
% minimax(Question, _, PopI, PopU, 0, _, [_,Val]) :-
	% !,
	% % Calcule de la population minimale IA découpée par la question Attr :
	% reponse([Question, o], PopI, _, PopIOui, _),
	% reponse([Question, n], PopI, _, PopINon, _),
	% minPop(PopIOui, PopINon, PopI1),
	% % Calcule de la population maximale User découpée par la question Attr :
	% reponse([Question, o], PopU, _, PopUOui, _),
	% reponse([Question, n], PopU, _, PopUNon, _),
	% maxPop(PopUOui, PopUNon, PopU1),
	% length(PopI1, LI),
	% length(PopU1, LU),
	% fonctionEvaluationQuestionBattle(LI, LU, Val).
% minimax(Question, QuestionsRestantes, PopI, PopU , Profondeur, Tour, [NextQuestion, Val]) :-
	% % En partant sur le principe que max(a,b) = -min(-a, -b), on peut ainsi regrouper les 2 cas (recherche du Min quand c'est le tour de l'User, recherche du max que c'est le tour de l'IA) en un seul, en appliquant un coef -1 aux valeurs quand User :
	% coefMinMax(Tour, Coef),
	% non(Tour, Tour1),
	% Profondeur1 is Profondeur-1,
	% % Calcule de la population minimale IA découpée par la question Attr :
	% reponse([Question, o], PopI, _, PopIOui, _),
	% reponse([Question, n], PopI, _, PopINon, _),
	% minPop(PopIOui, PopINon, PopI1),
	% % Calcule de la population maximale User découpée par la question Attr :
	% reponse([Question, o], PopU, _, PopUOui, _),
	% reponse([Question, n], PopU, _, PopUNon, _),
	% maxPop(PopUOui, PopUNon, PopU1),
	% % Evaluation des prochaines questions :
	% consulterQuestionsChild(QuestionsRestantes, QuestionsRestantesPopI1, PopI1, PopU1, Profondeur1, Tour1, Coef, ListChildVal),
	% % setof([QuestionChild, ValChild], (
		% % member(QuestionChild, QuestionsRestantes),
		% % subtract(QuestionsRestantes, [QuestionChild], QuestionsRestantes1),
		% % minimax(QuestionChild, QuestionsRestantes1, PopI1, PopU1, Profondeur1, Tour1, [_, ValChildOff]),
		% % ValChild = Coef*ValChildOff,
		% % write(QuestionChild), write(' - '), write([_, ValChild]), nl,
		% % read(_)
	% % ), ListChildVal),
	% % Recherche de la plus intéressante (la pire si User, la mieux si IA) :
	% bestNextQuestion(ListChildVal, [NextQuestion, ValUnOff]),
	% Val is (Coef*ValUnOff).
	
% consulterQuestionsChild([], _, _, _, _, _, _, []).
% consulterQuestionsChild([QuestionChild|QuestionsChildNonTraitees], QuestionsRestantes, PopI1, PopU1, Profondeur1, Tour1, Coef, [[QuestionChild, ValChild]|ListChildVal]) :-
	% minimax(QuestionChild, QuestionsRestantes, PopI1, PopU1, Profondeur1, Tour1, [_, ValChildOff]),
	% ValChild is (Coef*ValChildOff),
	% consulterQuestionsChild(QuestionsChildNonTraitees, QuestionsRestantes, PopI1, PopU1, Profondeur1, Tour1, Coef, ListChildVal).

	
	
% __________________
% minPop\3
%	Description :
%		Retourne la population la moins remplie des deux.
%	Paramètres :
%		- PopA : 1ere population donnée.
%		- PopB : 2eme population donnée.
%		- PopMin : min(PopA, PopB).
minPop([], PopB, PopB) :- !.
minPop(PopA, [], PopA) :- !.
minPop(PopA, PopB, PopA) :- length(PopA, X), length(PopB, Y), X < Y, !.
minPop(PopA, PopB, PopB).

% __________________
% maxPop\3
%	Description :
%		Retourne la population la plus remplie des deux.
%	Paramètres :
%		- PopA : 1ere population donnée.
%		- PopB : 2eme population donnée.
%		- PopMax : max(PopA, PopB).
maxPop(PopA, PopB, PopA) :- length(PopA, X), length(PopB, Y), X > Y, !.
maxPop(PopA, PopB, PopB).

% __________________
% fonctionEvaluationQuestionBattle\3
%	Description :
%		Calcule l'évaluation d'une situation où l'User hésite entre Li animaux et l'IA entre Lu.
%	Paramètres :
%		- Li : Nombre d'animaux auquel peut songer l'User.
%		- Lu : Nombre d'animaux auquel peut songer l'IA.
%		- Val : Valeur évaluant la situation.
fonctionEvaluationQuestionBattle(1, Lu, Val) :- Lu \== 1, !, Val = -1000000.
fonctionEvaluationQuestionBattle(Li, 1, Val) :- Li \== 1, !, Val = 1000000.
fonctionEvaluationQuestionBattle(Li, Lu, Val) :- Val is Li-Lu.
	

coefMinMax(i, 1).
coefMinMax(u, -1).	
	

% ________________________________________
% NON UTILISEE - DEBUT
% ________________________________________

	
% __________________
% minimax\6
%	Description :
%		Retourne la prochaine meilleure question selon l'algo. Minimax.
%	Paramètres :
%		- Questions : Liste des questions encore possibles.
%		- PopI : Liste des animaux auquel peut songer l'IA.
%		- Popu : Liste des animaux auquel peut songer l'User.
%		- Profondeur : Profondeur de recherche.
%		- Tour : Joueur actuel.
%		- [Question, Val] : Meilleure question suggérée et sa valeur.
minimax(Questions, PopI, PopU, Profondeur, Tour, [NextQuestion, Val]) :-
	minimax(Questions, Questions, PopI, PopU, Profondeur, Tour, ListChildVal),
	bestNextQuestion(ListChildVal, [NextQuestion, Val]).
	
% __________________
% minimax\7
%	Description :
%		Effectue l'algo. Minimax.
%	Paramètres :
%		- Questions : Liste des questions encore possibles encore non-évaluées.
%		- Questions : Liste des questions encore possibles.
%		- PopI : Liste des animaux auquel peut songer l'IA.
%		- Popu : Liste des animaux auquel peut songer l'User.
%		- Profondeur : Profondeur de recherche.
%		- Tour : Joueur actuel.
%		- [Question, Val] : Meilleure question suggérée et sa valeur.
minimax([], _, PopI, PopU, _, _, [[_,Val]]) :-
	!,
	length(PopI, LI),
	length(PopU, LU),
	fonctionEvaluationQuestionBattle(LI, LU, Val).
minimax(_, _, PopI, PopU, 0, _, [[_,Val]]) :-
	!,
	length(PopI, LI),
	length(PopU, LU),
	fonctionEvaluationQuestionBattle(LI, LU, Val).
minimax([QuestionChild|QuestionsChildNonTraitees], QuestionsRestantes, PopI, PopU, Profondeur, Tour, [[QuestionChild, Val]|ListChildVal]) :-
	coefMinMax(Tour, Coef),
	non(Tour, Tour1),
	Profondeur1 is Profondeur-1,
	% Calcule de la population minimale IA découpée par la question Attr :
	reponse([QuestionChild, o], PopI, _, PopIOui, _),
	reponse([QuestionChild, n], PopI, _, PopINon, _),
	minPop(PopIOui, PopINon, PopI1),
	% Calcule de la population maximale User découpée par la question Attr :
	reponse([QuestionChild, o], PopU, _, PopUOui, _),
	reponse([QuestionChild, n], PopU, _, PopUNon, _),
	maxPop(PopUOui, PopUNon, PopU1),
	% Evaluation des prochaines questions :
	subtract(QuestionsRestantes, [QuestionChild], QuestionsRestantes1),
	minimax(QuestionsRestantes1, QuestionsRestantes1, PopI1, PopU1, Profondeur1, Tour1, ListChildVal1),
	bestNextQuestion(ListChildVal1, [_, ValUnOff]),
	Val is (Coef*ValUnOff),
	minimax(QuestionsChildNonTraitees, QuestionsRestantes, PopI, PopU, Profondeur, Tour, ListChildVal).

% __________________
% bestNextQuestion\2
%	Description :
%		Retourne la meilleure question parmi celles évaluées.
%	Paramètres :
%		- Questions : Liste des couples <Question, Evaluation selon MiniMax>.
%		- [Question, Val] : Meilleure question suggérée et sa valeur.	
bestNextQuestion([[Question,Val]|ListeQuestions], Best) :- bestNextQuestion(ListeQuestions, [Question,Val], Best).
	
% __________________
% bestNextQuestion\3
%	Description :
%		Effectue la recherche de la meilleure question parmi celles évaluées.
%	Paramètres :
%		- Questions : Liste des couples <Question, Evaluation selon MiniMax>.
%		- [QuestionTemp, ValTemp] : Meilleure question suggérée et sa valeur parmi celles déja consultées.
%		- [Question, Val] : Meilleure question suggérée et sa valeur.	
bestNextQuestion([], CurrentBest, CurrentBest).
bestNextQuestion([[Question, Val]|Liste], [_, CurrentBestVal], [BestNext, BestVal]) :-
	Val > CurrentBestVal,
	!,
	bestNextQuestion(Liste, [Question, Val], [BestNext, BestVal]).
bestNextQuestion([_|Liste], [CurrentBestNext, CurrentBestVal], [BestNext, BestVal]) :-
	bestNextQuestion(Liste, [CurrentBestNext, CurrentBestVal], [BestNext, BestVal]).
	
	
% ________________________________________
% NON UTILISEE - FIN
% ________________________________________	
	

	
% __________________
% bestNextQuestion\7
%	Description :
%		Retourne la meilleure question parmi celles évaluées en utilisant l'algo AlphaBeta.
%	Paramètres :
%		- Questions : Liste des questions possibles.
%		- PopI : Liste des animaux auquel peut songer l'IA.
%		- Popu : Liste des animaux auquel peut songer l'User.
%		- Profondeur : Profondeur de recherche.
%		- Tour : Joueur actuel.
%		- Alpha : Valeur initiale d'Alpha.
%		- Beta : Valeur initiale de beta.
%		- [Question, Val] : Meilleure question suggérée et sa valeur.
bestNextQuestion([Q|Questions], PopI, PopU, Profondeur, Alpha, Beta, [BestNext, BestVal]) :-
		alphaBeta(Q, Questions, PopI, PopU, Profondeur, Alpha, Beta, i, Val),
		bestNextQuestion(Questions, [Q|Questions], PopI, PopU, Profondeur, Alpha, Beta,[Q, Val], [BestNext, BestVal]).
	
% __________________
% bestNextQuestion\9
%	Description :
%		Effectue la recherche de la meilleure question parmi celles évaluées en utilisant l'algo AlphaBeta.
%	Paramètres :
%		- Questions : Liste des questions possibles encore non évaluées.
%		- Questions : Liste des questions possibles.
%		- PopI : Liste des animaux auquel peut songer l'IA.
%		- Popu : Liste des animaux auquel peut songer l'User.
%		- Profondeur : Profondeur de recherche.
%		- Tour : Joueur actuel.
%		- Alpha : Valeur initiale d'Alpha.
%		- Beta : Valeur initiale de beta.
%		- [Question, Val] : Meilleure question suggérée et sa valeur parmi celles déja évaluées.
%		- [Question, Val] : Meilleure question suggérée et sa valeur.
bestNextQuestion([], _, _, _, _, _, _, CurrentBest, CurrentBest).
bestNextQuestion([Q|QuestionsRest], Questions, PopI, PopU, Profondeur, Alpha, Beta,[CurrentBestNext, CurrentBestVal], [BestNext, BestVal]) :-
	subtract(Questions, [Q], Questions2),
	alphaBeta(Q, Questions2, PopI, PopU, Profondeur, Alpha, Beta, i, Val),
	Val >= CurrentBestVal,
	!,
	bestNextQuestion(QuestionsRest, Questions, PopI, PopU, Profondeur, Alpha, Beta,[Q, Val], [BestNext, BestVal]).
bestNextQuestion([Q|QuestionsRest], Questions, PopI, PopU, Profondeur, Alpha, Beta,[CurrentBestNext, CurrentBestVal], [BestNext, BestVal]) :-
	bestNextQuestion(QuestionsRest, Questions, PopI, PopU, Profondeur, Alpha, Beta, [CurrentBestNext, CurrentBestVal], [BestNext, BestVal]).
	
	
% __________________
% alphaBeta\9
%	Description :
%		Effectue l'algo AlphaBeta.
%	Paramètres :
%		- Questions : Liste des questions possibles encore non évaluées.
%		- Questions : Liste des questions possibles.
%		- PopI : Liste des animaux auquel peut songer l'IA.
%		- Popu : Liste des animaux auquel peut songer l'User.
%		- Profondeur : Profondeur de recherche.
%		- Tour : Joueur actuel.
%		- Alpha : Valeur initiale d'Alpha.
%		- Beta : Valeur initiale de beta.
%		- Tour : Joueur actuel dans l'arborescence.
%		- [Question, Val] : Meilleure question suggérée et sa valeur.
alphaBeta([], _, PopI, PopU, _, _, _, _, Val) :-
	!,
	length(PopI, LI),
	length(PopU, LU),
	fonctionEvaluationQuestionBattle(LI, LU, Val).
alphaBeta(_, _, PopI, PopU, 0, _, _, _, Val) :-
	!,
	length(PopI, LI),
	length(PopU, LU),	
	fonctionEvaluationQuestionBattle(LI, LU, Val).
alphaBeta(QuestionNoeud, Questions, PopI, PopU, Profondeur, Alpha, Beta, i, Val) :-
	% Calcule de la population minimale IA découpée par la question Attr :
	reponse([QuestionChild, o], PopI, _, PopIOui, _),
	reponse([QuestionChild, n], PopI, _, PopINon, _),
	minPop(PopIOui, PopINon, PopI1),
	% Calcule de la population maximale User découpée par la question Attr :
	reponse([QuestionChild, o], PopU, _, PopUOui, _),
	reponse([QuestionChild, n], PopU, _, PopUNon, _),
	maxPop(PopUOui, PopUNon, PopU1),
	P1 is Profondeur-1,
	alphaBetaMax(Questions, Questions, PopI1, PopU1, P1, Alpha, Beta, Val).
	
alphaBeta(QuestionNoeud, Questions, PopI, PopU, Profondeur, Alpha, Beta, u, Val) :-
	% Calcule de la population minimale IA découpée par la question Attr :
	reponse([QuestionChild, o], PopI, _, PopIOui, _),
	reponse([QuestionChild, n], PopI, _, PopINon, _),
	minPop(PopIOui, PopINon, PopI1),
	% Calcule de la population maximale User découpée par la question Attr :
	reponse([QuestionChild, o], PopU, _, PopUOui, _),
	reponse([QuestionChild, n], PopU, _, PopUNon, _),
	maxPop(PopUOui, PopUNon, PopU1),
	P1 is Profondeur-1,
	alphaBetaMin(Questions, Questions, PopI1, PopU1, P1, Alpha, Beta, Val).

% __________________
% alphaBetaMax\9
%	Description :
%		Effectue l'évaluation Max de l'algo AlphaBeta.
%	Paramètres :
%		- Questions : Liste des questions possibles encore non évaluées.
%		- Questions : Liste des questions possibles.
%		- PopI : Liste des animaux auquel peut songer l'IA.
%		- Popu : Liste des animaux auquel peut songer l'User.
%		- Profondeur : Profondeur de recherche.
%		- Tour : Joueur actuel.
%		- Alpha : Valeur initiale d'Alpha.
%		- Beta : Valeur initiale de beta.
%		- AlphaFinal : Valeur d'Alpha obtenue.
alphaBetaMax([], _, _, _, _, Alpha, _, Alpha).
alphaBetaMax(_, _, _, _, _, Alpha, Beta, Alpha) :-
	Alpha >= Beta,
	!.
alphaBetaMax([Q|QuestionsAutre], Questions, PopI, PopU, Profondeur, Alpha, Beta, AlphaFinal) :-
	subtract(Questions, [Q], Questions2),
	alphaBeta(Q, Questions2, PopI, PopU, Profondeur, Alpha, Beta, u, Val),
	Alpha1 is max(Alpha, Val),
	alphaBetaMax(QuestionsAutre, Questions, PopI, PopU, Profondeur, Alpha1, Beta, AlphaFinal).
	
% __________________
% alphaBetaMin\9
%	Description :
%		Effectue l'évaluation Min de l'algo AlphaBeta.
%	Paramètres :
%		- Questions : Liste des questions possibles encore non évaluées.
%		- Questions : Liste des questions possibles.
%		- PopI : Liste des animaux auquel peut songer l'IA.
%		- Popu : Liste des animaux auquel peut songer l'User.
%		- Profondeur : Profondeur de recherche.
%		- Tour : Joueur actuel.
%		- Alpha : Valeur initiale d'Alpha.
%		- Beta : Valeur initiale de beta.
%		- BetaFinal : Valeur de Beta obtenue.
alphaBetaMin([], _, _, _, _, _, Beta, Beta).
alphaBetaMin(_, _, _, _, _, Alpha, Beta, Beta) :-
	Alpha >= Beta,
	!.
alphaBetaMin([Q|QuestionsAutre], Questions, PopI, PopU, Profondeur, Alpha, Beta, BetaFinal) :-
	subtract(Questions, [Q], Questions2),
	alphaBeta(Q, Questions2, PopI, PopU, Profondeur, Alpha, Beta, i, Val),
	Beta1 is min(Beta, Val),
	alphaBetaMin(QuestionsAutre, Questions, PopI, PopU, Profondeur, Alpha, Beta1, BetaFinal).

	

% ___________________________________________
%
% 			  INTERFACE ANINATOR
% ___________________________________________

formulation(o, Categ, Texte) :- formulationAffirmation(Categ, Texte).
formulation(n, Categ, Texte) :- formulationNegation(Categ, Texte).

% __________________
% verifReponse\3
%	Description :
%		Vérifie la validité d'une réponse de l'utilisateur, i.e. si sa réponse appartient à un ensemble de réponses admises. Si ce n'est pas le cas, une nouvelle réponse est demandée, et ce jusqu'à obtenir une valide.
%	Paramètres :
%		- Rep1 : Réponse actuelle donnée.
%		- Rep : Réponse finale valide.
%		- RepPossible : Liste des réponses admises.
verifReponse(Rep, Rep, RepPossible) :- member(Rep, RepPossible).
verifReponse(Rep1, Rep, RepPossible) :- not(member(Rep1, RepPossible)), write('Erreur - Caractère non reconnu.\nRéessayer :\n'), obtenirReponse(Rep, RepPossible).

% __________________
% obtenirReponse\2
%	Description :
%		Obtient la réponse de l'utilisateur, et vérifie sa validité. Si elle est invalide, une nouvelle réponse est demandée.
%	Paramètres :
%		- Rep : Réponse finale.
%		- RepPossible : Liste des réponses admises.
obtenirReponse(Rep, RepPossible) :- read(Rep1), verifReponse(Rep1, Rep, RepPossible).

% __________________
% poserQuestion\2
%	Description :
%		Pose une question à l'utilisateur, pour savoir si l'animal à deviner possède l'attribut choisi.
%	Paramètres :
%		- Attr : Attribut sur lequel porte la question.
%		- Rep : Réponse de l'utilisats	eur (p - Peut-être, o - Oui, n - Non).
poserQuestion(Attr, Rep) :- 
	categorie(Attr, Categ),
	formulationQuestion(Categ, Question),
	write(Question), write(Attr), write(' ?\t("o."->Oui , "n."->Non , "p."->Peut-être)\n'),
	obtenirReponse(Rep, [o, n, p]),
	write('---------------------\n').
	
	
% __________________
% poserQuestionRecurs\2
%	Description :
%		Pose une question à l'utilisateur, pour savoir si l'animal à deviner possède l'attribut choisi.
%	Paramètres :
%		- Attr : Attribut sur lequel porte la question.
%		- Rep : Réponse de l'utilisats	eur (p - Peut-être, o - Oui, n - Non).
poserQuestionRecurs(Attr, Rep) :- 
	categorie(Attr, Categ),
	formulationQuestion(Categ, Question),
	write('Maintenant, réponds à ta propre question :\n'), 
	write(Question), write(Attr), write(' ?\t("o."->Oui , "n."->Non)\n'),
	obtenirReponse(Rep, [o, n]),
	write('---------------------\n').

confirmation(o).
% __________________
% poserConfirmation\1
%	Description :
%		Demande confirmation à l'utilisateur, pour savoir si l'animal restant est le bon.
%	Paramètres :
%		- DernierAnim : Animal restant.
poserConfirmation(DernierAnim) :-
	write('Tu penses à '), write(DernierAnim), write(' ! Ai-je raison ?\t("o."->Oui , "n."->Non)"\n'),
	obtenirReponse(Rep, [o, n]),
	confirmation(Rep).

% __________________
% donnerExemplesAttribut\3
%	Description :
%		Affiche un certain nombre d'attributs d'une catégorie donnée.
%	Paramètres :
%		- Categ : Catégorie des attributs à retourner.
%		- Num : Nombre d'attributs max à retourner.	
%		- List : Liste des attributs de Categ.
donnerExemplesAttribut(Categ, Num, [Attr|List]) :- Num \== 0, write(Attr), write(', '), Num1 is Num-1, donnerExemplesAttribut(Categ, Num1, List), !.
donnerExemplesAttribut(_, 0, _) :- !.
donnerExemplesAttribut(_, _, []) :- !.

% __________________
% donnerExemplesAttribut\2	
%	Description :
%		Appelle la fonction d'affichage d'un certain nombre d'attributs d'une catégorie donnée.
%	Paramètres :
%		- Categ : Catégorie des attributs à retourner.
%		- Num : Nombre d'attributs max à retourner.	
donnerExemplesAttribut(Categ, Num) :-
	listeAttrCateg(ListAttr, Categ),
	formulationQuestion(Categ, Question),
	write(Question), write('... '),
	donnerExemplesAttribut(Categ, Num, ListAttr).

% __________________
% afficherCategorie\3
%	Description :
%		Appelle la liste numérotée des catégories.
%	Paramètres :
%		- ListCateg : Liste des catégories à afficher.
%		- Num : Numéro de la catégorie actuelle.	
%		- ListNum : Liste des numéros de catégorie.	
afficherCategorie([], _, []).
afficherCategorie([Categ|ListCateg], Num, [Num|ListNum]) :- write(Num), write(' - '), write(Categ), write('\n'), Num1 is Num+1, afficherCategorie(ListCateg, Num1, ListNum).

% __________________
% obtenirCategorie\1
%	Description :
%		Obtient de l'utilisateur une catégorie choisie parmi la liste de toutes celles connues.
%	Paramètres :
%		- Categ : Catégorie choisie.
obtenirCategorie(Categ) :-
	write('A quelle catégorie appartiendrait cet attribut ?\n'),
	listeCateg(List),
	afficherCategorie(List, 1, ListNum),
	write('Entrez le numéro correspondant : '),
	obtenirReponse(Rep, ListNum),
	Rep1 is Rep-1,
	nth0(Rep1, List, Categ).

% __________________
% demanderConfirmation\1
%	Description :
%		Pose une question à l'utilisateur, pour savoir si l'animal à deviner possède l'attribut choisi.
%	Paramètres :
%		- DernierAnim : Animal restant.	
demanderConfirmation(DernierAnim, ReponsesPrec) :-
	poserConfirmation(DernierAnim),
	ajoutAttributs(DernierAnim, ReponsesPrec),
	write('Cool !'), !.
demanderConfirmation(DernierAnim, ReponsesPrec) :-
write('---------------------\n'),
	write('Zut à quel animal pensais-tu ?\n'),
	read(NewAnimal),
	write('---------------------\n'),
	write('Peux-tu m\'aider à ne plus confondre ces 2 animaux, en me donnant un attribut différenciant '), write(NewAnimal), write(' de '), write(DernierAnim), write(' ?\n'),
	obtenirCategorie(Categ),
	write('---------------------\n'),
	write('Voici des exemples d\'attribut de cette catégorie :\n'),
	donnerExemplesAttribut(Categ, 5), write('...\n'),
	write('Entrez maintenant cet attribut, que possède '), write(NewAnimal), write(' et pas '), write(DernierAnim), write(' : '),
	read(NewAttr),
	assertNoDoublon(animal(NewAnimal)),
	assertNoDoublon(categorie(NewAttr, Categ)),
	ajoutAttributs(NewAnimal, [[NewAttr, o]|ReponsesPrec]),
	ajoutAttributs(DernierAnim, [[NewAttr, n]]),
	ajoutIntelligentAttr(NewAnimal, [[NewAttr, o]|ReponsesPrec]),
	ajoutIntelligentAttr(DernierAnim, [[NewAttr, n]]),
	write('---------------------\n'),
	write('Merci de ta contribution !\n').

% __________________
% associerAttrAnim\3
%	Description :
%		Pour un attribut donné, demande à l'utilisateur la valeur pour différents animaux d'une liste donnée.
%	Paramètres :
%		- NewAttr : Attribut à évaluer pour les différents animaux.	
%		- AnimRestants : Liste d'animaux à caractériser.	
%		- Num : Nombre max d'animaux de cette liste à caractériser.	
associerAttrAnim(_, [], _) :- !.	
associerAttrAnim(_, _, 0) :- !.	
associerAttrAnim(NewAttr, [Anim|AnimRestants], Num) :-
	write('- '), write(Anim), write(' : Possède-t-il cet attribut ?\t("o."->Oui , "n."->Non , "p."->Peut-être)\n'),
	obtenirReponse(Rep, [o, p, n]),
	write('---------\n'),
	ajoutAttributs(Anim, [[NewAttr, Rep]]),
	ajoutIntelligentAttr(Anim, [[NewAttr, Rep]]),
	Num1 is Num-1,
	associerAttrAnim(NewAttr, AnimRestants, Num1).

% __________________
% associerAnimAttr\3
%	Description :
%		Pour un animal donné, demande à l'utilisateur la valeur associée pour différents attributs d'une liste donnée.
%	Paramètres :
%		- AttrRestants : Liste d'attributs à caractériser.
%		- NewAnim : Animal à décrire.		
%		- Num : Nombre max d'animaux de cette liste à caractériser.		
associerAnimAttr([], _, _) :- !.	
associerAnimAttr(_, _, 0) :- !.	
associerAnimAttr([Attr|AttrRestants], NewAnim, Num) :-
	write('- '), write(Attr), write(' : Possède-t-il cet attribut ?\t("o."->Oui , "n."->Non , "p."->Peut-être)\n'),
	obtenirReponse(Rep, [o, p, n]),
	write('---------\n'),
	ajoutAttributs(NewAnim, [[Attr, Rep]]),
	ajoutIntelligentAttr(NewAnim, [[Attr, Rep]]),
	Num1 is Num-1,
	associerAnimAttr(AttrRestants, NewAnim, Num1).
	
% __________________
% avouerDefaiteZeroQuestion\2
%	Description :
%		Avoue à l'utilisateur sa défaite par manque d'attributs/questions, et lance le processus d'apprentissage.
%	Paramètres :
%		- AnimRestants : Liste d'animaux correspondant aux réponses données par l'utilisateur.
%		- ReponsesPrec : Liste des réponses de l'utilisateur.			
avouerDefaiteZeroQuestion(AnimRestants, ReponsesPrec) :-
	write('---------------------\n'),
	write('Zut\, je m\'avoue vaincu \: je n\'ai plus de question en tête !\nA quel animal pensais\-tu ?\n'),
	read(NewAnimal),
	write('---------------------\n'),
	write('Peux-tu m\'aider à mieux connaître cet animal, en me donnant un attribut le distinguant ?\n'),
	obtenirCategorie(Categ),
	write('---------------------\n'),
	write('Voici des exemples d\'attribut de cette catégorie :\n'),
	donnerExemplesAttribut(Categ, 5), write('...\n'),
	write('Entrez maintenant un attribut de '), write(NewAnimal), write(' : '),
	read(NewAttr),
	assertNoDoublon(animal(NewAnimal)),
	assertNoDoublon(categorie(NewAttr, Categ)),
	ajoutAttributs(NewAnimal, [[NewAttr, o]|ReponsesPrec]),
	ajoutIntelligentAttr(NewAnimal, [[NewAttr, o]|ReponsesPrec]),
	write('---------------------\n'),
	write('Peux-tu maintenant m\'aider en me disant si certains animaux possèdent également cet attribut ?\n'),
	associerAttrAnim(NewAttr, AnimRestants, 5),
	write('---------------------\n'),
	write('Merci de ta contribution !\n').

% __________________
% avouerDefaiteZeroAnimal\2
%	Description :
%		Avoue à l'utilisateur sa défaite par manque d'animaux correspondant, et lance le processus d'apprentissage.
%	Paramètres :
%		- AttrRestants : Liste d'attributs encore non évalués.
%		- ReponsesPrec : Liste des réponses de l'utilisateur.		
avouerDefaiteZeroAnimal(AttrRestants, ReponsesPrec) :-
	write('---------------------\n'),
	write('Zut, je m\'avoue vaincu : je n\'ai plus d\'animal en tête !\nA quel animal pensais\-tu ?\n'),
	read(NewAnimal),
	ajoutAttributs(NewAnimal, ReponsesPrec),
	ajoutIntelligentAttr(NewAnimal, ReponsesPrec),
	assertNoDoublon(animal(NewAnimal)),
	write('---------------------\n'),
	write('Peux-tu maintenant m\'aider en me disant si cet animal possède également certains attributs ?\n'),
	associerAnimAttr(AttrRestants, NewAnimal, 5),
	write('---------------------\n'),
	write('Merci de ta contribution !\n').
	
	
% ___________________________________________
%
% 				ANINATOR
% ___________________________________________

% __________________
% aninator\0
%	Description :
%		Lance le jeu Aninator. Le but étant à l'IA de deviner correctement l'animal auquel pense l'User.
%	Paramètres :
%		/		
aninator :- listeAttr(At), listeAnim(An), aninator(An, At, []).

% __________________
% aninator\3
%	Description :
%		Fait tourner le jeu Aninator.
%	Paramètres :
%		- AnimRestants : Liste des animaux encore en lisse, i.e possédant (o ou p) tous les attributs donnés dans ReponsesPrec.
%		- ListAttr : Liste des attributs n'ayant pas encore fait l'objet d'une question.
%		- ReponsesPrec :Liste des couples < Question posée par l'IA, Réponse de l'User >.
aninator([], ListAttr, ReponsesPrec) :- !, avouerDefaiteZeroAnimal(ListAttr, ReponsesPrec).
aninator(AnimRestants, [], ReponsesPrec) :- !, avouerDefaiteZeroQuestion(AnimRestants, ReponsesPrec).
aninator([DernierAnim], _, ReponsesPrec):- !, demanderConfirmation(DernierAnim, ReponsesPrec).
aninator(Anim, ListAttr, ReponsesPrec) :-
	meilleurAttr(ListAttr, Anim, AttrQ, ListAttrPop),
	poserQuestion(AttrQ, Rep), 
	reponse([AttrQ, Rep], Anim, ListAttrPop, Anim1, ListAttr1), 
	!,
	aninator(Anim1, ListAttr1, [[AttrQ, Rep]|ReponsesPrec]).


% ___________________________________________
%
% 		 INTERFACE ANINATOR REVERSE
% ___________________________________________

% __________________
% traiterQuestion\3
%	Description :
%		Traite la question ou l'affirmation donnée par l'utilisateur.
%	Paramètres :
%		- Rep : Choix de l'utilisateur (1..6 pour choisir une catégorie de questions, 0 pour donner une réponse).
%		- Attr : Question/Attribut demandée par l'utilisateur (s'il n' pas décidé de donner une réponse).	
%		- Animal : Animal donné par l'utilisateur (s'il n'a pas décidé de poser une autre question).	
traiterQuestion(0, [], Animal) :-
	write('Entre le nom de l\'animal supposé : '),
	read(Animal).
traiterQuestion(Rep, Attr, []) :-
	Rep \== 0,
	write('-----------\n'),
	write('Choisis ta question :\n'),
	Rep1 is Rep-1,
	listeCateg(ListCateg),
	nth0(Rep1, ListCateg, Categ),
	listeAttrCateg(ListAttr, Categ),
	formulationQuestion(Categ, Question),
	write(Question), write('...\n'),
	afficherCategorie(ListAttr, 1, ListNum),
	obtenirReponse(RepAttr, ListNum),
	RepAttr1 is RepAttr-1,
	nth0(RepAttr1, ListAttr, Attr).

% __________________
% recevoirQuestion\2
%	Description :
%		Demande à l'utilisateur la question qu'il désire poser pour deviner l'animal de l'IA ou l'affirmation, et traite cette réponse.
%	Paramètres :
%		- Attr : Attribut/Question posée par l'utilisateur  (s'il n'a pas à la place proposé un animal).
%		- Animal : Animal proposé par l'utilisateur (s'il n'a pas à la place posé une question).
recevoirQuestion(Attr, Animal) :-
	write('Pose-moi une question : choisis une catégorie pour ta question, ou si tu penses avoir deviné, donne-moi ta réponse :\n'),
	listeCateg(List),
	afficherCategorie(List, 1, ListNum),
	write('0 - Proposer ma réponse.\n'),
	obtenirReponse(Rep, [0|ListNum]),
	traiterQuestion(Rep, Attr, Animal).

	
reponseQuestion(o) :- write('Oui, il possède cet attribut.\n').
reponseQuestion(p) :- write('Désolé, je ne suis pas sûr ... Peut-être ...\n').
reponseQuestion(n) :- write('Non, il ne possède pas cet attribut.\n').

% __________________
% repondreQuestion\5
%	Description :
%		Répond à la question posée par l'utilisateur et retourne les éléments permettant au jeu de se poursuivre (ou non si fin).
%	Paramètres :
%		- Attr : Attribut/Question proposée par l'utilsiateur (s'il n'a pas à la place proposé un animal).
%		- Anim : Animal proposé par l'utilisateur (s'il n'a pas à la place posé une question).
%		- AnimChoisi : Animal-réponse choisi par l'IA.
%		- [Attr, Reponse] : Paire [Attribut, Réponse pour l'animal AnimalChoisi].
%		- Victoire : Retourne une de ces 3 valeurs : "p" ("peut-être") si le jeu se poursuit, "o" ("oui") si victoire de l'utilisateur, "n" ("non") si défaite.
repondreQuestion(Attr, [], AnimChoisi, [Attr, Reponse], p) :-
	attribut(Attr, Reponse, AnimChoisi),
	write('---------------------\n'),
	reponseQuestion(Reponse), 
	write('---------------------\n').
repondreQuestion([], AnimChoisi, AnimChoisi, [], Victoire) :-
	!,
	write('---------------------\n'),
	write('Bravo, tu as trouvé !\n'), 
	Victoire = o.
repondreQuestion([], Anim, AnimChoisi, [], Victoire) :-
	write('---------------------\n'),
	write('Dommage, ce n\'est pas la bonne réponse. Je pensais à '), write(AnimChoisi), write(' ...\n'),
	Victoire = n.


% ___________________________________________
%
% 		  		ANINATOR REVERSE
% ___________________________________________

% __________________
% choisirAnimal\2
%	Description :
%		Retourne aléatoirement un animal de l'ensemble Anim.
%	Paramètres :
%		- Anim : Liste d'animaux.
%		- AnimChoisi : Animal choisi aléatoirement dans Anim.
choisirAnimal(Anim, AnimChoisi) :-
	length(Anim, L),
	Num is random(L),
	nth0(Num, Anim, AnimChoisi).
	
% __________________
% aninatorReverse\0
%	Description :
%		Lance le jeu Aninator-Reverse. Le but étant à l'utilisateur de deviner correctement l'animal pioché par l'IA dans sa BDD.
%	Paramètres :
%		/		
aninatorReverse :- 
	listeAnim(ListeAnim),
	choisirAnimal(ListeAnim, AnimChoisi),
	write('J\' ai choisi mon animal ! Arriveras-tu à le deviner ?\n'),
	write('---------------------\n'),
	aninatorReverse([], AnimChoisi, [], p).

% __________________
% aninatorReverse\4
%	Description :
%		Fait tourner le jeu Aninator-Reverse.
%	Paramètres :
%		- Reponses : Liste des couples <Question posée par l'utilisateur, Réponse de l'IA>.
%		- AnimChoisi : Animal choisi par l'IA, à deviner.
%		- Anim : Animal proposé par l'utilisateur (dernière étape du jeu).
%		- Victoire : Variable déterminant si suite à la dernière action de l'utilisateur: le jeu peut continuer (p) ; le jeu se termine par une victoire de l'utilisateur (o), par une défaite de celui-ci (n) .
aninatorReverse(_, _, _, o).
aninatorReverse(Reponses, AnimChoisi, AnimErrone, n) :-
	write('---------------------\n'),
	write('Peux-tu m\'aider à différencier ton animal et le mien, en me donnant un attribut distinguant '), write(AnimErrone), write(' de '), write(AnimChoisi), write(' ?\n'),
	obtenirCategorie(Categ),
	write('---------------------\n'),
	write('Voici des exemples d\'attribut de cette catégorie :\n'),
	donnerExemplesAttribut(Categ, 5), write('...\n'),
	write('Entrez maintenant cet attribut, que possède '), write(AnimErrone), write(' et pas '), write(AnimChoisi), write(' : '),
	read(NewAttr),
	assertNoDoublon(animal(AnimErrone)),
	assertNoDoublon(categorie(NewAttr, Categ)),
	ajoutAttributs(AnimErrone, [[NewAttr, o]|Reponses]),
	ajoutAttributs(AnimChoisi, [[NewAttr, n]]),
	ajoutIntelligentAttr(AnimErrone, [[NewAttr, o]|Reponses]),
	ajoutIntelligentAttr(AnimChoisi, [[NewAttr, n]]),
	write('---------------------\n'),
	write('Merci de ta contribution !\n').
aninatorReverse(Reponse, AnimChoisi, Anim, p) :-
	recevoirQuestion(Attr, Anim2),
	repondreQuestion(Attr, Anim2, AnimChoisi, Reponse2, Victoire),
	aninatorReverse([Reponse2|Reponse], AnimChoisi, Anim2, Victoire).
	
	
% ___________________________________________
%
% 		  	    ANINATOR BATTLE
% ___________________________________________



% __________________
% gestionAnimauxUser\4
%	Description :
%		Permet de gérer la liste d'animaux auquels l'User peut encore songer, i.e les animaux possédant également les attributs demandés par l'User.
%	Paramètres :
%		- Reponses : Couple <Question posée par l'utilisateur, Réponse de l'IA>. Vide si l'User a proposé un animal à la place.
%		- AnimPropose : Animal proposé par l'User. Vide s'il a préféré poser une question à la place.
%		- ListeAnimUser : Liste des animaux avant prise en compte de la dernière action de l'User.
%		- ListeAnimUser1 : Liste des animaux après prise en compte de la dernière action de l'User.
gestionAnimauxUser(Reponse, [], ListeAnimUser, ListeAnimUser1) :-
	!,
	reponse(Reponse, ListeAnimUser, _, ListeAnimUser1, _).
gestionAnimauxUser([], AnimPropose, _, [AnimPropose]).


% __________________
% aninatorBattle\0
%	Description :
%		Lance le jeu Aninator-Battle. Le but étant à de confronter l'IA et l'User : chacun choisit un animal, et doit deviner le premier celui de l'autre.
%	Paramètres :
%		/		
aninatorBattle :-
	listeAnim(ListeAnim),
	choisirAnimal(ListeAnim, AnimChoisi),
	write('Chacun de nous choisit un animal. Le but du jeu : devinez celui de l\'autre avant qu\'il en fasse de même ! Bonne chance !\n'),
	write('...\n'),
	write('---------------------\n'),
	write('J\'ai choisi mon animal. Vas-y, à toi de commencer :\n'),
	write('---------------------\n'),
	listeAnim(LAni),
	listAttrSur(AnimChoisi, LAtt),
	aninatorBattle(AnimChoisi, LAni, LAni, [], [], LAtt, u, p).
	
	
tourSuivant(u, p, u) :-
	!,
	write('Tu as le droit à une autre question.\n'),
	write('---------------------\n').
tourSuivant(u, _, i).
tourSuivant(i, p, i) :-
	!,
	write('J\'ai donc le droit à une autre question.\n'),
	write('---------------------\n').
tourSuivant(i, _, u).

repondreQuestionUser(_, QuestionsIA, ListeAnimIA, ListAttr, ListeAnimIA, QuestionsIA, ListAttr, p) :- !.
repondreQuestionUser(Attr, QuestionsIA, ListeAnimIA, ListAttr, [[Attr, Rep]|QuestionsIA], Anim1, ListAttr1, _) :-
	poserQuestionRecurs(Attr, Rep),
	reponse([Attr, Rep], ListeAnimIA, ListAttr, Anim1, ListAttr1).
	

repondreQuestionIA(_, _, QuestionsUser, ListeAnimUser, QuestionsUser, ListeAnimUser, p) :- !.
repondreQuestionIA(AnimChoisi, Attr, QuestionsUser, ListeAnimUser, [[Attr, Val]|QuestionsUser], ListeAnimUser1, _) :-
	attribut(Attr, Val, AnimChoisi),
	!,
	categorie(Attr, Categ),
	formulation(Val, Categ, Phrase),
	write('Je dois donc répondre à ma propre question :\n'),
	write('J\'ai choisi un animal '), write(Phrase), write(Attr), write('.\n'),
	write('---------------------\n'),
	reponse([Attr, Val], ListeAnimUser, _, ListeAnimUser1, _).
	
listAttrSur(Anim, L) :- listeAttr(ListeTout), findall(X, (member(X, ListeTout), attribut(X, p, Anim)), ListeIncertains), subtract(ListeTout, ListeIncertains, L).


% __________________
% aninatorBattle\8
%	Description :
%		Fait tourner le jeu Aninator-Battle.
%	Paramètres :
%		- AnimChoisi : Animal choisi par l'IA
%		- ListeAnimUser : Liste d'animaux auquels l'User peut encore songer, i.e possédant (o ou p) tous les attributs donnés dans QuestionsUser.
%		- ListeAnimIA : Liste des animaux encore en lisse pour l'IA, i.e possédant (o ou p) tous les attributs donnés dans QuestionsIA.
%		- QuestionsUser :Liste des couples < Question posée par l'User, Réponse de l'IA >.
%		- QuestionsIA :Liste des couples < Question posée par l'IA, Réponse de l'User >.
%		- ListAttr : Liste des attributs n'ayant pas encore fait l'objet d'une question de l'IA.
%		- u/i : Variable définissant à qui est le tour (u-User, i-IA).
%		- Victoire : Variable déterminant si suite à la dernière action de l'utilisateur: le jeu peut continuer (p) ; le jeu se termine par une victoire de l'utilisateur (o), par une défaite de celui-ci (n) .
aninatorBattle(_, _, ListeAnimIA, _, QuestionsIA, [], i, p) :- avouerDefaiteZeroQuestion(ListeAnimIA, QuestionsIA).
aninatorBattle(_, _, [], _, QuestionsIA, ListAttr, i, p) :- !, avouerDefaiteZeroAnimal(ListAttr, QuestionsIA).
aninatorBattle(AnimChoisi, ListeAnimUser, [DernierAnim], QuestionsUser, QuestionsIA, ListAttr, i, p) :-
	demanderConfirmation(DernierAnim, QuestionsIA).
aninatorBattle(AnimChoisi, ListeAnimUser, ListeAnimIA, QuestionsUser, QuestionsIA, ListAttr, u, p) :-
	% User pose sa question :
	write('---------------------\n'),
	write('\tUTILISATEUR\n'),
	write('---------------------\n'),
	recevoirQuestion(Attr, Anim),
	repondreQuestion(Attr, Anim, AnimChoisi, [Attr, Rep], Victoire),
	gestionAnimauxUser([Attr, Rep], Anim, ListeAnimUser, ListeAnimUser1),
	tourSuivant(u, Rep, TourSuivant),
	% User répond à sa question :
	repondreQuestionUser(Attr, QuestionsIA, ListeAnimIA, ListAttr, QuestionsIA1, ListeAnimIA1, ListAttr1, Rep),
	aninatorBattle(AnimChoisi, ListeAnimUser1, ListeAnimIA1, [[Attr, Rep]|QuestionsUser], QuestionsIA1, ListAttr1, TourSuivant, Victoire).
	
aninatorBattle(AnimChoisi, ListeAnimUser, ListeAnimIA, QuestionsUser, QuestionsIA, ListAttr, i, p) :-
	write('---------------------\n'),
	write('\tANINATOR\n'),
	write('---------------------\n'),
	bestNextQuestion(ListAttr, ListeAnimUser, ListeAnimIA, 5, -100000000, 100000000, [AttrQ, Val]),
	write(Val), poserQuestion(AttrQ, Rep),
	reponse([AttrQ, Rep], ListeAnimIA, ListAttr, Anim1, ListAttr1),
	repondreQuestionIA(AnimChoisi, AttrQ, QuestionsUser, ListeAnimUser, QuestionsUser1, ListeAnimUser1, Rep),
	tourSuivant(i, Rep, TourSuivant),
	aninatorBattle(AnimChoisi, ListeAnimUser1, Anim1, QuestionsUser1, [[AttrQ, Rep]|QuestionsIA], ListAttr1, TourSuivant, p).
	

aninatorBattle(_, _, _, _, _, _, _, o).

aninatorBattle(AnimChoisi, [AnimErrone], _, QuestionsUser, _, _, _, n) :-
	write('---------------------\n'),
	write('Peux-tu m\'aider à différencier ton animal et le mien, en me donnant un attribut distinguant '), write(AnimErrone), write(' de '), write(AnimChoisi), write(' ?\n'),
	obtenirCategorie(Categ),
	write('---------------------\n'),
	write('Voici des exemples d\'attribut de cette catégorie :\n'),
	donnerExemplesAttribut(Categ, 5), write('...\n'),
	write('Entrez maintenant cet attribut, que possède '), write(AnimErrone), write(' et pas '), write(AnimChoisi), write(' : '),
	read(NewAttr),
	assertNoDoublon(animal(AnimErrone)),
	assertNoDoublon(categorie(NewAttr, Categ)),
	ajoutAttributs(AnimErrone, [[NewAttr, o]|QuestionsUser]),
	ajoutAttributs(AnimChoisi, [[NewAttr, n]]),
	ajoutIntelligentAttr(AnimErrone, [[NewAttr, o]|QuestionsUser]),
	ajoutIntelligentAttr(AnimChoisi, [[NewAttr, n]]),
	write('---------------------\n'),
	write('Merci de ta contribution !\n').	

	
% ___________________________________________
%
% 		  	    ANINATOR GLOBAL
% ___________________________________________

menu :-
	!,
	write('\n'),
	write('___________________________________________________________________\n'),
	write('\n'),
	write('___________________________________________________________________\n'),
	write('                               MENU                                \n'),
	write('___________________________________________________________________\n'),
	afficherCategorie(['Classic', 'Reverse', 'Battle', 'Quitter'], 1, ListNum),
	write('___________________________________________________________________\n'),
	write('Que veux-tu faire ? - '),
	obtenirReponse(RepJeu, ListNum),
	write('\n'),
	progAninator(RepJeu).

progAninator :-
	write('___________________________________________________________________\n'),
	write('\n'),
	write('                    ANINATOR, LE GENIE DES ANIMAUX                 \n'),
	write('___________________________________________________________________\n'),
	write('\n'),
	write('Chargement ...\n'), chargementDonnee('data'),
	write('___________________________________________________________________\n'),
	write('\n'),
	write('                       Phase d\'apprentissage                      \n'),
	write('___________________________________________________________________\n'),
	write('\n'),
	write('Avant de me consulter, il faut d\'abord satisfaire ma curiosité ...\n'),
	write('Je vais te poser quelques questions pour agrandir mon savoir. Merci d\'y répondre !\n'),
	write('___________________________________________________________________\n'),
	write('                             QUESTIONS                             \n'),
	write('\n'),
	majAttributs,
	write('\n'),
	write('Merci de ta participation !\n'),
	menu,
	!.
	
progAninator(1) :-
	!,
	aninator,
	menu.
progAninator(2) :-
	!,
	aninatorReverse,
	menu.
progAninator(3) :-
	!,
	aninatorBattle,
	menu.
progAninator(4) :-
	!,
	sauvegardeDonnee('data'),
	write('\n'),
	write('Bye Bye !').
	
