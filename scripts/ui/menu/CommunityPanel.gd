extends Control
class_name CommunityPanel

# --- Theme Colors (High Contrast & Rhythia Theme Alignment) ---
const COLOR_BG = Color(0.06, 0.04, 0.09, 0.98)
const COLOR_HEADER_BG = Color(0.11, 0.08, 0.17, 0.95)
const COLOR_CARD_BG = Color(0.13, 0.095, 0.20, 0.95)
const COLOR_CARD_BG_HOVER = Color(0.18, 0.13, 0.27, 0.98)
const COLOR_CARD_BORDER = Color(0.42, 0.32, 0.58, 0.85)
const COLOR_CARD_BORDER_HOVER = Color(0.78, 0.55, 1.0, 0.95)

const COLOR_PINNED_BG = Color(0.20, 0.15, 0.08, 0.95)
const COLOR_PINNED_BORDER = Color(0.95, 0.78, 0.28, 0.90)
const COLOR_PINNED_BADGE = Color(0.98, 0.82, 0.30, 1.0)

const COLOR_PRIMARY = Color(0.55, 0.25, 0.88, 1.0)
const COLOR_PRIMARY_HOVER = Color(0.68, 0.38, 1.0, 1.0)
const COLOR_PRIMARY_PRESSED = Color(0.44, 0.18, 0.72, 1.0)

const COLOR_SECONDARY = Color(0.20, 0.15, 0.30, 0.95)
const COLOR_SECONDARY_HOVER = Color(0.28, 0.22, 0.42, 1.0)
const COLOR_SECONDARY_BORDER = Color(0.42, 0.32, 0.58, 0.85)

const COLOR_SUCCESS = Color(0.30, 0.88, 0.52, 1.0)
const COLOR_WARNING = Color(0.98, 0.76, 0.25, 1.0)
const COLOR_DANGER = Color(0.95, 0.32, 0.40, 1.0)
const COLOR_HEART = Color(0.98, 0.38, 0.52, 1.0)
const COLOR_ACCENT_CYAN = Color(0.35, 0.88, 1.0, 1.0)

# High contrast text colors (Ensure full readability on dark backgrounds)
const COLOR_TEXT_TITLE = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_TEXT_BODY = Color(0.94, 0.92, 0.98, 1.0)
const COLOR_TEXT_MUTED = Color(0.80, 0.76, 0.88, 1.0)
const COLOR_TEXT_ACCENT = Color(0.88, 0.72, 1.0, 1.0)

# --- Compatibility Fields (preserved from original) ---
var status_label:Label
var feed_list:VBoxContainer
var username_edit:LineEdit
var display_name_edit:LineEdit
var password_edit:LineEdit
var account_label:Label
var post_title_edit:LineEdit
var post_body_edit:TextEdit
var publish_button:Button

# --- UI References ---
var _is_ui_built:bool = false
var _status_dot:ColorRect
var _account_chip_btn:Button
var _tab_buttons:Array[Button] = []
var _tab_views:Array[Control] = []
var _current_tab:int = 0

# Feed tab
var _feed_search_edit:LineEdit
var _feed_filter_buttons:Array[Button] = []
var _feed_current_filter:String = "all"
var _raw_posts:Array = []
var _feed_empty_card:Control

# Maps tab
var _maps_list:VBoxContainer
var _maps_search_edit:LineEdit
var _maps_diff_selector:OptionButton
var _maps_sort_selector:OptionButton
var _raw_maps:Array = []
var _maps_empty_card:Control

# Publish tab
var _title_count_label:Label
var _body_count_label:Label
var _publish_alert_label:Label
var _publish_auth_warning:Control

# Account tab
var _login_container:Control
var _register_container:Control
var _profile_container:Control
var _account_alert_label:Label
var _reg_username_edit:LineEdit
var _reg_display_name_edit:LineEdit
var _reg_password_edit:LineEdit
var _reg_password_confirm_edit:LineEdit
var _my_posts_list:VBoxContainer
var _account_sub_tab_btn_login:Button
var _account_sub_tab_btn_reg:Button

func _init():
	if !_is_ui_built:
		_build_ui()
		_is_ui_built = true

func _ready():
	if !_is_ui_built:
		_build_ui()
		_is_ui_built = true
	Community.connect("auth_changed", Callable(self, "_update_account_state"))
	_update_account_state()
	refresh_feed()
	refresh_maps()

# ==============================================================================
# UI Building
# ==============================================================================

func _build_ui():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Background dark panel
	var bg_panel = Panel.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(bg_panel)

	# Main margin container
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# 1. Top Header
	_build_header(root)

	# 2. Sleek Tab Navigation Bar
	_build_tab_bar(root)

	# 3. View Containers Stack
	var views_container = PanelContainer.new()
	views_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var views_style = StyleBoxFlat.new()
	views_style.bg_color = Color(0.04, 0.03, 0.07, 0.70)
	views_style.corner_radius_top_left = 10
	views_style.corner_radius_top_right = 10
	views_style.corner_radius_bottom_right = 10
	views_style.corner_radius_bottom_left = 10
	views_style.border_width_left = 1
	views_style.border_width_top = 1
	views_style.border_width_right = 1
	views_style.border_width_bottom = 1
	views_style.border_color = Color(0.28, 0.22, 0.40, 0.60)
	views_container.add_theme_stylebox_override("panel", views_style)
	root.add_child(views_container)

	var views_margin = MarginContainer.new()
	views_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	views_margin.add_theme_constant_override("margin_left", 6)
	views_margin.add_theme_constant_override("margin_top", 6)
	views_margin.add_theme_constant_override("margin_right", 6)
	views_margin.add_theme_constant_override("margin_bottom", 6)
	views_container.add_child(views_margin)

	# Stack 4 Tab Views
	var view_feed = _build_feed_view()
	var view_maps = _build_maps_view()
	var view_publish = _build_publish_view()
	var view_account = _build_account_view()

	views_margin.add_child(view_feed)
	views_margin.add_child(view_maps)
	views_margin.add_child(view_publish)
	views_margin.add_child(view_account)

	_tab_views = [view_feed, view_maps, view_publish, view_account]
	_switch_tab(0)

# ------------------------------------------------------------------------------
# 1. Header
# ------------------------------------------------------------------------------

func _build_header(parent:Node):
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	parent.add_child(header)

	# Title & subtitle
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	title_box.add_child(title_row)

	var title = Label.new()
	title.text = "Rhythia 中文社区"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	title_row.add_child(title)

	var beta_tag = _create_badge("Community Hub", COLOR_PRIMARY, Color.WHITE)
	title_row.add_child(beta_tag)

	var subtitle = Label.new()
	subtitle.text = "动态分享 · 精选谱面 · 交流互动"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	title_box.add_child(subtitle)

	# Right Header Controls
	var right_box = HBoxContainer.new()
	right_box.add_theme_constant_override("separation", 10)
	header.add_child(right_box)

	# Status indicator pill
	var status_chip = PanelContainer.new()
	status_chip.add_theme_stylebox_override("panel", _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 16, 1))
	right_box.add_child(status_chip)

	var status_margin = MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 12)
	status_margin.add_theme_constant_override("margin_right", 12)
	status_margin.add_theme_constant_override("margin_top", 6)
	status_margin.add_theme_constant_override("margin_bottom", 6)
	status_chip.add_child(status_margin)

	var status_hbox = HBoxContainer.new()
	status_hbox.add_theme_constant_override("separation", 8)
	status_margin.add_child(status_hbox)

	_status_dot = ColorRect.new()
	_status_dot.custom_minimum_size = Vector2(8, 8)
	_status_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_dot.color = COLOR_WARNING
	status_hbox.add_child(_status_dot)

	status_label = Label.new()
	status_label.text = "正在连接..."
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", COLOR_TEXT_BODY)
	status_hbox.add_child(status_label)

	# Account chip button (clicks jump to account tab)
	_account_chip_btn = Button.new()
	_account_chip_btn.text = "未登录 (点击登录)"
	_account_chip_btn.add_theme_font_size_override("font_size", 13)
	_style_button(_account_chip_btn, false, false, 32)
	_account_chip_btn.pressed.connect(func(): _switch_tab(3))
	right_box.add_child(_account_chip_btn)

	# Refresh button
	var refresh_button = Button.new()
	refresh_button.text = "刷新"
	refresh_button.add_theme_font_size_override("font_size", 13)
	_style_button(refresh_button, true, false, 32)
	refresh_button.pressed.connect(refresh_feed)
	refresh_button.pressed.connect(refresh_maps)
	right_box.add_child(refresh_button)

