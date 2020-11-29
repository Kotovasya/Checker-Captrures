script_name('Checker Captures')
script_description('Скрипт показывает активные захваты на серверах GalaxY RPG')
script_author('Kotovasya')
script_version(5.0)
script_dependencies('ImGui', 'Font Awesome 5')

require "lib.moonloader"
script_properties("work-in-pause")
local inicfg = require 'inicfg'
local dlstatus = require('moonloader').download_status
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local events = require "lib.samp.events"
local ffi = require 'ffi'

local lfsIsLoaded, lfs = pcall(require, 'lfs')
local imguiIsLoaded, imgui = pcall(require, 'imgui')
local faIsLoaded, fa = pcall(require, 'config.Checker Captures.fAwesome5')
if not faIsLoaded and getMoonloaderVersion() > 26.5 then
	faIsLoaded, fa = pcall(require, 'lib.Checker Captures.fAwesome5')
end
local fa_font = nil
if imguiIsLoaded then
	fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
end

ffi.cdef [[
struct stGangzone
{
    float    fPosition[4];
    uint32_t    dwColor;
    uint32_t    dwAltColor;
};

struct stGangzonePool
{
    struct stGangzone    *pGangzone[1024];
    int iIsListed[1024];
};
]]

local updateText = [[
	{FF0000}Warning! {FFFFFF} Скрипт выпущен для тестирования, просьба о багах/предложениях/новых территориях отписывать в игре ({FFD700}/pm Kotovasya{FFFFFF})
	или в {8A2BE2}Discord {FFFFFF}Kotovasya#3365 (преимущественно {8A2BE2}Discord{FFFFFF}, там отвечу быстрее). Заранее {7FFF00}благодарствую{FFFFFF}.

	Список новоизменений:
	{FFFFFF}Обновил терры для гу3 на 30.11.2020

	P.S. Если у кого-то все же по какой-то причине скрипт крашится - {FF0000}пишите(!) {FFFFFF}в {8A2BE2}Discord {FFFFFF}Kotovasya#3365
]]

local months = {
	[1] = "Январь",
	[2] = "Февраль",
	[3] = "Март",
	[4] = "Апрель",
	[5] = "Май",
	[6] = "Рюнь",
	[7] = "Рюль",
	[8] = "Август",
	[9] = "Сентябрь",
	[10] = "Октябрь",
	[11] = "Ноябрь",
	[12] = "Декабрь"
}

local skins = {
	["{057F94}La Cosa Nostra"] = { 46, 98, 113, 124, 126, 223, 233 },
	["{FAFB71}Yakuza"] = { 120, 121, 122, 123, 169, 186, 228 },
	["{778899}Русская Мафия"] = { 3, 111, 112, 125, 206, 216, 272 },
	["{8A2CD7}The Ballas Gang"] = { 13, 28, 102, 103, 104 },
	["{FFD720}Los Santos Vagos"] = { 12, 108, 109, 110, 273 },
	["{0FD9FA}El Coronos"] = { 114, 47, 115, 116, 292, 298 },
	["{10DC29}The Grove Street"] = { 86, 105, 106, 107, 195, 269, 270, 271 },
	["{6495ED}Street Racers"] = { 21, 48, 60, 180, 193, 250, 299 },
	["{20D4AD}San Fierro Rifa"] = { 30, 40, 173, 174, 175, 184 },
	["{FA24CC}The Triads Mafia"] = { 117, 118, 141, 170, 208, 294 },
	["{70524D}Hell Angels"] = { 100, 192, 247, 248, 254 },
	["{4C436E}Black Kings"] = { 24, 25, 66, 67, 190, 297, 183 }
}

local gangzoneColors = {
	[2861858565] = "{057F94}La Cosa Nostra",
	[2859596794] = "{FAFB71}Yakuza",
	[2862188663] = "{778899}Русская Мафия",
	[2866228362] = "{8A2CD7}The Ballas Gang",
	[2854279167] = "{FFD720}Los Santos Vagos",
	[2868566287] = "{0FD9FA}El Coronos",
	[2854870032] = "{10DC29}The Grove Street",
	[2867696996] = "{6495ED}Street Racers",
	[2863518752] = "{20D4AD}San Fierro Rifa",
	[2865505530] = "{FA24CC}The Triads Mafia",
	[2857194096] = "{70524D}Hell Angels",
	[2859352908] = "{4C436E}Black Kings",
}

local eventColors = {
	[1433108731] = "{057F94}La Cosa Nostra",
	[1435370502] = "{FAFB71}Yakuza",
	[1432778633] = "{778899}Русская Мафия",
	[1428738934] = "{8A2CD7}The Ballas Gang",
	[1440688129] = "{FFD720}Los Santos Vagos",
	[1426401009] = "{0FD9FA}El Coronos",
	[1440097264] = "{10DC29}The Grove Street",
	[1427270300] = "{6495ED}Street Racers",
	[1431448544] = "{20D4AD}San Fierro Rifa",
	[1429461766] = "{FA24CC}The Triads Mafia",
	[1437773200] = "{70524D}Hell Angels",
	[1435614388] = "{4C436E}Black Kings",
}

