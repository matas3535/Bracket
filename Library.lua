local Color3_fromHex, Color3_fromHSV, Color3_fromRGB, Color3_new, coroutine_wrap, Instance_new, math_clamp, math_floor, os_clock, Random_new, string_find, string_format, string_gsub, string_rep, string_split, table_clear, table_concat, table_find, table_remove, task_spawn, task_wait, UDim2_fromScale, utf8_char, tonumber, loadstring, delfile, UDim2_new, sethiddenproperty, tostring, readfile, writefile, isfile, listfiles, makefolder, isfolder, math_max, OnStop, OnTick, UDim2_fromOffset, Vector2_new, setmetatable, ipairs, table_insert, typeof, type, pairs = Color3.fromHex, Color3.fromHSV, Color3.fromRGB, Color3.new, coroutine.wrap, Instance.new, math.clamp, math.floor, os.clock, Random.new, string.find, string.format, string.gsub, string.rep, string.split, table.clear, table.concat, table.find, table.remove, task.spawn, task.wait, UDim2.fromScale, utf8.char, tonumber, loadstring, delfile, UDim2.new, sethiddenproperty, tostring, readfile, writefile, isfile, listfiles, makefolder, isfolder, math.max, OnStop, OnTick, UDim2.fromOffset, Vector2.new, setmetatable, ipairs, table.insert, typeof, type, pairs
--
local Utility = {
	Backgrounds = {
		{"Legacy", "rbxassetid://2151741365"},
		{"Hearts", "rbxassetid://6073763717"},
		{"Hexagon", "rbxassetid://6073628839"},
		{"Circles", "rbxassetid://6071579801"},
		{"Flowers", "rbxassetid://6071575925"},
		{"Floral", "rbxassetid://5553946656"},
		{"Christmas", "rbxassetid://11711560928"}
	},
	Drawings = {},
	Screens = {},
	Events = {}
}
--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local IsLocal,Assets,LocalPlayer = false,{},PlayerService.LocalPlayer
local MainAssetFolder = InsertService:LoadLocalAsset("rbxassetid://14761186068")
--
function Utility:Event(Type, Function)
	local Event = {
		Connection = Type:Connect(Function),
		Function = Function
	}
	--
	function Event:Disconnect()
		Event.Connection:Disconnect()
		--
		Utility.Events[Event] = nil
		--
		Event.Connection = nil
		Event.Function = nil
		Event.Disconnect = nil
		Event = nil
	end
	--
	Utility.Events[Event] = true
	--
	return Event
end
--
function Utility:Thread(Function)
	return coroutine_wrap(Function)()
end
--
function Utility:Unload()
	for Index, Value in pairs(Utility.Events) do
        Index:Disconnect()
    end
	--
	if Utility.Custom and typeof(Utility.Custom) == "function" then
		pcall(Utility.Custom)
	end
    --
	for Index, Value in pairs(Utility.Screens) do
		Index:Remove()
	end
	--
    for Index, Value in pairs(Utility.Drawings) do
        Index:Remove()
    end
	--
	RunService:SetRobloxGuiFocused(false)
    --
	Utility.Drawings = nil
	Utility.Screens = nil
    Utility.Events = nil
	--
    Utility.Unload = nil
	--
	Utility = nil
	Library = nil
end
--
local function GetAsset(AssetPath)
	AssetPath = AssetPath:split("/")
	local Asset = MainAssetFolder
	for Index,Name in pairs(AssetPath) do
		Asset = Asset[Name]
		end return Asset:Clone()
	end

	local function TableToColor(Table)
		if type(Table) ~= "table" then return Table end
		return Color3_fromHSV(Table[1],Table[2],Table[3])
	end
	local function ColorToString(Color)
		return ("%i,%i,%i"):format(Color.R * 255,Color.G * 255,Color.B * 255)
	end
	local function Scale(Value,InputMin,InputMax,OutputMin,OutputMax)
		return OutputMin + (Value - InputMin) * (OutputMax - OutputMin) / (InputMax - InputMin)
	end
	local function DeepCopy(Original)
		local Copy = {}
		for Index,Value in pairs(Original) do
			if type(Value) == "table" then
				Value = DeepCopy(Value)
			end
			Copy[Index] = Value
		end
		return Copy
	end
	local function Proxify(Table) local Proxy,Events = {},{}
		local ChangedEvent = Instance_new("BindableEvent")
		Table.Changed = ChangedEvent.Event
		Proxy.Internal = Table

		function Table:GetPropertyChangedSignal(Property)
			local PropertyEvent = Instance_new("BindableEvent")
			Events[Property] = Events[Property] or {}
			table_insert(Events[Property],PropertyEvent)
			return PropertyEvent.Event
		end

		setmetatable(Proxy,{
			__index = function(Self,Key)
			return Table[Key]
			end,
			__newindex = function(Self,Key,Value)
			local OldValue = Table[Key]
			Table[Key] = Value

			ChangedEvent:Fire(Key,Value,OldValue)
			if Events[Key] then
				for Index,Event in ipairs(Events[Key]) do
					Event:Fire(Value,OldValue)
				end
			end
		end
	})

	return Proxy
end

local function GetType(Object,Default,Type,UseProxify)
	if typeof(Object) == Type then
		return UseProxify and Proxify(Object) or Object
	end
	return UseProxify and Proxify(Default) or Default
end
local function GetTextBounds(Text,Font,Size)
	return TextService:GetTextSize(Text,Size.Y,Font,Vector2_new(Size.X,1e6))
end

local function MakeDraggable(Dragger,Object,OnTick,OnStop)
	local StartPosition,StartDrag = nil,nil
	Utility:Event(Dragger.InputBegan, function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		StartPosition = UserInputService:GetMouseLocation()
		StartDrag = Object.AbsolutePosition
	end
	end)
	Utility:Event(UserInputService.InputChanged, function(Input)
	if StartDrag and Input.UserInputType == Enum.UserInputType.MouseMovement then
		local Mouse = UserInputService:GetMouseLocation()
		local Delta = Mouse - StartPosition StartPosition = Mouse
		OnTick(Object.Position + UDim2_fromOffset(Delta.X,Delta.Y))
	end
	end)
	Utility:Event(Dragger.InputEnded, function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		StartPosition,StartDrag = nil,nil
		if OnStop then OnStop(Object.Position) end
	end
	end)
end
local function MakeResizeable(Dragger,Object,MinSize,OnTick,OnStop)
	local StartPosition,StartSize = nil,nil
	Utility:Event(Dragger.InputBegan, function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		StartPosition = UserInputService:GetMouseLocation()
		StartSize = Object.AbsoluteSize
	end
	end)
	Utility:Event(UserInputService.InputChanged, function(Input)
	if StartPosition and Input.UserInputType == Enum.UserInputType.MouseMovement then
		local Mouse = UserInputService:GetMouseLocation()
		local Delta = Mouse - StartPosition

		local Size = StartSize + Delta
		local SizeX = math_max(MinSize.X,Size.X)
		local SizeY = math_max(MinSize.Y,Size.Y)
		OnTick(UDim2_fromOffset(SizeX,SizeY))
	end
	end)
	Utility:Event(Dragger.InputEnded, function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		StartPosition,StartSize = nil,nil
		if OnStop then OnStop(Object.Size) end
	end
	end)
end

local function ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
	for Index,Object in pairs(ScreenAsset:GetChildren()) do
		if Object.Name == "OptionContainer"
		or Object.Name == "Palette" then
			Object.Visible = false
		end
	end
	for Index,Object in pairs(ScreenAsset.Window.TabContainer:GetChildren()) do
		if Object:IsA("ScrollingFrame")
		and Object ~= TabAsset then
			Object.Visible = false
		else
			Object.Visible = true
		end
	end
	for Index,Object in pairs(ScreenAsset.Window.TabButtonContainer:GetChildren()) do
		if Object:IsA("TextButton") then
			Object.Highlight.Visible = Object == TabButtonAsset
		end
	end
end
local function GetLongestSide(TabAsset)
	if TabAsset.LeftSide.ListLayout.AbsoluteContentSize.Y
	>= TabAsset.RightSide.ListLayout.AbsoluteContentSize.Y then
		return TabAsset.LeftSide
	else
		return TabAsset.RightSide
	end
end
local function GetShortestSide(TabAsset)
	if TabAsset.LeftSide.ListLayout.AbsoluteContentSize.Y
	<= TabAsset.RightSide.ListLayout.AbsoluteContentSize.Y then
		return TabAsset.LeftSide
	else
		return TabAsset.RightSide
	end
end
local function ChooseTabSide(TabAsset,Mode)
	if Mode == "Left" then
		return TabAsset.LeftSide
	elseif Mode == "Right" then
		return TabAsset.RightSide
	else
		return GetShortestSide(TabAsset)
	end
end

local function FindElementByFlag(Elements,Flag)
	for Index,Element in pairs(Elements) do
		if Element.Flag == Flag then
			return Element
		end
	end