# ------------------------------------------------------------------------------
# 2. Navigation Tab Bar (Clean Text Without Emojis)
# ------------------------------------------------------------------------------

func _build_tab_bar(parent:Node):
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 10)
	parent.add_child(tab_bar)

	var tab_titles = ["社区动态", "精选谱面", "发布动态", "个人中心"]

	_tab_buttons.clear()
	for i in range(tab_titles.size()):
		var title_text = tab_titles[i]
		var btn = Button.new()
		btn.text = title_text
		btn.add_theme_font_size_override("font_size", 14)
		btn.custom_minimum_size = Vector2(120, 36)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var idx = i
		btn.pressed.connect(func(): _switch_tab(idx))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

	_update_tab_buttons_visual()

func _switch_tab(index:int):
	_current_tab = index
	for i in range(_tab_views.size()):
		_tab_views[i].visible = (i == index)
	_update_tab_buttons_visual()

	if index == 0:
		_filter_and_display_posts()
	elif index == 1:
		_filter_and_display_maps()
	elif index == 3:
		_refresh_account_profile_view()

func _update_tab_buttons_visual():
	for i in range(_tab_buttons.size()):
		var btn = _tab_buttons[i]
		var is_active = (i == _current_tab)
		var sb_norm = StyleBoxFlat.new()
		sb_norm.corner_radius_top_left = 8
		sb_norm.corner_radius_top_right = 8
		sb_norm.corner_radius_bottom_right = 8
		sb_norm.corner_radius_bottom_left = 8
		sb_norm.border_width_left = 1
		sb_norm.border_width_top = 1
		sb_norm.border_width_right = 1

		if is_active:
			sb_norm.bg_color = COLOR_PRIMARY
			sb_norm.border_color = COLOR_ACCENT_CYAN
			sb_norm.border_width_bottom = 3
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
			btn.add_theme_color_override("font_pressed_color", Color.WHITE)
			btn.add_theme_color_override("font_focus_color", Color.WHITE)
		else:
			sb_norm.bg_color = COLOR_SECONDARY
			sb_norm.border_color = COLOR_SECONDARY_BORDER
			sb_norm.border_width_bottom = 1
			btn.add_theme_color_override("font_color", Color(0.94, 0.92, 0.98))
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
			btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
			btn.add_theme_color_override("font_focus_color", Color.WHITE)

		btn.add_theme_stylebox_override("normal", sb_norm)

		var sb_hover = sb_norm.duplicate()
		sb_hover.bg_color = COLOR_PRIMARY_HOVER if is_active else COLOR_SECONDARY_HOVER
		btn.add_theme_stylebox_override("hover", sb_hover)

# ------------------------------------------------------------------------------
# 3. View 0: 社区动态 (Feed View)
# ------------------------------------------------------------------------------

func _build_feed_view() -> Control:
	var view = VBoxContainer.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.add_theme_constant_override("separation", 10)

	# Sub toolbar: filters & search & quick post button
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	view.add_child(toolbar)

	# Filter pills
	var filters = [
		{"key": "all", "label": "全部"},
		{"key": "pinned", "label": "置顶"},
		{"key": "map", "label": "谱面"},
		{"key": "chat", "label": "讨论"}
	]
	_feed_filter_buttons.clear()
	for f in filters:
		var f_btn = Button.new()
		f_btn.text = f.label
		f_btn.add_theme_font_size_override("font_size", 12)
		f_btn.custom_minimum_size = Vector2(56, 28)
		_style_pill_button(f_btn, f.key == _feed_current_filter)
		var k = f.key
		f_btn.pressed.connect(func():
			_feed_current_filter = k
			_update_feed_filter_buttons()
			_filter_and_display_posts()
		)
		toolbar.add_child(f_btn)
		_feed_filter_buttons.append(f_btn)

	# Search input
	_feed_search_edit = LineEdit.new()
	_feed_search_edit.placeholder_text = "搜索动态标题、正文、作者..."
	_feed_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feed_search_edit.add_theme_font_size_override("font_size", 13)
	_style_input(_feed_search_edit, 30)
	_feed_search_edit.text_changed.connect(func(_t): _filter_and_display_posts())
	toolbar.add_child(_feed_search_edit)

	# Quick post button
	var quick_post_btn = Button.new()
	quick_post_btn.text = "发布动态"
	quick_post_btn.add_theme_font_size_override("font_size", 13)
	_style_button(quick_post_btn, true, false, 30)
	quick_post_btn.pressed.connect(func(): _switch_tab(2))
	toolbar.add_child(quick_post_btn)

	# Feed Scroll Container
	var feed_scroll = ScrollContainer.new()
	feed_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feed_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	view.add_child(feed_scroll)

	feed_list = VBoxContainer.new()
	feed_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_list.add_theme_constant_override("separation", 10)
	feed_scroll.add_child(feed_list)

	# Empty state card
	_feed_empty_card = _create_empty_state_card("暂无动态", "成为第一个在社区分享心得或自制谱面的玩家吧！", "发布动态", func(): _switch_tab(2))
	feed_list.add_child(_feed_empty_card)
	_feed_empty_card.visible = false

	return view

func _update_feed_filter_buttons():
	var keys = ["all", "pinned", "map", "chat"]
	for i in range(_feed_filter_buttons.size()):
		var f_btn = _feed_filter_buttons[i]
		_style_pill_button(f_btn, keys[i] == _feed_current_filter)

# ------------------------------------------------------------------------------
# 4. View 1: 社区谱面 (Maps View)
# ------------------------------------------------------------------------------

func _build_maps_view() -> Control:
	var view = VBoxContainer.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.add_theme_constant_override("separation", 10)

	# Sub toolbar
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	view.add_child(toolbar)

	_maps_search_edit = LineEdit.new()
	_maps_search_edit.placeholder_text = "搜索谱面名、歌曲名或谱师..."
	_maps_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_maps_search_edit.add_theme_font_size_override("font_size", 13)
	_style_input(_maps_search_edit, 30)
	_maps_search_edit.text_changed.connect(func(_t): _filter_and_display_maps())
	toolbar.add_child(_maps_search_edit)

	# Difficulty filter
	_maps_diff_selector = OptionButton.new()
	_maps_diff_selector.add_item("全部难度")
	_maps_diff_selector.add_item("Easy (1)")
	_maps_diff_selector.add_item("Medium (2)")
	_maps_diff_selector.add_item("Hard (3)")
	_maps_diff_selector.add_item("Expert (4+)")
	_maps_diff_selector.add_theme_font_size_override("font_size", 12)
	_style_button(_maps_diff_selector, false, false, 30)
	_maps_diff_selector.item_selected.connect(func(_idx): _filter_and_display_maps())
	toolbar.add_child(_maps_diff_selector)

	# Sort selector
	_maps_sort_selector = OptionButton.new()
	_maps_sort_selector.add_item("最新上传")
	_maps_sort_selector.add_item("难度从高到低")
	_maps_sort_selector.add_item("难度从低到高")
	_maps_sort_selector.add_theme_font_size_override("font_size", 12)
	_style_button(_maps_sort_selector, false, false, 30)
	_maps_sort_selector.item_selected.connect(func(_idx): _filter_and_display_maps())
	toolbar.add_child(_maps_sort_selector)

	# Maps list scroll
	var maps_scroll = ScrollContainer.new()
	maps_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	maps_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	view.add_child(maps_scroll)

	_maps_list = VBoxContainer.new()
	_maps_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_maps_list.add_theme_constant_override("separation", 10)
	maps_scroll.add_child(_maps_list)

	_maps_empty_card = _create_empty_state_card("暂无谱面", "社区尚未收录匹配条件的谱面，敬请期待！", "刷新谱面", refresh_maps)
	_maps_list.add_child(_maps_empty_card)
	_maps_empty_card.visible = false

	return view

