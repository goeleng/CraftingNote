------------------------------
-- CraftingNote
-- Created by: Goeleng
-- Version: 0.0.3
------------------------------

CraftingNote = {}

CraftingNote.name = "CraftingNote"
CraftingNote.quests = {}

function CraftingNote:Initialize()
    CraftingNote.ScanJournalForCraftingQuests()
end

function CraftingNote.OnAddOnLoaded(event, addonName)
    if addonName == CraftingNote.name then
        CraftingNote:Initialize()
    end
end

function CraftingNote.GetNumberOfQuest()
    return GetNumJournalQuests()
end

function CraftingNote.ScanJournalForCraftingQuests()
    CraftingNote.quests = {}
    collectgarbage()
    
    local numberOfQuests = CraftingNote.GetNumberOfQuest()
    for i = 1,numberOfQuests do
        local activeStepType
        local questName
        local activeStepText

        questName,_,_,activeStepType,_,_,_,_,_,_,_ = GetJournalQuestInfo(i)

        if GetJournalQuestType(i) == 4 then -- replace 4 with global variable
            CraftingNote.quests[table.getn(CraftingNote.quests) + 1] = CraftingNote.CreateQuestObject(i)
        end
    end
end

function CraftingNote.CreateQuestObject(journalIndex)
    local name = ""
    local backgroundText
    local activeStepText
    local activeStepType
    local stepText
    local stepType
    local completed

    local maxSteps = 0
    local numberOfConditions = 0
    local condition = {}

    name,backgroundText,activeStepText,activeStepType,_,completed,_,_,_,questType,_ = GetJournalQuestInfo(journalIndex)
    maxSteps = GetJournalQuestNumSteps(journalIndex)
  
    -- you need only first step with recipes?
    stepText,_,stepType,_,numberOfConditions = GetJournalQuestStepInfo(journalIndex, 1)

    for c = 1, numberOfConditions do
        local conditionText
        local currentConditionIndex
        local maxConditionIndex
        local isComplete

        conditionText,currentConditionIndex,maxConditionIndex,_,isComplete,_,_,_ = GetJournalQuestConditionInfo(journalIndex, 1, c)

        if conditionText ~= "" and conditionText ~= nil then
            condition[table.getn(condition) + 1] = {conditionText = conditionText, 
                                                    currentConditionIndex = currentConditionIndex,
                                                    maxConditionIndex = maxConditionIndex,
                                                    completed = isComplete}
        end
    end

    return {journalIndex = journalIndex, questName = name, displayed = false , questSteps = maxSteps, 
            stepText = stepText, numberOfConditions = numberOfConditions, condition = condition}
end

-- Not used right now
function CraftingNote.IsStepFinished(questIndex)
    for i = 1, table.getn(CraftingNote.quests[questIndex].condition) do
        local conditionText,currentConditionIndex,maxConditionIndex,_,isComplete,_,_,_ = GetJournalQuestConditionInfo(CraftingNote.quests[questIndex].journalIndex, 2, i)
    
        if isComplete == false then
            return false
        end
    end
    return true
end

function CraftingNote.GetQuestIndex(updateJournalIndex)
    local isCraftingQuest = false
    local updateIndex = 0

    for index = 1, table.getn(CraftingNote.quests) do
        if CraftingNote.quests[index].journalIndex == updateJournalIndex then
            return index
        end
    end
    return index
end

function CraftingNote.ConditionChanged(eventCode, journalIndex, questName, conditionText, conditionType, currConditionVal, newConditionVal, 
            conditionMax, isFailCondition, stepOverrideText, isPushed, isComplete, isConditionComplete, isStepHidden, isConditionCompleteStatusChanged)
    
    local questIndex = CraftingNote.GetQuestIndex(journalIndex)
    
    CraftingNote.UpdateConditionText(questIndex, true)
    CraftingNote.UpdateQuestEntry(journalIndex, questIndex)
    CraftingNote.UpdateConditionText(questIndex, false)
  
end

function CraftingNote.UpdateQuestEntry(updateJournalIndex, questIndex) 
    if questIndex ~= 0 then
        CraftingNote.quests[questIndex] = CraftingNote.CreateQuestObject(updateJournalIndex)
    end
end

function CraftingNote.HideNote()
    CraftingNoteWindow:SetHidden(true)
    for index=1, table.getn(CraftingNote.quests) do
        if CraftingNote.quests[index].displayed == true then
            CraftingNote.quests[index].displayed = false
        end
    end
    CraftingNote.ResetConditionText()
end

function CraftingNote.PrintAllQuests()
    for i = 1, table.getn(CraftingNote.quests) do --questPosition instead of size for new element
        d(CraftingNote.quests[i])
    end
end

