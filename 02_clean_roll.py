"""Clean class 1 rolls into one row per lot-year.

Reads the zips already in data/raw. Writes data/cleaned/class1_panel.csv.gz.
The rolls are tab-delimited and have no header. The layout changes in 2020.
"""

from pathlib import Path
import re
import zipfile
import pandas as pd

RAW = Path("data/raw")
OUT = Path("data/cleaned")

# 0-based positions.
NEW = dict(boro=1, block=2, lot=3, taxclass=55, mkt_land=45, mkt_total=46, act_land=47, act_total=48)
OLD = dict(boro=1, block=2, lot=3, taxclass=39, mkt_land=8, mkt_total=9, act_land=17, act_total=18)
KEEP = ["fy", "boro", "block", "lot", "taxclass", "mkt_land", "mkt_total", "act_land", "act_total"]


def fiscal_year(path: Path) -> int:
    name = path.stem.lower()
    if name == "tc1":
        return 2009
    match = re.search(r"fy(\d{2})", name)
    if match:
        return 2000 + int(match.group(1))
    match = re.search(r"(20\d{2})", name)
    if match:
        return int(match.group(1))
    match = re.search(r"tc1_(\d{2})", name)
    if match:
        return 2000 + int(match.group(1))
    raise ValueError(f"no fiscal year in {path.name}")


def clean_zip(path: Path) -> pd.DataFrame:
    fy = fiscal_year(path)
    with zipfile.ZipFile(path) as archive:
        inner = [n for n in archive.namelist() if n.lower().endswith(".txt")]
        if not inner:
            raise ValueError(f"no text file in {path.name}")
        frame = pd.read_csv(
            archive.open(inner[0]),
            sep="\t",
            header=None,
            dtype=str,
            encoding="latin1",
            quoting=3,
            on_bad_lines="skip",
        )
    idx = NEW if frame.shape[1] >= 140 else OLD
    out = frame.iloc[:, list(idx.values())].copy()
    out.columns = list(idx.keys())
    out["fy"] = fy
    out["taxclass"] = out["taxclass"].str.strip()
    out = out[out["taxclass"].str.startswith("1", na=False)]
    for col in ["block", "lot", "mkt_land", "mkt_total", "act_land", "act_total"]:
        out[col] = pd.to_numeric(out[col], errors="coerce")
    return out[KEEP]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    zips = sorted(RAW.glob("*.zip"))
    if not zips:
        raise SystemExit(f"no zips in {RAW}")
    frames = []
    for path in zips:
        frame = clean_zip(path)
        frames.append(frame)
        print(f"{path.name}: {len(frame):,} rows, fy {frame['fy'].iloc[0]}")
    panel = pd.concat(frames, ignore_index=True)
    dest = OUT / "class1_panel.csv.gz"
    panel.to_csv(dest, index=False, compression="gzip")
    print(f"wrote {dest} ({len(panel):,} rows)")


if __name__ == "__main__":
    main()
