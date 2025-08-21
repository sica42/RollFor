RollFor = RollFor or {}
local m = RollFor

if m.BossList then return end

---@class BossList
---@field zones table<string, string[]>

local M    = {}

M.zones    = {
  [ "Durotar" ] = {
    "Elder Mottled Boar"
  },
  [ "Emerald Sanctum" ] = {
    "Erennius",
    "Solnius"
  },
  [ "Tower of Karazhan" ] = {
    "Master Blacksmith Rolfen",
    "Brood Queen Araxxna",
    "Grizikil",
    "Clawlord Howlfang",
    "Lord Blackwald II",
    "Moroes"
  },
  [ "Zul'Gurub" ] = {
    "High Priestess Jeklik",
    "High Priest Venoxis",
    "Witherbark Speaker",
    "High Priestess Mar'li",
    "Vilebranch Speaker",
    "Broodlord Mandokir",
    "Ohgan",
    "Gri'lek",
    "Hazza'rah",
    "Renataki",
    "Wushoolay",
    "Gahz'ranka",
    "High Priest Thekal",
    "Zealot Zath",
    "Zealot Lor'Khan",
    "High Priestess Arlokk",
    "Jin'do the Hexxer",
    "Hakkar"
  },
  [ "Ruins of Ahn'Qiraj" ] = {
    "Kurinnaxx",
    "General Rajaxx",
    "Moam",
    "Buru the Gorger",
    "Ayamiss the Hunter",
    "Ossirian the Unscarred"
  },
  [ "Molten Core" ] = {
    "Incindis",
    "Basalthar",
    "Smoldaris",
    "Sorcerer-Thane Thaurissan",
    "Lucifron",
    "Magmadar",
    "Gehennas",
    "Garr",
    "Shazzrah",
    "Baron Geddon",
    "Golemagg the Incinerator",
    "Sulfuron Harbinger",
    "Majordomo Executus",
    "Ragnaros"
  },
  [ "Blackwing Lair" ] = {
    "Razorgore the Untamed",
    "Vaelastrasz the Corrupt",
    "Broodlord Lashlayer",
    "Firemaw",
    "Ebonroc",
    "Flamegor",
    "Chromaggus",
    "Nefarian"
  },
  [ "Onyxia's Lair" ] = {
    "Onyxia"
  },
  [ "Ahn'Qiraj" ] = {
    "The Prophet Skeram",
    "Vem",
    "Lord Kri",
    "Princess Yauj",
    "Battleguard Sartura",
    "Fankriss the Unyielding",
    "Viscidus",
    "Princess Huhuran",
    "Emperor Vek'lor",
    "Emperor Vek'nilash",
    "Ouro",
    "C'Thun"
  },
  [ "Naxxramas" ] = {
    "Patchwerk",
    "Grobbulus",
    "Gluth",
    "Thaddius",
    "Anub'Rekhan",
    "Grand Widow Faerlina",
    "Maexxna",
    "Noth the Plaguebringer",
    "Heigan the Unclean",
    "Loatheb",
    "Instructor Razuvious",
    "Gothik the Harvester",
    "Thane Korth'azz",
    "Lady Blaumeux",
    "Highlord Mograine",
    "Sir Zeliek",
    "Sapphiron",
    "Kel'Thuzad"
  }
}

---@type BossList
m.BossList = M
return M
