# Match-making algorithm research plan

## Inputs

The following information could be used as inputs:
* Surrogate/umbrella species - prioritising species based on distributions, threats, actions, and costs (DOI: 10.1111/cobi.13430)
* Threatened status - prioritising species that are closer to extinction
* Endemism - how unique the species is to a specific electorate (e.g. 44% of all species reside in a single electorate)
* Viewing - how recently the species was shown to another user
* Charisma - some species are more attractive to people such as the Koala, which has massive conservation funding, if the goal of our platform is the hihglight the lesser known, then we need to show less "charismatic" species more often
* Resonance - how likely the species is to resonate with the user (e.g. we know that the user is 15yo and we know that younger gens have an affinity for "cute" species [big eyes etc])
* Proximity - closeness to postcode entered (in the Durack [big WA electorate] example, if someone who lives closer to Perth enters their postcode but gets a species that is close to Darwin, this is probably not optimal)
* Proportion - size of species range to electorate
* Person type - the 6 categories according to the ACF report
* Picture - could show different styles of picture to users (animal VS human and animal) and see how people respond

## Methodology

### DIY

* Index
  * Create an index in a spreadsheet for every electorate

#### Pros

#### Cons
*

### Use existing techniques

* Recommender systems
  * Microsoft best practice - https://microsoft-recommenders.readthedocs.io/en/latest/#
  * Microsoft examples - https://github.com/Microsoft/Recommenders
  * Random tour - https://github.com/jrzaurin/RecoTour
* Information retrieval
  * td-idf - https://en.m.wikipedia.org/wiki/Tf%E2%80%93idf
  * LDA - https://towardsdatascience.com/tags-recommendation-algorithm-using-latent-dirichlet-allocation-lda-3f844abf99d7
  * LDA - https://humboldt-wi.github.io/blog/research/information_systems_1819/is_lda_final/

#### Pros

#### Cons

# Other

* formal hypotheses about relationships between resonance and user-actions and test them through the site

## Recommender systems

What would our dataset look like when design in comparison to the movie data from Microsoft?
The rating could be a calculation of if the user on that species clicked through to:
* Send an email to the MP
* Visited action group links

| user_id | species_id | rating | timestamp |
|---------|---------|---------|---------|
|1|S878|3|8794|
|2|S44|0|6544|
|3|S99|9|6155|

What information connected to user_id could be useful for research or prediction?
* Demographics:
  * Age
  * Location
  * Interests
* Date accessed
