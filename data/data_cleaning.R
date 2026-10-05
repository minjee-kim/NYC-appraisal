# Read class 1 DOF zips in data/raw. Write one cleaned CSV per year.
# Rolls are tab-delimited and have no header. The layout changes in 2020.
# Run from the repo root: source("R/01_clean_roll.R")

zip_dir <- "data/raw"
out_dir <- "data/cleaned"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# 1-based positions.
new_idx <- c(
  boro = 2, block = 3, lot = 4, year = 8, taxclass = 56,
  mkt_land = 46, mkt_total = 47, act_land = 48, act_total = 49
)
old_idx <- c(
  boro = 2, block = 3, lot = 4, year = 8, taxclass = 40,
  mkt_land = 9, mkt_total = 10, act_land = 18, act_total = 19
)

fy_from_name <- function(path) {
  name <- basename(path)
  if (grepl("fy[0-9]{2}", name, ignore.case = TRUE)) {
    yy <- as.integer(sub(".*fy([0-9]{2}).*", "\\1", name, ignore.case = TRUE))
    return(as.character(2000 + yy))
  }
  hit <- regmatches(name, regexpr("(19|20)[0-9]{2}", name))
  if (length(hit)) return(hit)
  hit2 <- regmatches(name, regexpr("tc1_([0-9]{2})", name, perl = TRUE))
  if (length(hit2)) {
    yy <- as.integer(sub("tc1_", "", hit2))
    return(as.character(2000 + yy))
  }
  NA_character_
}

read_roll <- function(path) {
  read.delim(
    path,
    header = FALSE,
    sep = "\t",
    quote = "",
    comment.char = "",
    stringsAsFactors = FALSE,
    colClasses = "character"
  )
}

clean_one <- function(d, fy) {
  idx <- if (ncol(d) >= 140) new_idx else old_idx
  if (ncol(d) < max(idx)) stop("Unexpected width: ", ncol(d), call. = FALSE)
  out <- d[idx]
  names(out) <- names(idx)
  out$fy <- fy
  out$taxclass <- trimws(out$taxclass)
  out <- out[out$taxclass %in% c("1", "1A", "1B", "1C"), ]
  for (col in c("block", "lot", "mkt_land", "mkt_total", "act_land", "act_total")) {
    out[[col]] <- as.numeric(out[[col]])
  }
  out[c("fy", "boro", "block", "lot", "taxclass", "mkt_land", "mkt_total", "act_land", "act_total")]
}

zips <- list.files(zip_dir, pattern = "\\.zip$", full.names = TRUE, ignore.case = TRUE)
if (!length(zips)) stop("No zips in ", zip_dir, call. = FALSE)

for (z in zips) {
  tmp <- tempfile("dof")
  dir.create(tmp)
  unzip(z, exdir = tmp)
  inner <- list.files(tmp, pattern = "\\.txt$", recursive = TRUE, full.names = TRUE)
  if (!length(inner)) stop("No text file inside ", z, call. = FALSE)
  
  fy <- fy_from_name(basename(z))
  raw <- read_roll(inner[1])
  if (is.na(fy)) fy <- unique(trimws(raw[[8]]))[1]
  d <- clean_one(raw, fy)
  out <- file.path(out_dir, sprintf("class1_%s.csv", fy))
  write.csv(d, out, row.names = FALSE)
  message("wrote ", out, " (", nrow(d), " rows)")
  unlink(tmp, recursive = TRUE)
}