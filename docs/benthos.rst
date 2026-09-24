===============================
Spécificités de l'atlas benthos
===============================

Ce document essaye de lister les spécificités de l'atlas Benthos et les
modifications apportées à l'implémentation d'origine.


Aperçu des besoins de l'atlas
=============================

Avant de plonger dans la technique, voici quelques éléments que nous avions en
tête lors du développement de l'atlas :

1. Pouvoir afficher des cartes départementales ;
2. Pouvoir afficher les stades de vie selon les mois d'observation ;
3. Compter les observations réelles plutôt que les dénombrements dans les
différents graphes.

Point 3 : en effet l'atlas se base sur la synthèse de GN comme source
d'observations, mais les lignes de la synthèse sont en réalité éclatées en
dénombrements. Pour le dire en terme SOTv3, les lignes de la synthèse sont plus
proches du concept de dénombrement (DescriptifSujet) que de l'observation qui
tient plutôt des concepts SujetObservation (et Evenement, mélangés).

Par exemple : une observation importée dans GeoNature via le module d'import qui
dénombre des adultes mâles, femelles, ainsi que des larves va produire 3 lignes
de synthèse, une par stade de vie et sexe (une ligne pour les adultes mâles, une
pour les adultes femelles et une pour les larves). Côté atlas, on
comptabiliserait donc trois "observations" alors qu'il ne s'agit en réalité que
d'une seule.


Base de données
===============

Ajout de ``vm_observations_grp`` : cette VM est similaire à ``vm_observations``
mais regroupe les lignes de synthèse correspondant à une même observation.