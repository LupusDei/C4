# Beads Import: AI Creative Director — Trend-Aware Prompt Intelligence

**Epic**: `C4-003`
**Project**: C4

## Hierarchy

```
C4-003           (root epic: AI Creative Director)
  C4-003.1       (sub-epic: Setup)
    C4-003.1.1   (task: T001 - Migration)
    C4-003.1.2   (task: T002 - StylePreset model)
    C4-003.1.3   (task: T003 - PromptHistory model)
  C4-003.2       (sub-epic: Foundational)
    C4-003.2.1   (task: T004 - Style routes)
    C4-003.2.2   (task: T005 - Prompt history routes)
    C4-003.2.3   (task: T006 - Seed style presets)
    C4-003.2.4   (task: T007 - Register routes)
    C4-003.2.5   (task: T008 - iOS API client)
    C4-003.2.6   (task: T009 - PromptFeature scaffold)
  C4-003.3       (sub-epic: US1 - Smart Prompt Enhancement)
    C4-003.3.1   (task: T010 - Prompt enhancer service)
    C4-003.3.2   (task: T011 - Enhance endpoint)
    C4-003.3.3   (task: T012 - PromptEnhancerView)
    C4-003.3.4   (task: T013 - PromptEnhancerReducer)
    C4-003.3.5   (task: T014 - Integrate into ImageGenerateView)
    C4-003.3.6   (task: T015 - Integrate into VideoGenerateView)
  C4-003.4       (sub-epic: US2 - Visual Style Library)
    C4-003.4.1   (task: T016 - StylePickerView)
    C4-003.4.2   (task: T017 - StylePickerReducer)
    C4-003.4.3   (task: T018 - Style extraction endpoint)
    C4-003.4.4   (task: T019 - Save as Style action)
    C4-003.4.5   (task: T020 - Project style lock UI)
    C4-003.4.6   (task: T021 - Wire style picker into gen views)
    C4-003.4.7   (task: T022 - Update project route)
  C4-003.5       (sub-epic: US3 - Prompt History & Remix)
    C4-003.5.1   (task: T023 - Auto-record prompt history)
    C4-003.5.2   (task: T024 - Kept tracking)
    C4-003.5.3   (task: T025 - Remix endpoint)
    C4-003.5.4   (task: T026 - PromptHistoryView)
    C4-003.5.5   (task: T027 - PromptHistoryReducer)
    C4-003.5.6   (task: T028 - History access in gen screens)
  C4-003.6       (sub-epic: US4 - Content Intelligence, P2)
    C4-003.6.1   (task: T029 - Niche migration)
    C4-003.6.2   (task: T030 - Suggest endpoint)
    C4-003.6.3   (task: T031 - Series endpoint)
    C4-003.6.4   (task: T032 - ContentSuggestionsView)
    C4-003.6.5   (task: T033 - SeriesGeneratorView)
    C4-003.6.6   (task: T034 - Content intelligence reducer)
  C4-003.7       (sub-epic: US5 - Learning Loop, P2)
    C4-003.7.1   (task: T035 - Analytics queries)
    C4-003.7.2   (task: T036 - More Like This endpoint)
    C4-003.7.3   (task: T037 - GenerationAnalyticsView)
    C4-003.7.4   (task: T038 - More Like This button)
    C4-003.7.5   (task: T039 - Learning loop reducer)
```

## Dependencies

```
C4-003.1 → C4-003.2                    (Setup blocks Foundational)
C4-003.2 → C4-003.3                    (Foundational blocks Enhancement)
C4-003.2 → C4-003.4                    (Foundational blocks Style Library)
C4-003.2 → C4-003.6                    (Foundational blocks Content Intelligence)
C4-003.3 → C4-003.5                    (Enhancement blocks History)
C4-003.5 → C4-003.7                    (History blocks Learning Loop)
```

Note: C4-003.3 and C4-003.4 can run in parallel. C4-003.6 and C4-003.7 can run in parallel (after their respective deps).

## Task Tables

### Phase 1: Setup

