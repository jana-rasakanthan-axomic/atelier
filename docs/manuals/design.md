# User Manual: /design

## Overview

The `/design` command bridges the gap between a Product Requirement Document (PRD) and implementable tickets. It creates **technical designs** and breaks them into detailed Jira stories.

## Target Audience

Senior engineers, tech leads, and architects performing the design phase of a feature.

## When to Use

- You have a PRD (from `/specify`) or high-level requirements.
- You need to document architecture decisions for team review.
- You need to turn requirements into JIRA tickets/stories.
- You are **not** ready to write code yet.

## Input Formats

```bash
/design .claude/context/user-export-prd.md   # From PRD file (Recommended)
/design PROJ-42                               # From Epic ID
/design "Add real-time notifications"         # From description
/design --split=services [input]              # Multi-repo microservices mode
```

## Strategy: Story Splitting

The command supports two splitting modes:

### 1. Monolith (Default)

Single story per endpoint or feature unit. Best for:

- Small teams (1-3 devs)
- Single repository
- Simple features

### 2. Services (`--split=services`)

Splits stories by service boundary (BFF, User Service, Notification Service). Best for:

- Microservices
- Multi-team environments
- Complex features

## Artifacts Produced

The command generates files in `.claude/design/`:

1.  **Technical Design Doc (TDD)**: Architecture, diagrams, data models.
2.  **Contracts**: OpenAPI/Interface definitions.
3.  **Tickets**: Markdown files ready for Jira import.

## Workflow Overview

1.  **Analyze**: Understands complexity and identifies unknowns.
2.  **Clarify**: Asks the user questions (Scale, Performance, Security).
3.  **Design**: Generates architectural alternatives (if complex).
4.  **Plan**: Breaks the chosen design into tickets.

## Prerequisites

You must run `/specify` first to generate:

- Business Rules (`[feature]-rules.md`)
- BDD Scenarios (`[feature]-bdd.feature`)