# ------------------------------------------------------------------------------
# 5. View 2: 发布动态 (Publish View)
# ------------------------------------------------------------------------------

func _build_publish_view() -> Control:
	var view = ScrollContainer.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	view.add_child(content)

	# Not logged in banner warning
	_publish_auth_warning = PanelContainer.new()
	_publish_auth_warning.add_theme_stylebox_override("panel", _create_card_style(Color(0.28, 0.20, 0.08, 0.95), COLOR_WARNING, 8, 1))
	content.add_child(_publish_auth_warning)

	var auth_warn_margin = MarginContainer.new()
	auth_warn_margin.add_theme_constant_override("margin_left", 14)
	auth_warn_margin.add_theme_constant_override("margin_right", 14)
	auth_warn_margin.add_theme_constant_override("margin_top", 10)
	auth_warn_margin.add_theme_constant_override("margin_bottom", 10)
	_publish_auth_warning.add_child(auth_warn_margin)

	var auth_warn_box = HBoxContainer.new()
	auth_warn_box.add_theme_constant_override("separation", 10)
	auth_warn_margin.add_child(auth_warn_box)

	var auth_warn_label = Label.new()
	auth_warn_label.text = "[提示] 您当前未登录社区账号，发布动态需要登录后进行。"
	auth_warn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auth_warn_label.add_theme_color_override("font_color", COLOR_WARNING)
	auth_warn_label.add_theme_font_size_override("font_size", 13)
	auth_warn_box.add_child(auth_warn_label)

	var go_login_btn = Button.new()
	go_login_btn.text = "前往登录"
	_style_button(go_login_btn, true, false, 28)
	go_login_btn.pressed.connect(func(): _switch_tab(3))
	auth_warn_box.add_child(go_login_btn)

	# Composer card
	var composer_card = PanelContainer.new()
	composer_card.add_theme_stylebox_override("panel", _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 10, 1))
	content.add_child(composer_card)

	var composer_margin = MarginContainer.new()
	composer_margin.add_theme_constant_override("margin_left", 20)
	composer_margin.add_theme_constant_override("margin_right", 20)
	composer_margin.add_theme_constant_override("margin_top", 16)
	composer_margin.add_theme_constant_override("margin_bottom", 16)
	composer_card.add_child(composer_margin)

	var form_box = VBoxContainer.new()
	form_box.add_theme_constant_override("separation", 12)
	composer_margin.add_child(form_box)

	var form_title = Label.new()
	form_title.text = "分享你的动态或谱面心得"
	form_title.add_theme_font_size_override("font_size", 18)
	form_title.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	form_box.add_child(form_title)

	# Quick Category Tag Row
	var tag_row = HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 8)
	form_box.add_child(tag_row)

	var tag_title = Label.new()
	tag_title.text = "快捷分类："
	tag_title.add_theme_font_size_override("font_size", 12)
	tag_title.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	tag_row.add_child(tag_title)

	var tags = ["[日常讨论]", "[谱面分享]", "[玩法心得]", "[求助提问]", "[社区建议]"]
	for t in tags:
		var t_btn = Button.new()
		t_btn.text = t
		t_btn.add_theme_font_size_override("font_size", 11)
		_style_pill_button(t_btn, false)
		var tag_str = t
		t_btn.pressed.connect(func():
			if !post_title_edit.text.begins_with(tag_str):
				for ot in tags:
					if post_title_edit.text.begins_with(ot):
						post_title_edit.text = post_title_edit.text.trim_prefix(ot).strip_edges()
				post_title_edit.text = tag_str + " " + post_title_edit.text.strip_edges()
				_on_post_title_changed(post_title_edit.text)
		)
		tag_row.add_child(t_btn)

	# Title Input with counter
	var title_header_row = HBoxContainer.new()
	form_box.add_child(title_header_row)

	var title_lbl = Label.new()
	title_lbl.text = "动态标题"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_header_row.add_child(title_lbl)

	_title_count_label = Label.new()
	_title_count_label.text = "0 / 100"
	_title_count_label.add_theme_font_size_override("font_size", 11)
	_title_count_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	title_header_row.add_child(_title_count_label)

	post_title_edit = LineEdit.new()
	post_title_edit.placeholder_text = "请输入标题 (简洁清晰)..."
	post_title_edit.max_length = 100
	_style_input(post_title_edit, 36)
	post_title_edit.text_changed.connect(_on_post_title_changed)
	form_box.add_child(post_title_edit)

	# Body Input with counter
	var body_header_row = HBoxContainer.new()
	form_box.add_child(body_header_row)

	var body_lbl = Label.new()
	body_lbl.text = "动态内容"
	body_lbl.add_theme_font_size_override("font_size", 13)
	body_lbl.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_header_row.add_child(body_lbl)

	_body_count_label = Label.new()
	_body_count_label.text = "0 / 2000"
	_body_count_label.add_theme_font_size_override("font_size", 11)
	_body_count_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	body_header_row.add_child(_body_count_label)

	post_body_edit = TextEdit.new()
	post_body_edit.placeholder_text = "在这里写下你的动态内容...\n• 分享你在 Rhythia 中的游玩心得、喜爱的谱面、成绩截图记录\n• 交流自制谱面的节奏设计与手感技巧\n• 遵守社区公约，友好文明交流"
	post_body_edit.custom_minimum_size = Vector2(0, 200)
	_style_text_edit(post_body_edit)
	post_body_edit.text_changed.connect(_on_post_body_changed)
	form_box.add_child(post_body_edit)

	# Guidelines callout
	var guide_box = PanelContainer.new()
	guide_box.add_theme_stylebox_override("panel", _create_card_style(Color(0.14, 0.18, 0.28, 0.8), Color(0.35, 0.55, 0.85, 0.7), 6, 1))
	form_box.add_child(guide_box)

	var guide_margin = MarginContainer.new()
	guide_margin.add_theme_constant_override("margin_left", 12)
	guide_margin.add_theme_constant_override("margin_right", 12)
	guide_margin.add_theme_constant_override("margin_top", 8)
	guide_margin.add_theme_constant_override("margin_bottom", 8)
	guide_box.add_child(guide_margin)

	var guide_text = Label.new()
	guide_text.text = "[社区守则] 文明发言，互相尊重；分享谱面时请附带谱面名称及难度；禁止发布违规广告或辱骂言论。"
	guide_text.add_theme_font_size_override("font_size", 11)
	guide_text.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	guide_margin.add_child(guide_text)

	# Action Row
	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 12)
	form_box.add_child(action_row)

	_publish_alert_label = Label.new()
	_publish_alert_label.text = ""
	_publish_alert_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_publish_alert_label.add_theme_font_size_override("font_size", 13)
	action_row.add_child(_publish_alert_label)

	var clear_btn = Button.new()
	clear_btn.text = "清空"
	_style_button(clear_btn, false, false, 36)
	clear_btn.pressed.connect(func():
		post_title_edit.clear()
		post_body_edit.text = ""
		_on_post_title_changed("")
		_on_post_body_changed()
		_publish_alert_label.text = ""
	)
	action_row.add_child(clear_btn)

	publish_button = Button.new()
	publish_button.text = "立即发布"
	publish_button.custom_minimum_size = Vector2(130, 36)
	_style_button(publish_button, true, false, 36)
	publish_button.pressed.connect(_publish_post)
	action_row.add_child(publish_button)

	return view

func _on_post_title_changed(new_text:String):
	if _title_count_label:
		_title_count_label.text = "%d / 100" % new_text.length()

