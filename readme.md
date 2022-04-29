# IMDB ratings checker - Shiny app

This repo is a way to test out using Shiny. The current app can be deployed locally, but can't be deployed in shinyapps.io because the files loaded into R are too large (>1Gb). 

## Running the app locally

1. Clone/download this GitHub repo
2. Navigate to where you cloned/downloaded the repo
3. Open R and run the following code

```r
# install.packages("shiny") # install if needed
shiny::runApp()
```

## Notes on improvements to be made

1. Setup a link to [OMDB](http://www.omdbapi.com/) so no data needs to be downloaded. Use this app as a template: https://shiny.rstudio.com/gallery/movie-explorer.html. 
2. Add functionality to look at Rotten Tomatoes scores (can be done via OMDB)
3. Make things look neater
