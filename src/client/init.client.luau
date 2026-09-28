-- Starts every client UI and controller. The UI builds itself in code (Rojo-friendly), so the
-- ScreenGuis MainUI, RollUI, CollectionUI, ShopUI, RebirthUI, TutorialUI and AnnouncementUI appear
-- in PlayerGui when the game runs.

local Controllers = script.Controllers
local UI = script.UI

local Ambience = require(Controllers.Ambience)
local AnnouncementUI = require(UI.AnnouncementUI)
local Animator = require(Controllers.Animator)
local CollectionUI = require(UI.CollectionUI)
local Machines = require(Controllers.Machines)
local MainUI = require(UI.MainUI)
local Prompts = require(Controllers.Prompts)
local RebirthUI = require(UI.RebirthUI)
local RollUI = require(UI.RollUI)
local ShopUI = require(UI.ShopUI)
local State = require(Controllers.State)
local TutorialUI = require(UI.TutorialUI)
local World = require(Controllers.World)

AnnouncementUI.init()
RollUI.init()
MainUI.init()
CollectionUI.init()
ShopUI.init()
RebirthUI.init()
TutorialUI.init()
Prompts.init()
World.init()
Animator.init()
Machines.init()
Ambience.init()

-- Last, so every screen is listening before the first data snapshot arrives.
State.init()