func _on_post_body_changed():
	if _body_count_label and post_body_edit:
		_body_count_label.text = "%d / 2000" % post_body_edit.text.length()

# ------------------------------------------------------------------------------
# 6. View 3: 个人中心 (Account View)
# ------------------------------------------------------------------------------

func _build_account_view() -> Control:
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	# Global Account Alert Banner
	_account_alert_label = Label.new()
	_account_alert_label.text = ""
	_account_alert_label.visible = false
	_account_alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_account_alert_label.add_theme_font_size_override("font_size", 13)
	content.add_child(_account_alert_label)

	# Compatibility account_label
	account_label = Label.new()
	account_label.visible = false
	content.add_child(account_label)

	# Container for NOT logged in (Login & Register Cards)
	var auth_box = VBoxContainer.new()
	auth_box.name = "AuthBox"
	auth_box.add_theme_constant_override("separation", 12)
	content.add_child(auth_box)

	# Segmented Mode Switcher (登录 / 注册)
	var auth_mode_row = HBoxContainer.new()
	auth_mode_row.add_theme_constant_override("separation", 8)
	auth_box.add_child(auth_mode_row)

	_account_sub_tab_btn_login = Button.new()
	_account_sub_tab_btn_login.text = "账号登录"
	_account_sub_tab_btn_login.custom_minimum_size = Vector2(110, 32)
	_style_pill_button(_account_sub_tab_btn_login, true)
	_account_sub_tab_btn_login.pressed.connect(func(): _switch_auth_sub_tab(true))
	auth_mode_row.add_child(_account_sub_tab_btn_login)

	_account_sub_tab_btn_reg = Button.new()
	_account_sub_tab_btn_reg.text = "注册新账号"
	_account_sub_tab_btn_reg.custom_minimum_size = Vector2(110, 32)
	_style_pill_button(_account_sub_tab_btn_reg, false)
	_account_sub_tab_btn_reg.pressed.connect(func(): _switch_auth_sub_tab(false))
	auth_mode_row.add_child(_account_sub_tab_btn_reg)

	# --- Login Card ---
	_login_container = PanelContainer.new()
	_login_container.add_theme_stylebox_override("panel", _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 10, 1))
	auth_box.add_child(_login_container)

	var login_margin = MarginContainer.new()
	login_margin.add_theme_constant_override("margin_left", 24)
	login_margin.add_theme_constant_override("margin_right", 24)
	login_margin.add_theme_constant_override("margin_top", 18)
	login_margin.add_theme_constant_override("margin_bottom", 18)
	_login_container.add_child(login_margin)

	var login_form = VBoxContainer.new()
	login_form.add_theme_constant_override("separation", 12)
	login_margin.add_child(login_form)

	var login_title = Label.new()
	login_title.text = "欢迎登录 Rhythia 社区账号"
	login_title.add_theme_font_size_override("font_size", 18)
	login_title.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	login_form.add_child(login_title)

	var login_desc = Label.new()
	login_desc.text = "登录后畅享社区发帖、点赞与评论互动。"
	login_desc.add_theme_font_size_override("font_size", 12)
	login_desc.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	login_form.add_child(login_desc)

	username_edit = LineEdit.new()
	username_edit.placeholder_text = "用户名"
	username_edit.max_length = 24
	_style_input(username_edit, 36)
	login_form.add_child(username_edit)

	password_edit = LineEdit.new()
	password_edit.placeholder_text = "密码"
	password_edit.secret = true
	_style_input(password_edit, 36)
	password_edit.text_submitted.connect(func(_t): _login())
	login_form.add_child(password_edit)

	var login_btn = Button.new()
	login_btn.text = "立即登录"
	_style_button(login_btn, true, false, 36)
	login_btn.pressed.connect(_login)
	login_form.add_child(login_btn)

	# --- Register Card ---
	_register_container = PanelContainer.new()
	_register_container.add_theme_stylebox_override("panel", _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 10, 1))
	auth_box.add_child(_register_container)
	_register_container.visible = false

	var reg_margin = MarginContainer.new()
	reg_margin.add_theme_constant_override("margin_left", 24)
	reg_margin.add_theme_constant_override("margin_right", 24)
	reg_margin.add_theme_constant_override("margin_top", 18)
	reg_margin.add_theme_constant_override("margin_bottom", 18)
	_register_container.add_child(reg_margin)

	var reg_form = VBoxContainer.new()
	reg_form.add_theme_constant_override("separation", 12)
	reg_margin.add_child(reg_form)

	var reg_title = Label.new()
	reg_title.text = "注册新账号"
	reg_title.add_theme_font_size_override("font_size", 18)
	reg_title.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	reg_form.add_child(reg_title)

	var reg_desc = Label.new()
	reg_desc.text = "加入 Rhythia 玩家社区，与大家一同分享节奏的快乐。"
	reg_desc.add_theme_font_size_override("font_size", 12)
	reg_desc.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	reg_form.add_child(reg_desc)

	_reg_username_edit = LineEdit.new()
	_reg_username_edit.placeholder_text = "用户名 (3-24位英文字母或数字，用于登录)"
	_reg_username_edit.max_length = 24
	_style_input(_reg_username_edit, 36)
	reg_form.add_child(_reg_username_edit)

	_reg_display_name_edit = LineEdit.new()
	_reg_display_name_edit.placeholder_text = "玩家昵称 (公开展示名称，最多40字)"
	_reg_display_name_edit.max_length = 40
	_style_input(_reg_display_name_edit, 36)
	reg_form.add_child(_reg_display_name_edit)
	display_name_edit = _reg_display_name_edit

	_reg_password_edit = LineEdit.new()
	_reg_password_edit.placeholder_text = "设置密码 (至少6位)"
	_reg_password_edit.secret = true
	_style_input(_reg_password_edit, 36)
	reg_form.add_child(_reg_password_edit)

	_reg_password_confirm_edit = LineEdit.new()
	_reg_password_confirm_edit.placeholder_text = "确认密码"
	_reg_password_confirm_edit.secret = true
	_style_input(_reg_password_confirm_edit, 36)
	_reg_password_confirm_edit.text_submitted.connect(func(_t): _register())
	reg_form.add_child(_reg_password_confirm_edit)

	var reg_btn = Button.new()
	reg_btn.text = "创建新账号"
	_style_button(reg_btn, true, false, 36)
	reg_btn.pressed.connect(_register)
	reg_form.add_child(reg_btn)

	# --- Logged In Profile Container ---
	_profile_container = VBoxContainer.new()
	_profile_container.add_theme_constant_override("separation", 14)
	content.add_child(_profile_container)
	_profile_container.visible = false

	return scroll

func _switch_auth_sub_tab(is_login:bool):
	_login_container.visible = is_login
	_register_container.visible = !is_login
	_style_pill_button(_account_sub_tab_btn_login, is_login)
	_style_pill_button(_account_sub_tab_btn_reg, !is_login)
	_set_account_alert("", false)