local captions = {
	[1] = {
		[0] = "Ц. Аммо LS",
		[1] = "Ц. Аммо SF",
		[2] = "Ресторан SF",
		[3] = "Бар ст. респы байкеров",
		[4] = "Бар Emerald",
		[5] = "Бар Jizzy",
		[6] = "Бар Pig Pen",
		[7] = "Бар Deliver",
		[8] = "Бар Grove",
		[9] = "Альхамбра",
		[10] = "Бар ТТМ",
		[11] = "Бар Yakuza",
		[12] = "Ресторан LSPD",
		[13] = "Бар Буренки",
		[14] = "Аммо Grove",
		[15] = "Аммо 4 драконов",
		[16] = "Аммо Карьера",
		[17] = "Аммо деревни РМ",
		[18] = "Аммо Street Racers",
		[19] = "Аммо ТТМ",
		[20] = "Аммо КХ",
		[21] = "Аммо ДБ",
		[22] = "Бар Баскет",
		[23] = "Аммо Black Kings",
		[24] = "Ц.Бинко LV",
		[25] = "Ц.Бинко SF",
		[26] = "Ц.Бинко LS",
		[27] = "Аммо Закупки",
		[28] = "Аммо РМ",
		[29] = "Новое аммо SF",
		[30] = "Аммо El Coronos",
		[31] = "Аммо Ballas",
		[32] = "Аммо LCN",
		[33] = "Казино 4 дракона",
		[34] = "Казино Калигула",
		[37] = "Бар Street Racers",
		[39] = "Бар Кактус",
		[40] = "Бар Вагос",
		[41] = "Новое бинко LS",
		[42] = "Новое бинко LV",
		[43] = "Бар Dilimore",
		[44] = "Бар Santa Maria",
		[45] = "Бинко Рифы",
		[46] = "Аммо Vagos",
		[48] = "Аренда авто SF",
		[49] = "Телефонная компания",
		[50] = "Нефтебаза",
		[51] = "Электростанция",
		[52] = "Car Delivery",
		[53] = "House Upgrade",
		[54] = "Студия CNN",
		[55] = "Fixcar",
		[56] = "General Store (24/7)",
		[59] = "Тюнинг дом.транспорта",
		[64] = "KFC штата",
		[65] = "Аэропорт SF",
		[66] = "Аэропорт LS",
		[67] = "Аэропорт LV",
		[68] = "Банк San Andreas",
		[73] = "Бинко Vagos",
	},
	[2] = {
		[0] = "Ц. Аммо LS",
		[1] = "Аммо Курочки",
		[6] = "Бар Pig Pen",
		[7] = "Бар Курочки",
		[8] = "Бар Grove",
		[9] = "Альхамбра",
		[10] = "Бар Байкеров",
		[12] = "Ресторан LSPD",
		[13] = "Кладбище",
		[14] = "Аммо Grove",
		[15] = "Аммо 4 драконов",
		[16] = "Аммо Карьера",
		[17] = "Аммо деревни РМ",
		[18] = "Аммо Street Racers",
		[19] = "Аммо ТТМ",
		[20] = "Аммо КХ",
		[21] = "Аммо ДБ",
		[23] = "Аммо Репортеров",
		[24] = "Ц.Бинко LV",
		[25] = "Новое Бинко LS",
		[26] = "Бинко Ballas",
		[27] = "Аммо Закупки",
		[30] = "Аммо Los Aztecas",
		[31] = "Аммо Ballas",
		[32] = "Аммо LCN",
		[33] = "Казино 4 дракона",
		[34] = "Казино Калигула",
		[35] = "Старое казино",
		[37] = "Бар Street Racers",
		[39] = "Бар Кактус",
		[40] = "Бар 69",
		[41] = "Ц. Бинко LS",
		[42] = "Новое бинко LV",
		[43] = "Бар Dilimore",
		[44] = "Бар Santa Maria",
		[46] = "Аммо Vagos",
		[49] = "Телефонная компания",
		[50] = "Нефтебаза",
		[51] = "Электростанция",
		[52] = "Car Delivery",
		[53] = "House Upgrade",
		[55] = "Fixcar",
		[56] = "General Store (24/7)",
		[59] = "Тюнинг дом.транспорта",
		[60] = "Аренда лодок",
		[63] = "Аренда отелей",
		[64] = "KFC штата",
		[66] = "Аэропорт LS",
		[67] = "Аэропорт LV",
		[68] = "Банк San Andreas",
		[73] = "Бинко Vagos",
	},
	[3] = {
        [0] = "Ц. Аммо LS",
        [1] = "Аммо Delimor",
        [3] = "Бар байкеров",
        [5] = "Аммо каллигулы",
        [6] = "Бар Pig Pen",
        [8] = "Бар Grove",
        [9] = "Бар Alhambra",
        [11] = "Бар LCN",
        [14] = "Аммо Grove",
        [15] = "Аммо Байкеров",
        [16] = "Аммо Карьера",
        [19] = "Аммо TTM",
        [18] = "Аммо Street Racers",
        [20] = "Аммо Починки LS",
        [21] = "Аммо ДБ1",
        [23] = "Аммо Репортёров",
        [24] = "Новое Бинко LV",
        [25] = "Ц.Бинко SF",
        [27] = "Аммо Закупки",
        [28] = "Аммо Русской Мафии",
        [29] = "Аммо LCN",
        [30] = "Аммо El Coronos",
        [31] = "Аммо Ballas",
        [32] = "Аммо Black Kings",
        [33] = "Казино LV",
        [34] = "Казино Каллигула",
        [35] = "Казино LS",
        [40] = "Бар Ballas",
        [43] = "Бар Delimor",
        [44] = "Бар Santa Maria",
        [45] = "Бар Банка LS",
        [46] = "Аммо Vagos",
        [48] = "Новая Аренда Каров LS",
        [49] = "Телефоная Компания",
        [50] = "Нефтибаза",
        [51] = "Электростанция",
        [52] = "Car Delivery",
        [53] = "House Upgrade",
        [54] = "Студия CNN",
        [55] = "Fixcar",
        [56] = "Магазины 24/7",
        [59] = "Тюнинг дом.транспорта",
        [61] = "Новая Аренда Каров LV",
        [64] = "KFC штата",
        [65] = "Аэропорт SF",
        [66] = "Аэропорт LS",
        [67] = "Аэропорт LV",
        [68] = "Банк San Andreas"
	}
}

local renderAlignments = {
	[0] = "По левому краю",
	[1] = "По правому краю",
}

local orders = {
	[0] = "Снизу-вверх",
	[1] = "Сверху-вниз"
}

local timerStyles = {
	[0] = { 
		String = "Время нападения [HH:MM]",
		Function = function(time)
			local date = os.date("!*t", time)
			return string.format("%s:%s", addZero(date.hour), addZero(date.min))
		end
	},
	[1] = {
		String = "Время нападения [HH:MM:SS]",
		Function = function(time)
			local date = os.date("!*t", time)
			return string.format("%s:%s:%s", addZero(date.hour), addZero(date.min), addZero(date.sec))
		end
	},
	[2] = {
		String = "Времени осталось [MM:SS]",
		Function = function(time)
			local timeLeft = time + 635 - os.time()
			if timeLeft < 0 then return "00:00" end
			local date = os.date("!*t", timeLeft)
			return string.format("%s:%s", addZero(date.min), addZero(date.sec))
		end
	},
	[3] = {
		String = "Времени прошло [MM:SS]",
		Function = function(time)
			local date = os.date("!*t", os.time() - time)
			return string.format("%s:%s", addZero(date.min), addZero(date.sec))
		end
	}
}

local timerDelay = {
	[1] = 0.075,
	[2] = 0.1,
	[3] = 0.1,
} 


if imguiIsLoaded then
	windowSizes = {
		[1] = imgui.ImVec2(895, 540),
		[2] = imgui.ImVec2(895, 320),
		[3] = imgui.ImVec2(895, 680),
		[4] = imgui.ImVec2(895, 450),
		[5] = imgui.ImVec2(895, 480)
	}
end

local gangzones = {}
local towns = {}
local captures = {}
local lastCaptions = {}

local winState = 1
local currentServer = 1
local currentServerLogs = 1
local currentLogsFolder = nil
local currentLogPath = nil
if imguiIsLoaded then
	settings_window_state = imgui.ImBool(false)
	buttonStyle = { active = imgui.ImVec4(0.00, 0.69, 0.33, 1.00), inactive = imgui.ImVec4(0.00, 0.69, 0.33, 1.00), hovered = imgui.ImVec4(0.00, 0.82, 0.39, 1.00), pushed = imgui.ImVec4(0.00, 0.87, 0.42, 1.00) }
	fontNameBuffer = imgui.ImBuffer(128)
	nameFractionBuffer = imgui.ImBuffer(128)
	nameCaptionBuffer = imgui.ImBuffer(128)
end

