class_name MapEditorGUI
extends CanvasLayer


signal restore_btn_pressed
signal cancel_btn_pressed
signal save_map_btn_pressed
signal place_continent_btn_pressed
signal place_other_btn_pressed
signal rt_tab_changed(tab: int)

enum TabStatus {
	PLACE,
	GRID,
}

enum PlaceMode {
	TERRAIN,
	LANDSCAPE,
	WONDER,
	CONTINENT,
	RIVER,
	CLIFF,
	RESOURCE,
	VILLAGE,
}

enum PainterSize {
	SMALL,
	MID,
	BIG,
}

const TERRAIN_NAME_TO_TYPE_DICT: Dictionary = {
	"草原": Map.TerrainType.GRASS,
	"草丘": Map.TerrainType.GRASS_HILL,
	"草山": Map.TerrainType.GRASS_MOUNTAIN,
	"平原": Map.TerrainType.PLAIN,
	"平丘": Map.TerrainType.PLAIN_HILL,
	"平山": Map.TerrainType.PLAIN_MOUNTAIN,
	"沙漠": Map.TerrainType.DESERT,
	"沙丘": Map.TerrainType.DESERT_HILL,
	"沙山": Map.TerrainType.DESERT_MOUNTAIN,
	"冻土": Map.TerrainType.TUNDRA,
	"冻丘": Map.TerrainType.TUNDRA_HILL,
	"冻山": Map.TerrainType.TUNDRA_MOUNTAIN,
	"雪地": Map.TerrainType.SNOW,
	"雪丘": Map.TerrainType.SNOW_HILL,
	"雪山": Map.TerrainType.SNOW_MOUNTAIN,
	"浅水": Map.TerrainType.SHORE,
	"海洋": Map.TerrainType.OCEAN,
}

const PAINTER_NAME_TO_SIZE_DICT: Dictionary = {
	"小笔刷": PainterSize.SMALL,
	"中笔刷": PainterSize.MID,
	"大笔刷": PainterSize.BIG,
}

const LANDSCAPE_NAME_TO_TYPE_DICT: Dictionary = {
	"冰块": Map.LandscapeType.ICE,
	"森林": Map.LandscapeType.FOREST,
	"沼泽": Map.LandscapeType.SWAMP,
	"泛滥": Map.LandscapeType.FLOOD,
	"绿洲": Map.LandscapeType.OASIS,
	"雨林": Map.LandscapeType.RAINFOREST,
}

const RESOURCE_NAME_TO_TYPE_DICT: Dictionary = {
	"丝绸": Map.ResourceType.SILK,
	"历遗": Map.ResourceType.RELIC,
	"可可": Map.ResourceType.COCOA_BEAN,
	"咖啡": Map.ResourceType.COFFEE,
	"大理": Map.ResourceType.MARBLE,
	"大米": Map.ResourceType.RICE,
	"小麦": Map.ResourceType.WHEAT,
	"松露": Map.ResourceType.TRUFFLE,
	"柑橘": Map.ResourceType.ORANGE,
	"染料": Map.ResourceType.DYE,
	"棉花": Map.ResourceType.COTTON,
	"水银": Map.ResourceType.MERCURY,
	"海遗": Map.ResourceType.WRECKAGE,
	"烟草": Map.ResourceType.TOBACCO,
	"煤": Map.ResourceType.COAL,
	"熏香": Map.ResourceType.INCENSE,
	"牛": Map.ResourceType.COW,
	"玉": Map.ResourceType.JADE,
	"玉米": Map.ResourceType.CORN,
	"珍珠": Map.ResourceType.PEARL,
	"皮草": Map.ResourceType.FUR,
	"盐": Map.ResourceType.SALT,
	"石头": Map.ResourceType.STONE,
	"石油": Map.ResourceType.OIL,
	"石膏": Map.ResourceType.GYPSUM,
	"硝石": Map.ResourceType.SALTPETER,
	"糖": Map.ResourceType.SUGAR,
	"羊": Map.ResourceType.SHEEP,
	"茶": Map.ResourceType.TEA,
	"葡萄": Map.ResourceType.WINE,
	"蜂蜜": Map.ResourceType.HONEY,
	"螃蟹": Map.ResourceType.CRAB,
	"象牙": Map.ResourceType.IVORY,
	"钻石": Map.ResourceType.DIAMOND,
	"铀": Map.ResourceType.URANIUM,
	"铁": Map.ResourceType.IRON,
	"铜": Map.ResourceType.COPPER,
	"铝": Map.ResourceType.ALUMINIUM,
	"银": Map.ResourceType.SILVER,
	"香料": Map.ResourceType.SPICE,
	"香蕉": Map.ResourceType.BANANA,
	"马": Map.ResourceType.HORSE,
	"鱼": Map.ResourceType.FISH,
	"鲸鱼": Map.ResourceType.WHALE,
	"鹿": Map.ResourceType.DEER,
}