end
local function GetConfigs(FolderName)
	if not isfolder(FolderName) then makefolder(FolderName) end
	if not isfolder(FolderName .. "\\Configs") then makefolder(FolderName .. "\\Configs") end

	local Configs = {}
	for Index,Config in pairs(listfiles(FolderName .. "\\Configs") or {}) do
		Config = Config:gsub(FolderName .. "\\Configs\\","")
		Config = Config:gsub(".json","")
		Configs[#Configs + 1] = Config
	end
	return Configs
end
local function ConfigsToList(FolderName)
	if not isfolder(FolderName) then makefolder(FolderName) end
	if not isfolder(FolderName .. "\\Configs") then makefolder(FolderName .. "\\Configs") end
	if not isfile(FolderName .. "\\AutoLoads.json") then writefile(FolderName .. "\\AutoLoads.json","[]") end

	local Configs = {}
	local AutoLoads = HttpService:JSONDecode(
	readfile(FolderName .. "\\AutoLoads.json")
	) local AutoLoad = AutoLoads[tostring(game.GameId)]

	for Index,Config in pairs(listfiles(FolderName .. "\\Configs") or {}) do
		Config = Config:gsub(FolderName .. "\\Configs\\","")
		Config = Config:gsub(".json","")
		Configs[#Configs + 1] = {
			Name = Config,Mode = "Button",
			Value = Config == AutoLoad
		}
	end

	return Configs
end

function Assets:Screen()
	local ScreenAsset = GetAsset("Screen/Bracket")
	Utility.Screens[ScreenAsset] = true
	sethiddenproperty(ScreenAsset,"OnTopOfCoreBlur",true)
	ScreenAsset.Name = game:GetService("HttpService"):GenerateGUID(false)
	ScreenAsset.Parent = CoreGui
	return {ScreenAsset = ScreenAsset}
end
function Assets:Window(ScreenAsset,Window)
	local WindowAsset = GetAsset("Window/Window")

	Window.Background = WindowAsset.Background
	Window.RainbowHue,Window.RainbowSpeed = 0,10
	Window.Colorable,Window.Elements,Window.Flags = {},{},{}

	WindowAsset.Parent = ScreenAsset
	WindowAsset.Visible = Window.Enabled
	WindowAsset.Title.Text = Window.Name
	WindowAsset.Version.Text = Window.Version
	WindowAsset.Position = Window.Position
	WindowAsset.Size = Window.Size

	MakeDraggable(WindowAsset.Drag,WindowAsset,function(Position)
	Window.Position = Position
	end)
	MakeResizeable(WindowAsset.Resize,WindowAsset,Vector2_new(296,296),function(Size)
	Window.Size = Size
	end)

	Utility:Event(WindowAsset.TabButtonContainer.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	WindowAsset.TabButtonContainer.CanvasSize = UDim2_fromOffset(
	WindowAsset.TabButtonContainer.ListLayout.AbsoluteContentSize.X,0
	)
	end)

	Utility:Event(UserInputService.InputChanged, function(Input)
	if WindowAsset.Visible and Input.UserInputType == Enum.UserInputType.MouseMovement then
		local Mouse = UserInputService:GetMouseLocation()
		ScreenAsset.ToolTip.Position = UDim2_fromOffset(
		Mouse.X + 5,Mouse.Y - 5
		)
	end
	end)
	Utility:Event(RunService.RenderStepped, function()
	Window.RainbowHue = os_clock() % Window.RainbowSpeed / Window.RainbowSpeed
	end)

	Utility:Event(Window:GetPropertyChangedSignal("Enabled"), function(Enabled)
	WindowAsset.Visible = Enabled

	RunService:SetRobloxGuiFocused(Enabled and Window.Blur)

	if not Enabled then
		for Index,Object in pairs(ScreenAsset:GetChildren()) do
			if Object.Name == "Palette" or Object.Name == "OptionContainer" then
				Object.Visible = false
			end
		end
	end
	end)
	Utility:Event(Window:GetPropertyChangedSignal("Blur"), function(Blur)
	if not IsLocal then RunService:SetRobloxGuiFocused(Window.Enabled and Blur) end
	end)
	Utility:Event(Window:GetPropertyChangedSignal("Name"), function(Name)
	WindowAsset.Title.Text = Name
	end)
	Utility:Event(Window:GetPropertyChangedSignal("Position"), function(Position)
	WindowAsset.Position = Position
	end)
	Utility:Event(Window:GetPropertyChangedSignal("Size"), function(Size)
	WindowAsset.Size = Size
	end)
	Utility:Event(Window:GetPropertyChangedSignal("Color"), function(Color)
	for Object,ColorConfig in pairs(Window.Colorable) do
		if ColorConfig[1] then Object[ColorConfig[2]] = Color end
	end
	end)

	function Window:SetValue(Flag,Value)
		for Index,Element in pairs(Window.Elements) do
			if Element.Flag == Flag then
				Element.Value = Value
			end
		end
	end
	function Window:GetValue(Flag)
		for Index,Element in pairs(Window.Elements) do
			if Element.Flag == Flag then
				return Element.Value
			end
		end
	end

	function Window:Watermark(Watermark)
		Watermark = GetType(Watermark,{},"table",true)
		Watermark.Enabled = GetType(Watermark.Enabled,false,"boolean")
		Watermark.Title = GetType(Watermark.Title,"Hello World!","string")
		Watermark.Flag = GetType(Watermark.Flag,"UI/Watermark/Position","string")

		ScreenAsset.Watermark.Visible = Watermark.Enabled
		ScreenAsset.Watermark.Text = Watermark.Title

		ScreenAsset.Watermark.Size = UDim2_fromOffset(
		ScreenAsset.Watermark.TextBounds.X + 6,
		ScreenAsset.Watermark.TextBounds.Y + 6
		)

		MakeDraggable(ScreenAsset.Watermark,ScreenAsset.Watermark,function(Position)
		ScreenAsset.Watermark.Position = Position
		end,function(Position)
		Watermark.Value = {
			Position.X.Scale,Position.X.Offset,
			Position.Y.Scale,Position.Y.Offset
		}
		end)

		Utility:Event(Watermark:GetPropertyChangedSignal("Enabled"), function(Enabled)
		ScreenAsset.Watermark.Visible = Enabled
		end)
		Utility:Event(Watermark:GetPropertyChangedSignal("Title"), function(Title)
		ScreenAsset.Watermark.Text = Title
		ScreenAsset.Watermark.Size = UDim2_fromOffset(
		ScreenAsset.Watermark.TextBounds.X + 6,
		ScreenAsset.Watermark.TextBounds.Y + 6
		)
		end)
		Utility:Event(Watermark:GetPropertyChangedSignal("Value"), function(Value)
		if type(Value) ~= "table" then return end
		ScreenAsset.Watermark.Position = UDim2_new(
		Value[1],Value[2],
		Value[3],Value[4]
		)
		Window.Flags[Watermark.Flag] = {
			Value[1],Value[2],
			Value[3],Value[4]
		}
		end)

		Window.Elements[#Window.Elements + 1] = Watermark
		Window.Watermark = Watermark
	end

	function Window:SaveConfig(FolderName,Name)
		local Config = {}
		for Index,Element in pairs(Window.Elements) do
			if not Element.IgnoreFlag then
				Config[Element.Flag] = Window.Flags[Element.Flag]
			end
		end
		writefile(
		FolderName .. "\\Configs\\" .. Name .. ".json",
		HttpService:JSONEncode(Config)
		)
	end
	function Window:LoadConfig(FolderName,Name)
		if table_find(GetConfigs(FolderName),Name) then
			local DecodedJSON = HttpService:JSONDecode(
			readfile(FolderName .. "\\Configs\\" .. Name .. ".json")
			)
			for Flag,Value in pairs(DecodedJSON) do
				local Element = FindElementByFlag(Window.Elements,Flag)
				if Element ~= nil then Element.Value = Value end
			end
		end
	end
	function Window:DeleteConfig(FolderName,Name)
		if table_find(GetConfigs(FolderName),Name) then
			delfile(FolderName .. "\\Configs\\" .. Name .. ".json")
		end
	end
	function Window:GetAutoLoadConfig(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfile(FolderName .. "\\AutoLoads.json") then
			writefile(FolderName .. "\\AutoLoads.json","[]")
		end

		local AutoLoads = HttpService:JSONDecode(
		readfile(FolderName .. "\\AutoLoads.json")
		) local AutoLoad = AutoLoads[tostring(game.GameId)]

		if table_find(GetConfigs(FolderName),AutoLoad) then
			return AutoLoad
		end
	end
	function Window:AddToAutoLoad(FolderName,Name)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfile(FolderName .. "\\AutoLoads.json") then
			writefile(FolderName .. "\\AutoLoads.json","[]")
		end

		local AutoLoads = HttpService:JSONDecode(
		readfile(FolderName .. "\\AutoLoads.json")
		) AutoLoads[tostring(game.GameId)] = Name

		writefile(FolderName .. "\\AutoLoads.json",
		HttpService:JSONEncode(AutoLoads)
		)
	end
	function Window:RemoveFromAutoLoad(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfile(FolderName .. "\\AutoLoads.json") then
			writefile(FolderName .. "\\AutoLoads.json","[]")
			return
		end

		local AutoLoads = HttpService:JSONDecode(
		readfile(FolderName .. "\\AutoLoads.json")
		) AutoLoads[tostring(game.GameId)] = nil

		writefile(FolderName .. "\\AutoLoads.json",
		HttpService:JSONEncode(AutoLoads)
		)
	end
	function Window:AutoLoadConfig(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfile(FolderName .. "\\AutoLoads.json") then
			writefile(FolderName .. "\\AutoLoads.json","[]")
		end

		local AutoLoads = HttpService:JSONDecode(
		readfile(FolderName .. "\\AutoLoads.json")
		) local AutoLoad = AutoLoads[tostring(game.GameId)]

		if table_find(GetConfigs(FolderName),AutoLoad) then
			Window:LoadConfig(FolderName,AutoLoad)
		end
	end

	return WindowAsset
end
function Assets:Tab(ScreenAsset,WindowAsset,Window,Tab)
	local TabButtonAsset,TabAsset = GetAsset("Tab/TabButton"),GetAsset("Tab/Tab")

	Tab.ColorConfig = {true,"BackgroundColor3"}
	Window.Colorable[TabButtonAsset.Highlight] = Tab.ColorConfig

	TabAsset.Parent = WindowAsset.TabContainer
	TabButtonAsset.Parent = WindowAsset.TabButtonContainer

	TabAsset.Visible = false
	TabButtonAsset.Text = Tab.Name
	TabButtonAsset.Highlight.BackgroundColor3 = Window.Color
	TabButtonAsset.Size = UDim2_new(0,TabButtonAsset.TextBounds.X + 12,1,-1)
	TabButtonAsset.Parent = WindowAsset.TabButtonContainer

	Utility:Event(TabAsset.LeftSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	local Side = GetLongestSide(TabAsset)
	TabAsset.CanvasSize = UDim2_fromOffset(0,Side.ListLayout.AbsoluteContentSize.Y + 21)
	end)
	Utility:Event(TabAsset.RightSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	local Side = GetLongestSide(TabAsset)
	TabAsset.CanvasSize = UDim2_fromOffset(0,Side.ListLayout.AbsoluteContentSize.Y + 21)
	end)
	Utility:Event(TabButtonAsset.MouseButton1Click, function()
	ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
	end)

	if #WindowAsset.TabContainer:GetChildren() == 1 then
		ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
	end

	Utility:Event(Tab:GetPropertyChangedSignal("Name"), function(Name)
	TabButtonAsset.Text = Name
	TabButtonAsset.Size = UDim2_new(
	0,TabButtonAsset.TextBounds.X + 12,
	1,-1
	)
	end)

	return TabAsset
end
function Assets:Section(Parent,Section)
	local SectionAsset = GetAsset("Section/Section")

	SectionAsset.Parent = Parent
	SectionAsset.Title.Text = Section.Name
	SectionAsset.Title.Size = UDim2_fromOffset(
	SectionAsset.Title.TextBounds.X + 6,2
	)

	Utility:Event(SectionAsset.Container.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	SectionAsset.Size = UDim2_new(1,0,0,SectionAsset.Container.ListLayout.AbsoluteContentSize.Y + 15)
	end)

	Utility:Event(Section:GetPropertyChangedSignal("Name"), function(Name)
	SectionAsset.Title.Text = Name
	SectionAsset.Title.Size = UDim2_fromOffset(
	Section.Title.TextBounds.X + 6,2
	)
	end)

	return SectionAsset.Container
end
function Assets:ToolTip(Parent,ScreenAsset,Text)
	Utility:Event(Parent.MouseEnter, function()
	ScreenAsset.ToolTip.Text = Text
	ScreenAsset.ToolTip.Size = UDim2_fromOffset(
	ScreenAsset.ToolTip.TextBounds.X + 6,
	ScreenAsset.ToolTip.TextBounds.Y + 6
	) ScreenAsset.ToolTip.Visible = true
	end)
	Utility:Event(Parent.MouseLeave, function()
	ScreenAsset.ToolTip.Visible = false
	end)
end
function Assets.Snowflakes(WindowAsset)
	local ParticleEmitter = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/rParticle/master/Main.lua"))()
	local Emitter = ParticleEmitter.new(WindowAsset.Background,WindowAsset.Snowflake)
	local NewRandom = Random_new() Emitter.SpawnRate = 20

	Emitter.OnSpawn = function(Particle)
	local RandomPosition = NewRandom:NextNumber()
	local RandomSize = NewRandom:NextInteger(5,25)
	local RandomYVelocity = NewRandom:NextInteger(20,100)
	local RandomXVelocity = NewRandom:NextInteger(-100,100)

	Particle.Object.ImageTransparency = RandomSize / 50
	Particle.Object.Size = UDim2_fromOffset(RandomSize,RandomSize)
	Particle.Velocity = Vector2_new(RandomXVelocity,RandomYVelocity)
	Particle.Position = Vector2_new(RandomPosition * WindowAsset.Background.AbsoluteSize.X,0)
	Particle.MaxAge = 20 task_wait(0.5) Particle.Object.Visible = true
end

Emitter.OnUpdate = function(Particle,Delta)
Particle.Position = Particle.Position + Particle.Velocity * Delta
end
end
function Assets:Divider(Parent,Divider)
local DividerAsset = GetAsset("Divider/Divider")

DividerAsset.Parent = Parent
DividerAsset.Title.Text = Divider.Text

Utility:Event(DividerAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
if DividerAsset.Title.TextBounds.X > 0 then
DividerAsset.Size = UDim2_new(1,0,0,DividerAsset.Title.TextBounds.Y)
DividerAsset.Left.Size = UDim2_new(0.5,-(DividerAsset.Title.TextBounds.X / 2) - 6,0,2)
DividerAsset.Right.Size = UDim2_new(0.5,-(DividerAsset.Title.TextBounds.X / 2) - 6,0,2)
else
DividerAsset.Size = UDim2_new(1,0,0,14)
DividerAsset.Left.Size = UDim2_new(1,0,0,2)
DividerAsset.Right.Size = UDim2_new(1,0,0,2)
end
end)

Utility:Event(Divider:GetPropertyChangedSignal("Text"), function(Text)
DividerAsset.Title.Text = Text
end)
end
function Assets:Label(Parent,Label)
local LabelAsset = GetAsset("Label/Label")

LabelAsset.Parent = Parent
LabelAsset.Text = Label.Text

Utility:Event(LabelAsset:GetPropertyChangedSignal("TextBounds"), function()
LabelAsset.Size = UDim2_new(1,0,0,LabelAsset.TextBounds.Y)
end)

Utility:Event(Label:GetPropertyChangedSignal("Text"), function(Text)
LabelAsset.Text = Text
end)
end
function Assets:Button(Parent,ScreenAsset,Window,Button)
local ButtonAsset = GetAsset("Button/Button")

Button.ColorConfig = {false,"BorderColor3"}
Window.Colorable[ButtonAsset] = Button.ColorConfig

Button.Connection = Utility:Event(ButtonAsset.MouseButton1Click, Button.Callback)

ButtonAsset.Parent = Parent
ButtonAsset.Title.Text = Button.Name

Utility:Event(ButtonAsset.MouseButton1Down, function()
Button.ColorConfig[1] = true
ButtonAsset.BorderColor3 = Window.Color
end)
Utility:Event(ButtonAsset.MouseButton1Up, function()
Button.ColorConfig[1] = false
ButtonAsset.BorderColor3 = Color3_new(0,0,0)
end)
Utility:Event(ButtonAsset.MouseLeave, function()
Button.ColorConfig[1] = false
ButtonAsset.BorderColor3 = Color3_new(0,0,0)
end)
Utility:Event(ButtonAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
ButtonAsset.Size = UDim2_new(1,0,0,ButtonAsset.Title.TextBounds.Y + 2)
end)

Utility:Event(Button:GetPropertyChangedSignal("Name"), function(Name)
ButtonAsset.Title.Text = Name
end)
Utility:Event(Button:GetPropertyChangedSignal("Callback"), function(Callback)
Button.Connection:Disconnect()
Button.Connection = Utility:Event(ButtonAsset.MouseButton1Click, Callback)
end)

function Button:ToolTip(Text)
Assets:ToolTip(ButtonAsset,ScreenAsset,Text)
end
end
function Assets:Toggle(Parent,ScreenAsset,Window,Toggle)
local ToggleAsset = GetAsset("Toggle/Toggle")

Toggle.ColorConfig = {Toggle.Value,"BackgroundColor3"}
Window.Colorable[ToggleAsset.Tick] = Toggle.ColorConfig

ToggleAsset.Parent = Parent
ToggleAsset.Title.Text = Toggle.Name
ToggleAsset.Tick.BackgroundColor3 = Toggle.Value
and Window.Color or Color3_fromRGB(60,60,60)

Utility:Event(ToggleAsset.MouseButton1Click, function()
Toggle.Value = not Toggle.Value
end)
Utility:Event(ToggleAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
ToggleAsset.Size = UDim2_new(1,0,0,ToggleAsset.Title.TextBounds.Y)
ToggleAsset.Layout.Size = UDim2_new(1,-ToggleAsset.Title.TextBounds.X - 18,1,0)
end)

Utility:Event(Toggle:GetPropertyChangedSignal("Name"), function(Name)
ToggleAsset.Title.Text = Name
end)
Utility:Event(Toggle:GetPropertyChangedSignal("Value"), function(Value)
Toggle.ColorConfig[1] = Value
ToggleAsset.Tick.BackgroundColor3 = Value
and Window.Color or Color3_fromRGB(60,60,60)
Window.Flags[Toggle.Flag] = Value
Toggle.Callback(Value)
end)

function Toggle:ToolTip(Text)
Assets:ToolTip(ToggleAsset,ScreenAsset,Text)
end

return ToggleAsset
end
function Assets:Slider(Parent,ScreenAsset,Window,Slider)
local SliderAsset = Slider.Wide
and GetAsset("Slider/HighSlider")
or GetAsset("Slider/Slider")

Slider.ColorConfig = {true,"BackgroundColor3"}
Window.Colorable[SliderAsset.Background.Bar] = Slider.ColorConfig

Slider.Active = false
Slider.Value = tonumber(string_format("%." .. Slider.Precise .. "f",Slider.Value))

SliderAsset.Parent = Parent
SliderAsset.Title.Text = Slider.Name
SliderAsset.Background.Bar.BackgroundColor3 = Window.Color
SliderAsset.Background.Bar.Size = UDim2_fromScale(Scale(Slider.Value,Slider.Min,Slider.Max,0,1),1)
SliderAsset.Value.PlaceholderText = #Slider.Unit == 0 and Slider.Value or Slider.Value .. " " .. Slider.Unit

local function AttachToMouse(Input)
local ScaleX = math_clamp((Input.Position.X - SliderAsset.Background.AbsolutePosition.X) / SliderAsset.Background.AbsoluteSize.X,0,1)
Slider.Value = Scale(ScaleX,0,1,Slider.Min,Slider.Max)
end

if Slider.Wide then
Utility:Event(SliderAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
SliderAsset.Value.Size = UDim2_new(0,SliderAsset.Value.TextBounds.X,1,0)
SliderAsset.Title.Size = UDim2_new(1,-SliderAsset.Value.Size.X.Offset + 12,1,0)
SliderAsset.Size = UDim2_new(1,0,0,SliderAsset.Title.TextBounds.Y + 2)
end)
Utility:Event(SliderAsset.Value:GetPropertyChangedSignal("TextBounds"), function()
SliderAsset.Value.Size = UDim2_new(0,SliderAsset.Value.TextBounds.X,1,0)
SliderAsset.Title.Size = UDim2_new(1,-SliderAsset.Value.Size.X.Offset + 12,1,0)
end)
else
Utility:Event(SliderAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
SliderAsset.Value.Size = UDim2_fromOffset(SliderAsset.Value.TextBounds.X,16)
SliderAsset.Title.Size = UDim2_new(1,-SliderAsset.Value.Size.X.Offset,0,16)
SliderAsset.Size = UDim2_new(1,0,0,SliderAsset.Title.TextBounds.Y + 8)
end)
Utility:Event(SliderAsset.Value:GetPropertyChangedSignal("TextBounds"), function()
SliderAsset.Value.Size = UDim2_fromOffset(SliderAsset.Value.TextBounds.X,16)
SliderAsset.Title.Size = UDim2_new(1,-SliderAsset.Value.Size.X.Offset,0,16)
end)
end

Utility:Event(SliderAsset.Value.FocusLost, function()
if not tonumber(SliderAsset.Value.Text) then
SliderAsset.Value.Text = Slider.Value
elseif tonumber(SliderAsset.Value.Text) <= Slider.Min then
SliderAsset.Value.Text = Slider.Min
elseif tonumber(SliderAsset.Value.Text) >= Slider.Max then
SliderAsset.Value.Text = Slider.Max
end
Slider.Value = SliderAsset.Value.Text
SliderAsset.Value.Text = ""
end)
Utility:Event(SliderAsset.InputBegan, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
AttachToMouse(Input)
Slider.Active = true
end
end)
Utility:Event(SliderAsset.InputEnded, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
Slider.Active = false
end
end)
Utility:Event(UserInputService.InputChanged, function(Input)
if Slider.Active and Input.UserInputType == Enum.UserInputType.MouseMovement then
AttachToMouse(Input)
end
end)

Utility:Event(Slider:GetPropertyChangedSignal("Name"), function(Name)
SliderAsset.Title.Text = Name
end)
Utility:Event(Slider:GetPropertyChangedSignal("Value"), function(Value)
Value = tonumber(string_format("%." .. Slider.Precise .. "f",Value))
SliderAsset.Background.Bar.Size = UDim2_fromScale(Scale(Value,Slider.Min,Slider.Max,0,1),1)
SliderAsset.Value.PlaceholderText = #Slider.Unit == 0
and Value or Value .. " " .. Slider.Unit

Window.Flags[Slider.Flag] = Value
Slider.Callback(Value)
end)

function Slider:ToolTip(Text)
Assets:ToolTip(SliderAsset,ScreenAsset,Text)
end
end
function Assets:Textbox(Parent,ScreenAsset,Window,Textbox)
local TextboxAsset = GetAsset("Textbox/Textbox")
Textbox.EnterPressed = false

TextboxAsset.Parent = Parent
TextboxAsset.Title.Text = Textbox.Name
TextboxAsset.Background.Input.Text = Textbox.Value
TextboxAsset.Background.Input.PlaceholderText = Textbox.Placeholder
TextboxAsset.Title.Visible = not Textbox.HideName

Utility:Event(TextboxAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
TextboxAsset.Title.Size = Textbox.HideName and UDim2_fromScale(1,0)
or UDim2_new(1,0,0,TextboxAsset.Title.TextBounds.Y + 2)

TextboxAsset.Background.Position = UDim2_new(0.5,0,0,TextboxAsset.Title.Size.Y.Offset)
TextboxAsset.Size = UDim2_new(1,0,0,TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)
end)
Utility:Event(TextboxAsset.Background.Input:GetPropertyChangedSignal("Text"), function()
local TextBounds = GetTextBounds(
TextboxAsset.Background.Input.Text,
TextboxAsset.Background.Input.Font.Name,
Vector2_new(TextboxAsset.Background.Input.AbsoluteSize.X,TextboxAsset.Background.Input.TextSize)
)

TextboxAsset.Background.Size = UDim2_new(1,0,0,TextBounds.Y + 2)
TextboxAsset.Size = UDim2_new(1,0,0,TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)
end)

Utility:Event(TextboxAsset.Background.Input.Focused, function()
TextboxAsset.Background.Input.Text = Textbox.Value
end)
Utility:Event(TextboxAsset.Background.Input.FocusLost, function(EnterPressed)
local Input = TextboxAsset.Background.Input

Textbox.EnterPressed = EnterPressed
Textbox.Value = Input.Text Textbox.EnterPressed = false
end)

Utility:Event(Textbox:GetPropertyChangedSignal("Name"), function(Name)
TextboxAsset.Title.Text = Name
end)
Utility:Event(Textbox:GetPropertyChangedSignal("Placeholder"), function(PlaceHolder)
TextboxAsset.Background.Input.PlaceholderText = PlaceHolder
end)
Utility:Event(Textbox:GetPropertyChangedSignal("Value"), function(Value)
local Input = TextboxAsset.Background.Input
Input.Text = Textbox.AutoClear and "" or Value
if Textbox.PasswordMode then Input.Text = string_rep(utf8_char(8226),#Input.Text) end

TextboxAsset.Background.Size = UDim2_new(1,0,0,Input.TextSize + 2)
TextboxAsset.Size = UDim2_new(1,0,0,TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)

Window.Flags[Textbox.Flag] = Value
Textbox.Callback(Value,Textbox.EnterPressed)
end)

function Textbox:ToolTip(Text)
Assets:ToolTip(TextboxAsset,ScreenAsset,Text)
end
end
function Assets:Keybind(Parent,ScreenAsset,Window,Keybind)
local KeybindAsset = GetAsset("Keybind/Keybind")
Keybind.WaitingForBind = false

KeybindAsset.Parent = Parent
KeybindAsset.Title.Text = Keybind.Name
KeybindAsset.Value.Text = "[ " .. Keybind.Value .. " ]"

Utility:Event(KeybindAsset.MouseButton1Click, function()
KeybindAsset.Value.Text = "[ ... ]"
Keybind.WaitingForBind = true
end)
Utility:Event(KeybindAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
KeybindAsset.Size = UDim2_new(1,0,0,KeybindAsset.Title.TextBounds.Y)
end)
Utility:Event(KeybindAsset.Value:GetPropertyChangedSignal("TextBounds"), function()
KeybindAsset.Value.Size = UDim2_new(0,KeybindAsset.Value.TextBounds.X,1,0)
KeybindAsset.Title.Size = UDim2_new(1,-KeybindAsset.Value.Size.X.Offset,1,0)
end)

Utility:Event(UserInputService.InputBegan, function(Input)
local Key = Input.KeyCode.Name
if Keybind.WaitingForBind and Input.UserInputType.Name == "Keyboard" then
Keybind.Value = Key
elseif Input.UserInputType.Name == "Keyboard" then
if Key == Keybind.Value then
	Keybind.Toggle = not Keybind.Toggle
	Keybind.Callback(Keybind.Value,true,Keybind.Toggle)
end
end
if Keybind.Mouse then Key = Input.UserInputType.Name
if Keybind.WaitingForBind and (Key == "MouseButton1"
or Key == "MouseButton2" or Key == "MouseButton3") then
Keybind.Value = Key
elseif Key == "MouseButton1"
or Key == "MouseButton2"
or Key == "MouseButton3" then
	if Key == Keybind.Value then
		Keybind.Toggle = not Keybind.Toggle
		Keybind.Callback(Keybind.Value,true,Keybind.Toggle)
	end
end
end
end)
Utility:Event(UserInputService.InputEnded, function(Input)
local Key = Input.KeyCode.Name
if Input.UserInputType.Name == "Keyboard" then
if Key == Keybind.Value then
	Keybind.Callback(Keybind.Value,false,Keybind.Toggle)
end
end
if Keybind.Mouse then Key = Input.UserInputType.Name
if Key == "MouseButton1"
or Key == "MouseButton2"
or Key == "MouseButton3" then
if Key == Keybind.Value then
	Keybind.Callback(Keybind.Value,false,Keybind.Toggle)
end
end
end
end)

Utility:Event(Keybind:GetPropertyChangedSignal("Name"), function(Name)
KeybindAsset.Title.Text = Name
end)
Utility:Event(Keybind:GetPropertyChangedSignal("Value"), function(Value,OldValue)
if table_find(Keybind.Blacklist,Value) then
if Keybind.DoNotClear then
Keybind.Internal.Value = OldValue
Value = OldValue
else
Keybind.Internal.Value = "NONE"
Value = "NONE"
end
end
KeybindAsset.Value.Text = "[ " .. tostring(Value) .. " ]"

Keybind.WaitingForBind = false
Window.Flags[Keybind.Flag] = Value
Keybind.Callback(Value,false,Keybind.Toggle)
end)

function Keybind:ToolTip(Text)
Assets:ToolTip(KeybindAsset,ScreenAsset,Text)
end
end
function Assets:ToggleKeybind(Parent,ScreenAsset,Window,Keybind,Toggle)
local KeybindAsset = GetAsset("Keybind/TKeybind")
Keybind.WaitingForBind = false

KeybindAsset.Parent = Parent
KeybindAsset.Text = "[ " .. Keybind.Value .. " ]"

Utility:Event(KeybindAsset.MouseButton1Click, function()
KeybindAsset.Text = "[ ... ]"
Keybind.WaitingForBind = true
end)
Utility:Event(KeybindAsset:GetPropertyChangedSignal("TextBounds"), function()
KeybindAsset.Size = UDim2_new(0,KeybindAsset.TextBounds.X,1,0)
end)

Utility:Event(UserInputService.InputBegan, function(Input)
local Key = Input.KeyCode.Name
if Keybind.WaitingForBind and Input.UserInputType.Name == "Keyboard" then
Keybind.Value = Key
elseif Input.UserInputType.Name == "Keyboard" then
if Key == Keybind.Value then
if not Keybind.DisableToggle then Toggle.Value = not Toggle.Value end
Keybind.Callback(Keybind.Value,true,Toggle.Value)
end
end
if Keybind.Mouse then Key = Input.UserInputType.Name
if Keybind.WaitingForBind and (Key == "MouseButton1"
or Key == "MouseButton2" or Key == "MouseButton3") then
Keybind.Value = Key
elseif Key == "MouseButton1"
or Key == "MouseButton2"
or Key == "MouseButton3" then
if Key == Keybind.Value then
	if not Keybind.DisableToggle then Toggle.Value = not Toggle.Value end
	Keybind.Callback(Keybind.Value,true,Toggle.Value)
end
end
end
end)
Utility:Event(UserInputService.InputEnded, function(Input)
local Key = Input.KeyCode.Name
if Input.UserInputType.Name == "Keyboard" then
if Key == Keybind.Value then
Keybind.Callback(Keybind.Value,false,Toggle.Value)
end
end
if Keybind.Mouse then Key = Input.UserInputType.Name
if Key == "MouseButton1"
or Key == "MouseButton2"
or Key == "MouseButton3" then
if Key == Keybind.Value then
Keybind.Callback(Keybind.Value,false,Toggle.Value)
end
end
end
end)

Utility:Event(Keybind:GetPropertyChangedSignal("Value"), function(Value,OldValue)
if table_find(Keybind.Blacklist,Value) then
if Keybind.DoNotClear then
Keybind.Internal.Value = OldValue
Value = OldValue
else
Keybind.Internal.Value = "NONE"
Value = "NONE"
end
end
KeybindAsset.Text = "[ " .. tostring(Value) .. " ]"

Keybind.WaitingForBind = false
Window.Flags[Keybind.Flag] = Value
Keybind.Callback(Value,false,Toggle.Value)
end)
end
function Assets:Dropdown(Parent,ScreenAsset,Window,Dropdown)
local OptionContainerAsset = GetAsset("Dropdown/OptionContainer")
local DropdownAsset = GetAsset("Dropdown/Dropdown")

Dropdown.Internal.Value = {}
local ContainerRender = nil

DropdownAsset.Parent = Parent
OptionContainerAsset.Parent = ScreenAsset

DropdownAsset.Title.Text = Dropdown.Name
DropdownAsset.Title.Visible = not Dropdown.HideName

Utility:Event(DropdownAsset.MouseButton1Click, function()
	if not OptionContainerAsset.Visible and OptionContainerAsset.ListLayout.AbsoluteContentSize.Y ~= 0 then
		ContainerRender = RunService.RenderStepped:Connect(function()
			if not OptionContainerAsset.Visible then ContainerRender:Disconnect() end

			OptionContainerAsset.Position = UDim2.fromOffset(
				DropdownAsset.Background.AbsolutePosition.X + 1,
				DropdownAsset.Background.AbsolutePosition.Y + DropdownAsset.Background.AbsoluteSize.Y + 40
			)
			OptionContainerAsset.Size = UDim2.fromOffset(
				DropdownAsset.Background.AbsoluteSize.X,
				math.clamp(OptionContainerAsset.ListLayout.AbsoluteContentSize.Y,16,112) + 4
			)
		end)
		OptionContainerAsset.Visible = true
	else
		OptionContainerAsset.Visible = false
	end
end)
Utility:Event(DropdownAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
DropdownAsset.Title.Size = Dropdown.HideName and UDim2_fromScale(1,0)
or UDim2_new(1,0,0,DropdownAsset.Title.TextBounds.Y + 2)

DropdownAsset.Background.Position = UDim2_new(0.5,0,0,DropdownAsset.Title.Size.Y.Offset)
DropdownAsset.Size = UDim2_new(1,0,0,DropdownAsset.Title.Size.Y.Offset + DropdownAsset.Background.Size.Y.Offset)
end)
Utility:Event(OptionContainerAsset.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
OptionContainerAsset.CanvasSize = UDim2_fromOffset(0,OptionContainerAsset.ListLayout.AbsoluteContentSize.Y + 4)
end)
local function RefreshSelected()
table_clear(Dropdown.Internal.Value)

for Index,Option in pairs(Dropdown.List) do
if Option.Value then
table_insert(Dropdown.Internal.Value,Option.Name)
end
end

Window.Flags[Dropdown.Flag] = Dropdown.Internal.Value
DropdownAsset.Background.Value.Text = #Dropdown.Internal.Value == 0
and "..." or table_concat(Dropdown.Internal.Value,", ")
end

local function SetValue(Option,Value)
Option.Value = Value
Option.ColorConfig[1] = Value
Option.Object.Tick.BackgroundColor3 = Value
and Window.Color or Color3_fromRGB(60,60,60)
end

local function AddOption(Option,AddToList,Order)
Option = GetType(Option,{},"table",true)
Option.Name = GetType(Option.Name,"Option","string")
Option.Mode = GetType(Option.Mode,"Button","string")
Option.Value = GetType(Option.Value,false,"boolean")
Option.Callback = GetType(Option.Callback,function() end,"function")

local OptionAsset = GetAsset("Dropdown/Option")
Option.Object = OptionAsset

OptionAsset.LayoutOrder = Order
OptionAsset.Parent = OptionContainerAsset
OptionAsset.Title.Text = Option.Name
OptionAsset.Tick.BackgroundColor3 = Option.Value
and Window.Color or Color3_fromRGB(60,60,60)

Option.ColorConfig = {Option.Value,"BackgroundColor3"}
Window.Colorable[OptionAsset.Tick] = Option.ColorConfig
if AddToList then table_insert(Dropdown.List,Option) end

Utility:Event(OptionAsset.MouseButton1Click, function()
Option.Value = not Option.Value
end)
Utility:Event(OptionAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
OptionAsset.Layout.Size = UDim2_new(1,-OptionAsset.Title.TextBounds.X - 22,1,0)
end)

Utility:Event(Option:GetPropertyChangedSignal("Name"), function(Name)
OptionAsset.Title.Text = Name
end)
Utility:Event(	Option:GetPropertyChangedSignal("Value"), function(Value)
if Option.Mode == "Button" then
for Index,OldOption in pairs(Dropdown.List) do
SetValue(OldOption.Internal,false)
end Option.Internal.Value = true
Value = Option.Internal.Value
OptionContainerAsset.Visible = false
end

RefreshSelected()
Option.ColorConfig[1] = Value
Option.Object.Tick.BackgroundColor3 = Value
and Window.Color or Color3_fromRGB(60,60,60)
Option.Callback(Dropdown.Value,Option)
end)

for Index,Value in pairs(Option.Internal) do
if string_find(Index,"Colorpicker") then
	Option[Index] = GetType(Option[Index],{},"table",true)
	Option[Index].Flag = GetType(Option[Index].Flag,
	Dropdown.Flag .. "/" .. Option.Name .. "/Colorpicker","string")

	Option[Index].Value = GetType(Option[Index].Value,{1,1,1,0,false},"table")
	Option[Index].Callback = GetType(Option[Index].Callback,function() end,"function")
	Window.Elements[#Window.Elements + 1] = Option[Index]
	Window.Flags[Option[Index].Flag] = Option[Index].Value

	Assets:ToggleColorpicker(OptionAsset.Layout,ScreenAsset,Window,Option[Index])
end
end

return Option
end

for Index,Option in pairs(Dropdown.List) do
Dropdown.List[Index] = AddOption(Option,false,Index)
end for Index,Option in pairs(Dropdown.List) do
if Option.Value then Option.Value = true end
end RefreshSelected()

function Dropdown:BulkAdd(Table)
	for Index,Option in pairs(Table) do
		AddOption(Option,true,Index)
	end
end
function Dropdown:AddOption(Option)
	AddOption(Option,true,#Dropdown.List)
end

function Dropdown:Clear()
	for Index,Option in pairs(Dropdown.List) do
		Option.Object:Destroy()
		end table_clear(Dropdown.List)
	end
	function Dropdown:RemoveOption(Name)
		for Index,Option in pairs(Dropdown.List) do
			if Option.Name == Name then
				Option.Object:Destroy()
				table_remove(Dropdown.List,Index)
			end
		end
		for Index,Option in pairs(Dropdown.List) do
			Option.Object.LayoutOrder = Index
		end
	end
	function Dropdown:RefreshToPlayers(ToggleMode)
		local Players = {}
		for Index,Player in pairs(PlayerService:GetPlayers()) do
			if Player ~= LocalPlayer then
				table_insert(Players,{Name = Player.Name,
				Mode = ToggleMode == "Toggle" or "Button"
			})
		end
	end
	Dropdown:Clear()
	Dropdown:BulkAdd(Players)
end

Utility:Event(Dropdown:GetPropertyChangedSignal("Name"), function(Name)
DropdownAsset.Title.Text = Name
end)
Utility:Event(Dropdown:GetPropertyChangedSignal("Value"), function(Value)
if type(Value) ~= "table" then return end
if #Value == 0 then RefreshSelected() return end

for Index,Option in pairs(Dropdown.List) do
	if table_find(Value,Option.Name) then
		Option.Value = true
	else
		if Option.Mode ~= "Button" then
			Option.Value = false
		end
	end
end
end)

function Dropdown:ToolTip(Text)
	Assets:ToolTip(DropdownAsset,ScreenAsset,Text)
end
end
function Assets:Colorpicker(Parent,ScreenAsset,Window,Colorpicker)
local ColorpickerAsset = GetAsset("Colorpicker/Colorpicker")
local PaletteAsset = GetAsset("Colorpicker/Palette")

Colorpicker.ColorConfig = {Colorpicker.Value[5],"BackgroundColor3"}
Window.Colorable[PaletteAsset.Rainbow.Tick] = Colorpicker.ColorConfig
local PaletteRender,SVRender,HueRender,AlphaRender = nil,nil,nil,nil


ColorpickerAsset.Parent = Parent
PaletteAsset.Parent = ScreenAsset

ColorpickerAsset.Title.Text = Colorpicker.Name
PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
and Window.Color or Color3_fromRGB(60,60,60)


Utility:Event(ColorpickerAsset.Title:GetPropertyChangedSignal("TextBounds"), function()
ColorpickerAsset.Size = UDim2_new(1,0,0,ColorpickerAsset.Title.TextBounds.Y)
end)

Utility:Event(ColorpickerAsset.MouseButton1Click, function()
if not PaletteAsset.Visible then
	PaletteAsset.Visible = true
	PaletteRender = Utility:Event(RunService.RenderStepped, function()
	if not PaletteAsset.Visible then PaletteRender:Disconnect() end
	PaletteAsset.Position = UDim2_fromOffset(
	(ColorpickerAsset.Color.AbsolutePosition.X - PaletteAsset.AbsoluteSize.X) + 21,
	ColorpickerAsset.Color.AbsolutePosition.Y + 50
	)
	end)
else
	PaletteAsset.Visible = false
end
end)

Utility:Event(PaletteAsset.Rainbow.MouseButton1Click, function()
Colorpicker.Value[5] = not Colorpicker.Value[5]
Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
and Window.Color or Color3_fromRGB(60,60,60)
end)
Utility:Event(PaletteAsset.SVPicker.InputBegan, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if SVRender then SVRender:Disconnect() end
	SVRender = Utility:Event(RunService.RenderStepped, function()
	if not PaletteAsset.Visible then SVRender:Disconnect() end
	local Mouse = UserInputService:GetMouseLocation()
	local ColorX = math_clamp(Mouse.X - PaletteAsset.SVPicker.AbsolutePosition.X,0,PaletteAsset.SVPicker.AbsoluteSize.X) / PaletteAsset.SVPicker.AbsoluteSize.X
	local ColorY = math_clamp(Mouse.Y - (PaletteAsset.SVPicker.AbsolutePosition.Y + 36),0,PaletteAsset.SVPicker.AbsoluteSize.Y) / PaletteAsset.SVPicker.AbsoluteSize.Y

	Colorpicker.Value[2] = ColorX
	Colorpicker.Value[3] = 1 - ColorY
	Colorpicker.Value = Colorpicker.Value
	end)
end
end)
Utility:Event(PaletteAsset.SVPicker.InputEnded, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if SVRender then SVRender:Disconnect() end
end
end)
Utility:Event(PaletteAsset.Hue.InputBegan, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if HueRender then HueRender:Disconnect() end
	HueRender = Utility:Event(RunService.RenderStepped, function()
	if not PaletteAsset.Visible then HueRender:Disconnect() end
	local Mouse = UserInputService:GetMouseLocation()
	local ColorX = math_clamp(Mouse.X - PaletteAsset.Hue.AbsolutePosition.X,0,PaletteAsset.Hue.AbsoluteSize.X) / PaletteAsset.Hue.AbsoluteSize.X
	Colorpicker.Value[1] = 1 - ColorX
	Colorpicker.Value = Colorpicker.Value
	end)
end
end)
Utility:Event(PaletteAsset.Hue.InputEnded, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if HueRender then HueRender:Disconnect() end
end
end)
Utility:Event(PaletteAsset.Alpha.InputBegan, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if AlphaRender then AlphaRender:Disconnect() end
	AlphaRender = Utility:Event(RunService.RenderStepped, function()
	if not PaletteAsset.Visible then AlphaRender:Disconnect() end
	local Mouse = UserInputService:GetMouseLocation()
	local ColorX = math_clamp(Mouse.X - PaletteAsset.Alpha.AbsolutePosition.X,0,PaletteAsset.Alpha.AbsoluteSize.X) / PaletteAsset.Alpha.AbsoluteSize.X
	Colorpicker.Value[4] = math_floor(ColorX * 10^2) / (10^2)
	Colorpicker.Value = Colorpicker.Value
	end)
end
end)
Utility:Event(PaletteAsset.Alpha.InputEnded, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if AlphaRender then AlphaRender:Disconnect() end
end
end)

Utility:Event(PaletteAsset.RGB.RGBBox.FocusLost, function(Enter)
if not Enter then return end
local ColorString = string_split(string_gsub(PaletteAsset.RGB.RGBBox.Text," ",""),",")
local Hue,Saturation,Value = Color3_fromRGB(ColorString[1],ColorString[2],ColorString[3]):ToHSV()
PaletteAsset.RGB.RGBBox.Text = ""
Colorpicker.Value[1] = Hue
Colorpicker.Value[2] = Saturation
Colorpicker.Value[3] = Value
Colorpicker.Value = Colorpicker.Value
end)
Utility:Event(PaletteAsset.HEX.HEXBox.FocusLost, function(Enter)
if not Enter then return end
local Hue,Saturation,Value = Color3_fromHex("#" .. PaletteAsset.HEX.HEXBox.Text):ToHSV()
PaletteAsset.RGB.RGBBox.Text = ""
Colorpicker.Value[1] = Hue
Colorpicker.Value[2] = Saturation
Colorpicker.Value[3] = Value
Colorpicker.Value = Colorpicker.Value
end)

Utility:Event(RunService.Heartbeat, function()
if Colorpicker.Value[5] then
	if PaletteAsset.Visible then
		Colorpicker.Value[1] = Window.RainbowHue
		Colorpicker.Value = Colorpicker.Value
	else
		Colorpicker.Value[1] = Window.RainbowHue
		Colorpicker.Value[6] = TableToColor(Colorpicker.Value)
		ColorpickerAsset.Color.BackgroundColor3 = Colorpicker.Value[6]
		Window.Flags[Colorpicker.Flag] = Colorpicker.Value
		Colorpicker.Callback(Colorpicker.Value,Colorpicker.Value[6])
	end
end
end)

Utility:Event(Colorpicker:GetPropertyChangedSignal("Name"), function(Name)
ColorpickerAsset.Title.Text = Name
end)
Utility:Event(Colorpicker:GetPropertyChangedSignal("Value"), function(Value)
Value[6] = TableToColor(Value)
Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
ColorpickerAsset.Color.BackgroundColor3 = Value[6]

PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
and Window.Color or Color3_fromRGB(60,60,60)

PaletteAsset.SVPicker.BackgroundColor3 = Color3_fromHSV(Value[1],1,1)
PaletteAsset.SVPicker.Pin.Position = UDim2_fromScale(Value[2],1 - Value[3])
PaletteAsset.Hue.Pin.Position = UDim2_fromScale(1 - Value[1],0.5)

PaletteAsset.Alpha.Pin.Position = UDim2_fromScale(Value[4],0.5)
PaletteAsset.Alpha.Value.Text = Value[4]
PaletteAsset.Alpha.BackgroundColor3 = Value[6]

PaletteAsset.RGB.RGBBox.PlaceholderText = ColorToString(Value[6])
PaletteAsset.HEX.HEXBox.PlaceholderText = Value[6]:ToHex()
Window.Flags[Colorpicker.Flag] = Value
Colorpicker.Callback(Value,Value[6])
end) Colorpicker.Value = Colorpicker.Value

function Colorpicker:ToolTip(Text)
	Assets:ToolTip(ColorpickerAsset,ScreenAsset,Text)
end
end
function Assets:ToggleColorpicker(Parent,ScreenAsset,Window,Colorpicker)
local ColorpickerAsset = GetAsset("Colorpicker/TColorpicker")
local PaletteAsset = GetAsset("Colorpicker/Palette")

Colorpicker.ColorConfig = {Colorpicker.Value[5],"BackgroundColor3"}
Window.Colorable[PaletteAsset.Rainbow.Tick] = Colorpicker.ColorConfig
local PaletteRender,SVRender,HueRender,AlphaRender = nil,nil,nil,nil

ColorpickerAsset.Parent = Parent
PaletteAsset.Parent = ScreenAsset

PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
and Window.Color or Color3_fromRGB(60,60,60)

Utility:Event(ColorpickerAsset.MouseButton1Click, function()
if not PaletteAsset.Visible then
	PaletteAsset.Visible = true
	PaletteRender = Utility:Event(RunService.RenderStepped, function()
	if not PaletteAsset.Visible then PaletteRender:Disconnect() end
	PaletteAsset.Position = UDim2_fromOffset(
	(ColorpickerAsset.AbsolutePosition.X - PaletteAsset.AbsoluteSize.X) + 21,
	ColorpickerAsset.AbsolutePosition.Y + 50
	)
	end)
else
	PaletteAsset.Visible = false
end
end)

Utility:Event(PaletteAsset.Rainbow.MouseButton1Click, function()
Colorpicker.Value[5] = not Colorpicker.Value[5]
Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
and Window.Color or Color3_fromRGB(60,60,60)
end)
Utility:Event(PaletteAsset.SVPicker.InputBegan, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if SVRender then SVRender:Disconnect() end
	SVRender = Utility:Event(RunService.RenderStepped, function()
	if not PaletteAsset.Visible then SVRender:Disconnect() end
	local Mouse = UserInputService:GetMouseLocation()
	local ColorX = math_clamp(Mouse.X - PaletteAsset.SVPicker.AbsolutePosition.X,0,PaletteAsset.SVPicker.AbsoluteSize.X) / PaletteAsset.SVPicker.AbsoluteSize.X

	local ColorY = math_clamp(Mouse.Y - (PaletteAsset.SVPicker.AbsolutePosition.Y + 36),0,PaletteAsset.SVPicker.AbsoluteSize.Y) / PaletteAsset.SVPicker.AbsoluteSize.Y
	Colorpicker.Value[2] = ColorX
	Colorpicker.Value[3] = 1 - ColorY
	Colorpicker.Value = Colorpicker.Value
	end)
end
end)
Utility:Event(PaletteAsset.SVPicker.InputEnded, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if SVRender then SVRender:Disconnect() end
end
end)
Utility:Event(PaletteAsset.Hue.InputBegan, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if HueRender then HueRender:Disconnect() end
	HueRender = Utility:Event(RunService.RenderStepped, function()
	if not PaletteAsset.Visible then HueRender:Disconnect() end
	local Mouse = UserInputService:GetMouseLocation()
	local ColorX = math_clamp(Mouse.X - PaletteAsset.Hue.AbsolutePosition.X,0,PaletteAsset.Hue.AbsoluteSize.X) / PaletteAsset.Hue.AbsoluteSize.X
	Colorpicker.Value[1] = 1 - ColorX
	Colorpicker.Value = Colorpicker.Value
	end)
end
end)
Utility:Event(PaletteAsset.Hue.InputEnded, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if HueRender then HueRender:Disconnect() end
end
end)
Utility:Event(PaletteAsset.Alpha.InputBegan, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if AlphaRender then AlphaRender:Disconnect() end
	AlphaRender = Utility:Event(RunService.RenderStepped, function()
	if not PaletteAsset.Visible then AlphaRender:Disconnect() end
	local Mouse = UserInputService:GetMouseLocation()
	local ColorX = math_clamp(Mouse.X - PaletteAsset.Alpha.AbsolutePosition.X,0,PaletteAsset.Alpha.AbsoluteSize.X) / PaletteAsset.Alpha.AbsoluteSize.X
	Colorpicker.Value[4] = math_floor(ColorX * 10^2) / (10^2)
	Colorpicker.Value = Colorpicker.Value
	end)
end
end)
Utility:Event(PaletteAsset.Alpha.InputEnded, function(Input)
if Input.UserInputType == Enum.UserInputType.MouseButton1 then
	if AlphaRender then AlphaRender:Disconnect() end
end
end)

Utility:Event(PaletteAsset.RGB.RGBBox.FocusLost, function(Enter)
if not Enter then return end
local ColorString = string_split(string_gsub(PaletteAsset.RGB.RGBBox.Text," ",""),",")
local Hue,Saturation,Value = Color3_fromRGB(ColorString[1],ColorString[2],ColorString[3]):ToHSV()
PaletteAsset.RGB.RGBBox.Text = ""
Colorpicker.Value[1] = Hue
Colorpicker.Value[2] = Saturation
Colorpicker.Value[3] = Value
Colorpicker.Value = Colorpicker.Value
end)
Utility:Event(PaletteAsset.HEX.HEXBox.FocusLost, function(Enter)
if not Enter then return end
local Hue,Saturation,Value = Color3_fromHex("#" .. PaletteAsset.HEX.HEXBox.Text):ToHSV()
PaletteAsset.RGB.RGBBox.Text = ""
Colorpicker.Value[1] = Hue
Colorpicker.Value[2] = Saturation
Colorpicker.Value[3] = Value
Colorpicker.Value = Colorpicker.Value
end)

Utility:Event(RunService.Heartbeat, function()
if Colorpicker.Value[5] then
	if PaletteAsset.Visible then
		Colorpicker.Value[1] = Window.RainbowHue
		Colorpicker.Value = Colorpicker.Value
	else
		Colorpicker.Value[1] = Window.RainbowHue
		Colorpicker.Value[6] = TableToColor(Colorpicker.Value)
		ColorpickerAsset.BackgroundColor3 = Colorpicker.Value[6]
		Window.Flags[Colorpicker.Flag] = Colorpicker.Value
		Colorpicker.Callback(Colorpicker.Value,Colorpicker.Value[6])
	end
end
end)
Utility:Event(Colorpicker:GetPropertyChangedSignal("Value"), function(Value)
Value[6] = TableToColor(Value)
Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
ColorpickerAsset.BackgroundColor3 = Value[6]

PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
and Window.Color or Color3_fromRGB(60,60,60)

PaletteAsset.SVPicker.BackgroundColor3 = Color3_fromHSV(Value[1],1,1)
PaletteAsset.SVPicker.Pin.Position = UDim2_fromScale(Value[2],1 - Value[3])
PaletteAsset.Hue.Pin.Position = UDim2_fromScale(1 - Value[1],0.5)

PaletteAsset.Alpha.Pin.Position = UDim2_fromScale(Value[4],0.5)
PaletteAsset.Alpha.Value.Text = Value[4]
PaletteAsset.Alpha.BackgroundColor3 = Value[6]

PaletteAsset.RGB.RGBBox.PlaceholderText = ColorToString(Value[6])
PaletteAsset.HEX.HEXBox.PlaceholderText = Value[6]:ToHex()
Window.Flags[Colorpicker.Flag] = Value
Colorpicker.Callback(Value,Value[6])
end) Colorpicker.Value = Colorpicker.Value
end

local Bracket = Assets:Screen()
function Bracket:Window(Window)
Window = GetType(Window,{},"table",true)
Window.Blur = GetType(Window.Blur,false,"boolean")
Window.Name = GetType(Window.Name,"Window","string")
Window.Version = GetType(Window.Version,"","string")
Window.Enabled = GetType(Window.Enabled,true,"boolean")
Window.Color = GetType(Window.Color,Color3_new(1,0.5,0.25),"Color3")
Window.Size = GetType(Window.Size,UDim2_new(0,496,0,496),"UDim2")
Window.Position = GetType(Window.Position,UDim2_new(1,-Window.Size.X.Offset - 50,0.5,-(Window.Size.Y.Offset / 2)),"UDim2")
local WindowAsset = Assets:Window(Bracket.ScreenAsset,Window)

function Window:Tab(Tab)
	Tab = GetType(Tab,{},"table",true)
	Tab.Name = GetType(Tab.Name,"Tab","string")
	local TabAsset = Assets:Tab(Bracket.ScreenAsset,WindowAsset,Window,Tab)

	function Tab:AddConfigSection(FolderName,Side)
		local ConfigSection = Tab:Section({Name = "Configs",Side = Side}) do
			local ConfigList,ConfigDropdown = ConfigsToList(FolderName),nil
			local ALConfig = Window:GetAutoLoadConfig(FolderName)

			local function UpdateList(Name) ConfigDropdown:Clear()
				ConfigList = ConfigsToList(FolderName) ConfigDropdown:BulkAdd(ConfigList)
				ConfigDropdown.Value = {}
			end

			local ConfigTextbox = ConfigSection:Textbox({HideName = true,Placeholder = "Config Name",IgnoreFlag = true})
			ConfigSection:Button({Name = "Create",Callback = function()
			Window:SaveConfig(FolderName,ConfigTextbox.Value) UpdateList(ConfigTextbox.Value)
			end})

			ConfigSection:Divider({Text = "Configs"})

			ConfigDropdown = ConfigSection:Dropdown({HideName = true,IgnoreFlag = true,List = ConfigList})

			ConfigSection:Button({Name = "Save",Callback = function()
			if ConfigDropdown.Value and ConfigDropdown.Value[1] then
				Window:SaveConfig(FolderName,ConfigDropdown.Value[1])
			else
				Bracket:Notification({
					Title = "Config System",
					Description = "Select Config First",
					Duration = 10
				})
			end
			end})
			ConfigSection:Button({Name = "Load",Callback = function()
			if ConfigDropdown.Value and ConfigDropdown.Value[1] then
				Window:LoadConfig(FolderName,ConfigDropdown.Value[1])
			else
				Bracket:Notification({
					Title = "Config System",
					Description = "Select Config First",
					Duration = 10
				})
			end
			end})
			ConfigSection:Button({Name = "Delete",Callback = function()
			if ConfigDropdown.Value and ConfigDropdown.Value[1] then
				Window:DeleteConfig(FolderName,ConfigDropdown.Value[1])
				UpdateList()
			else
				Bracket:Notification({
					Title = "Config System",
					Description = "Select Config First",
					Duration = 10
				})
			end
			end})
			ConfigSection:Button({Name = "Refresh",Callback = UpdateList})

			local ConfigDivider = ConfigSection:Divider({Text = not ALConfig and "AutoLoad Config"
			or "AutoLoad Config\n<font color=\"rgb(189,189,189)\">[ " .. ALConfig .. " ]</font>"})

			ConfigSection:Button({Name = "Set AutoLoad Config",Callback = function()
			if ConfigDropdown.Value and ConfigDropdown.Value[1] then
				Window:AddToAutoLoad(FolderName,ConfigDropdown.Value[1])
				ConfigDivider.Text = "AutoLoad Config\n<font color=\"rgb(189,189,189)\">[ " .. ConfigDropdown.Value[1] .. " ]</font>"
			else
				Bracket:Notification({
					Title = "Config System",
					Description = "Select Config First",
					Duration = 10
				})
			end
			end})
			ConfigSection:Button({Name = "Clear AutoLoad Config",Callback = function()
			Window:RemoveFromAutoLoad(FolderName)
			ConfigDivider.Text = "AutoLoad Config"
			end})
		end
	end

	function Tab:Divider(Divider)
		Divider = GetType(Divider,{},"table",true)
		Divider.Text = GetType(Divider.Text,"","string")
		Assets:Divider(ChooseTabSide(TabAsset,Divider.Side),Divider)
		return Divider
	end
	function Tab:Label(Label)
		Label = GetType(Label,{},"table",true)
		Label.Text = GetType(Label.Text,"Label","string")
		Assets:Label(ChooseTabSide(TabAsset,Label.Side),Label)
		return Label
	end
	function Tab:Button(Button)
		Button = GetType(Button,{},"table",true)
		Button.Name = GetType(Button.Name,"Button","string")
		Button.Callback = GetType(Button.Callback,function() end,"function")
		Assets:Button(ChooseTabSide(TabAsset,Button.Side),Bracket.ScreenAsset,Window,Button)
		return Button
	end
	function Tab:Toggle(Toggle)
		Toggle = GetType(Toggle,{},"table",true)
		Toggle.Name = GetType(Toggle.Name,"Toggle","string")
		Toggle.Flag = GetType(Toggle.Flag,Toggle.Name,"string")

		Toggle.Value = GetType(Toggle.Value,false,"boolean")
		Toggle.Callback = GetType(Toggle.Callback,function() end,"function")
		Window.Elements[#Window.Elements + 1] = Toggle
		Window.Flags[Toggle.Flag] = Toggle.Value

		local ToggleAsset = Assets:Toggle(ChooseTabSide(TabAsset,Toggle.Side),Bracket.ScreenAsset,Window,Toggle)
		function Toggle:Keybind(Keybind)
			Keybind = GetType(Keybind,{},"table",true)
			Keybind.Flag = GetType(Keybind.Flag,Toggle.Flag .. "/Keybind","string")

			Keybind.Value = GetType(Keybind.Value,"NONE","string")
			Keybind.Mouse = GetType(Keybind.Mouse,false,"boolean")
			Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
			Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")
			Window.Elements[#Window.Elements + 1] = Keybind
			Window.Flags[Keybind.Flag] = Keybind.Value

			Assets:ToggleKeybind(ToggleAsset.Layout,Bracket.ScreenAsset,Window,Keybind,Toggle)
			return Keybind
		end
		function Toggle:Colorpicker(Colorpicker)
			Colorpicker = GetType(Colorpicker,{},"table",true)
			Colorpicker.Flag = GetType(Colorpicker.Flag,Toggle.Flag .. "/Colorpicker","string")

			Colorpicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"table")
			Colorpicker.Callback = GetType(Colorpicker.Callback,function() end,"function")
			Window.Elements[#Window.Elements + 1] = Colorpicker
			Window.Flags[Colorpicker.Flag] = Colorpicker.Value

			Assets:ToggleColorpicker(ToggleAsset.Layout,Bracket.ScreenAsset,Window,Colorpicker)
			return Colorpicker
		end
		return Toggle
	end
	function Tab:Slider(Slider)
		Slider = GetType(Slider,{},"table",true)
		Slider.Name = GetType(Slider.Name,"Slider","string")
		Slider.Flag = GetType(Slider.Flag,Slider.Name,"string")

		Slider.Min = GetType(Slider.Min,0,"number")
		Slider.Max = GetType(Slider.Max,100,"number")
		Slider.Precise = GetType(Slider.Precise,0,"number")
		Slider.Unit = GetType(Slider.Unit,"","string")
		Slider.Value = GetType(Slider.Value,Slider.Max / 2,"number")
		Slider.Callback = GetType(Slider.Callback,function() end,"function")
		Window.Elements[#Window.Elements + 1] = Slider
		Window.Flags[Slider.Flag] = Slider.Value

		Assets:Slider(ChooseTabSide(TabAsset,Slider.Side),Bracket.ScreenAsset,Window,Slider)
		return Slider
	end
	function Tab:Textbox(Textbox)
		Textbox = GetType(Textbox,{},"table",true)
		Textbox.Name = GetType(Textbox.Name,"Textbox","string")
		Textbox.Flag = GetType(Textbox.Flag,Textbox.Name,"string")

		Textbox.Value = GetType(Textbox.Value,"","string")
		Textbox.NumbersOnly = GetType(Textbox.NumbersOnly,false,"boolean")
		Textbox.Placeholder = GetType(Textbox.Placeholder,"Input here","string")
		Textbox.Callback = GetType(Textbox.Callback,function() end,"function")
		Window.Elements[#Window.Elements + 1] = Textbox
		Window.Flags[Textbox.Flag] = Textbox.Value

		Assets:Textbox(ChooseTabSide(TabAsset,Textbox.Side),Bracket.ScreenAsset,Window,Textbox)
		return Textbox
	end
	function Tab:Keybind(Keybind)
		Keybind = GetType(Keybind,{},"table",true)
		Keybind.Name = GetType(Keybind.Name,"Keybind","string")
		Keybind.Flag = GetType(Keybind.Flag,Keybind.Name,"string")

		Keybind.Value = GetType(Keybind.Value,"NONE","string")
		Keybind.Mouse = GetType(Keybind.Mouse,false,"boolean")
		Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
		Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")
		Window.Elements[#Window.Elements + 1] = Keybind
		Window.Flags[Keybind.Flag] = Keybind.Value

		Assets:Keybind(ChooseTabSide(TabAsset,Keybind.Side),Bracket.ScreenAsset,Window,Keybind)
		return Keybind
	end
	function Tab:Dropdown(Dropdown)
		Dropdown = GetType(Dropdown,{},"table",true)
		Dropdown.Name = GetType(Dropdown.Name,"Dropdown","string")
		Dropdown.Flag = GetType(Dropdown.Flag,Dropdown.Name,"string")
		Dropdown.List = GetType(Dropdown.List,{},"table")
		Window.Elements[#Window.Elements + 1] = Dropdown
		Window.Flags[Dropdown.Flag] = Dropdown.Value

		Assets:Dropdown(ChooseTabSide(TabAsset,Dropdown.Side),Bracket.ScreenAsset,Window,Dropdown)
		return Dropdown
	end
	function Tab:Colorpicker(Colorpicker)
		Colorpicker = GetType(Colorpicker,{},"table",true)
		Colorpicker.Name = GetType(Colorpicker.Name,"Colorpicker","string")
		Colorpicker.Flag = GetType(Colorpicker.Flag,Colorpicker.Name,"string")

		Colorpicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"table")
		Colorpicker.Callback = GetType(Colorpicker.Callback,function() end,"function")
		Window.Elements[#Window.Elements + 1] = Colorpicker
		Window.Flags[Colorpicker.Flag] = Colorpicker.Value

		Assets:Colorpicker(ChooseTabSide(TabAsset,Colorpicker.Side),Bracket.ScreenAsset,Window,Colorpicker)
		return Colorpicker
	end
	function Tab:Section(Section)
		Section = GetType(Section,{},"table",true)
		Section.Name = GetType(Section.Name,"Section","string")
		local SectionContainer = Assets:Section(ChooseTabSide(TabAsset,Section.Side),Section)

		function Section:Divider(Divider)
			Divider = GetType(Divider,{},"table",true)
			Divider.Text = GetType(Divider.Text,"","string")
			Assets:Divider(SectionContainer,Divider)
			return Divider
		end
		function Section:Label(Label)
			Label = GetType(Label,{},"table",true)
			Label.Text = GetType(Label.Text,"Label","string")
			Assets:Label(SectionContainer,Label)
			return Label
		end
		function Section:Button(Button)
			Button = GetType(Button,{},"table",true)
			Button.Name = GetType(Button.Name,"Button","string")
			Button.Callback = GetType(Button.Callback,function() end,"function")
			Assets:Button(SectionContainer,Bracket.ScreenAsset,Window,Button)
			return Button
		end
		function Section:Toggle(Toggle)
			Toggle = GetType(Toggle,{},"table",true)
			Toggle.Name = GetType(Toggle.Name,"Toggle","string")
			Toggle.Flag = GetType(Toggle.Flag,Toggle.Name,"string")

			Toggle.Value = GetType(Toggle.Value,false,"boolean")
			Toggle.Callback = GetType(Toggle.Callback,function() end,"function")
			Window.Elements[#Window.Elements + 1] = Toggle
			Window.Flags[Toggle.Flag] = Toggle.Value

			local ToggleAsset = Assets:Toggle(SectionContainer,Bracket.ScreenAsset,Window,Toggle)
			function Toggle:Keybind(Keybind)
				Keybind = GetType(Keybind,{},"table",true)
				Keybind.Flag = GetType(Keybind.Flag,Toggle.Flag .. "/Keybind","string")

				Keybind.Value = GetType(Keybind.Value,"NONE","string")
				Keybind.Mouse = GetType(Keybind.Mouse,false,"boolean")
				Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
				Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")
				Window.Elements[#Window.Elements + 1] = Keybind
				Window.Flags[Keybind.Flag] = Keybind.Value

				Assets:ToggleKeybind(ToggleAsset.Layout,Bracket.ScreenAsset,Window,Keybind,Toggle)
				return Keybind
			end
			function Toggle:Colorpicker(Colorpicker)
				Colorpicker = GetType(Colorpicker,{},"table",true)
				Colorpicker.Flag = GetType(Colorpicker.Flag,Toggle.Flag .. "/Colorpicker","string")

				Colorpicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"table")
				Colorpicker.Callback = GetType(Colorpicker.Callback,function() end,"function")
				Window.Elements[#Window.Elements + 1] = Colorpicker
				Window.Flags[Colorpicker.Flag] = Colorpicker.Value

				Assets:ToggleColorpicker(ToggleAsset.Layout,Bracket.ScreenAsset,Window,Colorpicker)
				return Colorpicker
			end
			return Toggle
		end
		function Section:Slider(Slider)
			Slider = GetType(Slider,{},"table",true)
			Slider.Name = GetType(Slider.Name,"Slider","string")
			Slider.Flag = GetType(Slider.Flag,Slider.Name,"string")

			Slider.Min = GetType(Slider.Min,0,"number")
			Slider.Max = GetType(Slider.Max,100,"number")
			Slider.Precise = GetType(Slider.Precise,0,"number")
			Slider.Unit = GetType(Slider.Unit,"","string")
			Slider.Value = GetType(Slider.Value,Slider.Max / 2,"number")
			Slider.Callback = GetType(Slider.Callback,function() end,"function")
			Window.Elements[#Window.Elements + 1] = Slider
			Window.Flags[Slider.Flag] = Slider.Value

			Assets:Slider(SectionContainer,Bracket.ScreenAsset,Window,Slider)
			return Slider
		end
		function Section:Textbox(Textbox)
			Textbox = GetType(Textbox,{},"table",true)
			Textbox.Name = GetType(Textbox.Name,"Textbox","string")
			Textbox.Flag = GetType(Textbox.Flag,Textbox.Name,"string")

			Textbox.Value = GetType(Textbox.Value,"","string")
			Textbox.NumbersOnly = GetType(Textbox.NumbersOnly,false,"boolean")
			Textbox.Placeholder = GetType(Textbox.Placeholder,"Input here","string")
			Textbox.Callback = GetType(Textbox.Callback,function() end,"function")
			Window.Elements[#Window.Elements + 1] = Textbox
			Window.Flags[Textbox.Flag] = Textbox.Value

			Assets:Textbox(SectionContainer,Bracket.ScreenAsset,Window,Textbox)
			return Textbox
		end
		function Section:Keybind(Keybind)
			Keybind = GetType(Keybind,{},"table",true)
			Keybind.Name = GetType(Keybind.Name,"Keybind","string")
			Keybind.Flag = GetType(Keybind.Flag,Keybind.Name,"string")

			Keybind.Value = GetType(Keybind.Value,"NONE","string")
			Keybind.Mouse = GetType(Keybind.Mouse,false,"boolean")
			Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
			Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")
			Window.Elements[#Window.Elements + 1] = Keybind
			Window.Flags[Keybind.Flag] = Keybind.Value

			Assets:Keybind(SectionContainer,Bracket.ScreenAsset,Window,Keybind)
			return Keybind
		end
		function Section:Dropdown(Dropdown)
			Dropdown = GetType(Dropdown,{},"table",true)
			Dropdown.Name = GetType(Dropdown.Name,"Dropdown","string")
			Dropdown.Flag = GetType(Dropdown.Flag,Dropdown.Name,"string")
			Dropdown.List = GetType(Dropdown.List,{},"table")
			Window.Elements[#Window.Elements + 1] = Dropdown
			Window.Flags[Dropdown.Flag] = Dropdown.Value

			Assets:Dropdown(SectionContainer,Bracket.ScreenAsset,Window,Dropdown)
			return Dropdown
		end
		function Section:Colorpicker(Colorpicker)
			Colorpicker = GetType(Colorpicker,{},"table",true)
			Colorpicker.Name = GetType(Colorpicker.Name,"Colorpicker","string")
			Colorpicker.Flag = GetType(Colorpicker.Flag,Colorpicker.Name,"string")

			Colorpicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"table")
			Colorpicker.Callback = GetType(Colorpicker.Callback,function() end,"function")
			Window.Elements[#Window.Elements + 1] = Colorpicker
			Window.Flags[Colorpicker.Flag] = Colorpicker.Value

			Assets:Colorpicker(SectionContainer,Bracket.ScreenAsset,Window,Colorpicker)
			return Colorpicker
		end
		return Section
	end
	return Tab
end
return Window
end

function Bracket:Notification(Notification)
Notification = GetType(Notification,{},"table")
Notification.Title = GetType(Notification.Title,"Title","string")
Notification.Description = GetType(Notification.Description,"Description","string")

local NotificationAsset = GetAsset("Notification/ND")
NotificationAsset.Parent = Bracket.ScreenAsset.NDHandle
NotificationAsset.Title.Text = Notification.Title
NotificationAsset.Description.Text = Notification.Description
NotificationAsset.Title.Size = UDim2_new(1,0,0,NotificationAsset.Title.TextBounds.Y)
NotificationAsset.Description.Size = UDim2_new(1,0,0,NotificationAsset.Description.TextBounds.Y)

NotificationAsset.Size = UDim2_fromOffset(
(NotificationAsset.Title.TextBounds.X > NotificationAsset.Description.TextBounds.X
and NotificationAsset.Title.TextBounds.X or NotificationAsset.Description.TextBounds.X) + 24,
NotificationAsset.ListLayout.AbsoluteContentSize.Y + 8
)

if Notification.Duration then
	Utility:Thread(function()
		for Time = Notification.Duration,1,-1 do
			NotificationAsset.Title.Close.Text = Time
			task_wait(1)
		end
		NotificationAsset.Title.Close.Text = 0
		NotificationAsset:Destroy()
		if Notification.Callback then
			Notification.Callback()
		end
	end)
else
	Utility:Event(NotificationAsset.Title.Close.MouseButton1Click, function()
	NotificationAsset:Destroy()
	end)
end
end

function Bracket:Notification2(Notification)
Notification = GetType(Notification,{},"table")
Notification.Title = GetType(Notification.Title,"Title","string")
Notification.Color = GetType(Notification.Color,Color3_new(1,0.5,0.25),"Color3")

local NotificationAsset = GetAsset("Notification/NL")
NotificationAsset.Parent = Bracket.ScreenAsset.NLHandle
NotificationAsset.Main.Title.Text = Notification.Title
NotificationAsset.Main.GLine.BackgroundColor3 = Notification.Color

NotificationAsset.Main.Size = UDim2_fromOffset(
NotificationAsset.Main.Title.TextBounds.X + 10,
NotificationAsset.Main.Title.TextBounds.Y + 6
)
NotificationAsset.Size = UDim2_fromOffset(0,
NotificationAsset.Main.Size.Y.Offset + 4
)
return NotificationAsset
end

local Notifications = {
	Queue = {},
	Last = nil
}
--
function Bracket:QueueNotification(Name, Duration, Color, Callback)
	if Notifications.Last and Notifications.Last.Name == Name then
		Notifications.Last.Count += 1
		Notifications.Last.Tick = tick()
		--
		return
	end
	--
	local Notification = {
		LastCount = 1,
		Count = 1,
		--
		Name = Name,
		Duration = ((Duration or 5) + 0.25),
		Callback = Callback,
		--
		Item = Bracket:Notification2({
			Title = Name,
			Color = (Color or Color3_new(1, 0, 0))
		})
	}
	--
	function Notification:Tween(X, Y, Callback)
		Notification.Item:TweenSize(
			UDim2_fromOffset(X, Y),
			Enum.EasingDirection.InOut,
			Enum.EasingStyle.Linear,
			0.25,false,Callback
		)
	end
	--
	function Notification:Update()
		if Notification.Count ~= Notification.LastCount then
			Notification.Item.Main.Title.Text = (Notification.Name .. " ( " .. Notification.Count .. " )")
			--
			Notification.Item.Main.Size = UDim2_fromOffset(Notification.Item.Main.Title.TextBounds.X + 10, Notification.Item.Main.Title.TextBounds.Y + 6)
			Notification.Item.Size = UDim2_fromOffset(0, Notification.Item.Main.Size.Y.Offset + 4)
			--
			Notification.LastCount = Notification.Count
		end
	end
	--
	Notifications.Last = Notification
	Notifications.Queue[Notification] = true
	--
	Notification:Tween(Notification.Item.Main.Size.X.Offset + 4, Notification.Item.Main.Size.Y.Offset + 4)
end
--
Utility:Event(RunService.Heartbeat, function()
	local Tick = tick()
	--
	for Notification, Value in pairs(Notifications.Queue) do
		if not Notification.Tick then Notification.Tick = Tick end
		--
		Notification:Update()
		--
		if (Tick - Notification.Tick) >= Notification.Duration then
			Notifications.Queue[Notification] = nil
			--
			if Notifications.Last == Notification then
				Notifications.Last = nil
			end
			--
			Notification:Tween(0, Notification.Item.Main.Size.Y.Offset + 4, function()
				Notification.Item:Destroy()
				--
				if Notification.Callback then
					Notification.Callback()
				end
			end)
		end
	end
end)
--
return Bracket, Utility