--===================================================== MAIN =====================================================

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(0) end
	if doesFileExist(getWorkingDirectory() .. "\\CheckerZx.lua") then os.remove(getWorkingDirectory() .. "\\CheckerZx.lua") end
	if not faIsLoaded then 
		if not doesDirectoryExist("moonloader/config/Checker Captures") then createDirectory("moonloader/config/Checker Captures") end
		sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Скачивается шрифт для правильной работы ImGUI окна..."), 0xFF7F00)
		if getMoonloaderVersion() > 26.5 then
			if not doesDirectoryExist("moonloader/lib/Checker Captures") then createDirectory("moonloader/lib/Checker Captures") end
			resultFa = downloadFile("https://raw.githubusercontent.com/Kotovasya/Checker-Captrures/master/config/Checker%20Captures/fAwesome5.lua", "lib\\Checker Captures\\fAwesome5.lua")
			resultFaFont = downloadFile("https://github.com/Kotovasya/Checker-Captrures/raw/master/config/Checker%20Captures/fa5.ttf", "lib\\Checker Captures\\fa5.ttf")
		else
			resultFa = downloadFile("https://raw.githubusercontent.com/Kotovasya/Checker-Captrures/master/config/Checker%20Captures/fAwesome5.lua", "config\\Checker Captures\\fAwesome5.lua")
			resultFaFont = downloadFile("https://github.com/Kotovasya/Checker-Captrures/raw/master/config/Checker%20Captures/fa5.ttf", "config\\Checker Captures\\fa5.ttf")
		end
		if resultFa and resultFaFont then
			sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Шрифты успешно скачены! Перезагрузка скрипта..."), 0xFF7F00)
			thisScript():reload()
			wait(1000)
		else
			sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Не удалось скачать шрифт, обратитесь за помощью в Discord Kotovasya#3365. Скрипт выгружается..."), 0xFF7F00)
			thisScript():unload()
			wait(1000)
		end
	end
	if not imguiIsLoaded then
		sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Скачивается библиотека ImGUI..."), 0xFF7F00)
		local imguiLibrary = downloadFile("https://raw.githubusercontent.com/Kotovasya/Checker-Captrures/master/lib/imgui.lua", "lib\\imgui.lua")
		local imguiDll = downloadFile("https://github.com/Kotovasya/Checker-Captrures/raw/master/lib/MoonImGui.dll", "lib\\MoonImGui.dll")
		if imguiLibrary and imguiDll then
			sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} ImGUI библиотека успешно скачана! Перезагрузка скрипта..."), 0xFF7F00)
			thisScript():reload()
			wait(1000)
		else
			sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Не удалось скачать ImGUI, обратитесь за помощью в Discord Kotovasya#3365. Скрипт выгружается..."), 0xFF7F00)
			thisScript():unload()
			wait(1000)
		end
	end
	if not lfsIsLoaded then
		sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Скачивается библиотека lfs..."), 0xFF7F00)
		local lfsLibrary = downloadFile("https://github.com/Kotovasya/Checker-Captrures/raw/master/lib/lfs.dll", "lib\\lfs.dll")
		if lfsLibrary then
			sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} lfs библиотека успешно скачана! Перезагрузка скрипта..."), 0xFF7F00)
			thisScript():reload()
			wait(1000)
		else
			sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Не удалось скачать lfs.dll, обратитесь за помощью в Discord Kotovasya#3365. Скрипт выгружается..."), 0xFF7F00)
			thisScript():unload()
			wait(1000)
		end
	end
	if update() then
		sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Обновление успешно скачано, перезагрузка скрипта..."), 0xFF7F00)
		wait(500)
		thisScript():reload()
	end
	LAST_INFO_FILE = "Checker Captures/LastCaptures[" .. getServer() .. "]"
	SETTINGS_FILE = "Checker Captures/Settings"
	loadSettings()
	font = renderCreateFont(Settings.Captures.FontName, Settings.Captures.FontSize, Settings.Captures.FontFlags)
	lastCaptions = inicfg.load({}, LAST_INFO_FILE)
	while not sampIsLocalPlayerSpawned() do wait(0) end
	currentServer = getServer()
	currentServerLogs = currentServer
	createTable()
	os.remove(getWorkingDirectory() .. "/config/" .. LAST_INFO_FILE .. ".ini")
	lua_thread.create(capturesRender)
	sampRegisterChatCommand("zx", Count)
	sampRegisterChatCommand("azx", function() settings_window_state.v = not settings_window_state.v end)
	sampRegisterChatCommand("fakezx", function() table.insert(captures, 13, {name = string.format("{FFFFFF}%s [%d]", captions[getServer()][1], 1), attack = "{FA24CC}The Triads Mafia", defender = "{70524D}Hell Angels", time = os.time(), lastDelay = os.time()}) end)
	wait(-1)
end

function capturesRender()
	while true do
		wait(0)
		imgui.Process = settings_window_state.v
		if settings_window_state.v and winState == 1 then
			if table.length(captures) == 0 then
				table.insert(captures, 12, {name = string.format("{FFFFFF}%s [0]", captions[getServer()][0]), attack = "{10DC29}The Grove Street", defender = "{0FD9FA}El Coronos", time = os.time() - 450, lastDelay = os.time()})
				table.insert(captures, 13, {name = string.format("{FFFFFF}%s [1]", captions[getServer()][1]), attack = "{FAFB71}Yakuza", defender = "{20D4AD}San Fierro Rifa", time = os.time(), lastDelay = os.time()})
				table.insert(captures, 25, {name = string.format("{FFFFFF}%s [18]", captions[getServer()][18]), attack = "{6495ED}Street Racers", defender = "{4C436E}Black Kings", time = os.time() - 120, lastDelay = os.time()})
				table.insert(captures, 26, {name = string.format("{FFFFFF}%s [46]", captions[getServer()][46]), attack = "{FFD720}Los Santos Vagos", defender = "{8A2CD7}The Ballas Gang", time = os.time() - 520, lastDelay = os.time()})
				table.insert(captures, 27, {name = string.format("{FFFFFF}%s [15]", captions[getServer()][15]), attack = "{FA24CC}The Triads Mafia", defender = "{70524D}Hell Angels", time = os.time() - 333, lastDelay = os.time()})
				table.insert(captures, 28, {name = string.format("{FFFFFF}%s [28]", captions[getServer()][28]), attack = "{20D4AD}San Fierro Rifa", defender = "{778899}Русская Мафия", time = os.time() - 333, lastDelay = os.time()})
				lua_thread.create(function()
					while settings_window_state.v or isRemoveChecker do
						wait(0)
						if not isRemoveChecker and winState ~= 1 then
							captures[12] = nil
							captures[13] = nil
							captures[25] = nil
							captures[26] = nil
							captures[27] = nil
							captures[28] = nil
						end
					end
					captures[12] = nil
					captures[13] = nil
					captures[25] = nil
					captures[26] = nil
					captures[27] = nil
					captures[28] = nil
					winState = 1
				end)
			end
		end
		if Settings.Captures.Visible then
			if isRemoveChecker then
				local x, y = getCursorPos()
				Settings.Captures.X = x
				Settings.Captures.Y = y
			end
			local Y = Settings.Captures.Y
			for id, capture in pairs(captures) do
				if os.time() - capture.lastDelay ~= 0 then
					captures[id].time = capture.time + (os.time() - capture.lastDelay) * timerDelay[getServer()]
					captures[id].lastDelay = os.time()
				end
				if Settings.Captures[towns[id]] then
					local attack =  Settings.Fractions[capture.attack]
					local defender = Settings.Fractions[capture.defender]
					if Settings.Captures.ShowPlayers then
						local attackPlayers, defenderPlayers = getPlayers(capture, id)
						if attackPlayers ~= 0 or defenderPlayers ~= 0 then
							attack = string.format("%s{FFFFFF} (%d)", attack, attackPlayers)
							defender = string.format("%s{FFFFFF} (%d)", defender, defenderPlayers)
						end
					end
					local renderString = string.format("%s: %s {FFFFFF}vs %s {FFFFFF} | %s", capture.name, attack, defender, timerStyles[Settings.Captures.TimerStyle].Function(capture.time))
					if Settings.Captures.RollbackTime then
						local timeLeft = capture.time + 180 - os.time()
						if timeLeft > 0 then
							local date = os.date("!*t", timeLeft)
							renderString = string.format("%s [%s:%s]", renderString, addZero(date.min), addZero(date.sec))
						end
					end
					if Settings.Captures.Alignment == 0 then
						renderFontDrawText(font, renderString, Settings.Captures.X, Y, -1)
					else
						renderFontDrawText(font, renderString, Settings.Captures.X - renderGetFontDrawTextLength(font, renderString), Y, -1)
					end
					if Settings.Captures.Order == 0 then
						Y = Y - Settings.Captures.Gap
					else
						Y = Y + Settings.Captures.Gap
					end
				end
			end
		end
	end
