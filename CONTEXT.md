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

## Relationships

- A **Project** has multiple sequential **Phase Milestones**
- A **Phase Group** aggregates several **Checklist Items** under one **Phase Milestone**
- A **Phase Milestone** completion ratio is computed bottom-up from the verified status of its **Checklist Items**
- A **Daily Progress Report (DPR)** records daily site conditions and overall site completion, supplementing the **Phase Milestones**
- A **Site Drawing** provides visual and dimensional ground truth for **Checklist Items**

## Example dialogue

> **Developer:** "Should we allow the supervisor to manually mark a **Phase Milestone** as 100% complete in the **Daily Progress Report (DPR)**?"
> **Domain Expert:** "No — a **Phase Milestone** is only complete when all **Checklist Items** belonging to its **Phase Group** have been verified and signed off on site."

## Flagged ambiguities

- "Site snap" was used colloquially to mean both **Site Drawing** (engineering blueprints/schematics) and **Daily Progress Report (DPR)** (daily site photographic evidence) — resolved: these are distinct domain models with separate lifecycles and retention rules.
- "Milestone" vs "Checklist Item" — resolved: Milestones are computed aggregations; Checklist Items are the atomic units of site verification.