func _refresh_account_profile_view():
	_clear_children(_profile_container)
	if !Community.is_logged_in():
		return

	var u = Community.current_user
	var display_name = u.get("display_name", u.get("username", "玩家"))
	var username = u.get("username", "")
	var role = u.get("role", "member")
	var role_name = "管理员" if (role == "admin" or role == "moderator") else "社区玩家"

	# 1. Profile Card
	var profile_card = PanelContainer.new()
	profile_card.add_theme_stylebox_override("panel", _create_card_style(COLOR_CARD_BG, COLOR_PRIMARY, 12, 1))
	_profile_container.add_child(profile_card)

	var p_margin = MarginContainer.new()
	p_margin.add_theme_constant_override("margin_left", 20)
	p_margin.add_theme_constant_override("margin_right", 20)
	p_margin.add_theme_constant_override("margin_top", 16)
	p_margin.add_theme_constant_override("margin_bottom", 16)
	profile_card.add_child(p_margin)

	var p_hbox = HBoxContainer.new()
	p_hbox.add_theme_constant_override("separation", 16)
	p_margin.add_child(p_hbox)

	# Avatar
	var avatar = _create_avatar_box(display_name, 56)
	p_hbox.add_child(avatar)

	# User Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	p_hbox.add_child(info_vbox)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	info_vbox.add_child(name_row)

	var name_lbl = Label.new()
	name_lbl.text = display_name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	name_row.add_child(name_lbl)

	var role_badge = _create_badge(role_name, COLOR_PRIMARY, Color.WHITE)
	name_row.add_child(role_badge)

	var user_lbl = Label.new()
	user_lbl.text = "@%s · 在线" % username
	user_lbl.add_theme_font_size_override("font_size", 12)
	user_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	info_vbox.add_child(user_lbl)

	# Profile Actions
	var action_vbox = VBoxContainer.new()
	action_vbox.add_theme_constant_override("separation", 6)
	p_hbox.add_child(action_vbox)

	var refresh_u_btn = Button.new()
	refresh_u_btn.text = "刷新资料"
	_style_button(refresh_u_btn, false, false, 30)
	refresh_u_btn.pressed.connect(func():
		await Community.refresh_user()
		_update_account_state()
		_refresh_account_profile_view()
	)
	action_vbox.add_child(refresh_u_btn)

	var logout_btn = Button.new()
	logout_btn.text = "退出登录"
	_style_button(logout_btn, false, true, 30)
	logout_btn.pressed.connect(_logout)
	action_vbox.add_child(logout_btn)

	# 2. My Posts Section
	var my_posts_header = HBoxContainer.new()
	_profile_container.add_child(my_posts_header)

	var my_posts_title = Label.new()
	my_posts_title.text = "我的社区动态"
	my_posts_title.add_theme_font_size_override("font_size", 16)
	my_posts_title.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	my_posts_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_posts_header.add_child(my_posts_title)

	_my_posts_list = VBoxContainer.new()
	_my_posts_list.add_theme_constant_override("separation", 8)
	_profile_container.add_child(_my_posts_list)

	_load_my_posts()

func _load_my_posts():
	_clear_children(_my_posts_list)
	var loading_lbl = Label.new()
	loading_lbl.text = "正在加载我的动态..."
	loading_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	_my_posts_list.add_child(loading_lbl)

	var res = await Community.get_my_posts()
	_clear_children(_my_posts_list)
	if !res.get("ok", false):
		var err_lbl = Label.new()
		err_lbl.text = "加载动态失败: " + _error_message(res)
		err_lbl.add_theme_color_override("font_color", COLOR_DANGER)
		_my_posts_list.add_child(err_lbl)
		return

	var items = res.get("items", [])
	if items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "您尚未发布过动态。前往“发布动态”分享你的第一条动态吧！"
		empty_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		_my_posts_list.add_child(empty_lbl)
		return

	for p in items:
		var p_card = PanelContainer.new()
		p_card.add_theme_stylebox_override("panel", _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 8, 1))
		_my_posts_list.add_child(p_card)

		var m = MarginContainer.new()
		m.add_theme_constant_override("margin_left", 14)
		m.add_theme_constant_override("margin_right", 14)
		m.add_theme_constant_override("margin_top", 10)
		m.add_theme_constant_override("margin_bottom", 10)
		p_card.add_child(m)

		var h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		m.add_child(h)

		var v = VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)

		var t = Label.new()
		t.text = String(p.get("title", "未命名"))
		t.add_theme_font_size_override("font_size", 15)
		t.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
		v.add_child(t)

		var meta = Label.new()
		meta.text = "%s · %s 赞 · %s 评论" % [
			_format_time(String(p.get("created_at", ""))),
			p.get("like_count", 0),
			p.get("comment_count", 0)
		]
		meta.add_theme_font_size_override("font_size", 12)
		meta.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		v.add_child(meta)

		var del_btn = Button.new()
		del_btn.text = "删除"
		_style_button(del_btn, false, true, 28)
		var post_id = p.get("id")
		del_btn.pressed.connect(func():
			del_btn.disabled = true
			var d_res = await Community.delete_post(post_id)
			if d_res.get("ok", false):
				_load_my_posts()
				refresh_feed()
			else:
				del_btn.disabled = false
		)
		h.add_child(del_btn)

# ==============================================================================
# Data Loading & Feed Rendering
# ==============================================================================

func refresh_feed():
	_clear_children(feed_list)
	if !Community.is_configured():
		_set_status_state("未配置", COLOR_DANGER)
		_feed_empty_card = _create_empty_state_card("社区服务未配置", "请在 project.godot 中配置 application/networking/community_api。", "", Callable())
		feed_list.add_child(_feed_empty_card)
		_feed_empty_card.visible = true
		return

	_set_status_state("正在加载...", COLOR_WARNING)
	var response = await Community.get_posts(1, 50)
	if !response.get("ok", false):
		var err_msg = _error_message(response)
		_set_status_state("连接失败", COLOR_DANGER)
		_clear_children(feed_list)
		_feed_empty_card = _create_empty_state_card("加载失败", err_msg, "重新加载", refresh_feed)
		feed_list.add_child(_feed_empty_card)
		_feed_empty_card.visible = true
		return

	_set_status_state("已连接", COLOR_SUCCESS)
	_raw_posts = response.get("items", [])
	_filter_and_display_posts()

func _filter_and_display_posts():
	if !is_instance_valid(feed_list):
		return
	_clear_children(feed_list)

	var q = _feed_search_edit.text.strip_edges().to_lower() if _feed_search_edit else ""
	var filtered:Array = []

	for post in _raw_posts:
		var title = String(post.get("title", "")).to_lower()
		var body = String(post.get("body", "")).to_lower()
		var author = String(post.get("display_name", post.get("username", ""))).to_lower()
		var is_pinned = post.get("pinned", false)

		# Category check
		if _feed_current_filter == "pinned" and !is_pinned:
			continue
		elif _feed_current_filter == "map" and !title.contains("谱面") and !body.contains("谱面"):
			continue
		elif _feed_current_filter == "chat" and (title.contains("谱面") or is_pinned):
			continue

		# Search check
		if q != "" and !title.contains(q) and !body.contains(q) and !author.contains(q):
			continue

		filtered.append(post)

	if filtered.is_empty():
		var desc = "没有找到符合条件的动态。" if (q != "" or _feed_current_filter != "all") else "社区中还没有动态，快来发布第一条吧！"
		_feed_empty_card = _create_empty_state_card("暂无动态", desc, "发布动态", func(): _switch_tab(2))
		feed_list.add_child(_feed_empty_card)
		_feed_empty_card.visible = true
		return

	for post in filtered:
		_add_post_card(post)