end

--===================================================== IMGUI =====================================================

function applyStyle()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.Border]                 = ImVec4(0.70, 0.70, 0.70, 0.40)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.19, 0.19, 0.19, 0.71)
    colors[clr.FrameBgActive]          = ImVec4(0.34, 0.34, 0.34, 0.79)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.69, 0.33, 0.80)
    colors[clr.TitleBgActive]          = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.69, 0.33, 0.50)
    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.16, 0.16, 0.16, 1.00)
    colors[clr.ScrollbarGrab]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.ComboBg]                = ImVec4(0.20, 0.20, 0.20, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.77, 0.37, 1.00)
    colors[clr.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00)
    colors[clr.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57)
    colors[clr.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89)
    colors[clr.Separator]              = ImVec4(1.00, 1.00, 1.00, 0.40)
    colors[clr.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
    colors[clr.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 0.80)
    colors[clr.ResizeGrip]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.00, 0.76, 0.37, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(0.00, 0.86, 0.41, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.CloseButtonHovered]     = ImVec4(0.00, 0.88, 0.42, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.00, 0.69, 0.33, 0.72)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.17, 0.17, 0.17, 0.48)
end

function formatImguiVarriables()
	local fontFlags = Settings.Captures.FontFlags
	font_none = fontFlags == 0 and imgui.ImBool(true) or imgui.ImBool(false)
	if fontFlags >= 8 then
		font_shadow = imgui.ImBool(true)
		fontFlags = fontFlags - 8
	else
		font_shadow = imgui.ImBool(false)
	end
	if fontFlags >= 4 then
		font_border = imgui.ImBool(true)
		fontFlags = fontFlags - 4
	else
		font_border = imgui.ImBool(false)
	end
	if fontFlags >= 2 then
		font_italic = imgui.ImBool(true)
		fontFlags = fontFlags - 2
	else
		font_italic = imgui.ImBool(false)
	end
	if fontFlags >= 1 then
		font_bold = imgui.ImBool(true)
		fontFlags = fontFlags - 1
	else
		font_bold = imgui.ImBool(false)
	end

	settings_captures_ls = imgui.ImBool(Settings.Captures.LS)
	settings_captures_lv = imgui.ImBool(Settings.Captures.LV)
	settings_captures_sf = imgui.ImBool(Settings.Captures.SF)
	settings_captures_country = imgui.ImBool(Settings.Captures.Country)
	settings_captures_visible = imgui.ImBool(Settings.Captures.Visible)
	settings_captures_fontName = u8(Settings.Captures.FontName)
	settings_captures_fontSize = imgui.ImInt(Settings.Captures.FontSize)
	settings_captures_fontFlags = imgui.ImInt(Settings.Captures.FontFlags)
	settings_captures_alignment = imgui.ImInt(Settings.Captures.Alignment)
	settings_captures_x = imgui.ImInt(Settings.Captures.X)
	settings_captures_y = imgui.ImInt(Settings.Captures.Y)
	settings_captures_timerStyle = imgui.ImInt(Settings.Captures.TimerStyle)
	settings_captures_order = imgui.ImInt(Settings.Captures.Order)
	settings_captures_rollbackTime = imgui.ImBool(Settings.Captures.RollbackTime)
	settings_captures_showPlayers = imgui.ImBool(Settings.Captures.ShowPlayers)
	settings_captures_message = imgui.ImBool(Settings.Captures.Message)
	settings_captures_log = imgui.ImBool(Settings.Captures.Log)
	settings_captures_gap = imgui.ImInt(Settings.Captures.Gap)
	settings_fractions = {}
	for fraction, name in pairs(Settings.Fractions) do
		settings_fractions[fraction] = u8(name)
	end
	settings_captions = {[1] = {}, [2] = {}, [3] = {}}
	for server, table in pairs(captions) do
		for id, name in pairs(table) do
			settings_captions[server][id] = u8(name)
		end
	end
end

if imguiIsLoaded then

function imgui.CustomButton(name, color, colorHovered, colorActive, size)
	local clr = imgui.Col
  	imgui.PushStyleColor(clr.Button, color)
  	imgui.PushStyleColor(clr.ButtonHovered, colorHovered)
  	imgui.PushStyleColor(clr.ButtonActive, colorActive)
  	if not size then size = imgui.ImVec2(0, 0) end
  	local result = imgui.Button(name, size)
  	imgui.PopStyleColor(3)
  	return result
end

