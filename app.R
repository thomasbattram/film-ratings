# --------------------------------------------------------------------
# Shiny app for comparing IMDB film ratings
# --------------------------------------------------------------------

## Aim: Provide a Shiny app to compare IMDB films across genres etc.
## Date: 2022-04-29

## pkgs
library(tidyverse) # tidy code and data
library(shiny) # for the app
library(readxl) # readxl

## Path to IMDB database files
ratings_file <- "https://datasets.imdbws.com/title.ratings.tsv.gz"
basics_file <- "https://datasets.imdbws.com/title.basics.tsv.gz"

ratings <- read_tsv(ratings_file, na = "\\N", quote = '')
basics <- read_tsv(basics_file, na = "\\N", quote = '')

## Getting genres
all_genres <- unique(unlist(str_split(basics$genres, ",")))
all_genres <- all_genres[!is.na(all_genres)]

# --------------------------------------------------------------------
# All-purpose function for filtering data
# --------------------------------------------------------------------

#' Get films based on filters
#' 
#' @param b_tab data.frame or tibble. table from the "title.basics.tsv.gz" file on IMDB.
#' @param r_tab data.frame or tibble. table from the "title.ratings.tsv.gz" file on IMDB.
#' @param movie_only logical. TRUE = search amongst only movies
#' @param genre character vector. Choose all genres of interest from the list of valid IMDB genres
#' @param rating_min numeric vector. Minimum rating. Must be between 0 and 1. Default = 0.4.
#' @param vote_min numeric vector. Minimum number of votes. Default = 5000
#' @param min_time numeric. Minimum time of film/show. Default = 0
#' @param max_time numeric. Maximum time of film/show. Default = Inf
#' @param omit_genre character vector. Genres to omit.
#' 
#' @return table of titles, ratings etc.
get_best_films <- function(b_tab, r_tab, movie_only, genre, rating_min = 0.4, vote_min = 5000, 
						   min_time = 0, max_time = Inf, omit_genre = "none")
{
	r_filt <- r_tab %>%
		dplyr::filter(numVotes > vote_min, averageRating > rating_min)
	if (movie_only) {
		ttype <- "movie"
	} else {
		ttype <- unique(b_tab$titleType)
	}
	
	b_filt <- b_tab %>%
		dplyr::filter(tconst %in% r_filt$tconst, titleType %in% ttype) %>%
		dplyr::filter(runtimeMinutes > min_time, runtimeMinutes < max_time) %>%
		dplyr::filter(grepl(paste(genre, collapse = "|"), genres)) %>%
		left_join(r_filt) %>%
		arrange(desc(averageRating)) %>%
		dplyr::select(Title = primaryTitle, Year = startYear, Mins = runtimeMinutes, 
					  Genres = genres, Rating = averageRating, Votes = numVotes)

	if (!any(omit_genre == "none")) {
		b_filt <- b_filt %>%
			dplyr::filter(!grepl(paste(omit_genre, collapse = "|"), Genres))
	}

	return(b_filt)
}

# b_tab = basics
# r_tab = ratings
# movie_only = TRUE
# genre = c("Horror", "Mystery")
# omit_genre = c("Comedy", "Music")
#

# get_best_films(basics, ratings, TRUE, c("Horror", "Mystery"), omit_genre = c("Comedy", "Music"))


# --------------------------------------------------------------------
# The app
# --------------------------------------------------------------------

ui <- fluidPage(
	
	titlePanel("Find the highest-rated IMDB films for your chosen genre"),
	sidebarLayout(
		sidebarPanel(
			h1("Choose your filters"),
			selectInput(inputId = "movie_only", label = "Movies only", choices = c(TRUE, FALSE)),
			sliderInput(inputId = "rating_min", label = "Minimum IMDB rating",
						min = 0, max = 10, value = 0, step = 0.5),
			numericInput(inputId = "minvote", label = "Minimum number of votes", value = 5000),
			numericInput(inputId = "maxtime", label = "Film length upper limit", value = 1000),
			numericInput(inputId = "mintime", label = "Film length lower limit", value = 0),
			selectInput(inputId = "genre", label = "Select genres", 
						choices = all_genres, selected = "Horror", multiple = TRUE),
			selectInput(inputId = "omit_genre", label = "Select genres to remove", 
						choices = c(all_genres, "none"), selected = "none", multiple = TRUE)			
		),
		mainPanel(
			dataTableOutput(outputId = "table")
		)
	)

)


server <- function(input, output) {
	films_out <- reactive({
		get_best_films(b_tab = basics, 
					   r_tab = ratings, 
					   movie_only = input$movie_only, 
					   genre = input$genre, 
					   rating_min = input$rating_min, 
					   vote_min = input$minvote, 
					   min_time = input$mintime, 
					   max_time = input$maxtime, 
					   omit_genre = input$omit_genre)
	})

	output$table <- renderDataTable({
		films_out()
	})	
}
shinyApp(ui = ui, server = server)