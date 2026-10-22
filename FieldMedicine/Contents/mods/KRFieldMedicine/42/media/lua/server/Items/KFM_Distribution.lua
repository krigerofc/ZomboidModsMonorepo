require "Items/ProceduralDistributions"
local supplies={"Base.KFM_ThroatLozenges",2,"Base.KFM_BreathingAid",1,"Base.KFM_CardiacSupport",1,"Base.KFM_RecoveryJournal",2,"Base.KFM_InsectRepellent",2,"Base.KFM_SupportSachet",2,"Base.KFM_SkinOintment",1,"Base.KFM_BurnDressing",2,"Base.KFM_RehabWrap",1}
local d=ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list.MedicalStorageDrugs
if d and d.items then for _,v in ipairs(supplies) do table.insert(d.items,v) end end
