# Read class 1 DOF zips in data/raw and write data/panel/class1_YYYY.csv.
# The rolls are tab-delimited and have no header. Column names differ by era,
# so fields are taken by position.
#
# 2020 and later, 140 fields: final market land/total are 46 and 47.
# 2010-2019, 118 fields: current market land/total are 9 and 10.
#
# Run from the repo root: source("R/01_clean_roll.R")

zip_dir <- "data/raw"
out_dir <- "data/panel"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

new_idx <- c(
  boro = 2, block = 3, lot = 4, year = 8, taxclass = 56,
  mkt_land = 46, mkt_total = 47, act_land = 48, act_total = 49
)
old_idx <- c(
  boro = 2, block = 3, lot = 4, year = 8, taxclass = 40,
  mkt_land = 9, mkt_total = 10, act_land = 18, act_total = 19
)

fy_from_name <- function(path) {
  hit <- regmatches(path, regexpr("(19|20)[0-9]{2}", path))
  if (!length(hit)) stop("No fiscal year in ", path, call. = FALSE)
  hit
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
  if (ncol(d) < max(idx)) {
    stop("Unexpected width: ", ncol(d), " columns", call. = FALSE)
  }
  out <- d[idx]
  names(out) <- names(idx)
  out$fy <- fy
  out$taxclass <- trimws(out$taxclass)
  out <- out[startsWith(out$taxclass, "1"), ]
  for (col in c("block", "lot", "mkt_land", "mkt_total", "act_land", "act_total")) {
    out[[col]] <- as.integer(out[[col]])
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
  d <- clean_one(read_roll(inner[1]), fy)
  out <- file.path(out_dir, sprintf("class1_%s.csv", fy))
  write.csv(d, out, row.names = FALSE)
  message("wrote ", out, " (", nrow(d), " rows, ", ncol(read_roll(inner[1])), " source fields)")
  unlink(tmp, recursive = TRUE)
}
