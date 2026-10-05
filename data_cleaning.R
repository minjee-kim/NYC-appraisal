# Read class 1 DOF zips already on disk. Write one cleaned CSV per year.
# Does not copy the zip. Deletes the unzipped extract when the year is done.
#
# Usage: set zip_dir to the folder of class 1 zips, then source this file.

zip_dir <- "data/raw"
out_dir <- "data/panel"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

keep <- c(
  "boro", "block", "lot", "year", "taxclass",
  "mkt_land", "mkt_total", "act_land", "act_total"
)

# Final-roll names in the recent layout. Older years use other names;
# the script prints the header and stops on the first file it cannot map.
name_map <- c(
  boro = "BORO",
  block = "BLOCK",
  lot = "LOT",
  year = "TAXYR",
  taxclass = "FINTAXCLASS",
  mkt_land = "FINMKTLAND",
  mkt_total = "FINMKTTOT",
  act_land = "FINACTLAND",
  act_total = "FINACTTOT"
)

read_one <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("csv", "txt")) {
    return(read.csv(path, stringsAsFactors = FALSE, check.names = FALSE))
  }
  if (ext %in% c("mdb", "accdb")) {
    stop(
      "Access file: ", path,
      "\nInstall mdbtools and export the table to csv, or read this year by hand.",
      call. = FALSE
    )
  }
  stop("Unrecognized file: ", path, call. = FALSE)
}

map_cols <- function(d) {
  have <- toupper(names(d))
  hit <- match(toupper(unname(name_map)), have)
  if (anyNA(hit)) {
    missing <- names(name_map)[is.na(hit)]
    stop(
      "Missing columns: ", paste(missing, collapse = ", "),
      "\nFile has: ", paste(names(d), collapse = ", "),
      call. = FALSE
    )
  }
  out <- d[hit]
  names(out) <- names(name_map)
  out
}

zips <- list.files(zip_dir, pattern = "\\.zip$", full.names = TRUE, ignore.case = TRUE)
if (!length(zips)) stop("No zips in ", zip_dir, call. = FALSE)

for (z in zips) {
  tmp <- tempfile("dof")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  unzip(z, exdir = tmp)
  inner <- list.files(tmp, recursive = TRUE, full.names = TRUE)
  inner <- inner[!grepl("layout|dictionary|summary", inner, ignore.case = TRUE)]
  inner <- inner[grepl("\\.(csv|txt|mdb|accdb)$", inner, ignore.case = TRUE)]
  if (!length(inner)) stop("No data file inside ", z, call. = FALSE)
  
  d <- map_cols(read_one(inner[1]))
  d <- d[d$taxclass %in% c("1", "1A", "1B", "1C"), ]
  yr <- unique(stats::na.omit(d$year))[1]
  out <- file.path(out_dir, sprintf("class1_%s.csv", yr))
  write.csv(d, out, row.names = FALSE)
  message("wrote ", out, " (", nrow(d), " rows)")
  unlink(tmp, recursive = TRUE)
}