func _add_post_card(post:Dictionary):
	var is_pinned = post.get("pinned", false)
	var post_id = post.get("id")

	var card = PanelContainer.new()
	var bg = COLOR_PINNED_BG if is_pinned else COLOR_CARD_BG
	var border = COLOR_PINNED_BORDER if is_pinned else COLOR_CARD_BORDER
	card.add_theme_stylebox_override("panel", _create_card_style(bg, border, 10, 1))
	feed_list.add_child(card)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# --- Header Row ---
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var author_name = String(post.get("display_name", post.get("username", "玩家")))
	var username = String(post.get("username", ""))
	var avatar = _create_avatar_box(author_name, 36)
	header.add_child(avatar)

	var author_vbox = VBoxContainer.new()
	author_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	author_vbox.add_theme_constant_override("separation", 2)
	header.add_child(author_vbox)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	author_vbox.add_child(name_row)

	var author_lbl = Label.new()
	author_lbl.text = author_name
	author_lbl.add_theme_font_size_override("font_size", 14)
	author_lbl.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	name_row.add_child(author_lbl)

	if username != "":
		var user_lbl = Label.new()
		user_lbl.text = "@" + username
		user_lbl.add_theme_font_size_override("font_size", 12)
		user_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		name_row.add_child(user_lbl)

	var time_lbl = Label.new()
	time_lbl.text = _format_time(String(post.get("created_at", "")))
	time_lbl.add_theme_font_size_override("font_size", 11)
	time_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	author_vbox.add_child(time_lbl)

	# Badges (Pinned / Category)
	if is_pinned:
		var pinned_badge = _create_badge("[置顶公告]", COLOR_PINNED_BADGE, Color(0.12, 0.08, 0.02))
		header.add_child(pinned_badge)

	# Delete button if own post
	if Community.is_logged_in() and String(Community.current_user.get("username", "")) == username:
		var del_btn = Button.new()
		del_btn.text = "删除"
		del_btn.tooltip_text = "删除此动态"
		_style_button(del_btn, false, true, 26)
		del_btn.pressed.connect(func():
			del_btn.disabled = true
			var res = await Community.delete_post(post_id)
			if res.get("ok", false):
				refresh_feed()
		)
		header.add_child(del_btn)

	# --- Post Content ---
	var title = Label.new()
	title.text = String(post.get("title", ""))
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	var body = Label.new()
	body.text = String(post.get("body", ""))
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", COLOR_TEXT_BODY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body)

	# --- Post Footer / Action Bar ---
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	vbox.add_child(actions)

	var like_count:int = int(post.get("like_count", 0))
	var is_liked:bool = post.get("liked", false)
	var like_btn = Button.new()
	_update_like_button_visual(like_btn, is_liked, like_count)
	like_btn.pressed.connect(func():
		if !Community.is_logged_in():
			_set_status_state("请先登录社区账号", COLOR_WARNING)
			return
		like_btn.disabled = true
		var res = await Community.toggle_post_like(post_id)
		like_btn.disabled = false
		if res.get("ok", false):
			var new_liked = res.get("liked", !is_liked)
			like_count += 1 if new_liked else -1
			is_liked = new_liked
			_update_like_button_visual(like_btn, is_liked, max(0, like_count))
	)
	actions.add_child(like_btn)

	var comment_count:int = int(post.get("comment_count", 0))
	var comment_btn = Button.new()
	comment_btn.text = "评论 (%d)" % comment_count
	comment_btn.add_theme_font_size_override("font_size", 12)
	_style_button(comment_btn, false, false, 28)
	actions.add_child(comment_btn)

	var report_btn = Button.new()
	report_btn.text = "举报"
	report_btn.add_theme_font_size_override("font_size", 12)
	_style_button(report_btn, false, false, 28)
	report_btn.pressed.connect(func():
		if !Community.is_logged_in():
			_set_status_state("请先登录社区账号", COLOR_WARNING)
			return
		report_btn.disabled = true
		var r_res = await Community.report("post", String(post_id), "违规举报", "用户在动态中提交了举报。")
		report_btn.text = "已举报" if r_res.get("ok", false) else "举报失败"
	)
	actions.add_child(report_btn)

	# In-card Comment Drawer (collapsible)
	var comment_drawer = VBoxContainer.new()
	comment_drawer.visible = false
	comment_drawer.add_theme_constant_override("separation", 8)
	vbox.add_child(comment_drawer)

	var sep = HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.25)
	comment_drawer.add_child(sep)

	var comment_list_box = VBoxContainer.new()
	comment_list_box.add_theme_constant_override("separation", 6)
	comment_drawer.add_child(comment_list_box)

	var comment_input_row = HBoxContainer.new()
	comment_input_row.add_theme_constant_override("separation", 8)
	comment_drawer.add_child(comment_input_row)

	var comment_edit = LineEdit.new()
	comment_edit.placeholder_text = "写下你的评论..."
	comment_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_input(comment_edit, 30)
	comment_input_row.add_child(comment_edit)

	var comment_send_btn = Button.new()
	comment_send_btn.text = "发送"
	_style_button(comment_send_btn, true, false, 30)
	comment_input_row.add_child(comment_send_btn)

	# Toggle comment drawer on button click
	comment_btn.pressed.connect(func():
		comment_drawer.visible = !comment_drawer.visible
		if comment_drawer.visible:
			_load_comments_for_post(post_id, comment_list_box)
	)

	var send_comment_action = func():
		var txt = comment_edit.text.strip_edges()
		if txt.is_empty():
			return
		if !Community.is_logged_in():
			_set_status_state("请先登录社区账号", COLOR_WARNING)
			return
		comment_send_btn.disabled = true
		var c_res = await Community.create_comment("post", String(post_id), txt)
		comment_send_btn.disabled = false
		if c_res.get("ok", false):
			comment_edit.clear()
			comment_count += 1
			comment_btn.text = "评论 (%d)" % comment_count
			_load_comments_for_post(post_id, comment_list_box)
		else:
			_set_status_state(_error_message(c_res), COLOR_DANGER)

	comment_send_btn.pressed.connect(send_comment_action)
	comment_edit.text_submitted.connect(func(_t): send_comment_action.call())

func _load_comments_for_post(post_id, container:Node):
	_clear_children(container)
	var loading = Label.new()
	loading.text = "正在加载评论..."
	loading.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	loading.add_theme_font_size_override("font_size", 12)
	container.add_child(loading)

	var res = await Community.get_comments("post", String(post_id))
	_clear_children(container)
	if !res.get("ok", false):
		var err = Label.new()
		err.text = "评论加载失败"
		err.add_theme_color_override("font_color", COLOR_DANGER)
		err.add_theme_font_size_override("font_size", 12)
		container.add_child(err)
		return

	var items = res.get("items", [])
	if items.is_empty():
		var empty = Label.new()
		empty.text = "暂无评论，留下第一条想法吧~"
		empty.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		empty.add_theme_font_size_override("font_size", 12)
		container.add_child(empty)
		return

	for c in items:
		var c_row = HBoxContainer.new()
		c_row.add_theme_constant_override("separation", 6)
		container.add_child(c_row)

		var c_author = Label.new()
		c_author.text = "%s:" % c.get("display_name", c.get("username", "玩家"))
		c_author.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
		c_author.add_theme_font_size_override("font_size", 12)
		c_row.add_child(c_author)

		var c_body = Label.new()
		c_body.text = String(c.get("body", ""))
		c_body.add_theme_color_override("font_color", COLOR_TEXT_BODY)
		c_body.add_theme_font_size_override("font_size", 12)
		c_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		c_row.add_child(c_body)

		var c_time = Label.new()
		c_time.text = _format_time(String(c.get("created_at", "")))
		c_time.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		c_time.add_theme_font_size_override("font_size", 10)
		c_row.add_child(c_time)

func _update_like_button_visual(btn:Button, liked:bool, count:int):
	btn.text = "已赞 (%d)" % count if liked else "点赞 (%d)" % count
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_focus_color", Color.WHITE)

	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1

	if liked:
		sb.bg_color = Color(0.85, 0.25, 0.40, 0.90)
		sb.border_color = Color(1.0, 0.50, 0.65, 0.95)
	else:
		sb.bg_color = COLOR_SECONDARY
		sb.border_color = COLOR_SECONDARY_BORDER
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.95, 0.35, 0.50, 0.98) if liked else COLOR_SECONDARY_HOVER
	btn.add_theme_stylebox_override("hover", sb_hover)

# ==============================================================================
# Community Maps View Logic
# ==============================================================================

func refresh_maps():
	if !is_instance_valid(_maps_list):
		return
	_clear_children(_maps_list)
	if !Community.is_configured():
		return

	# First try to load maps from Community home or maps endpoint
	var res = await Community.get_home()
	if res.get("ok", false) and res.has("maps") and res.maps.size() > 0:
		_raw_maps = res.maps
		_filter_and_display_maps()
		return

	# Fallback to get_maps endpoint
	var maps_res = await Community.get_maps(1, 100)
	if maps_res.get("ok", false):
		_raw_maps = maps_res.get("items", [])
		_filter_and_display_maps()
	else:
		_filter_and_display_maps()

