# Competition Organisation

## Product position

Competition Organisation expands Alliam from a learner platform into the
infrastructure that powers academic competitions.

Learners remain the core audience. Organisers become a second first-class user
group with dedicated tools for planning, promoting, funding, running, and
repeating competitions.

The organiser product is not limited to spelling. Its underlying event model
must support spelling, mathematics, science, and future academic disciplines.

## Core principles

- A competition is a persistent project, not a one-off event.
- Organisers should reuse relationships, content, settings, and operating
  history across recurring events.
- Participant acquisition must be built into the competition workspace.
- Sponsor discovery is assisted research, not an open sponsorship marketplace.
- Sponsor recommendations must explain why an organisation is relevant.
- Outreach, follow-ups, outcomes, and sponsorship history remain attached to
  the competition and organiser.
- Recorded outcomes should improve future recommendations, subject to privacy,
  consent, data-quality, and regional compliance requirements.

## Product areas

### Organiser identity and workspace

- Organiser onboarding and organisation profile
- Team members, roles, and permissions
- Competition workspace switcher
- Organiser dashboard
- Billing and plan controls

### Competition lifecycle

- Create, edit, publish, duplicate, archive, and repeat competitions
- Discipline, format, divisions, eligibility, rules, and age/grade bands
- Venue, online, and hybrid delivery
- Schedules, milestones, staff, judges, moderators, and volunteers
- Draft, published, registration, live, completed, and archived states

### Public presence and participant acquisition

- Public competition landing page
- Rules, schedule, prizes, sponsors, FAQs, and registration calls to action
- Sharing, campaign tracking, school invitations, and announcements
- Public search/discovery and unlisted-event controls

### Registration and participant management

- Individual, parent-managed, school, and team registration
- Custom questions, eligibility, consent, approval, waitlist, and withdrawal
- Payments where applicable
- Import/export, check-in, attendance, and accreditation
- Persistent participant and school relationship history

### Communication

- Segmented email and in-app announcements
- Registration, schedule, venue, and event reminders
- Templates, delivery status, communication history, and emergency notices

### Tournament operations

- Divisions, pools, fixtures, heats, rounds, brackets, seeding, and draws
- Judge and moderator workspaces
- Live status, scoring, rulings, appeals, withdrawals, and disqualifications
- Advancement rules, live results, certificates, awards, and final reports
- Audit logs and result locking

### Competition history

- Annual edition timeline
- Prior participants, schools, sponsors, staff, and results
- Duplicate and revise prior events
- Operational notes, post-event review, and comparative reporting

### Sponsor discovery

- Competition sponsorship brief and sponsor-fit criteria
- Research based on publicly available organisational information
- Suggestions based on region, subject alignment, audience, and prior
  educational sponsorship
- Relevant public contact information
- Evidence, reasoning, confidence, freshness, and source metadata
- Organiser review before outreach

Sponsor suggestions must never imply agreement to sponsor. Research, contact
data, and outreach must comply with applicable privacy, anti-spam, and
data-protection rules.

### Sponsor CRM and outreach

- Prospect pipeline, owner, status, value, and next action
- Tailored proposal and outreach drafting
- Sponsorship packages and proposal documents
- Conversation, follow-up, and meeting history
- Commitments, benefits, deliverables, and payment status
- Successful, declined, unresponsive, and future-opportunity outcomes
- Reusable sponsor relationship history

Outbound messages require organiser review and explicit send action.

### Sponsorship intelligence

- Record recommendation, outreach, and sponsorship outcomes
- Improve matching using verified historical results
- Protect organiser-specific private relationship data
- Separate platform-wide intelligence from confidential organiser records
- Provide correction, exclusion, and retention controls

## Initial page map

### Organiser entry

- Organiser onboarding
- Organisation setup
- Organiser Home
- Competition workspace switcher

### Competition workspace

- Competition overview
- Create/edit competition
- Timeline and milestones
- Registrations
- Participants
- Schools and teams
- Communications
- Schedule
- Tournament control
- Results
- Public page editor
- Sharing and acquisition
- Sponsors
- Reports
- Settings and permissions
- Competition history

### Sponsor workspace

- Sponsor discovery
- Recommendation detail
- Sponsor pipeline
- Sponsor profile/history
- Proposal builder
- Outreach composer
- Follow-up queue
- Sponsorship commitments and delivery

## Delivery sequence

### CO-0 — Product and data foundation

- Define organiser, organisation, membership, competition, edition,
  participant, registration, sponsor, prospect, outreach, and result entities.
- Define roles, permissions, lifecycle states, and audit requirements.
- Establish learner-product and organiser-product navigation boundaries.

### CO-1 — Competition workspace MVP

- Organiser onboarding and organisation profile
- Create, edit, publish, duplicate, and archive competitions
- Competition overview and milestone checklist
- Public landing page
- Individual and school registration
- Participant management
- Basic communications
- Competition history

### CO-2 — Tournament delivery

- Divisions, rounds, fixtures, brackets, and progression
- Judge/moderator workspaces
- Live scoring and results
- Check-in and attendance
- Awards, exports, and post-event reporting

### CO-3 — Sponsor operations

- Sponsor brief
- Manually managed sponsor pipeline
- Proposal and outreach drafting
- Follow-up tracking
- Commitments and sponsorship history

### CO-4 — Assisted sponsor discovery

- Public-source research pipeline
- Evidence-backed recommendations
- Public contact enrichment
- Relevance reasoning and confidence
- Review-before-outreach workflow

### CO-5 — Sponsorship intelligence

- Outcome-based recommendation improvements
- Cross-event sponsor-fit models
- Privacy-preserving platform intelligence
- Regional and discipline expansion

## Platform UI classification

- `VP`: organiser dashboard and competition workspace. Desktop is the primary
  operational composition; mobile is a focused companion.
- `DW`: bracket editing, bulk import, advanced reporting, public-page
  composition, and proposal document editing.
- `MN`: event-day check-in, alerts, quick scoring, attendance, and field updates.
- `SH`: public competition pages, simple approvals, prospect details, and
  read-only reports.
- `CW`: approvals, status checks, and lightweight updates without native-device
  assumptions.

## Outstanding product decisions

- New organiser role versus organisation membership on any account
- Multiple organisations per organiser
- Competition pricing and payment responsibilities
- Initial supported competition formats
- Public discovery versus unlisted/private competitions
- Sponsor enrichment sources and legal basis
- Outreach provider and approval rules
- Separation of private sponsor history from platform intelligence
- Desktop-first organiser release versus simultaneous mobile companion