var place_mode: PlaceMode = PlaceMode.TERRAIN
var place_mode_group: ButtonGroup = null
var terrain_type: Map.TerrainType = Map.TerrainType.GRASS
var terrain_type_group: ButtonGroup = null
var painter_size: PainterSize = PainterSize.SMALL
var painter_size_group: ButtonGroup = null
var landscape_type: Map.LandscapeType = Map.LandscapeType.ICE
var landscape_type_group: ButtonGroup = null
var continent_type: Map.ContinentType = Map.ContinentType.AFRICA
var resource_type: Map.ResourceType = Map.ResourceType.SILK
var resource_type_group: ButtonGroup = null
var mouse_hover_info_showed: bool = false

@onready var info_label: Label = $MarginContainer/RightTopPanelContainer/RtVBoxContainer/TitleVBoxContainer/InfoLabel
@onready var rt_tab: TabContainer = $MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer
# 右边格位面板相关
@onready var grid_coord_label: Label = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/格位/GridContainer/CoordLabel"
# 左上角的选择放置模式的按钮
@onready var terrain_button: Button = $MarginContainer/LeftTopPanelContainer/VBoxContainer/GridContainer/TerrainButton
@onready var landscape_button: Button = $MarginContainer/LeftTopPanelContainer/VBoxContainer/GridContainer/LandscapeButton
@onready var wonder_button: Button = $MarginContainer/LeftTopPanelContainer/VBoxContainer/GridContainer/WonderButton
@onready var continent_button: Button = $MarginContainer/LeftTopPanelContainer/VBoxContainer/GridContainer/ContinentButton
@onready var river_button: Button = $MarginContainer/LeftTopPanelContainer/VBoxContainer/GridContainer/RiverButton
@onready var cliff_button: Button = $MarginContainer/LeftTopPanelContainer/VBoxContainer/GridContainer/CliffButton
@onready var resource_button: Button = $MarginContainer/LeftTopPanelContainer/VBoxContainer/GridContainer/ResourceButton
@onready var village_button: Button = $MarginContainer/LeftTopPanelContainer/VBoxContainer/GridContainer/VillageButton
# 菜单界面相关
@onready var menu_overlay: PanelContainer = $MenuOverlay
# 右下角放置时的容器
@onready var terrain_container: GridContainer = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/TerrainGridContainer"
@onready var landscape_container: GridContainer = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/LandscapeGridContainer"
@onready var wonder_container: GridContainer = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/WonderGridContainer"
@onready var continent_container: VBoxContainer = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/ContinentVBoxContainer"
@onready var river_container: GridContainer = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/RiverGridContainer"
@onready var cliff_container: GridContainer = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/CliffGridContainer"
@onready var resource_container: GridContainer = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/ResourceGridContainer"
@onready var village_container: GridContainer = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/VillageGridContainer"
# 右边选择笔刷大小的按钮
@onready var small_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/EditGridContainer/SmallButton"
# 恢复和取消按钮
@onready var restore_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/EditGridContainer/RestoreButton"
@onready var cancel_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/EditGridContainer/CancelButton"
# 右边放置地形时的按钮
@onready var grass_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/TerrainGridContainer/GrassButton"
# 右边放置地貌时的按钮
@onready var ice_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/LandscapeGridContainer/IceButton"
@onready var forest_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/LandscapeGridContainer/ForestButton"
@onready var swamp_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/LandscapeGridContainer/SwampButton"
@onready var flood_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/LandscapeGridContainer/FloodButton"
@onready var oasis_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/LandscapeGridContainer/OasisButton"
@onready var rainforest_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/LandscapeGridContainer/RainforestButton"
# 右边放置大陆时的按钮
@onready var continent_option_button: OptionButton = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/ContinentVBoxContainer/ContinentOptionButton"
# 右边放置资源时的按钮
@onready var silk_button: Button = $"MarginContainer/RightTopPanelContainer/RtVBoxContainer/TabContainer/放置/ScrollContainer/ResourceGridContainer/SilkButton"
# 鼠标悬停在地块上时显示的面板
@onready var mouse_hover_tile_panel: PanelContainer = $MouseHoverTilePanel
@onready var mouse_hover_tile_label: Label = $MouseHoverTilePanel/MarginContainer/Label