| Bead ID | T-ID | Type | Priority | Title |
|---------|------|------|----------|-------|
| C4-003.1.1 | T001 | task | P2 | Create style_presets, prompt_history tables migration |
| C4-003.1.2 | T002 | task | P2 | Create StylePreset iOS model |
| C4-003.1.3 | T003 | task | P2 | Create PromptHistory iOS model |

### Phase 2: Foundational

| Bead ID | T-ID | Type | Priority | Title |
|---------|------|------|----------|-------|
| C4-003.2.1 | T004 | task | P2 | Create style preset CRUD routes |
| C4-003.2.2 | T005 | task | P2 | Create prompt history routes |
| C4-003.2.3 | T006 | task | P2 | Seed 30+ curated style presets |
| C4-003.2.4 | T007 | task | P2 | Register styles and prompts routes |
| C4-003.2.5 | T008 | task | P2 | Add style/history API methods to iOS APIClient |
| C4-003.2.6 | T009 | task | P2 | Create PromptFeature SPM package scaffold |

### Phase 3: US1 - Smart Prompt Enhancement

| Bead ID | T-ID | Type | Priority | Title |
|---------|------|------|----------|-------|
| C4-003.3.1 | T010 | task | P2 | Create prompt-enhancer service with Claude API |
| C4-003.3.2 | T011 | task | P2 | Add prompt enhance endpoint |
| C4-003.3.3 | T012 | task | P2 | Create PromptEnhancerView |
| C4-003.3.4 | T013 | task | P2 | Create PromptEnhancerReducer |
| C4-003.3.5 | T014 | task | P2 | Integrate enhancer into ImageGenerateView |
| C4-003.3.6 | T015 | task | P2 | Integrate enhancer into VideoGenerateView |

### Phase 4: US2 - Visual Style Library

| Bead ID | T-ID | Type | Priority | Title |
|---------|------|------|----------|-------|
| C4-003.4.1 | T016 | task | P2 | Create StylePickerView gallery |
| C4-003.4.2 | T017 | task | P2 | Create StylePickerReducer |
| C4-003.4.3 | T018 | task | P2 | Add style extraction endpoint |
| C4-003.4.4 | T019 | task | P2 | Add Save as Style action |
| C4-003.4.5 | T020 | task | P2 | Add project style lock UI |
| C4-003.4.6 | T021 | task | P2 | Wire style picker into generation views |
| C4-003.4.7 | T022 | task | P2 | Update project route for style lock |

### Phase 5: US3 - Prompt History & Remix

| Bead ID | T-ID | Type | Priority | Title |
|---------|------|------|----------|-------|
| C4-003.5.1 | T023 | task | P2 | Auto-record prompt history on generation |
| C4-003.5.2 | T024 | task | P2 | Track kept/regenerated status |
| C4-003.5.3 | T025 | task | P2 | Add remix endpoint |
| C4-003.5.4 | T026 | task | P2 | Create PromptHistoryView |
| C4-003.5.5 | T027 | task | P2 | Create PromptHistoryReducer |
| C4-003.5.6 | T028 | task | P2 | Add history access to generation screens |

### Phase 6: US4 - Content Intelligence (P2)

| Bead ID | T-ID | Type | Priority | Title |
|---------|------|------|----------|-------|
| C4-003.6.1 | T029 | task | P3 | Add niche field migration |
| C4-003.6.2 | T030 | task | P3 | Add suggest endpoint |
| C4-003.6.3 | T031 | task | P3 | Add series ideation endpoint |
| C4-003.6.4 | T032 | task | P3 | Create ContentSuggestionsView |
| C4-003.6.5 | T033 | task | P3 | Create SeriesGeneratorView |
| C4-003.6.6 | T034 | task | P3 | Create content intelligence reducer |

### Phase 7: US5 - Learning Loop (P2)

| Bead ID | T-ID | Type | Priority | Title |
|---------|------|------|----------|-------|
| C4-003.7.1 | T035 | task | P3 | Add analytics aggregation queries |
| C4-003.7.2 | T036 | task | P3 | Add More Like This endpoint |
| C4-003.7.3 | T037 | task | P3 | Create GenerationAnalyticsView |
| C4-003.7.4 | T038 | task | P3 | Add More Like This button to asset preview |
| C4-003.7.5 | T039 | task | P3 | Create learning loop reducer |
