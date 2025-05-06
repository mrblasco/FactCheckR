# ---- setup, include = FALSE
library(jsonlite)
library(dplyr)

knitr::opts_chunk$set(cache.path = "cache/")

path <- "data-raw/test.json"

# ---- data, cache = TRUE, cache.extra=tools::md5sum(path)

load_claim_data <- function(path) {
  jsonlite::fromJSON(path, flatten = FALSE)
}

load_claim_data_stream <- function(path) {
  jsonlite::stream_in(file(path), verbose = FALSE)
}

claim <- load_claim_data_stream(path)
message("Dataset rows ", nrow(claim))

# ---- process
process_review_rating <- function(x) {
  x <- tolower(trimws(x))
  x <- gsub("\\.$", "", x)

  # General fake content (claims, statements, misinformation)
  fake_text_terms <- c(
    "false", "falso", "falso!", "faux", "notizia falsa", "false.",
    "falsk", "netačno", "errado", "nepravda", "yanlış", 
    "fals", "fałsz", "fake",
    "fabricated", "خطأ", "錯誤", "mostly false", "partly false",
    "falsch", "onwaar", "pants on fire",
    "زائف", "نادرست", "مركّب", "مركّبة", "scam", "невярно", 
    "four pinocchios", "hamis", "incorrect",
    "keliru", "মিছা", "tvrdnja je netočna",
    "ψευδές", "hoax", "epätosi",
    "misvisende", "hindi totoo",
    "eerder onwaar", "false headline"
  )

  # Manipulated media (altered visuals/media)
  fake_media_terms <- c(
    "altered", "altered image", "altered photo", "altered video",
    "altered media", "altered photo/video", "manipulated media",
    "immagine modificata", "manipulado", "manipulation",
    "manipulacja", "manipulated", "montagem", "montaje"
  )

  context_terms <- c(
    "missing context", "context", "fuori contesto", "false context",
    "misplaced context", "contexto", "needs context", "falta contexto",
    "half true", "mixture",
    "sem contexto", "outdated", 
    "descontextualizado", "sin contexto",
    "notizia vecchia", "notizia fuori contesto",
    "out of context",
    "not the whole story",
    "false context/false",
    "verdadeiro, mas…", "brakujący kontekst",
    "kailangan ng konteksto",
    "contexte manquant"
  )

  misleading_terms <- c(
    "misleading", "engañoso", "enganoso", "مضلل", "miscaptioned",
    "trompeur", "sesat", "karma", "distorts the facts",
    "سياق مضلل", "گمراه‌کننده", "irreführend", "verdad a medias",
    "flip-flop", "mix", "impreciso", "és enganyós", 
    "misleidend", "enganador", "notizia imprecisa",
    "misleading/partly false", "spins the facts",
    "distorcido", "exagerado", "misattributed"
  )

  correct_terms <- c(
    "true", "mostly true", "verdadeiro", "prawda", "notizia vera",
    "correct attribution", "doğru", "prawda.", "verdadero", "real", 
    "vero", "waar", "correct"
  )

  lack_evidence_terms <- c(
    "no evidence", "unproven", "cuestionable", "unsupported",
    "ikke dokumenteret", "nieweryfikowalne", "senza prove",
    "no basis", "unfounded"
  )

  satire_terms <- c(
    "satire", "labeled satire", "legend", "explainer",
    "شاخ‌دار", "pimenta na língua", "事實釐清",
    "notizia satirica", "originated as satire",
    "ساخر"
  )

  result <- dplyr::case_when(
    x %in% fake_text_terms ~ "Fake",
    x %in% fake_media_terms ~ "Manipulated media",
    x %in% context_terms ~ "Lack context",
    x %in% misleading_terms ~ "Misleading",
    x %in% correct_terms ~ "Correct",
    x %in% lack_evidence_terms ~ "Lack evidence",
    x %in% satire_terms ~ "Satire",
    x %in% c("") ~ "Missing",
    TRUE ~ "Unrecognized"
  )

  factor(result)
}

fact_check_insights <- dplyr::tibble(
  id = claim$id,
  context = claim$context,
  type = claim$type,
  author_name = claim$author$name,
  author_type = claim$author$`@type`,
  author_url = claim$author$url,
  claim_reviewed = claim$claimReviewed,
  date_published = claim$datePublished,
  item_date_published = claim$itemReviewed$datePublished,
  item_author_type = claim$itemReviewed$author$type,
  item_author_name = claim$itemReviewed$author$name,
  review_rating = claim$reviewRating$alternateName
  #url = claim$url
) %>%
  mutate(
    author_name = factor(trimws(author_name)),
    review_rating_type = process_review_rating(review_rating)
  )


# ---- show, echo = FALSE, results = "asis"

lapply(fact_check_insights, function(x) {
  try({
    x <- gsub("\\n", " ", x)
    sorted <- sort(table(x), decreasing = TRUE)
    df <- cbind(
      "N" = sorted,
      "%" = 100 * sorted / sum(sorted),
      "% (csum)" = 100 * cumsum(sorted / sum(sorted))
    )
    knitr::kable(head(df, 20), digits = 1)
  })
})

# ---- unrecognized review type

fact_check_insights %>% 
  filter(review_rating_type == "Unrecognized") %>% 
  count(tolower(review_rating)) %>% 
  arrange(desc(n)) %>% 
  head(50) %>% 
  knitr::kable()

# ---- counts

fact_check_insights_counts <- fact_check_insights %>%
  count(date_published, author_name, review_rating_type) %>% 
  mutate(date_published = as.Date(date_published)) %>% 
  dplyr::filter(!is.na(date_published), 
                !is.na(author_name),
                date_published < Sys.Date(),
                date_published > as.Date("1990-01-01")) %>% 
  arrange(desc(date_published))


head(fact_check_insights_counts) %>% 
  knitr::kable()

# ---- save counts
format(object.size(fact_check_insights), "MB")
format(object.size(fact_check_insights_counts), "MB")

fact_check_insights <- fact_check_insights_counts
usethis::use_data(fact_check_insights, overwrite = TRUE)

# ----- dataset defintions

definitions <- list(
  id = "Claim ID",
  context = "Context",
  type = "Type",
  author_name = "Author Name of the reviewer",
  author_url = "Author URL of the reviewer",
  claim_reviewed = "Claim Reviewed",
  date_published = "Date of publication of the claim",
  item_date_published = "Date of publication of the reviewed claim",
  item_author_type = "Author type of the reviewed claim",
  item_author_name = "Author Name of the reviewed claim",
  review_rating = "Review Rating",
  review_rating_type = "Review rating type",
  n = "Number of claims",
  url = "URL"
)

roller::document_data(
  data = fact_check_insights,
  questions = definitions[names(fact_check_insights)],
  filename = "R/data.R",
  dataset_name = "fact_check_insights",
  description = "Count of Claims Reviewed in the Fact Check Insights Dataset",
  source = "Fact Check Insights"
)