func _ready() -> void:
	place_mode_group = terrain_button.button_group
	place_mode_group.pressed.connect(handle_place_mode_group_pressed)
	terrain_type_group = grass_button.button_group
	terrain_type_group.pressed.connect(handle_terrain_type_group_pressed)
	painter_size_group = small_button.button_group
	painter_size_group.pressed.connect(handle_painter_size_group_pressed)
	landscape_type_group = ice_button.button_group
	landscape_type_group.pressed.connect(handle_landscape_type_group_pressed)
	continent_option_button.item_selected.connect(handle_continent_item_selected)
	resource_type_group = silk_button.button_group
	resource_type_group.pressed.connect(handle_resource_type_group_pressed)
	# 初始为放置面板
	rt_tab.current_tab = 0
	rt_tab.tab_changed.connect(handle_rt_tab_changed)
	# 初始化右下角放置界面
	disvisible_all_place_container()
	terrain_container.visible = true
	# 初始化恢复和取消按钮
	restore_button.disabled = true
	cancel_button.disabled = true
	# 菜单界面不显示
	menu_overlay.visible = false
	# 鼠标悬停面板不显示
	hide_mouse_hover_tile_info()
	# 经常重新打开项目时，Git 提交里就显示这个值就没了，不是自定义（-1）了，就离谱
	# 为了避免哪天不小心提交了，所以强制指定一下
	mouse_hover_tile_panel.anchors_preset = -1


func _process(delta: float) -> void:
	if mouse_hover_info_showed:
		var mouse_posi: Vector2 = get_viewport().get_mouse_position()
		# TODO: 目前如果只在右下角显示的话，当鼠标在窗口右下角可能看不到提示。
		# 未来可以加个根据坐标相对窗口的位置决定悬浮面板位置的逻辑
		mouse_hover_tile_panel.offset_left = mouse_posi.x + 10
		mouse_hover_tile_panel.offset_top = mouse_posi.y + 10


func disvisible_all_place_container() -> void:
	terrain_container.visible = false
	landscape_container.visible = false
	wonder_container.visible = false
	continent_container.visible = false
	river_container.visible = false
	cliff_container.visible = false
	resource_container.visible = false
	village_container.visible = false


func handle_rt_tab_changed(tab: int) -> void:
	rt_tab_changed.emit(tab)
	if tab == 0:
		# 切换放置，格位相关信息需要还原
		grid_coord_label.text = "无"
		# TODO: 其他格位信息


func update_grid_info(coord: Vector2i, tile_info: Map.TileInfo) -> void:
	grid_coord_label.text = str(coord)
	# TODO: 其他格位信息


func show_mouse_hover_tile_info(map_coord: Vector2i, tile_info: Map.TileInfo) -> void:
	mouse_hover_info_showed = true
	mouse_hover_tile_panel.visible = true
	mouse_hover_tile_label.text = Map.TERRAIN_TYPE_TO_NAME_DICT[tile_info.type]
	if tile_info.landscape != Map.LandscapeType.EMPTY:
		mouse_hover_tile_label.text += "\n" + Map.LANDSCAPE_TYPE_TO_NAME_DICT[tile_info.landscape]
	if tile_info.village == 1:
		mouse_hover_tile_label.text += "\n部落村庄"
	if tile_info.resource != Map.ResourceType.EMPTY:
		mouse_hover_tile_label.text += "\n" + Map.RESOURCE_TYPE_TO_NAME_DICT[tile_info.resource]
	if tile_info.type != Map.TerrainType.SHORE and tile_info.type != Map.TerrainType.OCEAN:
		mouse_hover_tile_label.text += "\n大陆：" + Map.CONTINENT_TYPE_TO_NAME_DICT[tile_info.continent]
	mouse_hover_tile_label.text += "\n---------------"
	mouse_hover_tile_label.text += "\nHex " + str(map_coord)
	
	var mouse_posi: Vector2 = get_viewport().get_mouse_position()
	mouse_hover_tile_panel.offset_left = mouse_posi.x
	mouse_hover_tile_panel.offset_top = mouse_posi.y


