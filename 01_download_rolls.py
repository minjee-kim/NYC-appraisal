"""Download NYC class 1 final assessment rolls.

Source: NYC Department of Finance assessment roll archives.
Files land in data/raw and are not committed.
"""

from pathlib import Path
import requests

RAW = Path("data/raw")
BASE = "https://www.nyc.gov/assets/finance/downloads/tar"

# Fiscal year -> archive filename. tc1.zip is the FY2009 roll.
ROLLS = {
    2009: "tc1.zip",
    2010: "tc1_10.zip",
    2011: "tc1_11.zip",
    2012: "tc1_12.zip",
    2013: "tc1_13.zip",
    2014: "tc1_14.zip",
    2015: "tc1_15.zip",
    2016: "tc1_16.zip",
    2017: "tc1_17.zip",
    2018: "tc1_18.zip",
    2019: "tc1_19.zip",
    2020: "tc1_20.zip",
    2021: "tc1_21.zip",
    2022: "tc1_22.zip",
    2023: "final_tc1_2023.zip",
    2024: "fy24_tc1.zip",
    2025: "fy25_tc1.zip",
    2026: "fy26_tc1.zip",
}


def download(year: int, name: str) -> Path:
    dest = RAW / f"class1_{year}.zip"
    if dest.exists() and dest.stat().st_size > 0:
        print(f"skip {year}: {dest.name}")
        return dest
    url = f"{BASE}/{name}"
    print(f"get {year}: {url}")
    with requests.get(url, stream=True, timeout=120) as response:
        response.raise_for_status()
        with dest.open("wb") as handle:
            for chunk in response.iter_content(chunk_size=1 << 20):
                handle.write(chunk)
    print(f"wrote {dest} ({dest.stat().st_size // 1_000_000} MB)")
    return dest


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    for year, name in ROLLS.items():
        download(year, name)


if __name__ == "__main__":
    main()