func _filter_and_display_maps():
	if !is_instance_valid(_maps_list):
		return
	_clear_children(_maps_list)

	var q = _maps_search_edit.text.strip_edges().to_lower() if _maps_search_edit else ""
	var diff_filter = _maps_diff_selector.selected - 1 if _maps_diff_selector else -1 # 0: all, 1: diff 1, etc.
	var sort_idx = _maps_sort_selector.selected if _maps_sort_selector else 0

	var filtered:Array = []
	for m in _raw_maps:
		var name_str = String(m.get("name", "")).to_lower()
		var song_str = String(m.get("song", "")).to_lower()
		var author_str = String(m.get("author", "")).to_lower()
		var diff = int(m.get("difficulty", 1))

		if diff_filter >= 0 and diff != (diff_filter + 1):
			continue
		if q != "" and !name_str.contains(q) and !song_str.contains(q) and !author_str.contains(q):
			continue

		filtered.append(m)

	# Sorting
	if sort_idx == 1: # High to low
		filtered.sort_custom(func(a, b): return int(a.get("difficulty", 0)) > int(b.get("difficulty", 0)))
	elif sort_idx == 2: # Low to high
		filtered.sort_custom(func(a, b): return int(a.get("difficulty", 0)) < int(b.get("difficulty", 0)))

	if filtered.is_empty():
		_maps_empty_card = _create_empty_state_card("暂无匹配谱面", "没有找到符合搜索条件的社区谱面。", "重新加载", refresh_maps)
		_maps_list.add_child(_maps_empty_card)
		_maps_empty_card.visible = true
		return

	for m in filtered:
		_add_map_card(m)

func _add_map_card(map_data:Dictionary):
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 10, 1))
	_maps_list.add_child(card)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	# Difficulty Badge (Color-coded)
	var diff = int(map_data.get("difficulty", 1))
	var diff_color = COLOR_SUCCESS
	if diff == 2:
		diff_color = COLOR_ACCENT_CYAN
	elif diff == 3:
		diff_color = COLOR_WARNING
	elif diff >= 4:
		diff_color = COLOR_DANGER

	var diff_badge = PanelContainer.new()
	diff_badge.custom_minimum_size = Vector2(56, 48)
	diff_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var diff_sb = StyleBoxFlat.new()
	diff_sb.bg_color = diff_color
	diff_sb.corner_radius_top_left = 8
	diff_sb.corner_radius_top_right = 8
	diff_sb.corner_radius_bottom_right = 8
	diff_sb.corner_radius_bottom_left = 8
	diff_badge.add_theme_stylebox_override("panel", diff_sb)
	hbox.add_child(diff_badge)

	var diff_lbl = Label.new()
	diff_lbl.text = "Lv. %d" % diff
	diff_lbl.add_theme_font_size_override("font_size", 13)
	diff_lbl.add_theme_color_override("font_color", Color.BLACK)
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	diff_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	diff_badge.add_child(diff_lbl)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)

	var map_title = Label.new()
	map_title.text = String(map_data.get("name", map_data.get("song", "未知谱面")))
	map_title.add_theme_font_size_override("font_size", 16)
	map_title.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	info_vbox.add_child(map_title)

	var meta_row = Label.new()
	meta_row.text = "曲师: %s · 谱师: %s" % [map_data.get("song", "未知"), map_data.get("author", "未知")]
	meta_row.add_theme_font_size_override("font_size", 12)
	meta_row.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	info_vbox.add_child(meta_row)

	var stats_row = Label.new()
	var dls = map_data.get("download_count", map_data.get("downloads", 0))
	var rating = map_data.get("rating_avg", 5.0)
	stats_row.text = "下载: %s 次 · 评分: %.1f · 谱面ID: %s" % [dls, rating, map_data.get("id", "")]
	stats_row.add_theme_font_size_override("font_size", 11)
	stats_row.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	info_vbox.add_child(stats_row)

	# Action: Play in Song Menu
	var play_btn = Button.new()
	play_btn.text = "在选曲列表中游玩"
	play_btn.add_theme_font_size_override("font_size", 12)
	_style_button(play_btn, true, false, 32)
	var map_id = map_data.get("id", "")
	var map_name = String(map_data.get("name", "社区谱面"))
	play_btn.pressed.connect(func():
		_jump_to_community_map(map_id, map_name)
	)
	hbox.add_child(play_btn)

func _jump_to_community_map(map_id:String, map_name:String):
	Rhythia.last_map_source = "community"
	Globals.notify(Globals.NOTIFY_INFO, "正在定位社区谱面: " + map_name, "社区选曲")
	# Switch to Maps Menu (Page 0 in Sidebar)
	var sidebar = get_node_or_null("../../Sidebar")
	if sidebar and sidebar.has_method("press"):
		sidebar.press(0)

# ==============================================================================
# Publish Logic
# ==============================================================================

func _publish_post():
	if !Community.is_logged_in():
		_set_publish_alert("请先登录社区账号后再发布动态", COLOR_WARNING)
		return

	var title_text = post_title_edit.text.strip_edges()
	var body_text = post_body_edit.text.strip_edges()

	if title_text.length() < 2:
		_set_publish_alert("标题太短，请输入至少 2 个字符", COLOR_WARNING)
		return
	if body_text.length() < 2:
		_set_publish_alert("内容太短，请输入至少 2 个字符", COLOR_WARNING)
		return

	publish_button.disabled = true
	_set_publish_alert("正在发布...", COLOR_TEXT_MUTED)

	var response = await Community.create_post(title_text, body_text)
	publish_button.disabled = false

	if response.get("ok", false):
		post_title_edit.clear()
		post_body_edit.text = ""
		_on_post_title_changed("")
		_on_post_body_changed()
		_set_publish_alert("动态发布成功！", COLOR_SUCCESS)
		Globals.notify(Globals.NOTIFY_SUCCESS, "动态已成功发布至社区", "发布成功")
		refresh_feed()
		_switch_tab(0) # Jump to feed tab to see post
	else:
		_set_publish_alert(_error_message(response), COLOR_DANGER)

func _set_publish_alert(msg:String, col:Color):
	if _publish_alert_label:
		_publish_alert_label.text = msg
		_publish_alert_label.add_theme_color_override("font_color", col)

# ==============================================================================
# Authentication & Account Logic
# ==============================================================================

func _login():
	var u = username_edit.text.strip_edges()
	var p = password_edit.text.strip_edges()
	if u.is_empty() or p.is_empty():
		_set_account_alert("请输入用户名和密码", false)
		return

	_set_account_alert("正在登录...", false, true)
	var response = await Community.login(u, p)
	if response.get("ok", false):
		_set_account_alert("登录成功！欢迎回来。", true)
		password_edit.clear()
		_update_account_state()
		refresh_feed()
	else:
		_set_account_alert(_error_message(response), false)

func _register():
	var u = _reg_username_edit.text.strip_edges()
	var d = _reg_display_name_edit.text.strip_edges()
	var p = _reg_password_edit.text.strip_edges()
	var pc = _reg_password_confirm_edit.text.strip_edges()

	if u.length() < 3:
		_set_account_alert("用户名长度需在 3-24 个字符之间", false)
		return
	if p.length() < 6:
		_set_account_alert("密码长度不能少于 6 个字符", false)
		return
	if p != pc:
		_set_account_alert("两次输入的密码不一致", false)
		return

	_set_account_alert("正在注册账号...", false, true)
	var response = await Community.register(u, d, p)
	if response.get("ok", false):
		_set_account_alert("注册成功！欢迎加入社区。", true)
		_reg_password_edit.clear()
		_reg_password_confirm_edit.clear()
		_update_account_state()
		refresh_feed()
	else:
		_set_account_alert(_error_message(response), false)

func _logout():
	await Community.logout()
	_set_account_alert("已安全退出登录", true)
	_update_account_state()
	refresh_feed()