function imgui.ColorText(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function imgui.CenterColorText(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.BeforeDrawFrame()
	if fa_font == nil then
    	local font_config = imgui.ImFontConfig()
    	font_config.MergeMode = true
		font_config.SizePixels = 15.0;
		font_config.GlyphExtraSpacing.x = 0.1
    	fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader\\config\\Checker Captures\\fa5.ttf', font_config.SizePixels, font_config, fa_glyph_ranges)
  	end
end

function imgui.OnDrawFrame()
	if settings_window_state.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(windowSizes[winState], imgui.Cond.Always)
		applyStyle()
		imgui.Begin(fa.ICON_COGS .. u8('	Настройки | Чекер захватов by Kotovasya	'), settings_window_state, imgui.WindowFlags.NoResize)
		
		imgui.BeginChild(1, imgui.ImVec2(885, 50), false)
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			if imgui.CustomButton(fa.ICON_COG .. u8(' Чекер'), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
				winState = 1
			end
			imgui.SameLine()
			imgui.SetCursorPosX(180)
			if imgui.CustomButton(fa.ICON_USERS_COG .. u8(' Названия фракций'), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
				winState = 2
			end
			imgui.SameLine()
			imgui.SetCursorPosX(355)
			if imgui.CustomButton(fa.ICON_GLOBE_AFRICA .. u8(' Названия территорий'), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
				winState = 3
			end
			imgui.SameLine()
			imgui.SetCursorPosX(530)
			if imgui.CustomButton(fa.ICON_HISTORY .. u8(' Логи захватов'), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
				winState = 4
			end
			imgui.SameLine()
			imgui.SetCursorPosX(705)
			if imgui.CustomButton(fa.ICON_SYNC_ALT .. u8(' Проверить обновление'), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
				lua_thread.create(function()
					if not update() then sampAddChatMessage("{FF7F00}[Checker Captures]:{ffffff} Обновлений не обнаружено", 0xFF7F00) end
				end)
			end
		imgui.EndChild()

		if winState == 1 then
			imgui.SetCursorPosX(150)
			imgui.Text(fa.ICON_SLIDERS_H .. u8('  Настройки отображения'))
			imgui.SameLine()
			imgui.SetCursorPosX(600)
			imgui.Text(fa.ICON_FONT .. u8('  Настройки шрифта'))

			imgui.BeginChild(2, imgui.ImVec2(435, 225), true)
				if imgui.Checkbox(u8("Включить отображение активных захватов"), settings_captures_visible) then Settings.Captures.Visible = settings_captures_visible.v end
				if imgui.Checkbox(u8("Показывать количество игроков в территории"), settings_captures_showPlayers) then Settings.Captures.ShowPlayers = settings_captures_showPlayers.v end
				if imgui.Checkbox(u8("Показывать время до отката на час"), settings_captures_rollbackTime) then Settings.Captures.RollbackTime = settings_captures_rollbackTime.v end
				imgui.PushItemWidth(200)
				if imgui.Combo(fa.ICON_ALIGN_LEFT .. u8(" Выравнивание"), settings_captures_alignment, table.u8(renderAlignments)) then Settings.Captures.Alignment = settings_captures_alignment.v end
				if imgui.Combo(fa.ICON_SORT_AMOUNT_DOWN_ALT .. u8(" Порядок отображения"), settings_captures_order, table.u8(orders)) then Settings.Captures.Order = settings_captures_order.v end
				if imgui.Combo(fa.ICON_CLOCK .. u8(" Стиль отображения таймера"), settings_captures_timerStyle, table.u8(timerStyles)) then Settings.Captures.TimerStyle = settings_captures_timerStyle.v end
				if imgui.Button(fa.ICON_RETWEET .. u8(" Выбрать позицию"), imgui.ImVec2(160, 30)) then
					lua_thread.create(function()
						isRemoveChecker = true
						settings_window_state.v = false
						sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} С помощью мыши перенесите чекер и нажмите ЛКМ."), 0xFF7F00)
						while true do
							wait(0)
							sampSetCursorMode(3)			
							if isKeyJustPressed(1) then
								sampSetCursorMode(0)
								sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Позиция чекера сохранена."), 0xFF7F00)
								addOneOffSound(0, 0, 0, 1057)
								settings_window_state.v = true
								isRemoveChecker = false
								return
							end
						end
					end)
			  	end
				imgui.PushItemWidth(70)
				if imgui.InputInt(fa.ICON_LONG_ARROW_ALT_DOWN .. u8(" Расстояние между строк"), settings_captures_gap, 1, 10) then
					Settings.Captures.Gap = LimitInputInt(1, 30, settings_captures_gap.v)
				end
			imgui.EndChild()
			
			imgui.SameLine()

			imgui.BeginChild(3, imgui.ImVec2(435, 225), true)
				imgui.SetCursorPos(imgui.ImVec2(5, 5))
				imgui.PushItemWidth(120)
				if imgui.InputText(fa.ICON_FONT .. u8(string.format(" Название шрифта (Сейчас: %s)", settings_captures_fontName)), fontNameBuffer, imgui.InputTextFlags.EnterReturnsTrue) then
					Settings.Captures.FontName = u8:decode(fontNameBuffer.v)
					settings_captures_fontName = fontNameBuffer.v
					font = renderCreateFont(Settings.Captures.FontName, Settings.Captures.FontSize, Settings.Captures.FontFlags)
				end
				if imgui.InputInt(fa.ICON_TEXT_WIDTH .. u8("  Размер шрифта"), settings_captures_fontSize, 1, 10) then
					Settings.Captures.FontSize = LimitInputInt(1, 145, settings_captures_fontSize.v)
					font = renderCreateFont(Settings.Captures.FontName, Settings.Captures.FontSize, Settings.Captures.FontFlags)
				end
				if imgui.Checkbox(u8("Без особенностей"), font_none) then
					if font_none.v then
						Settings.Captures.FontFlags = 0
						font_bold.v = false
						font_italic.v = false
						font_border.v = false
						font_shadow.v = false
					end
					font = renderCreateFont(Settings.Captures.FontName, Settings.Captures.FontSize, Settings.Captures.FontFlags)
				end
				if imgui.Checkbox(u8("Жирный"), font_bold) then
					if font_none.v then 
						font_none.v = false
						Settings.Captures.FontFlags = 1
					elseif font_bold.v then
						Settings.Captures.FontFlags = Settings.Captures.FontFlags + 1
					else
						Settings.Captures.FontFlags = Settings.Captures.FontFlags - 1
					end
					font = renderCreateFont(Settings.Captures.FontName, Settings.Captures.FontSize, Settings.Captures.FontFlags)
				end
				if imgui.Checkbox(u8("Наклонный"), font_italic) then
					if font_none.v then 
						font_none.v = false
						Settings.Captures.FontFlags = 2
					elseif font_italic.v then
						Settings.Captures.FontFlags = Settings.Captures.FontFlags + 2
					else
						Settings.Captures.FontFlags = Settings.Captures.FontFlags - 2
					end
					font = renderCreateFont(Settings.Captures.FontName, Settings.Captures.FontSize, Settings.Captures.FontFlags)
				end
				if imgui.Checkbox(u8("Обводка"), font_border) then
					if font_none.v then 
						font_none.v = false
						Settings.Captures.FontFlags = 4
					elseif font_border.v then
						Settings.Captures.FontFlags = Settings.Captures.FontFlags + 4
					else
						Settings.Captures.FontFlags = Settings.Captures.FontFlags - 4
					end
					font = renderCreateFont(Settings.Captures.FontName, Settings.Captures.FontSize, Settings.Captures.FontFlags)
				end
				if imgui.Checkbox(u8("Тень"), font_shadow) then
					if font_none.v then 
						font_none.v = false
						Settings.Captures.FontFlags = 8
					elseif font_shadow.v then
						Settings.Captures.FontFlags = Settings.Captures.FontFlags + 8
					else
						Settings.Captures.FontFlags = Settings.Captures.FontFlags - 8
					end
					font = renderCreateFont(Settings.Captures.FontName, Settings.Captures.FontSize, Settings.Captures.FontFlags)
				end
			imgui.EndChild()

			imgui.SetCursorPosX(400)
			imgui.Text(fa.ICON_INFO .. u8('  Дополнительно'))
			imgui.BeginChild(4, imgui.ImVec2(875, 100), true)
				imgui.SetCursorPosX(340)
				imgui.Text(fa.ICON_CITY .. u8("  Отображение захватов в городах"))
				imgui.SetCursorPosX(280)
				if imgui.Checkbox(u8("Los Santos"), settings_captures_ls) then Settings.Captures.LS = settings_captures_ls.v end
				imgui.SameLine()
				if imgui.Checkbox(u8("Las Venturas"), settings_captures_lv) then Settings.Captures.LV = settings_captures_lv.v end
				imgui.SameLine()
				if imgui.Checkbox(u8("San Fierro"), settings_captures_sf) then Settings.Captures.SF = settings_captures_sf.v end
				imgui.SameLine()
				if imgui.Checkbox(u8("Деревни"), settings_captures_country) then Settings.Captures.Country = settings_captures_country.v end
				imgui.NewLine()
				imgui.SetCursorPosX(200)
				if imgui.Checkbox(u8("Показывать уведомления в чат"), settings_captures_message) then Settings.Captures.Message = settings_captures_message.v end
				imgui.SameLine()
				imgui.SetCursorPosX(450)
				if imgui.Checkbox(u8("Вести логи захватов"), settings_captures_log) then Settings.Captures.Log = settings_captures_log.v end
				imgui.SameLine()
				imgui.SetCursorPosX(670)
				imgui.SetCursorPosY(60)
				if imgui.CustomButton(fa.ICON_INFO .. u8("  Что изменилось?"), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 30)) then
					winState = 5
				end
			imgui.EndChild()
		elseif winState == 2 then
			local sameLine = false
			imgui.PushItemWidth(150)
			for fraction, name in pairs(settings_fractions) do
				if sameLine then imgui.SameLine() end
				sameLine = not sameLine
				nameFractionBuffer.v = string.sub(name, 9, #name)
				imgui.SetCursorPosX(sameLine and 120 or 500)
				imgui.ColorText(fraction)
				imgui.SameLine()
				imgui.SetCursorPosX(sameLine and 220 or 600)
				if imgui.InputText("##EditFraction" .. fraction, nameFractionBuffer) then
					settings_fractions[fraction] = string.sub(fraction, 0, 8) .. nameFractionBuffer.v
					Settings.Fractions[fraction] = u8:decode(string.sub(fraction, 0, 8) .. nameFractionBuffer.v)
				end
			end
		elseif winState == 3 then
			imgui.SetCursorPosX(180)
			imgui.BeginChild(5, imgui.ImVec2(530, 50), false)
				imgui.SetCursorPos(imgui.ImVec2(5, 5))
				if imgui.CustomButton("Galaxy I", buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
					currentServer = 1
				end
				imgui.SameLine()
				if imgui.CustomButton("Galaxy II", buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
					currentServer = 2
				end
				imgui.SameLine()
				if imgui.CustomButton("Galaxy III", buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
					currentServer = 3
				end
			imgui.EndChild()
			imgui.SetCursorPosX(420)
			imgui.Text("GALAXY " .. currentServer)
			imgui.NewLine()
			local count = 0
			imgui.PushItemWidth(150)
			for id, name in pairs(settings_captions[currentServer]) do
				if count < 4 then imgui.SameLine() else count = 0 end
				if id < 10 then
					imgui.SetCursorPosX(count * 220 + 25)
				else
					imgui.SetCursorPosX(count * 220 + 18)
				end
				imgui.Text(id .. " ")
				imgui.SameLine()
				nameCaptionBuffer.v = name
				if imgui.InputText("##EditCaption" .. id, nameCaptionBuffer) then
					settings_captions[currentServer][id] = nameCaptionBuffer.v
					Settings[currentServer][id] = u8:decode(nameCaptionBuffer.v)
					captions[currentServer][id] = u8:decode(nameCaptionBuffer.v)
				end
				imgui.SameLine()
				if imgui.CustomButton(fa.ICON_MAP_MARKER_ALT .. "##MarkerButton" .. id, buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(20, 20)) then
					if table.contains(gangzones, id) then
						setMarkerOnGangzone(id)
					else
						sampAddChatMessage("{FF7F00}[Checker Captures]:{ffffff} Метка не установлена. Данной территории нет на сервере, либо скрипт еще не обновлен", 0xFF7F00)
					end
				end
				count = count + 1
			end
			imgui.NewLine()
			imgui.SetCursorPosX(350)
			if imgui.CustomButton(fa.ICON_MAP_MARKER .. u8("  Удалить маркер"), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(200, 40)) then
				raknetEmulRpcReceiveBitStream(37, raknetNewBitStream())
			end
		elseif winState == 4 then
			imgui.SetCursorPosX(180)
			imgui.BeginChild(5, imgui.ImVec2(530, 50), false)
				imgui.SetCursorPos(imgui.ImVec2(5, 5))
				if imgui.CustomButton("Galaxy I", buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
					currentLogsFolder = nil
					currentLogPath = nil
					currentServerLogs = 1
				end
				imgui.SameLine()
				if imgui.CustomButton("Galaxy II", buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
					currentLogsFolder = nil
					currentLogPath = nil
					currentServerLogs = 2
				end
				imgui.SameLine()
				if imgui.CustomButton("Galaxy III", buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(170, 40)) then
					currentLogsFolder = nil
					currentLogPath = nil
					currentServerLogs = 3
				end
			imgui.EndChild()
			local count = 0
			if currentLogPath then
				if imgui.CustomButton(fa.ICON_ARROW_LEFT .. u8("  Вернуться к датам"), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(350, 40)) then currentLogPath = nil end
				imgui.NewLine()
				imgui.CenterColorText(logFile)
			elseif currentLogsFolder then
				if imgui.CustomButton(fa.ICON_ARROW_LEFT .. u8("  Вернуться к месяцам"), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(200, 40)) then currentLogsFolder = nil end
				imgui.NewLine()
				if currentLogsFolder ~= nil then
					for line in lfs.dir(currentLogsFolder) do
						if line ~= nil and line ~= "." and line ~= ".." then
							imgui.SetCursorPosX(count * 250 + 90)
							if imgui.CustomButton(fa.ICON_FILE_ALT .. "  " .. u8(line) .. "##File" .. u8(line), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(200, 40)) then
								currentLogPath = currentLogsFolder .. "\\" .. line
								local f = io.open(currentLogPath, "r")
								if f then
									logFile = f:read("*a")
									f:close()
								else
									logFile = "Не удалось загрузить логи захватов из файла"
								end
							end
							if count < 2 then
								imgui.SameLine()
								count = count + 1
							else
								count = 0
							end
						end
					end
				end
			else
				local logsPath = getWorkingDirectory() .. "\\config\\Checker Captures\\Logs\\Galaxy " .. currentServerLogs
				for line in lfs.dir(logsPath) do
					if line ~= nil and line ~= "." and line ~= ".." then
						imgui.SetCursorPosX(count * 250 + 50)
						if imgui.CustomButton(fa.ICON_FOLDER_OPEN .. "  " .. u8(line) .. "##Folder" .. u8(line), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(200, 40)) then
							currentLogsFolder = logsPath .. "\\" .. line
						end
						if count < 3 then
							imgui.SameLine()
							count = count + 1
						else
							count = 0
						end
					end
				end
			end
		elseif winState == 5 then
			imgui.ColorText(updateText)
			imgui.SetCursorPosX(20)
			if imgui.CustomButton(fa.ICON_ARROW_LEFT .. u8("  Ок, я гном"), buttonStyle.inactive, buttonStyle.hovered, buttonStyle.pushed, imgui.ImVec2(120, 40)) then
				winState = 1
				sampAddChatMessage(">> ПМ от [RoX].Kotovasya.(1000): соболезную, гном", 0xFFFF22)
			end
		end
		if winState ~= 5 and winState ~= 4 then
			imgui.NewLine()
			imgui.SetCursorPosX(350)
			if imgui.CustomButton(fa.ICON_SAVE .. u8("  Сохранить настройки"), imgui.ImVec4(0.00, 0.59, 0.10, 1.00), imgui.ImVec4(0.00, 0.72, 0.20, 1.00), imgui.ImVec4(0.00, 0.87, 0.42, 1.00), imgui.ImVec2(200, 50)) then
				if inicfg.save(Settings, SETTINGS_FILE) then
					sampAddChatMessage("{FF7F00}[Checker Captures]:{ffffff} Настройки успешно сохранены", 0xFF7F00)
				else
					sampAddChatMessage("{FF7F00}[Checker Captures]:{ffffff} Не удалось сохранить настройки((", 0xFF7F00)
				end
			end
		end
		imgui.End()
	end
end

function LimitInputInt(min, max, var)
	if var < min then var = min end
	if max < var then	var = max end
	return var
end

end

--===================================================== CONFIG =====================================================

function saveConfig()
	Settings.Captures.Visible = settings_captures_visible.v
	Settings.Captures.FontName = settings_captures_fontName.v ~= nil and u8:decode(settings_captures_fontName.v) or Settings.Captures.FontName
	Settings.Captures.FontSize = settings_captures_fontSize.v
	Settings.Captures.FontFlags = 0 
	if not font_none.v then
		if font_shadow.v then Settings.Captures.FontFlags = 8 end
		if font_border.v then Settings.Captures.FontFlags = Settings.Captures.FontFlags + 4 end
		if font_italic.v then Settings.Captures.FontFlags = Settings.Captures.FontFlags + 2 end
		if font_bold.v then Settings.Captures.FontFlags = Settings.Captures.FontFlags + 1 end
	end
	Settings.Captures.Alignment = settings_captures_alignment.v
	Settings.Captures.X = settings_captures_x.v
	Settings.Captures.Y = settings_captures_y.v
	Settings.Captures.TimerStyle = settings_captures_timerStyle.v
	Settings.Captures.Order = settings_captures_order.v
	Settings.Captures.RollbackTime = settings_captures_rollbackTime.v
	Settings.Captures.ShowPlayers = settings_captures_showPlayers.v
	Settings.Captures.Message = settings_captures_message.v
	Settings.Captures.Log = settings_captures_log.v
	Settings.Captures.Gap = settings_captures_gap.v

	for fraction, name in pairs(settings_fractions) do
		Settings.Fractions[fraction] = u8:decode(name)
	end

	for server, table in pairs(settings_captions) do
		for id, name in pairs(table) do
			Settings[server][id] = u8:decode(name)
		end
	end
	inicfg.save(Settings, SETTINGS_FILE)
end

function getServer()
	local ip, port = sampGetCurrentServerAddress()
	local iport = ip .. ":" .. tostring(port)

	local TNames = {
    	["176.32.39.200:7777"] = 1,
    	["176.32.39.199:7777"] = 2,
    	["176.32.39.198:7777"] = 3
  	}

	return TNames[iport] and TNames[iport] or 0
end

function createTable()
	local gz_pool = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
	local id = 12
	for idCaption, name in pairs(captions[getServer()]) do
		if gz_pool.pGangzone[id] ~= nil then
			gangzones[id] = idCaption
			towns[id] = getCityByCoord(gz_pool.pGangzone[id].fPosition[0], gz_pool.pGangzone[id].fPosition[1])
			local gz = gz_pool.pGangzone[id]
			if gz.dwColor ~= gz.dwAltColor then
				if lastCaptions[id] ~= nil and lastCaptions[id].time + 700 > os.time() then
					table.insert(captures, id, lastCaptions[id])
					lastCaptions[id] = nil
				else
					local attack = gangzoneColors[gz.dwAltColor]
					local defender = gangzoneColors[gz.dwColor]
					table.insert(captures, id, {name = string.format("{FFFFFF}%s [%d]", name, idCaption), attack = attack, defender = defender, time = os.time(), lastDelay = os.time()})
				end
			end
			id = id + 1
		end
	end
end

function loadSettings()

	local fractionsInitialization = function()
		local t = {}
		for key, _ in pairs(skins) do t[key] = key end
		return t
	end

	local sw, sh = getScreenResolution()
	Settings = inicfg.load({
		["Captures"] = {
			LS = true,
			LV = true,
			SF = true,
			Country = true,
			Visible = true,
			FontName = "Roboto Bold",
			FontSize = 9,
			FontFlags = 5,
			Alignment = 1,
			X = sw - 10,
			Y = sh - 40,
			TimerStyle = 3,
			Order = 0,
			RollbackTime = true,
			ShowPlayers = true,
			Message = true,
			Log = true,
			Gap = 13
		},
		["Fractions"] = fractionsInitialization(),
		[1] = {},
		[2] = {},
		[3] = {}
	}, SETTINGS_FILE)
	inicfg.save(Settings, SETTINGS_FILE)
	if Settings[getServer()] ~= nil then
		for id, name in pairs(Settings[getServer()]) do
			captions[getServer()][id] = name
		end
	end
	formatImguiVarriables()
end

--===================================================== EVENTS =====================================================

function events.onGangZoneFlash(id, color)
	if gangzones[id] ~= nil then
		local gz_pool = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
		local moduleColor = math.abs(color)
		local attack = eventColors[moduleColor]
		local defender = gangzoneColors[gz_pool.pGangzone[id].dwColor]
		table.insert(captures, id, {name = string.format("{FFFFFF}%s [%d]", captions[getServer()][gangzones[id]], gangzones[id]), attack = attack, defender = defender, time = os.time(), lastDelay = os.time()})
		if Settings.Captures.Message and Settings.Captures[towns[id]] then
			sampAddChatMessage(string.format("{FF7F00}%s [%d] {FFFFFF}- начат захват между %s {FFFFFF}и %s", captions[getServer()][gangzones[id]], gangzones[id], attack, defender), 0xFF7F00)
		end
		local date = os.getTime(3)
		if Settings.Captures.Log then
			saveLog(string.format("[%d:%d:%d] {FF7F00}%s [%d] {FFFFFF}- начат захват между %s {FFFFFF}и %s\n", addZero(date.hour), addZero(date.min), addZero(date.sec), captions[getServer()][gangzones[id]], gangzones[id], attack, defender))
		end
	end
end

function events.onGangZoneStopFlash(id)
	if captures[id] ~= nil then
		lua_thread.create(function()
			wait(10)
			if captures[id] ~= nil then
				local gz_pool = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
				local str = string.format("{FF7F00}%s [%d] {FFFFFF}- захват завершен. ", captions[getServer()][gangzones[id]], gangzones[id])
				if gangzoneColors[gz_pool.pGangzone[id].dwColor] ~= captures[id].attack then
					str = str .. string.format("%s {FFFFFF}удержали территорию. ", captures[id].defender)
				else
					str = str .. string.format("%s {FFFFFF}захватили территорию. ", captures[id].attack)
				end
				if os.time() - captures[id].time < 660 then 
					if Settings.Captures.Message and Settings.Captures[towns[id]] then	
						sampAddChatMessage(str, 0xFF7F00)
					end
					if Settings.Captures.Log then
						local date = os.date("!*t", os.time() - captures[id].time)
						local dateNow = os.getTime(3)
						saveLog(string.format("[%d:%d:%d] ", addZero(dateNow.hour), addZero(dateNow.min), addZero(dateNow.sec)) .. str .. string.format("Захват длился %d:%d\n", addZero(date.min), addZero(date.sec)))
					end
				end
				captures[id] = nil
			end
		end)
	end
end

function events.onCreate3DText(id, _, position, _, _, _, _, text)
	if string.find(text, "конца захвата") then
		local gz_pool = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
		for idGangzone, name in pairs(gangzones) do
			local gangzonePosition = gz_pool.pGangzone[idGangzone].fPosition
			if isCoordInArea2d(position.x, position.y, gangzonePosition[2], gangzonePosition[1], gangzonePosition[0], gangzonePosition[3]) then
				local minutes, seconds = string.match(text, "(%d+):(%d+)$")
				if captures[idGangzone] == nil then
					if lastCaptions[idGangzone] ~= nil and lastCaptions[idGangzone].time + 700 > os.time() then
						table.insert(captures, idGangzone, lastCaptions[idGangzone])
						createCapture(idGangzone, table.getKey(eventColors, lastCaptions[idGangzone].attack) * -1)
						lastCaptions[idGangzone] = nil
					else
						local defender = gangzoneColors[gz_pool.pGangzone[idGangzone].dwColor]
						local attack = getMaxPlayersFraction(defender, idGangzone)
						table.insert(captures, idGangzone, {name = string.format("{FFFFFF}%s [%d]", captions[getServer()][gangzones[idGangzone]], gangzones[idGangzone]), attack = attack, defender = defender, time = os.time(), lastDelay = os.time()})
						createCapture(idGangzone, table.getKey(eventColors, attack) * -1)
					end
				end
				captures[idGangzone].time = os.time() + tonumber(minutes) * 60 + tonumber(seconds) - 600
				break
			end
		end
	end
end

function onScriptTerminate(scr)
	if scr == script.this and not settings_window_state.v and table.length(captures) ~= 0 then
		inicfg.save(captures, LAST_INFO_FILE)
	end
end

--===================================================== /AZX =====================================================

function Count()
	local count = {}
	for _, value in pairs(gangzoneColors) do count[value] = 0 end
	for i = 12, 72, 1 do
		local gz_pool = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
		if gz_pool.pGangzone[i] ~= nil then
			count[gangzoneColors[gz_pool.pGangzone[i].dwColor]] = count[gangzoneColors[gz_pool.pGangzone[i].dwColor]] + 1
		end
	end
	local dialogText = ""
	for fraction, captions in pairs(count) do
		dialogText = string.format("%s%s", dialogText, string.format("%s\t%d\n", fraction, captions))
	end
	sampShowDialog(999, string.format("{FFFFFF}Количество территорий"), dialogText, "Выбрать", "Ок", 4)
	sampSetCurrentDialogListItem(-1)
end

--===================================================== EXTENSIONS =====================================================

function table.getKey(table, element)
	for key, value in pairs(table) do
		if value == element then
			return key
		end
	end
	return nil
end

function table.u8(table)
	local t = {}
	for key, value in pairs(table) do
		if type(value) ~= 'table' then
			t[key] = u8(value)
		else
			t[key] = u8(value.String)
		end
	end
	return t
end

function table.contains(table, element)
	for _, value in pairs(table) do
    	if value == element then
      	return true
    	end
  	end
  	return false
end

function table.length(table)
	local count = 0
	for _, value in pairs(table) do
		if value ~= nil then
			count = count + 1
		end
	end
	return count
end

function os.getTime(shift)
	return os.date("*t", os.time(os.date("!*t")) + 3600 * shift)
end

--===================================================== CUSTOM FUNCTIONS =====================================================

function getPlayers(capture, id)
	local attack, defender = 0, 0
	local gz_pool = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
	local gzPosition = gz_pool.pGangzone[id].fPosition
	for _, ped in pairs(getAllChars()) do	
		if isCharInArea2d(ped, gzPosition[0], gzPosition[1], gzPosition[2], gzPosition[3], false) then
			if table.contains(skins[capture.attack], getCharModel(ped)) then
				attack = attack + 1
			elseif table.contains(skins[capture.defender], getCharModel(ped)) then
				defender = defender + 1
			end
		end
	end
	return attack, defender
end

function getMaxPlayersFraction(exception, id)
	local maxFraction = nil
	local maxPlayers = 0
	local gz_pool = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
	local gzPosition = gz_pool.pGangzone[id].fPosition
	for fraction, tableSkin in pairs(skins) do
		if exception ~= fraction then
			local fractionCount = 0
			for _, ped in pairs(getAllChars()) do
				if isCharInArea2d(ped, gzPosition[0], gzPosition[1], gzPosition[2], gzPosition[3], false) and table.contains(tableSkin, getCharModel(ped)) then
					fractionCount = fractionCount + 1
				end
			end
			if maxPlayers < fractionCount then
				maxFraction = fraction
			end
		end
	end
	return maxFraction
end

function getCityByCoord(x, y)
  if isCoordInArea2d(x, y, 80, -2970, 2970, -670) then return "LS"
	elseif isCoordInArea2d(x, y, -2990, -1000, -1250, 1600) then return "SF"
	elseif isCoordInArea2d(x, y, 600, 600, 2990, 2990) then return "LV"
	else return "Country"
	end
end

function isCoordInArea2d(xW, yW, x1, y1, x2, y2)
	if (xW < x1) and (yW < y1) and (xW > x2) and (yW > y2) then
		return true
	elseif (xW > x1) and (yW > y1) and (xW < x2) and (yW < y2) then
		return true
	else
		return false
	end
end

function createCapture(id, color)
	local bs = raknetNewBitStream()
	raknetBitStreamWriteInt16(bs, id)
	raknetBitStreamWriteInt32(bs, color)
	raknetEmulRpcReceiveBitStream(121, bs)
	raknetDeleteBitStream(bs)
end

function setMarkerOnGangzone(id)
	local gz_pool = ffi.cast('struct stGangzonePool*', sampGetGangzonePoolPtr())
	local gz_pos = gz_pool.pGangzone[table.getKey(gangzones, id)].fPosition
	local x = (gz_pos[0] + gz_pos[2]) / 2
	local y = (gz_pos[1] + gz_pos[3]) / 2
	if checkpoint ~= nil then
		raknetEmulRpcReceiveBitStream(37, raknetNewBitStream())
	end
    local bs = raknetNewBitStream()
	raknetBitStreamWriteFloat(bs, x)
	raknetBitStreamWriteFloat(bs, y)
	raknetBitStreamWriteFloat(bs, 20)
	raknetEmulRpcReceiveBitStream(107, bs)
	raknetDeleteBitStream(bs)
end

function addZero(value)
	if tonumber(value) < 10 then return "0" .. value else return tostring(value) end
end

function saveLog(line)
	local date = os.getTime(3)
	local directory = getWorkingDirectory() .. "\\config\\Checker Captures\\Logs\\Galaxy " .. getServer() .. "\\" .. string.format("%s %d", months[date.month], date.year)
	if not doesDirectoryExist(directory) then createDirectory(directory) end
	local logPath = directory .. "\\" .. string.format("%s.%s.%s", addZero(date.day), addZero(date.month), date.year) .. ".txt"
	local f = io.open(logPath, "a")
	if f == nil then
		f = io.open(logPath, "w")
	end
	f:write(line)
	f:close()
end

function update()
	local checkVersion = downloadFile("https://raw.githubusercontent.com/Kotovasya/Checker-Captrures/master/Version.ini", "config\\Checker Captures\\Version.ini")
	if checkVersion then
		local ini = inicfg.load({}, "/Checker Captures/Version")
		os.remove(getWorkingDirectory() .. "/config/Checker Captures/Version.ini")
		if ini.Script.Version > tonumber(thisScript().version) then
			sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Обнаружена новая версия скрипта, пробуем обновиться..."), 0xFF7F00)
			local script = downloadFile("https://raw.githubusercontent.com/Kotovasya/Checker-Captrures/master/CheckerCaptures.lua", "CheckerCaptures.lua")
			if script then
				return true
			else
				sampAddChatMessage(string.format("{FF7F00}[Checker Captures]:{ffffff} Не удалось скачать новую версию :("), 0xFF7F00)
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

function downloadFile(url, path)
	local download_status = false
	local download_result = false
	local downloadPath = getWorkingDirectory() .. '\\' .. path
	downloadUrlToFile(url, downloadPath, function(id, status) 
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			download_status = true
			download_result = true
		elseif status == dlstatus.STATUSEX_ENDDOWNLOAD and not download_status then
			download_status = true
			download_result = false
		end
	end)
	while not download_status do wait(0) end
	return download_result
end