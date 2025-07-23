library(dplyr) 
library(readxl)
library(here)
library(openxlsx)

# read file
blit_talk_abstracts_qualtrics_file <- "UW table sample symposium.xlsx"

blitz.df <- read_excel(file.path(here(), "Qualtrics_Tables", 
                                 blit_talk_abstracts_qualtrics_file)) 

# functions
clean_qualtrics_table_for_review <- function(qualtrics_table) {
  cleaned_table <- qualtrics_table %>% 
    rename(blitz_yes_no = `Blitz Yes/No`, 
           abstract_text = Q10, 
           abstract_title = Q8) %>% # Rename columns based on the names in the function below
    select(blitz_yes_no, abstract_text, abstract_title) %>% 
    filter(blitz_yes_no == "Yes - Blitz Talk") %>%  # Only Blitz talks
    mutate(abstract_number_for_review = {set.seed(1234); sample(1:n())}) %>%
    arrange(abstract_number_for_review)
  
  return(cleaned_table)
}


formatted_abstract_for_program <- function(df, abstract_type = "Poster", 
                                           anonymize = T) {
  # abstract_type -> "Poster" or "Blitz Talk"
  lines <- list()

  lines$number_line <- sprintf("## %s #%i", abstract_type, 
                               ifelse(abstract_type == "Poster", df$`Poster Number`,
                                      ifelse(abstract_type == "Blitz Talk", df$`Talk Number`, 
                                             df$abstract_number_for_review)))
  lines$title_line <- sprintf('**Title:** %s\\', 
                              df$abstract_title)
  if (!anonymize) {
    lines$author_line <- sprintf('**Authors:** %s\\', 
                                 df$Authors)
    lines$presenter_line <- sprintf('**Presenter:** %s %s; %s\\', 
                                    df$`First Name`, 
                                    df$`Last Name`, 
                                    df$Affiliation)
  }
  lines$abstact_line <- sprintf('**Abstract:** %s\\', 
                                df$abstract_text)
  sep_char <- "\n"
  full_line <- paste0(paste(lines, collapse = sep_char), "\n\n\\newpage\n\n")
  return(full_line)
}

# Blitz Talk
blitz_clean.df <- blitz.df %>% 
  clean_qualtrics_table_for_review() %>% 
  relocate(abstract_number_for_review, abstract_title, abstract_text)

blitz_text.df <- blitz_clean.df %>%  rowwise() %>% 
  dplyr::summarise(text = formatted_abstract_for_program(across(everything()), 
                                                         abstract_type = "Blitz Talk Abstract", 
                                                         anonymize = T))

header <- data.frame(text = paste("---",
                                  "title: \"Blitz Talk Abstracts Symposium 2025\" ",
                                  "author: \"Scoring Material\" ",
                                  "output: word_document",
                                  "---",
                                  "\n\\newpage",
                                  "\n",
                                  sep = "\n"))

blitz_text.df <- bind_rows(header, blitz_text.df)

fout <- file(file.path(here(), "Scripts", "Blitz_Talks_Abstracts_For_Scoring_Materials", 
                       "blitz_abstract_texts.txt"), "w")
for (i_row in 1:nrow(blitz_text.df)) {
  cat(blitz_text.df$text[i_row], file=fout)
}
close(fout)

fout <- file(file.path(here(), "Scripts", "Blitz_Talks_Abstracts_For_Scoring_Materials", 
                       "blitz_abstract_texts.Rmd"), "w")
for (i_row in 1:nrow(blitz_text.df)) {
  cat(blitz_text.df$text[i_row], file=fout)
}
close(fout)


write.xlsx(blitz_clean.df, 
           file = file.path(here(), "Scripts", 
                            "Blitz_Talks_Abstracts_For_Scoring_Materials", 
                            "blitz_abstracts_table_for_review.xlsx"))



