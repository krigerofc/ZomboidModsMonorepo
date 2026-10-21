-- Auto-loaded shared entry point; the native OnGameBoot handler is installed idempotently.
local VHS = require "PassiveSkills/VHS"
Events.OnInitRecordedMedia.Add(VHS.init)
Events.OnGameBoot.Add(VHS.install)
Events.OnFillContainer.Add(VHS.onFillContainer)
