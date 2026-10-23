from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch


OUT = Path(__file__).resolve().parent

COLORS = {
    "data": "#DCEAF7",
    "view": "#E8E1F5",
    "summary": "#DCEFD9",
    "trigger": "#FBE5C8",
    "benchmark": "#F7E1E3",
    "neutral": "#EEF1F4",
    "edge": "#3C4858",
    "text": "#17212B",
    "accent": "#2F5D8A",
    "warning": "#8A5A18",
}


def box(ax, x, y, w, h, title, body, color, title_size=10.5, body_size=8.5):
    patch = FancyBboxPatch(
        (x, y), w, h,
        boxstyle="round,pad=0.012,rounding_size=0.012",
        linewidth=1.25,
        edgecolor=COLORS["edge"],
        facecolor=color,
        zorder=2,
    )
    ax.add_patch(patch)
    ax.text(
        x + w / 2, y + h * 0.73, title,
        ha="center", va="center", fontsize=title_size,
        fontweight="bold", color=COLORS["text"], zorder=3,
    )
    ax.text(
        x + w / 2, y + h * 0.36, body,
        ha="center", va="center", fontsize=body_size,
        color=COLORS["text"], linespacing=1.25, zorder=3,
    )
    return patch


def arrow(ax, start, end, label=None, color=None, style="-"):
    edge_color = color or COLORS["edge"]
    a = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=13,
        linewidth=1.35,
        linestyle=style,
        color=edge_color,
        connectionstyle="arc3,rad=0.0",
        zorder=1,
    )
    ax.add_patch(a)
    if label:
        mx, my = (start[0] + end[0]) / 2, (start[1] + end[1]) / 2
        ax.text(
            mx, my + 0.012, label,
            ha="center", va="bottom", fontsize=7.8,
            color=edge_color,
            bbox=dict(facecolor="white", edgecolor="none", pad=1.2),
            zorder=4,
        )


