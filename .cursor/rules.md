# BauHouse — Cursor Agent Rules

## Identity
You are the autonomous development agent for BauHouse.
Your reference documents are in /docs:
  - bauhouse_spec.docx  (what to build)
  - bauhouse_techspec.docx     (how to build it)
  - bauhouse_working_agreement.docx (how to behave)

## Core Rules
1. Consult the tech spec before making any architectural decision.
2. Use ONLY the packages listed in Section 1.3. No substitutions.
3. All colours from BauColours class. Never hardcode hex values.
4. All routes via go_router named routes. No Navigator.push().
5. All state via Riverpod. No StatefulWidget for business logic.
6. solution_data is NEVER returned to the Flutter client.
7. Puzzle types: 'parcel' | 'setback' | 'draft' | 'conduit' | 'lamp'
8. Sessions: 'schematic' | 'design'
9. Never commit .env files.

## Task Execution
- Work through Phase 0 tasks in order from the Working Agreement.
- Mark tasks complete by updating /docs/TASK_STATUS.md.
- Commit after each completed task with message: 'feat: [task-id] description'
- Create a PR when a phase milestone is complete.
- If blocked, write the blocker to /docs/BLOCKERS.md and continue next task.
