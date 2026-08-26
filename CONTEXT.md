# IBUILD Construction Platform

Domain context for site operations, construction progress telemetry, quality assurance checklists, and project governance.

## Language

### Construction Execution

**Phase Milestone**:
A macro-stage of construction execution (e.g., Earthwork, Substructure, Masonry, MEP, Finishing) whose completion represents a verified structural transition.
_Avoid_: Stage, sub-task, activity

**Checklist Item**:
A granular quality assurance inspection check or compliance gate on site that requires explicit verification.
_Avoid_: Todo, task, snag, bug

**Phase Group**:
The structural classification that aggregates multiple **Checklist Items** into a single **Phase Milestone**.
_Avoid_: Category, bucket, tag

**Daily Progress Report (DPR)**:
A daily point-in-time site snapshot logged by on-site supervisors capturing physical work notes, completion estimates, and photographic evidence.
_Avoid_: Site snap, daily log, time card

**Site Drawing**:
An architectural blueprint, floor plan, structural mapping, or engineering schematic attached to a project for on-site reference and inspection validation.
_Avoid_: Document, file, attachment, snap

**Photographic Evidence**:
A visual capture attached to a **Daily Progress Report (DPR)** or **Checklist Item** verifying work completion or defect resolution.
_Avoid_: Pic, snap, screenshot

**Evidence Queue**:
The client-side offline buffer that holds unsynchronized media and metadata until cloud storage connectivity is confirmed.
_Avoid_: Upload cache, staging area

### Financial Telemetry & Governance

**Financial Variance**:
The difference between budget utilization percentage and physical progress percentage ($\text{Utilization} - \text{Physical Progress}$), serving as an early indicator of cashflow overrun or material hoarding.
_Avoid_: Cost discrepancy, gap, slippage

**Budget Utilization**:
The percentage ratio of committed and disbursed site expenditures against the total approved project budget.
_Avoid_: Burn rate, spent ratio

**Physical Progress**:
The ground-truth percentage of completed structural and architectural execution on site.
_Avoid_: Site percentage, work done

## Relationships

- A **Project** has multiple sequential **Phase Milestones**
- A **Phase Group** aggregates several **Checklist Items** under one **Phase Milestone**
- A **Phase Milestone** completion ratio is computed bottom-up from the verified status of its **Checklist Items**
- A **Daily Progress Report (DPR)** records daily site conditions and overall site completion, supplementing the **Phase Milestones**
- A **Site Drawing** provides visual and dimensional ground truth for **Checklist Items**
- **Photographic Evidence** attaches to a **Daily Progress Report (DPR)** or **Checklist Item** and is buffered via the **Evidence Queue** when offline
- A **Financial Variance** exceeding $+15\%$ triggers an automated executive warning banner

## Example dialogue

> **Developer:** "If a supervisor is in a basement with no cellular signal, should we block them from logging site progress photos?"
> **Domain Expert:** "Never. The app must immediately commit the **Daily Progress Report (DPR)** with its **Photographic Evidence** into the local **Evidence Queue**, display it optimistically in the feed, and synchronize with the cloud once connectivity is regained."

## Flagged ambiguities

- "Site snap" was used colloquially to mean both **Site Drawing** (engineering blueprints/schematics) and **Photographic Evidence** (daily site progress photos) — resolved: these are distinct domain models with separate lifecycles and retention rules.
- "Milestone" vs "Checklist Item" — resolved: Milestones are computed aggregations; Checklist Items are the atomic units of site verification.
- "Financial Variance" vs "Profit/Loss" — resolved: Financial Variance tracks the timing alignment between cash outflow and physical completion, not accounting margin.
