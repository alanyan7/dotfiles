---
name: eng-design
description: How to draft an engineering design doc (proposal, design, architecture plan, RFC) that others will review — when one is worth writing, lifecycle, format (artifact with diagrams), structure (TL;DR, TOC, why, sub-problems, root cause, simple solutions, evidence, roadmap) and language. Use before drafting or revising any design doc meant to be shared.
---

# Engineering design guide

How to draft an engineering design doc.

## When to write one

- **Only when others need to see it.** A design is worth the time when it has to be shared and reviewed. If one person can do the work without involving anyone, do whatever suits you and skip this guide.
- **Designs are one-off.** A design serves one project and is done once the project is finished. It is not a contract that future changes have to stay compatible with.
- **Decisions are different.** A decision that future work must respect (an interface, a convention, a constraint) is a contract: write it down on its own and track it in git, not only inside the design.

## Lifecycle

Draft → share and review → implement → verify.

## Format

- **Collaborative HTML (an artifact), not Markdown.** Reviewers comment in place.
- **A diagram beats a paragraph.** Use whatever fits:
  - ER diagrams for data;
  - sequence diagrams for interactions;
  - flowcharts for logic;
  - dependency graphs for structure and ordering;
  - tables for comparisons and numbers.

## Structure

1. **TL;DR first.** The core message in the fewest words possible.
2. **Table of contents** in a sidebar beside the content, sticky to the top of the viewport (`position: sticky; top: 0`) so it stays visible while scrolling and any section is one click away. Highlight the section in view. On narrow screens, collapse it into a menu that is still reachable without scrolling back up.
3. **Why.** State the problem with a precise definition before anything else.
4. **Break the problem down.** Split it into sub-problems. Don't take on the problem as a whole with one solution that touches everything.
5. **Root cause before solutions.** For each sub-problem, dig to the deepest cause first. Ask why the problem exists at all, and don't solve problems that shouldn't exist.
6. **Simple solutions.** Apply Occam's razor and avoid over-engineering. If a solution takes a lot of effort to explain and defend, something is usually wrong. Step back and ask two questions:
   - Is this the right problem to solve?
   - Is there an existing solution to use instead of building one?
7. **Evidence.** When time allows, run experiments and bring concrete results. Evaluate feasibility, risks and costs. Stay practical, not theoretical.
8. **Roadmap.** Combine all the solutions into one actionable plan.
   - Order it so the most blocking and riskiest items come first, to get the most signal early and guide the rest of the work.
   - Often the first item is an experiment that shows whether the whole thing is feasible at all.

## Language

- **Nothing specific to the author or the drafting session.** Keep out PR numbers, agent or session names, and decisions still pending with the author. The doc should read the same to anyone, at any time.
- **Objective and concise.** No filler, no slop.
- **Concrete numbers** wherever possible: measured times, costs, counts, before and after.
