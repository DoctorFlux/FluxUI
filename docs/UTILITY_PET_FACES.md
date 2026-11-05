# Utility-slot Pet Journal faces — 5 November 2026

The user clarified the symptom as a question mark or incorrect icon after
assigning a collection pet to a utility button. The saved GUID and summon
macro were already present. Utility assignments compile to macrotext, whose
shared display parser resolves spell/item faces, not a Pet Journal GUID.
The utility manager had checked-state support for pets but no corresponding
icon or journal-tooltip ownership.

The utility manager now resolves the selected display entry (including its
modifier and preferred-base mirror) through the existing Pet Journal API.
It supplies the existing icon override and tooltip-extra surfaces without
changing the stored identity or summon macro. Missing metadata uses the pet
fallback icon until `PET_JOURNAL_LIST_UPDATE` feeds the existing coalesced
checked refresh. Pet overrides are removed on replacement or emptying a slot.
Modifier face updates are visual and do not write protected attributes in
combat. One existing frame gains one capability-gated event; no polling,
frame, independent timer or saved-variable schema is added.

[Blizzard's pinned Forever slash handler](https://raw.githubusercontent.com/Gethe/wow-ui-source/aff0d8cd53bf4d9ef1c1dd2786b94461a276fb16/Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommands.lua)
uses conditional parsing for the pet summon command and accepts the GUID
fallback. That supports preserving the current summon path. The installed
source mirror also uses `C_PetJournal.GetPetInfoByPetID` and companion-pet
cursor identity. The packaged API declaration query lacked an entry for
that info helper; absence there was not interpreted as removal. Sources
establish contracts, not native runtime acceptance. No reference code copied.

Baseline `11fec297ad16e57b702f12b20d9ab51675733187`; exact candidate
hashes and raw pairs are in [the comparison](validation/utility-pet-comparison-2026-11-05.json).
Verified external `Utility-pets-20261105T074210Z` preserves1,428 actual
files, Git history and131 available on-disk settings files. Source archive
SHA256: `8b960e54725d651a2f2b0395d9b74fdc58fa93781b04f9d3542f9f7b28a79aa2`.
No game input, settings/profiler reset, companion change or excluded callback
work occurred.

The [regression](../tests/utility_pet_faces.lua) loads production assignment,
utility-manager and EBS painter code; native journal data, frames and macro
writes are mocked. Five target models plus a missing-journal control cover
base/modifier icons, GUID tooltip, no action rebuild during combat,
metadata recovery, snapshot restoration, preferred modifier mirroring and
replacement cleanup. Five alternating fresh-process pairs pass920 checks;
the baseline fails40. Three mutations (wrong icon, no cleanup, no metadata
event) are rejected. [Full desktop validation](validation/utility-pet-faces-2026-11-05.json)
passes **125 scripts /780 syntax files**, including transmog/utility controls.
Desktop process times include fixture/assertion overhead. Native CPU, memory,
frame time, operation latency, matched screenshots, exact builds/settings/
hardware/addon lists and secure execution remain unavailable/pending.

Native checks: reload, drag two distinct owned pets into base and Shift/Control
utility assignments, then compare icons/tooltips with the journal and test
summoning/dismissing by click and key. Change modifiers during combat and
confirm only the face changes. Reload with the journal initially closed;
verify saved GUIDs and icons recover after journal data loads. Test custom
names, modifier-only mirror, replacement with a spell/item/mount/outfit, and
clearing the slot. Repeat on supported clients with Pet Journal APIs; clients
without those APIs retain their existing capabilities. Check pixels, taint
and matched timings before claiming native parity or performance.