def main():
    fig, ax = plt.subplots(figsize=(16, 9.3))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")

    fig.suptitle(
        "Incremental View Maintenance Experiment: Six-Script Workflow",
        fontsize=18,
        fontweight="bold",
        y=0.975,
        color=COLORS["text"],
    )
    ax.text(
        0.5,
        0.936,
        "PostgreSQL SLA analytics: full recomputation versus trigger-maintained deltas",
        ha="center",
        va="center",
        fontsize=11,
        color="#4F5D6B",
    )

    # Lane labels
    ax.text(0.012, 0.835, "SETUP", fontsize=10, fontweight="bold", color=COLORS["accent"], rotation=90, va="center")
    ax.text(0.012, 0.555, "LIVE DELTA", fontsize=10, fontweight="bold", color=COLORS["warning"], rotation=90, va="center")
    ax.text(0.012, 0.245, "BENCHMARKS", fontsize=10, fontweight="bold", color="#8B3A43", rotation=90, va="center")
    ax.plot([0.035, 0.985], [0.69, 0.69], color="#C9D0D7", lw=1)
    ax.plot([0.035, 0.985], [0.405, 0.405], color="#C9D0D7", lw=1)

    # Setup lane
    box(
        ax, 0.05, 0.76, 0.18, 0.13,
        "Normalized base tables",
        "Route_Logs → Deliveries\n→ Hubs + Customers",
        COLORS["data"],
    )
    box(
        ax, 0.29, 0.76, 0.20, 0.13,
        "01 · vw_sla_on_the_fly",
        "JOIN → Delay > 60 → GROUP BY\nregion and priority → penalties",
        COLORS["view"],
        title_size=9.6,
    )
    box(
        ax, 0.55, 0.76, 0.18, 0.13,
        "Initial seed / rebuild",
        "INSERT grouped rows from\nvw_sla_on_the_fly",
        COLORS["neutral"],
    )
    box(
        ax, 0.79, 0.76, 0.17, 0.13,
        "02 · Summary table",
        "Fact_SLA_Region_Summary\nkey: region + priority",
        COLORS["summary"],
        title_size=9.8,
    )
    arrow(ax, (0.23, 0.825), (0.29, 0.825), "full scan")
    arrow(ax, (0.49, 0.825), (0.55, 0.825), "grouped rows")
    arrow(ax, (0.73, 0.825), (0.79, 0.825), "populate")
    ax.text(
        0.875, 0.716,
        "Implemented in script 06 before its write test; required whenever the summary must be resynchronized.",
        ha="center", va="center", fontsize=7.6, color=COLORS["warning"], wrap=True,
    )

    # Live delta lane
    box(
        ax, 0.08, 0.50, 0.17, 0.13,
        "Route_Logs change",
        "INSERT or UPDATE\nproduces OLD / NEW values",
        COLORS["data"],
    )
    box(
        ax, 0.32, 0.50, 0.22, 0.13,
        "03 · fn_ivm_sla_update",
        "Lookup region + priority\nand calculate delta penalty",
        COLORS["trigger"],
        title_size=9.8,
    )
    box(
        ax, 0.61, 0.54, 0.16, 0.095,
        "Subtract OLD",
        "If UPDATE and OLD delay > 60",
        COLORS["benchmark"],
        body_size=8,
    )
    box(
        ax, 0.61, 0.43, 0.16, 0.095,
        "Add NEW",
        "If NEW delay > 60: UPSERT",
        COLORS["summary"],
        body_size=8,
    )
    box(
        ax, 0.83, 0.50, 0.14, 0.13,
        "Fact_SLA_Region_Summary",
        "Adjust counts + costs;\nremove zero-count groups",
        COLORS["summary"],
        title_size=9.2,
    )
    arrow(ax, (0.25, 0.565), (0.32, 0.565), "AFTER each row")
    arrow(ax, (0.54, 0.58), (0.61, 0.585), "UPDATE")
    arrow(ax, (0.54, 0.53), (0.61, 0.475), "INSERT / UPDATE")
    arrow(ax, (0.77, 0.585), (0.83, 0.585))
    arrow(ax, (0.77, 0.475), (0.83, 0.545))

    # Benchmarks lane
    box(
        ax, 0.045, 0.18, 0.20, 0.15,
        "04 · Read benchmark",
        "1 warm-up + 3 measured runs\nEXPLAIN (ANALYZE, BUFFERS)",
        COLORS["benchmark"],
    )
    box(
        ax, 0.28, 0.25, 0.16, 0.095,
        "On-the-fly read",
        "Rejoin and regroup base tables",
        COLORS["view"],
        body_size=8,
    )
    box(
        ax, 0.28, 0.135, 0.16, 0.095,
        "Summary read",
        "Scan precomputed grouped rows",
        COLORS["summary"],
        body_size=8,
    )
    arrow(ax, (0.245, 0.275), (0.28, 0.297))
    arrow(ax, (0.245, 0.235), (0.28, 0.182))

    box(
        ax, 0.49, 0.18, 0.20, 0.15,
        "05 · Write baseline",
        "Disable trigger → insert 10,000 rows\n→ record time → clean up",
        COLORS["neutral"],
    )
    box(
        ax, 0.75, 0.18, 0.20, 0.15,
        "06 · Write with IVM",
        "Enable trigger → rebuild summary\n→ insert 10,000 → verify equality",
        COLORS["trigger"],
    )
    arrow(ax, (0.69, 0.255), (0.75, 0.255), "compare insert cost")

    # Output row
    box(
        ax, 0.10, 0.025, 0.31, 0.075,
        "READ-LATENCY RESULT",
        "Full recomputation time  ↔  summary-table time",
        "#E8EEF6",
        title_size=9.5,
        body_size=8,
    )
    box(
        ax, 0.57, 0.025, 0.33, 0.075,
        "WRITE-PENALTY RESULT",
        "Trigger disabled time  ↔  trigger enabled time",
        "#F7E8DB",
        title_size=9.5,
        body_size=8,
    )
    arrow(ax, (0.36, 0.135), (0.26, 0.10), color=COLORS["accent"])
    arrow(ax, (0.59, 0.18), (0.66, 0.10), color=COLORS["warning"])
    arrow(ax, (0.85, 0.18), (0.82, 0.10), color=COLORS["warning"])

    plt.tight_layout(rect=(0.01, 0.025, 0.99, 0.955))
    fig.savefig(OUT / "ivm_six_script_workflow.png", dpi=300, bbox_inches="tight", facecolor="white")
    fig.savefig(OUT / "ivm_six_script_workflow.pdf", bbox_inches="tight", facecolor="white")
    plt.close(fig)


if __name__ == "__main__":
    main()
