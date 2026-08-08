# Rerate

**You know what you paid. Rerate remembers why.**

An iOS app for people who already own stocks and want to answer one question:
*what has changed since I bought this, and does my thesis still hold?*

Rerate is not a broker, screener, tracker or stock chatbot. It exists to separate
five things investors routinely blur together:

| | |
|---|---|
| **Business** | Did the company get better or worse? |
| **Valuation** | Are investors paying more for the same thing? |
| **Flows** | Who has actually been transacting? |
| **Sentiment** | Is attention running ahead of the facts? |
| **Thesis** | Are the reasons you bought still true? |

It never issues buy, hold or sell instructions.

---

## Running it

Requires Xcode 16+ and an iOS 17+ simulator. No dependencies, no network calls.

```bash
open Rerate.xcodeproj
```

If `xcode-select` points at the Command Line Tools rather than Xcode, either fix
it once (`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`) or
prefix builds with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Rerate.xcodeproj -scheme Rerate -sdk iphonesimulator \
  -destination 'name=iPhone 17 Pro' build
```

The app launches straight into a seeded portfolio. To see onboarding, tap
**Add a position**, or launch with `-reset`.

### Debug launch arguments

Debug builds accept arguments that open a screen directly — useful for
screenshotting and for driving the simulator without tapping:

```
-screen  position | explain | mustbetrue | thesis | review | challenge
         | history | flows | business | signals | add
-ticker  D05 | O39 | Z74 | C38U          (default D05)
-anchor  dimensions | actions            (scroll target on the position screen)
-obPrefill                               (jump to the thesis step of onboarding)
```

---

## The demonstration case

DBS bought at **S$39.69**, now **S$76.00** — up 91%. Friends have started
talking about it. Is this still fundamentals, or is it becoming speculation?

Rerate answers it arithmetically rather than rhetorically. Price is an identity:

```
price  =  book value per share  ×  price to book
S$76.00  =      S$23.75         ×       3.20×
```

Both terms are known at purchase and today, so the move splits with no room for
interpretation: **35% of the gain came from the bank, 65% from investors
deciding to pay more for it.** Switching to the earnings lens gives 58/42 — and
the gap between the two readings *is* the return-on-equity improvement, which is
the most interesting thing on the screen.

Every figure in the seed data is internally consistent at every date, so the
decomposition, the charts and the review text can never contradict each other.

---

## Structure

```
Rerate/
  Design/       Palette, type scale, springs, haptics, animated figures
  Model/        Domain vocabulary, Holding, the valuation identity
  Data/         Seeded positions, catalogue, thesis extraction, store
  Features/
    Onboarding/ Four questions, then an editable thesis
    Portfolio/  What deserves attention today
    Position/   Where things stand, and what changed
    ExplainMove/The signature decomposition
    MustBeTrue/ Interactive assumptions and scenarios
    Thesis/     Conditions, passing / under pressure / broken
    Review/     Generated review, saved into memory
    Challenge/  Strongest bull and bear cases
    History/    The investment timeline
    Flows/      Who is transacting, and confidence in that
    Business/   Sector-specific metrics
    Signals/    Meaningful alerts only
```

### Design decisions worth knowing

**Four tones, no more.** Every qualitative judgement resolves to affirm /
neutral / caution / breach, in desaturated warm colours. There is no saturated
red or green anywhere in the app.

**Two typefaces.** New York (serif) for anything the reader should slow down
over; SF Pro for labels, controls and dense figures. The serif is what makes it
feel like a research note rather than a terminal.

**Analysis adapts to the business.** Banks are read on ROE, margin, fee mix,
credit and capital; REITs on occupancy, distributions, gearing and the cost of
debt; telecoms on cash flow and margins. `MetricGrouping` and `ValuationEngine`
both branch on `BusinessKind`.

**Uncertainty is part of the interface.** Claims are tagged Evidence /
Interpretation / Uncertain and carry a confidence mark. Where flow data does not
support a conclusion, the app says so instead of constructing a plausible story.

**The valuation screen refuses to give a fair value.** It runs the model
backwards instead: at 3.20× book with 4% growth and a 9% required return, today's
price implies a **20% sustained return on equity** — against 17.9% today and a
12.4% ten-year average. That question has a far more stable answer than "what is
it worth".

### Where a model would plug in

`ThesisExtractor` and `ReviewComposer` are the two AI surfaces, implemented
locally and deterministically. Both are structured so a language model can
replace the implementation without changing the interface — the *shape* of the
output (falsifiable conditions; a fixed set of review sections) is fixed by the
product rather than by the model. That is deliberate: it is what stops the app
becoming a chatbot.

---

## Not built (V1 scope)

Live market data, real flow feeds, push notification delivery, persistence
beyond the session, accounts, payments, and the conversational interface inside
a position. Figures throughout are illustrative and labelled as such in the app.