func hide_mouse_hover_tile_info() -> void:
	mouse_hover_info_showed = false
	mouse_hover_tile_panel.visible = false


func handle_place_mode_group_pressed(button: BaseButton) -> void:
	disvisible_all_place_container()
	match button:
		terrain_button:
			place_mode = PlaceMode.TERRAIN
			terrain_container.visible = true
			place_other_btn_pressed.emit()
		landscape_button:
			place_mode = PlaceMode.LANDSCAPE
			landscape_container.visible = true
			place_other_btn_pressed.emit()
		wonder_button:
			place_mode = PlaceMode.WONDER
			wonder_container.visible = true
			place_other_btn_pressed.emit()
		continent_button:
			place_mode = PlaceMode.CONTINENT
			continent_container.visible = true
			place_continent_btn_pressed.emit()
		river_button:
			place_mode = PlaceMode.RIVER
			river_container.visible = true
			place_other_btn_pressed.emit()
		cliff_button:
			place_mode = PlaceMode.CLIFF
			cliff_container.visible = true
			place_other_btn_pressed.emit()
		resource_button:
			place_mode = PlaceMode.RESOURCE
			resource_container.visible = true
			place_other_btn_pressed.emit()
		village_button:
			place_mode = PlaceMode.VILLAGE
			village_container.visible = true
			place_other_btn_pressed.emit()
		_:
			printerr("wrong button in place mode group")


func handle_terrain_type_group_pressed(button: BaseButton) -> void:
	var btn := button as Button
	if not TERRAIN_NAME_TO_TYPE_DICT.has(btn.text):
		printerr("handle_terrain_type_group_pressed | wrong button in terrain type group")
		return
	terrain_type = TERRAIN_NAME_TO_TYPE_DICT[btn.text]


func handle_painter_size_group_pressed(button: BaseButton) -> void:
	var btn := button as Button
	if not PAINTER_NAME_TO_SIZE_DICT.has(btn.text):
		printerr("handle_painter_size_group_pressed | wrong button in painter size group")
		return
	painter_size = PAINTER_NAME_TO_SIZE_DICT[btn.text]


func handle_landscape_type_group_pressed(button: BaseButton) -> void:
	var btn := button as Button
	if not LANDSCAPE_NAME_TO_TYPE_DICT.has(btn.text):
		printerr("handle_landscape_type_group_pressed | wrong button in landscape type group")
		return
	landscape_type = LANDSCAPE_NAME_TO_TYPE_DICT[btn.text]


func handle_continent_item_selected(idx: int) -> void:
	# 直接默认大陆选择按钮的个数和枚举个数是一一对应的，暂时不校验
	continent_type = idx + 1


func handle_resource_type_group_pressed(button: BaseButton) -> void:
	var btn := button as Button
	if not RESOURCE_NAME_TO_TYPE_DICT.has(btn.text):
		printerr("handle_resource_type_group_pressed | wrong button in resource type group")
		return
	resource_type = RESOURCE_NAME_TO_TYPE_DICT[btn.text]


func get_painter_size_dist() -> int:
	match painter_size:
		PainterSize.SMALL:
			return 0
		PainterSize.MID:
			return 1
		PainterSize.BIG:
			return 2
		_:
			printerr("unknown painter size")
			return -1


func get_rt_tab_status() -> TabStatus:
	if rt_tab.current_tab == 0:
		return TabStatus.PLACE
	else:
		return TabStatus.GRID


func set_info_label_text(text: String) -> void:
	info_label.text = text


func set_restore_button_disable(b: bool) -> void:
	restore_button.disabled = b


func set_cancel_button_disable(b: bool) -> void:
	cancel_button.disabled = b


## 点击右边栏“恢复”按钮
func _on_restore_button_pressed() -> void:
	restore_btn_pressed.emit()


## 点击右边栏“取消”按钮
func _on_cancel_button_pressed() -> void:
	cancel_btn_pressed.emit()


## 点击右上角菜单按钮
func _on_menu_button_pressed() -> void:
	menu_overlay.visible = true


## 点击菜单页面“返回到地图”
func _on_return_button_pressed() -> void:
	menu_overlay.visible = false


## 点击菜单页面“返回主菜单”
func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


## 点击菜单页面“返回桌面”
func _on_desktop_button_pressed() -> void:
	get_tree().quit()


## 点击菜单页面“保存地图”
func _on_save_button_pressed() -> void:
	save_map_btn_pressed.emit()