function CraftingNote.FillNote(craftSkill)
    
    local questCompareName = ""
    local questIndex = 0

    -- ToDO find better solution to find correct crafting quest
    if craftSkill == 1 then -- Schmied
        questCompareName = "Schmiedeschrieb"
    elseif craftSkill == 2 then -- Schneider
        questCompareName = "Schneiderschrieb"
    elseif craftSkill == 3 then -- Verzaubern
        questCompareName = "Verzaubererschrieb"
    elseif craftSkill == 4 then -- Alchemy
        questCompareName = "Alchemistenschrieb"
    elseif craftSkill == 5 then -- Kochen
        questCompareName = "Versorgerschrieb"
    elseif craftSkill == 6 then -- Schreiner
        questCompareName = "Schreinerschrieb"
    elseif craftSkill == 7 then -- Juewlier
        questCompareName = "Schmuckhandwerksschrieb"
    else 
        questCompareName = "Empty" -- check for empty string and stop searching 
    end

    -- Find correct quest index for crafting station
    for index = 1, table.getn(CraftingNote.quests) do
        if CraftingNote.quests[index].questName == questCompareName then
            questIndex = index
            CraftingNote.quests[index].displayed = true
        end
    end

    if questIndex == 0 then
        return false
    end

    local questLabelControl = CraftingNote.CreateQuestText(CraftingNote.quests[questIndex].questName, 1)

    for i = 1,table.getn(CraftingNote.quests[questIndex].condition) do
        CraftingNote.CreateConditionText(CraftingNote.quests[questIndex].condition[i].conditionText, questLabelControl, i)
    end
    return true
end

function CraftingNote.CreateQuestText(questName, index) 
    local questPanelControl = GetControl("CN_QuestPanel_".. index)
    if questPanelControl == nil then
        questPanelControl = CreateControlFromVirtual("CN_QuestPanel_", CraftingNoteWindow, "CN_QuestPanel", index)
    end
    
    local questLabelControl = GetControl("CN_QuestPanel_" .. index .. "_Label")
    questLabelControl:SetText(questName)
    return questLabelControl
end

function CraftingNote.CreateConditionText(conditionText, questLabelControl, index)
    local conditionPanelControl = GetControl("CN_ConditionPanel_" .. index)
    if conditionPanelControl == nil then
        conditionPanelControl = CreateControlFromVirtual("CN_ConditionPanel_", CraftingNoteWindow, "CN_ConditionPanel", index)
    end
   
    conditionPanelControl:ClearAnchors()
    local height = CraftingNote.CalculateHeight(index)
    conditionPanelControl:SetAnchor(TOPLEFT, questLabelControl, BOTTOMLEFT, 10, height)
    local conditionLabelControl = GetControl("CN_ConditionPanel_" .. index .. "_Label")
    conditionLabelControl:SetText(conditionText)
end

function CraftingNote.CalculateHeight(index) 
    local height = 0
    for index = 1, index - 1 do
        preControl = GetControl("CN_ConditionPanel_" .. index .. "_Label")
        if preControl ~= nil then
            _,_,_,_,_,delta = preControl:GetAnchor()
            height = height + delta + preControl:GetHeight()
        end
    end
    return height
end

function CraftingNote.ResetConditionText()
    for index = 1, 5 do 
        local conditionLabel = GetControl("CN_ConditionPanel_" .. index .. "_Label")
        if conditionLabel ~= nil then
            conditionLabel:SetText("")
        end
    end
end

function CraftingNote.UpdateConditionText(updateIndex, isRemovingText)
    local conditionPanelControl = GetControl("CN_ConditionPanel_" .. 1) -- conditions are on step one
    if conditionPanelControl == nil then
        return -- nothing to update because UI is hidden
    end

    if updateIndex ~= 0 then
        for index = 1, table.getn(CraftingNote.quests[updateIndex].condition) do
            local conditionLabel = GetControl("CN_ConditionPanel_" .. index .. "_Label")
            if isRemovingText == false then
                conditionLabel:SetText(CraftingNote.quests[updateIndex].condition[index].conditionText)
            else
                conditionLabel:SetText("")
            end       
        end
    end
end

function CraftingNote.CreateNote(eventCode, craftSkill)
    local craftSkillFound
    CraftingNote.ScanJournalForCraftingQuests()
    craftSkillFound = CraftingNote.FillNote(craftSkill)
    if craftSkillFound then
        CraftingNoteWindow:SetHidden(false)
    end
end

-------------------------------------------------------------
-------- EVENT REGISTRATION ---------------------------------
-------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent(CraftingNote.name, EVENT_ADD_ON_LOADED, CraftingNote.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(CraftingNote.name, EVENT_CRAFTING_STATION_INTERACT, CraftingNote.CreateNote)
EVENT_MANAGER:RegisterForEvent(CraftingNote.name, EVENT_END_CRAFTING_STATION_INTERACT, CraftingNote.HideNote)
EVENT_MANAGER:RegisterForEvent(CraftingNote.name, EVENT_QUEST_CONDITION_COUNTER_CHANGED, CraftingNote.ConditionChanged)
-------------------------------------------------------------
-------- General Information about API ----------------------
-------------------------------------------------------------
-- QuestJournal Step is the quest text
-- QuestJournal Condition is the task which you need to fulfill
-- QuestJournal NumCondition: sum of all conditions through every step