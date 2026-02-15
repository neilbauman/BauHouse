# BauHouse — Build Your Corner of Something Real

BauHouse is a daily puzzle mobile app set in the fictional town of Elmfield. Players solve themed logic puzzles each day, contributing to an ongoing community construction project. Visual identity inspired by the Bauhaus design movement.

## Tech Stack

- **Mobile**: Flutter (Dart) — single codebase for iOS & Android
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **Puzzle Generation**: Python microservice (Google OR-Tools)
- **Narrative Generation**: LLM API (Claude/GPT-4 class)
- **Analytics**: PostHog
- **Subscriptions**: RevenueCat
- **Ads**: AdMob
- **Deployment**: Vercel (Python services) + Supabase Edge Functions

## Repository Structure

```
bauhouse/
├── app/                  # Flutter mobile application
├── services/             # Python backend microservices
│   ├── puzzle_generator/ # Constraint-solver puzzle generation
│   └── narrative/        # LLM narrative generation
├── supabase/             # Supabase migrations, seed data, edge functions
│   ├── migrations/
│   └── functions/
├── scripts/              # Utility and deployment scripts
├── docs/                 # Product spec, tech spec, working agreement
├── .cursor/              # Cursor agent rules
├── .env.example          # Environment variable template
└── README.md
```

## Getting Started

### Prerequisites

- Flutter SDK 3.41+
- Dart 3.11+
- Supabase CLI
- Python 3.11+ (for puzzle/narrative services)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/bauhouse.git
   cd bauhouse
   ```

2. Copy environment variables:
   ```bash
   cp .env.example .env.local
   # Fill in your Supabase and API keys
   ```

3. Install Flutter dependencies:
   ```bash
   cd app
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
   ```

## Development

- **Task tracking**: See `/docs/TASK_STATUS.md`
- **Blockers**: See `/docs/BLOCKERS.md`
- **Decision log**: See `/docs/DECISIONS_LOG.md`
- **Commit convention**: `feat: [TASK-ID] description`

## Documentation

- Product Specification: `/docs/bauhouse_spec.docx`
- Technical Specification: `/docs/bauhouse_techspec.docx`
- Working Agreement: `/docs/bauhouse_working_agreement.docx`
