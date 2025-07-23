library(dplyr) 
library(readxl)

# read file
abstract_file_name <- "2024_Symposium_Abstracts_Qualtrics.xlsx"
poster_sheet <- "Poster Abstracts - Cleaned "
blitz_talk_sheet <- "Blitz Talk Abstracts - Cleaned"

posters.df <- read_excel(file.path("Abstracts", abstract_file_name), 
                         sheet = poster_sheet) %>% 
  filter(!is.na(Email)) %>% 
  filter(grepl('YES', Confirmed))
blitz.df <- read_excel(file.path("Abstracts", abstract_file_name), 
                         sheet = blitz_talk_sheet) %>% 
  filter(!is.na(Email)) %>% 
  filter(Confirmed == 'YES')

formatted_abstract_for_program <- function(df, abstract_type = "Poster") {
  # abstract_type -> "Poster" or "Blitz Talk"
  lines <- list()
  lines$number_line <- sprintf("## %s #%i", abstract_type, 
                               ifelse(abstract_type == "Poster", 
                                      df$`Poster Number`,
                                      df$`Talk Number`))
  lines$title_line <- sprintf('**Title:** %s\\', 
                              df$Title)
  lines$author_line <- sprintf('**Authors:** %s\\', 
                               df$Authors)
  lines$presenter_line <- sprintf('**Presenter:** %s %s; %s\\', 
                                  df$`First Name`, 
                                  df$`Last Name`, 
                                  df$Affiliation)  
  lines$abstact_line <- sprintf('**Abstract:** %s\\', 
                                df$Abstract)
  sep_char <- "\n"
  full_line <- paste0(paste(lines, collapse = sep_char), "\n\n\\newpage\n\n")
  return(full_line)
}

# Posters
posters_text.df <- posters.df %>% 
  rowwise() %>% 
  dplyr::summarise(text = formatted_abstract_for_program(across(everything())))

header <- data.frame(text = paste("---",
      "title: \"Poster Abstracts Symposium 2024\" ",
      "author: \"UWPA\" ",
      "date: \"Monday September 16th, 2024\" ",
      "output: word_document",
      "---", "\n", sep = "\n"))

posters_text.df <- bind_rows(header, posters_text.df)


# data.table::fwrite(posters_text.df, "posters_text.txt", col.names = FALSE, sep = "\t")

fout <- file(file.path("Posters", "posters_text.txt"), "w")
for (i_row in 1:nrow(posters_text.df)) {
  cat(posters_text.df$text[i_row], file=fout)
}
close(fout)

fout <- file(file.path("Posters", "posters_text.Rmd"), "w")
for (i_row in 1:nrow(posters_text.df)) {
  cat(posters_text.df$text[i_row], file=fout)
}
close(fout)


# Blitz Talk
blitz_text.df <- blitz.df %>% 
  rowwise() %>% 
  dplyr::summarise(text = formatted_abstract_for_program(across(everything()), 
                                                         abstract_type = "Blitz Talk"))

header <- data.frame(text = paste("---",
                                  "title: \"Blitz Talks Abstracts Symposium 2024\" ",
                                  "author: \"UWPA\" ",
                                  "date: \"Monday September 16th, 2024\" ",
                                  "output: word_document",
                                  "---", "\n", sep = "\n"))

blitz_text.df <- bind_rows(header, blitz_text.df)

fout <- file(file.path("Blitz_Talks", "blitz_text.txt"), "w")
for (i_row in 1:nrow(blitz_text.df)) {
  cat(blitz_text.df$text[i_row], file=fout)
}
close(fout)

fout <- file(file.path("Blitz_Talks", "blitz_text.Rmd"), "w")
for (i_row in 1:nrow(blitz_text.df)) {
  cat(blitz_text.df$text[i_row], file=fout)
}
close(fout)
