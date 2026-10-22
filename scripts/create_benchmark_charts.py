from __future__ import annotations

import csv
from pathlib import Path

import matplotlib.pyplot as plt


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent if SCRIPT_DIR.name == "scripts" else SCRIPT_DIR
CSV_PATH = PROJECT_ROOT / "results" / "benchmark_results.csv"
if not CSV_PATH.exists():
    # Also supports keeping this script beside the downloaded CSV.
    CSV_PATH = SCRIPT_DIR / "benchmark_results.csv"
OUTPUT_DIR = CSV_PATH.parent / "graphs"


def load_results() -> dict[tuple[str, str], float]:
    """Load averaged PostgreSQL execution times from the benchmark CSV."""
    with CSV_PATH.open(newline="", encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        time_column = (
            "average_execution_time_ms"
            if "average_execution_time_ms" in (reader.fieldnames or [])
            else "execution_time_ms"
        )
        return {
            (row["benchmark"], row["condition"]): float(row[time_column])
            for row in reader
        }


def add_value_labels(axis, bars, values: list[float]) -> None:
    labels = [f"{value:.3f} ms" for value in values]
    axis.bar_label(bars, labels=labels, padding=4, fontsize=9)


def create_read_chart(results: dict[tuple[str, str], float]) -> None:
    on_the_fly = results[("read_latency", "on_the_fly_view")]
    summary_key = (
        "read_latency",
        "trigger_maintained_summary",
    )
    if summary_key not in results:
        summary_key = ("read_latency", "materialized_summary")
    summary = results[summary_key]
    labels = ["On-the-fly view", "Trigger-maintained\nsummary"]
    values = [on_the_fly, summary]

    figure, axis = plt.subplots(figsize=(7.2, 4.5))
    bars = axis.bar(labels, values, color=["#C44E52", "#4C72B0"], width=0.58)
    axis.set_yscale("log")
    axis.set_ylabel("Average execution time (ms, log scale)")
    axis.set_title("Read Latency Comparison")
    axis.grid(axis="y", which="both", linestyle="--", alpha=0.35)
    axis.set_axisbelow(True)
    add_value_labels(axis, bars, values)
    figure.tight_layout()
    figure.savefig(OUTPUT_DIR / "read_latency_comparison.png", dpi=300, bbox_inches="tight")
    plt.close(figure)


def create_write_chart(results: dict[tuple[str, str], float]) -> None:
    disabled = results[("write_penalty", "trigger_disabled")]
    enabled = results[("write_penalty", "trigger_enabled")]
    labels = ["Trigger disabled", "Trigger enabled"]
    values = [disabled, enabled]

    figure, axis = plt.subplots(figsize=(7.2, 4.5))
    bars = axis.bar(labels, values, color=["#55A868", "#DD8452"], width=0.58)
    axis.set_ylabel("Average execution time for 10,000 inserts (ms)")
    axis.set_title("Write Penalty from Incremental Maintenance")
    axis.set_ylim(0, max(values) * 1.20)
    axis.grid(axis="y", linestyle="--", alpha=0.35)
    axis.set_axisbelow(True)
    add_value_labels(axis, bars, values)
    figure.tight_layout()
    figure.savefig(OUTPUT_DIR / "write_penalty_comparison.png", dpi=300, bbox_inches="tight")
    plt.close(figure)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    results = load_results()
    create_read_chart(results)
    create_write_chart(results)
    print(f"Created charts in: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