func _update_account_state():
	var logged_in = Community.is_logged_in()

	# Compatibility account_label
	if account_label:
		if logged_in:
			account_label.text = "当前账号：%s" % Community.current_user.get("display_name", Community.current_user.get("username", ""))
		else:
			account_label.text = "当前未登录"

	# Update Top Account Chip
	if _account_chip_btn:
		if logged_in:
			var d_name = Community.current_user.get("display_name", Community.current_user.get("username", "玩家"))
			_account_chip_btn.text = "%s (个人中心)" % d_name
		else:
			_account_chip_btn.text = "未登录 (点击登录)"

	# Update Publish Tab warning
	if _publish_auth_warning:
		_publish_auth_warning.visible = !logged_in

	# Toggle Account Tab Views
	var auth_box = find_child("AuthBox", true, false)
	if auth_box:
		auth_box.visible = !logged_in
	if _profile_container:
		_profile_container.visible = logged_in
		if logged_in:
			_refresh_account_profile_view()

func _set_account_alert(msg:String, is_success:bool, is_info:bool=false):
	if _account_alert_label:
		_account_alert_label.text = msg
		_account_alert_label.visible = !msg.is_empty()
		if is_info:
			_account_alert_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		elif is_success:
			_account_alert_label.add_theme_color_override("font_color", COLOR_SUCCESS)
		else:
			_account_alert_label.add_theme_color_override("font_color", COLOR_DANGER)

func _set_status_state(text:String, color:Color):
	if status_label:
		status_label.text = text
	if _status_dot:
		_status_dot.color = color

# ==============================================================================
# Visual Style Helpers
# ==============================================================================

func _create_card_style(bg:Color, border:Color=Color.TRANSPARENT, radius:int=8, border_w:int=1) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	if border != Color.TRANSPARENT and border_w > 0:
		sb.border_width_left = border_w
		sb.border_width_top = border_w
		sb.border_width_right = border_w
		sb.border_width_bottom = border_w
		sb.border_color = border
	return sb

func _style_button(btn:Button, primary:bool=false, danger:bool=false, height:int=32):
	btn.custom_minimum_size.y = height

	# Crucial: Override theme colors to guarantee high contrast white text
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.90, 0.96))
	btn.add_theme_color_override("font_focus_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.65, 0.62, 0.70))

	var sb_norm = StyleBoxFlat.new()
	sb_norm.corner_radius_top_left = 6
	sb_norm.corner_radius_top_right = 6
	sb_norm.corner_radius_bottom_right = 6
	sb_norm.corner_radius_bottom_left = 6
	sb_norm.border_width_left = 1
	sb_norm.border_width_top = 1
	sb_norm.border_width_right = 1
	sb_norm.border_width_bottom = 1

	if danger:
		sb_norm.bg_color = Color(0.65, 0.20, 0.25, 0.90)
		sb_norm.border_color = COLOR_DANGER
	elif primary:
		sb_norm.bg_color = COLOR_PRIMARY
		sb_norm.border_color = COLOR_ACCENT_CYAN
	else:
		sb_norm.bg_color = COLOR_SECONDARY
		sb_norm.border_color = COLOR_SECONDARY_BORDER

	btn.add_theme_stylebox_override("normal", sb_norm)

	var sb_hover = sb_norm.duplicate()
	if danger:
		sb_hover.bg_color = Color(0.82, 0.25, 0.32, 0.98)
	elif primary:
		sb_hover.bg_color = COLOR_PRIMARY_HOVER
	else:
		sb_hover.bg_color = COLOR_SECONDARY_HOVER
	btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed = sb_norm.duplicate()
	sb_pressed.bg_color = COLOR_PRIMARY_PRESSED if primary else Color(0.14, 0.10, 0.22, 0.98)
	btn.add_theme_stylebox_override("pressed", sb_pressed)

func _style_pill_button(btn:Button, active:bool):
	btn.add_theme_color_override("font_color", Color.WHITE if active else Color(0.94, 0.92, 0.98))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.90, 0.96))
	btn.add_theme_color_override("font_focus_color", Color.WHITE)

	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1

	if active:
		sb.bg_color = COLOR_PRIMARY
		sb.border_color = COLOR_ACCENT_CYAN
	else:
		sb.bg_color = COLOR_SECONDARY
		sb.border_color = COLOR_SECONDARY_BORDER
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover = sb.duplicate()
	sb_hover.bg_color = COLOR_PRIMARY_HOVER if active else COLOR_SECONDARY_HOVER
	btn.add_theme_stylebox_override("hover", sb_hover)

func _style_input(input:LineEdit, height:int=34):
	input.custom_minimum_size.y = height
	input.add_theme_color_override("font_color", Color.WHITE)
	input.add_theme_color_override("font_selected_color", Color.WHITE)
	input.add_theme_color_override("placeholder_color", Color(0.75, 0.72, 0.82, 0.85))
	input.add_theme_color_override("caret_color", Color(0.90, 0.70, 1.0))

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.07, 0.14, 0.95)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = COLOR_CARD_BORDER
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	input.add_theme_stylebox_override("normal", sb)

	var sb_focus = sb.duplicate()
	sb_focus.border_color = COLOR_PRIMARY_HOVER
	input.add_theme_stylebox_override("focus", sb_focus)

func _style_text_edit(edit:TextEdit):
	edit.add_theme_color_override("font_color", Color.WHITE)
	edit.add_theme_color_override("font_selected_color", Color.WHITE)
	edit.add_theme_color_override("font_readonly_color", Color(0.75, 0.72, 0.82))
	edit.add_theme_color_override("caret_color", Color(0.90, 0.70, 1.0))

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.07, 0.14, 0.95)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = COLOR_CARD_BORDER
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	edit.add_theme_stylebox_override("normal", sb)

	var sb_focus = sb.duplicate()
	sb_focus.border_color = COLOR_PRIMARY_HOVER
	edit.add_theme_stylebox_override("focus", sb_focus)

func _create_badge(text:String, bg_col:Color, text_col:Color) -> PanelContainer:
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	panel.add_child(margin)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", text_col)
	margin.add_child(lbl)
	return panel

func _create_avatar_box(seed_name:String, avatar_size:int=36) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(avatar_size, avatar_size)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var sb = StyleBoxFlat.new()
	sb.bg_color = _get_avatar_color(seed_name)
	var r = int(avatar_size / 2.0)
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_right = r
	sb.corner_radius_bottom_left = r
	panel.add_theme_stylebox_override("panel", sb)

	var lbl = Label.new()
	lbl.text = seed_name.substr(0, 1).to_upper() if seed_name.length() > 0 else "R"
	lbl.add_theme_font_size_override("font_size", int(avatar_size * 0.45))
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(lbl)

	return panel

func _create_empty_state_card(title_txt:String, desc_txt:String, action_btn_txt:String="", on_action:Callable=Callable()) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 120
	panel.add_theme_stylebox_override("panel", _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 10, 1))

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var t = Label.new()
	t.text = title_txt
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(t)

	var d = Label.new()
	d.text = desc_txt
	d.add_theme_font_size_override("font_size", 13)
	d.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(d)

	if action_btn_txt != "" and on_action.is_valid():
		var btn = Button.new()
		btn.text = action_btn_txt
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_style_button(btn, true, false, 32)
		btn.pressed.connect(on_action)
		vbox.add_child(btn)

	return panel

func _get_avatar_color(s:String) -> Color:
	var h = abs(s.hash()) % 7
	match h:
		0: return Color(0.58, 0.28, 0.88) # Purple
		1: return Color(0.25, 0.68, 0.92) # Blue
		2: return Color(0.20, 0.78, 0.52) # Emerald
		3: return Color(0.92, 0.44, 0.22) # Orange
		4: return Color(0.88, 0.28, 0.48) # Rose
		5: return Color(0.44, 0.38, 0.88) # Indigo
		_: return Color(0.22, 0.78, 0.84) # Teal

func _format_time(iso_str:String) -> String:
	if iso_str.is_empty():
		return ""
	var s = iso_str.replace("T", " ")
	if s.length() >= 16:
		return s.substr(0, 16)
	return s

func _error_message(response:Dictionary) -> String:
	var error = response.get("error", {})
	return String(error.get("message", "社区请求失败")) if error is Dictionary else "社区请求失败"

func _clear_children(node:Node):
	if !is_instance_valid(node):
		return
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
